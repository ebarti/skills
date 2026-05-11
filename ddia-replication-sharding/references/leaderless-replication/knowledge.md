# Leaderless Replication Knowledge

Core concepts for Dynamo-style leaderless replication, where any replica accepts writes and clients coordinate reads/writes across multiple nodes.

## Overview

Leaderless replication abandons the leader concept: any replica can accept writes from clients directly (or via a coordinator that does not enforce ordering). Popularized by Amazon's 2007 Dynamo paper, this model trades strict consistency for fault tolerance and is the basis for Cassandra, Riak, ScyllaDB, and Voldemort.

## Key Concepts

### Leaderless Replication

**Definition**: Replication style with no designated leader; any replica accepts writes, and clients send reads/writes to multiple replicas in parallel.

**Key points**:
- No failover (all replicas are equal)
- Client (or coordinator) sends writes to several replicas in parallel
- Coordinator does NOT enforce write ordering (unlike a leader)
- Also called "Dynamo-style" after Amazon's original Dynamo system

### Quorum (n, w, r)

**Definition**: A configuration where every value is stored on `n` replicas, every write must be confirmed by `w` nodes, and every read must query `r` nodes.

**Key points**:
- `n` = number of replicas per value (commonly 3 or 5)
- `w` = write quorum (nodes that must acknowledge a write)
- `r` = read quorum (nodes that must respond to a read)
- Common choice: `w = r = (n+1)/2` (rounded up)
- If fewer than `w` or `r` nodes are available, the operation returns an error

### w + r > n (Quorum Condition)

**Definition**: The overlap condition that guarantees the read set and write set share at least one node, ensuring at least one replica returns the latest value.

**Key points**:
- Every value tagged with version/timestamp; client picks the highest
- Quorums need not be majorities, only that read/write sets overlap
- Even with `w + r > n`, NOT linearizable (only "probably newest")

### Read Repair

**Definition**: When a client receives differing values from a parallel read, it writes the newest value back to replicas that returned stale values.

**Key points**:
- Works only for values that are read often
- Repairs happen during normal read operations (no background process)

### Hinted Handoff

**Definition**: When a replica is unavailable, another replica temporarily stores writes (hints) on its behalf and forwards them when the replica recovers.

### Anti-Entropy

**Definition**: A background process that periodically scans replicas for differences and copies missing data, with no ordering guarantees.

### Sloppy Quorum

**Definition**: A configuration where any reachable replica may accept a write even if it is not one of the usual `n` replicas for that key (Cassandra/ScyllaDB call this consistency level ANY).

**Key points**:
- Increases write availability during network partitions
- Subsequent reads may not see the written value
- Requires hinted handoff to deliver writes back to home replicas

### Happens-Before Relation

**Definition**: Operation A happens-before B if B knows about, depends on, or builds upon A. Two operations are concurrent if neither happens-before the other.

**Key points**:
- Concurrency is NOT about overlapping in physical time
- Two ops are concurrent if both are unaware of each other
- Three possibilities: A→B, B→A, or A∥B (concurrent)

### Version Vector

**Definition**: A collection of version numbers, one per replica, used to detect concurrent writes across multiple leaderless replicas.

**Key points**:
- Single version number works for one replica; multiple replicas need a vector
- Each replica increments its own counter on write and tracks counters seen from other replicas
- Sent from database to client on read; sent back on write (Riak calls this "causal context")
- Distinguishes overwrites from concurrent writes (siblings)

### Vector Clock vs Version Vector

**Definition**: Often conflated. Version vectors are the correct structure for comparing replica states; vector clocks track logical event ordering. The distinction is subtle.

### Lamport Timestamp (briefly)

**Definition**: A simpler logical clock that produces a total ordering of events but cannot distinguish concurrent operations from causally related ones (covered in Chapter 9).

## Terminology

| Term | Definition |
|------|------------|
| Dynamo-style | Leaderless replication architecture from Amazon's 2007 Dynamo paper |
| n | Number of replicas storing each value |
| w | Write quorum (acks required for successful write) |
| r | Read quorum (responses required for successful read) |
| Sibling | Concurrent value kept alongside other values for the same key |
| Coordinator | Node that forwards a client request to replicas |
| Causal context | Riak's serialized form of the version vector |
| Request hedging | Using fastest responses to reduce tail latency |
| Gray failure | Node not down but degraded/slow |

## How It Relates To

- **Single-leader replication**: Trades strict ordering for availability; no failover required
- **Multi-leader replication**: Both allow concurrent writes and need conflict resolution; multi-leader uses one leader per region
- **Conflict resolution**: LWW, manual merge, and CRDTs all apply (CRDTs used by Riak, LWW by Cassandra/ScyllaDB)
- **Sharding**: There may be more than n nodes in the cluster; each value lives on n nodes

## Common Misconceptions

- **Myth**: Quorum reads (`w + r > n`) guarantee linearizability.
  **Reality**: Only "probably newest" — edge cases (failed writes, rebalancing, concurrent reads/writes, clock skew) can violate this.

- **Myth**: Amazon DynamoDB uses leaderless Dynamo-style replication.
  **Reality**: Amazon DynamoDB is unrelated — it uses single-leader replication based on Multi-Paxos. Only the original 2007 Dynamo paper was leaderless.

- **Myth**: Concurrent operations must overlap in physical time.
  **Reality**: Concurrent means neither knows about the other, regardless of clock time.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Quorum condition | `w + r > n` ensures read and write sets overlap |
| Read repair | Client repairs stale replicas during reads |
| Hinted handoff | Healthy replica holds writes for unavailable peer |
| Anti-entropy | Background sync of differences across replicas |
| Sloppy quorum | Accept writes on any reachable replica when partitioned |
| Version vector | Per-replica version numbers detect concurrent writes |
