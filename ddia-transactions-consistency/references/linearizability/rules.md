# Linearizability and Logical Clocks Rules

Decision rules for when to require linearizability, when to fall back to logical clocks, and how to read CAP correctly.

## Core Rules

### 1. Require linearizability for distributed locks and leader election

Split brain is a correctness bug, not a performance issue. Lease acquisition and leader election must be linearizable so two nodes never both hold the lock or believe they are leader.

- Use ZooKeeper, etcd, or another consensus-backed coordinator
- ZooKeeper writes are linearizable, but reads may be stale unless you `sync()` first
- etcd v3+ provides linearizable reads by default
- Combine with fencing tokens at the storage layer to defend against stale lock holders

### 2. Require linearizability for hard uniqueness constraints

A hard constraint (unique username, unique email, unique file path) needs all nodes to agree on a single up-to-date value. Effectively a CAS on the resource name.

- Username/email registration: linearizable
- "Account balance never goes negative" with strict enforcement: linearizable
- Foreign-key and attribute constraints: do **not** need linearizability
- Soft uniqueness ("flight overbooked, compensate later"): can drop linearizability

### 3. Require linearizability across cross-channel timing dependencies

When information flows through two channels (e.g., file storage + message queue, or push notification + database fetch), without linearizability the second channel can outrun the first and read stale or missing data.

- Video upload → enqueue transcode job: storage must be linearizable, or the job sees old data
- Push notification → app refetches: backing store must be linearizable, or the fetch misses the new record
- Alternative: use the read-your-writes pattern at the cost of additional plumbing

### 4. Treat CAP as "C or A *when* partitioned" — never "pick 2 of 3"

Network partitions are inevitable, not chosen. The real choice surfaces only during a partition.

- CP system: refuses or stalls writes from a partitioned minority (etcd, ZooKeeper, Spanner)
- AP system: keeps accepting writes locally; reconciles later (multi-leader, Dynamo-style)
- Most systems also drop linearizability during normal operation for **latency**, not just for partition tolerance (PACELC)

### 5. Accept the latency cost of linearizability

Attiya–Welch: linearizable read/write response time is at least proportional to network delay uncertainty. There is no faster algorithm.

- Geo-distributed linearizable reads pay cross-region RTT
- Even multi-core CPU caches drop linearizability for speed (memory barriers required)
- If latency matters more than recency, choose a weaker model (read-your-writes, monotonic reads)

### 6. Use Lamport timestamps when you need a causal total order, not recency

Lamport clocks give a unique, causally-consistent ordering at minimal cost. They do **not** give linearizability.

- Good for: snapshot isolation transaction IDs, event ordering within a session
- Algorithm: every event increments local counter; on receiving a remote timestamp, `local = max(local, remote)` before incrementing
- Tiebreak by node ID
- Cannot tell whether two events were truly concurrent

### 7. Use vector clocks only when you need to detect concurrency

If your application must distinguish "A happened before B" from "A and B were concurrent" (e.g., to merge them), use a vector clock — but pay the per-node storage cost.

- Classic case: Dynamo-style shopping cart merging concurrent adds
- Storage: one integer per node per timestamp — heavy with many nodes
- If you only need ordering, prefer Lamport or HLC

### 8. Use HLC when you want wall-clock-ish timestamps with causal ordering

HLC gives you human-readable timestamps that move monotonically and respect happens-before. Excellent default for distributed databases.

- Used by CockroachDB and MongoDB
- Survives NTP backward jumps without re-issuing duplicate timestamps
- Requires only roughly synchronized clocks — no atomic clocks needed

### 9. Use TrueTime / commit-wait only when you have the hardware

Spanner's approach gives linearizable IDs without coordination, but requires GPS + atomic clocks and tight uncertainty bounds. Without that, the wait dominates latency.

### 10. Logical clocks alone are not enough for locks or uniqueness

You can pick "the lowest timestamp wins," but determining your timestamp *is* the lowest requires hearing from every node — which fails if any node is unreachable. For fault-tolerant locks, leases, or constraints, you need **consensus**, not just a logical clock.

## Guidelines

- Default to a single-leader (consensus-backed) system if any of locks, uniqueness, or cross-channel ordering apply
- If you choose AP, design for conflict resolution from day one (CRDTs, vector clocks, application-level merge)
- Avoid LWW with wall-clock timestamps (Cassandra-style) when correctness depends on ordering — clock skew breaks it
- Sharding a single-leader DB does not break per-shard linearizability, but cross-shard transactions do
- Batched ID allocation amortizes the latency cost of a linearizable ID generator at the price of skipped IDs after a crash

## Exceptions

When these rules may be relaxed:

- **Loose constraints**: Overbookings tolerated with later compensation — drop linearizability for availability
- **Latency-critical reads**: Sports scores, social feeds, analytics — stale data is acceptable
- **Single-region deployments with reliable networks**: The CAP penalty is rarely felt in practice
- **Same-device session**: Track latest write timestamp client-side instead of server-side linearizability

## Quick Reference

| Rule | Summary |
|------|---------|
| Locks / leader election | Need linearizability — use consensus |
| Hard uniqueness | Need linearizability — CAS-equivalent |
| Cross-channel deps | Need linearizability or explicit RYW |
| CAP framing | "C or A when partitioned," not pick-2-of-3 |
| Latency cost | Always present, not just during partition (PACELC) |
| Lamport | Causal total order, no recency |
| Vector clock | Only when concurrency detection required |
| HLC | Default for distributed DB timestamps |
| TrueTime | Needs GPS/atomic clock hardware |
| Logical clocks ≠ locks | Need consensus for fault-tolerant locks |
