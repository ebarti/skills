# Linearizability and Logical Clocks Knowledge

Core concepts for the strongest single-object consistency model and the logical clock alternatives engineers reach for when full linearizability is too costly.

## Overview

Linearizability makes a replicated system appear to clients as if there were a single copy of the data, with every operation taking effect atomically at some point between its invocation and response. It is the strongest common consistency model and underpins distributed locks, leader election, and uniqueness constraints — but it has unavoidable performance and availability costs, which is why systems often substitute logical clocks instead.

## Key Concepts

### Linearizability (atomic / strong / immediate / external consistency)

**Definition**: A recency guarantee on reads and writes of a single object (register): if operation A finishes before operation B starts (in real time), B must observe a state at least as new as A.

**Key points**:
- Each operation takes effect atomically at some point between invocation and response
- Once any client reads a new value, all subsequent reads must see that value or newer
- Concerns one register at a time — does not group operations into transactions
- Implementable via single-leader replication or consensus algorithms; not generally achievable with multi-leader or Dynamo-style leaderless replication

### Linearizability vs Serializability

**Definition**: Two distinct guarantees commonly confused because both involve "sequential order."

| Property | Serializability | Linearizability |
|----------|-----------------|-----------------|
| Scope | Multiple objects, in transactions | Single object (register) |
| Guarantee | Equivalent to *some* serial order | Recency — order matches real time |
| Allows stale reads? | Yes | No |
| Combination | Together = "strict serializability" / strong-1SR (e.g., Spanner, FoundationDB) |

### CAP Theorem

**Definition**: When a network partition occurs, a system must choose between linearizability (CP) and availability (AP).

**Key points**:
- Better phrased as: "either Consistent or Available *when* Partitioned"
- The "pick 2 of 3" framing is misleading — partitions are not optional
- Considers only one consistency model (linearizability) and one fault (network partition)
- Says nothing about latency, network delays, or weaker consistency models
- Largely of historical interest today; PACELC adds the non-partition (latency vs consistency) trade-off

### Lamport Timestamp

**Definition**: A logical clock pair `(counter, node_id)` that produces a total ordering consistent with causality (happens-before).

**Algorithm**:
- Each node maintains a counter; increments on every event
- On receiving a timestamp, set local counter = max(local, received) before incrementing
- Compare timestamps by counter first, then node_id as tiebreaker

**Limitations**: Not linearizable (no recency); cannot tell whether two events were truly concurrent or sequential.

### Vector Clock

**Definition**: One counter per node, attached to each event; explicitly detects concurrency.

**Key points**:
- A < B if every component of A ≤ B (and at least one is strictly less)
- A and B concurrent if neither dominates the other
- Higher storage cost: O(N) per timestamp

### Hybrid Logical Clock (HLC)

**Definition**: Combines a physical wall-clock timestamp with a Lamport-style logical counter so timestamps are roughly comparable to time-of-day yet remain causally consistent.

**Key points**:
- Moves forward monotonically even when NTP jumps the physical clock backward
- On receiving a higher remote timestamp, advances local clock to match
- Used by CockroachDB and MongoDB; needs only roughly synchronized clocks

### TrueTime (Spanner)

**Definition**: A clock API returning a bounded uncertainty interval `[earliest, latest]` rather than a single timestamp.

**Key points**:
- Spanner waits out the uncertainty interval (commit-wait) before returning
- Yields linearizable ID assignment without cross-region coordination
- Requires GPS + atomic clocks for tight bounds

### Linearizable ID Generator

**Definition**: A counter source whose IDs respect real-time order — request A finishing before B starts implies `id(A) < id(B)`.

**Implementations**:
- Single-node fetch-and-add with persistence + single-leader replication (timestamp oracle, e.g., TiDB/TiKV inspired by Google Percolator)
- Batched preallocation to amortize disk + network cost
- Spanner-style: wait out clock uncertainty interval

## Terminology

| Term | Definition |
|------|------------|
| Register | A single mutable object (key, row, document) |
| CAS | Compare-and-set; atomic conditional write |
| Recency guarantee | Reads observe the most recent committed write |
| Strict serializability (strong-1SR) | Serializability + linearizability |
| Split brain | Two nodes simultaneously believing they are leader |
| Fencing token | Monotonic ID that lets storage reject stale lock holders |
| Timestamp oracle | A linearizable single-node ID/timestamp service |
| PACELC | Partition: A vs C; Else: Latency vs C |

## How It Relates To

- **Consensus**: The fault-tolerant primitive used to *implement* linearizable systems (ZooKeeper/Zab, etcd/Raft)
- **Distributed locks**: Require linearizability to prevent split brain
- **Snapshot isolation / MVCC**: Often uses Lamport or HLC timestamps for transaction IDs
- **Replication lag**: Read-after-write, monotonic reads, consistent prefix are weaker models linearizability subsumes
- **Clock skew**: Why time-of-day timestamps (Cassandra LWW) cannot give linearizability

## Common Misconceptions

- **Myth**: CAP forces you to "pick 2 of 3."
  **Reality**: Partitions happen whether you pick them or not; the real trade-off is C vs A *during* a partition.

- **Myth**: Quorum reads/writes (w + r > n) give linearizability.
  **Reality**: They do not, due to variable network delays. Synchronous read repair + per-write timestamp checks are needed, and even then LWW with wall-clock timestamps breaks it.

- **Myth**: Lamport timestamps give linearizability.
  **Reality**: They give a causally-consistent total order, but no recency guarantee — two non-communicating nodes can disagree.

- **Myth**: Linearizability is only sacrificed for fault tolerance.
  **Reality**: Most often it is sacrificed for *performance*. Even multi-core CPU caches drop linearizability for speed.

- **Myth**: Serializability implies linearizability.
  **Reality**: No — serializability allows stale reads. Strict serializability is the combination.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Linearizability | Single-object recency: as if one copy, atomic operations |
| Serializability | Multi-object isolation: as if some serial transaction order |
| CAP | During a partition, pick consistency or availability |
| Lamport timestamp | (counter, node_id) — causally-ordered total order |
| Vector clock | Per-node counter array — detects concurrency explicitly |
| HLC | Physical clock + logical counter — monotonic, causal |
| TrueTime | Bounded uncertainty interval; wait it out |
| Linearizable ID | Single-leader counter or commit-wait; respects real time |
