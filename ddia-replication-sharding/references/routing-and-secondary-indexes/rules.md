# Request Routing & Secondary Indexes Rules

Design guidance for routing layers and sharded secondary indexes.

## Core Rules

### 1. Pick the routing approach to match operational maturity

Trade-off summary:

- **Forwarding (any node)** — simplest to deploy; clients use a plain LB. Cost: an extra hop per misrouted request. Often combined with a gossip protocol so every node knows the map.
- **Routing tier (proxy)** — clean separation of concerns; clients are dumb. Cost: extra component to deploy, scale, and monitor. Examples: MongoDB `mongos`, Couchbase `moxi`, Twemproxy/Mcrouter.
- **Partition-aware client** — best latency, no intermediary. Cost: client library must subscribe to the shard map and handle reassignments correctly.

### 2. Use a consensus-based coordinator for the shard map

Use ZooKeeper, etcd, or built-in Raft to hold the *authoritative* assignment of shards to nodes:

- Each node registers itself in the coordinator.
- Routing tier and clients subscribe and are notified on change.
- Consensus prevents split brain when the coordinator role itself fails over.

Only fall back to gossip (Cassandra, Riak) when the database already accepts weak consistency (leaderless model).

### 3. Handle the cutover period during shard moves

While a shard moves from node A to node B, requests already in flight to A may need to be redirected. Plan for:

- Forwarding old → new during handoff, OR
- Returning a "moved" response so the client retries against the new owner.

### 4. Choose local SI when writes dominate

Local (document-partitioned) secondary indexes:

- **Write**: single shard, cheap.
- **Read without partition key**: scatter-gather across all shards, expensive.
- Best when writes are heavy or queries usually include the partition key.

### 5. Choose global SI when reads dominate

Global (term-partitioned) secondary indexes:

- **Read of a single term**: one shard, cheap.
- **Write**: each indexed term may live on a different shard — multi-shard write.
- Use when read throughput >> write throughput and postings lists stay reasonably short.

### 6. Decide how to keep global SIs consistent with primary data

A single record write may touch many SI shards. Pick a strategy:

- **Distributed transaction** — atomic but slow (CockroachDB, TiDB, YugabyteDB style).
- **Asynchronous update** — fast but reads may be stale (DynamoDB GSIs).

State the consistency contract explicitly so callers know whether SI reads can lag.

### 7. Avoid scatter-gather where possible

Scatter-gather queries are bound by the slowest shard (tail latency amplification) and do not benefit from adding more shards. Mitigations:

- Include the partition key in queries when possible.
- Limit fan-out by routing on a secondary partition key.
- Cap result counts so partial results from any shard are acceptable.

### 8. Use DNS for stable node addressing

Node IP addresses change much less often than shard assignments. DNS is sufficient for the address layer; the coordinator handles the fast-changing shard-to-node map.

## Guidelines

- For OLTP, route per single key. For analytical/parallel queries, expect every shard to participate (different problem — see batch processing).
- Don't roll your own SI by writing value→ID mappings in app code over a key-value store; race conditions and partial failures will desync the index.
- If you must build SIs in app code, wrap them in multi-object transactions.
- Treat the routing layer as a hot path — instrument latency per hop and per shard.

## Exceptions

- **Leaderless DBs (Cassandra, Riak)**: gossip is acceptable because consistency is already weak.
- **Small clusters**: a single coordinator without HA may be fine in dev/staging.
- **Read-mostly workloads with stable terms**: a global SI's write cost is amortized.

## Quick Reference

| Decision | Default | Use Other When |
|----------|---------|---------------|
| Routing approach | Routing tier | High-perf client → partition-aware; tiny ops → forwarding+gossip |
| Coordinator | ZooKeeper/etcd/Raft | Leaderless data model → gossip |
| SI type | Local | Read-heavy single-term lookups → global |
| SI write consistency | Sync (distributed txn) | Latency-sensitive writes, can tolerate stale reads → async |
| Address resolution | DNS | — |
