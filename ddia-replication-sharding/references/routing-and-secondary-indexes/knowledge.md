# Request Routing & Secondary Indexes Knowledge

Core concepts for routing requests to the correct shard and for sharding secondary indexes.

## Overview

Once data is sharded across nodes, two questions arise: (1) how does a client find the node that owns a given key? and (2) how do we index by attributes other than the partition key? Request routing solves the first; local and global secondary indexes are the two answers to the second.

## Key Concepts

### Request Routing

**Definition**: Determining which node (IP and port) should handle a read or write for a particular key.

Closely related to *service discovery*, but stricter: a sharded request must go to a replica of the right shard, not to any random instance.

**Three approaches** (Figure 7-7):

1. **Client to any node (forwarding)** — Client uses round-robin or load balancer; node forwards to the right node if it doesn't own the shard.
2. **Routing tier (proxy)** — A shard-aware load balancer in front of nodes routes every request; clients are oblivious to sharding.
3. **Partition-aware client** — Client knows the shard map and connects directly to the correct node, no intermediary.

### Service Discovery vs. Request Routing

Service discovery sends requests to any stateless instance; request routing must target the *replica that owns this specific key*. Routing must be aware of two mappings: keys to shards, and shards to nodes.

### Coordination Service

**Definition**: An external system (ZooKeeper, etcd) that holds the authoritative shard-to-node assignment using a consensus algorithm.

Each node registers itself; routing tier and clients subscribe for updates and are notified on changes (rebalancing, node add/remove).

### Gossip Protocol (alternative to coordination)

Nodes disseminate cluster-state changes peer-to-peer. Weaker consistency than consensus — split brain is possible. Acceptable for leaderless databases that already have weak consistency.

### Local Secondary Index (Document-Partitioned)

**Definition**: Each shard maintains its own secondary index, covering only records living on that shard.

- Writes touch only one shard (the one holding the record).
- Reads without partition key require **scatter-gather** across all shards.

### Global Secondary Index (Term-Partitioned)

**Definition**: A single logical secondary index that spans all primary-key shards, itself sharded by the indexed term.

- A term (e.g. `color:red`) lives on exactly one index shard.
- Reads of a single condition hit one shard; writes touch many shards.

### Scatter-Gather Query

**Definition**: A query pattern in which the coordinator sends the request to every shard in parallel and merges the responses.

Suffers from **tail latency amplification**: total latency ~= slowest shard. Throughput does not scale with more shards because every shard processes every query.

### Postings List

The list of record IDs associated with a single index entry (term). Generalized from full-text search.

## Terminology

| Term | Definition |
|------|------------|
| Request routing | Mapping a key request to the node that owns it |
| Routing tier | Stateless shard-aware proxy that forwards client requests |
| Partition-aware client | Client embedding the shard map; talks directly to owning node |
| Coordination service | External consensus-based store of shard assignments (ZooKeeper, etcd) |
| Gossip protocol | Peer-to-peer dissemination of cluster state, weaker than consensus |
| Local secondary index | Per-shard SI; document-partitioned |
| Global secondary index | Cross-shard SI sharded by term; term-partitioned |
| Term | Any value indexable in a secondary index (generalized from IR keyword) |
| Scatter-gather | Query that fans out to all shards and merges results |
| Postings list | List of record IDs for a given index term |

## How It Relates To

- **Sharding strategies**: Routing answers "where is this key?" given the chosen partition scheme.
- **Replication**: Routing must target a node that is a *replica* of the shard, not just any node.
- **Rebalancing**: Routing tables must update as shards move between nodes; the cutover period needs special handling.
- **Distributed transactions**: Global SI writes that touch multiple shards may require atomic cross-shard updates.
- **Tail latency**: Scatter-gather over local SIs is sensitive to slow shards.

## Common Misconceptions

- **Myth**: A routing tier handles requests itself.
  **Reality**: It only routes; it is a stateless shard-aware load balancer.

- **Myth**: Global indexes are always better because reads are cheaper.
  **Reality**: Writes are more expensive (multi-shard) and may require distributed transactions or lag asynchronously.

- **Myth**: Adding shards always improves SI query throughput.
  **Reality**: With local SIs, every shard processes every scatter-gather query, so throughput does not improve.

- **Myth**: Gossip and ZooKeeper-style coordination are interchangeable.
  **Reality**: Gossip can produce split brain; only consensus-based coordination guarantees a single authoritative assignment.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Forwarding routing | Any node accepts; forwards if needed (simple, extra hop) |
| Routing tier | Dedicated proxy layer (clean separation) |
| Partition-aware client | Client routes itself (highest performance) |
| ZooKeeper/etcd | Consensus-backed authoritative shard map |
| Gossip | Peer-to-peer state dissemination, eventual |
| Local SI | Cheap writes, scatter-gather reads |
| Global SI | Cheap reads, multi-shard writes |
