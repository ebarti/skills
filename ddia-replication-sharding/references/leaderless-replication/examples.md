# Leaderless Replication Examples

Real Dynamo-style systems, quorum math, and concurrency walkthroughs.

## Real Systems

| System | Conflict Resolution | Notes |
|--------|--------------------|-------|
| Cassandra | LWW (real-time clock) | "Consistency level ANY" = sloppy quorum |
| ScyllaDB | LWW (real-time clock) | Cassandra-compatible |
| Riak | CRDTs, version vectors | Encodes version vector as "causal context"; uses dotted version vectors in 2.0+ |
| Voldemort | Version vectors | LinkedIn's open-source Dynamo-style store |
| Original Dynamo (Amazon, 2007) | Per-paper | NEVER released outside Amazon |
| Amazon DynamoDB (cloud) | NOT leaderless | Single-leader, Multi-Paxos — unrelated to original Dynamo |

## Quorum Math

### Basic 3-Replica Setup

```
n = 3, w = 2, r = 2
w + r = 4 > 3 (quorum satisfied)
Tolerates: 1 unavailable node
```

### 5-Replica Setup

```
n = 5, w = 3, r = 3
w + r = 6 > 5 (quorum satisfied)
Tolerates: 2 unavailable nodes
```

### Read-Optimized Setup

```
n = 3, w = 3, r = 1
w + r = 4 > 3 (quorum satisfied)
Tolerates: 0 unavailable nodes for writes (any node failure breaks writes)
Reads: fast (single node)
```

### Quorum-Failing Setup

```
n = 3, w = 1, r = 1
w + r = 2, NOT > 3 (quorum NOT satisfied)
Higher availability, lower latency
Higher probability of stale reads
```

## Read Repair Walkthrough

```
Setup: n=3, w=2, r=2

Initial write (user 1234 writes value v7):
  Client → Replica 1, Replica 2, Replica 3 (all in parallel)
  Replica 3 is offline; Replicas 1, 2 ack
  Client receives 2 OKs → write succeeds (replica 3 missed it)

Replica 3 comes back online with stale value v6.

Subsequent read (user 2345 reads):
  Client → Replicas 1, 2, 3 (all in parallel)
  Response from Replica 1: v7
  Response from Replica 2: v7
  Response from Replica 3: v6  ← stale!

Client picks v7 (highest version).
Client writes v7 back to Replica 3 (read repair).
Replica 3 now consistent.
```

## Concurrent Shopping Cart Walkthrough (Single Replica with Version Numbers)

Two clients add items concurrently to the same cart. Server tracks version per key and returns siblings when writes are concurrent.

```
1. Client 1: addToCart(milk)            v0 → v1 = [milk]
   Server returns: v1, [milk]

2. Client 2: addToCart(eggs)            v? → v2
   Client 2 did NOT read first, so this is concurrent with v1.
   Server stores eggs as a sibling of milk.
   v2 = [milk] + [eggs] (siblings)
   Server returns: v2, [[milk], [eggs]]

3. Client 1: addToCart(flour) at v1
   Client 1 sends [milk, flour] with v1.
   Server: v1 superseded; [milk] removed.
   Server: [eggs] (v2) is concurrent with [milk, flour] → keep both.
   v3 = [milk, flour] + [eggs] (siblings)
   Server returns: v3, [[milk, flour], [eggs]]

4. Client 2: addToCart(ham) at v2
   Client 2 had [milk] and [eggs] from step 2 → merges to [milk, eggs]
   Adds ham → sends [eggs, milk, ham] at v2.
   Server: v2 superseded; [eggs] removed.
   Server: [milk, flour] (v3) is concurrent with new write → keep both.
   v4 = [milk, flour] + [eggs, milk, ham] (siblings)

5. Client 1: addToCart(bacon) at v3
   Client 1 had [milk, flour] and [eggs] from step 3 → merges
   Adds bacon → sends [milk, flour, eggs, bacon] at v3.
   Server: v3 superseded; [milk, flour] removed.
   Server: [eggs, milk, ham] (v4) is concurrent → keep both.
   v5 = [milk, flour, eggs, bacon] + [eggs, milk, ham] (siblings)
```

Final state: two sibling values; client must merge on next read.

## Version Vector Across Multiple Replicas

```
Setup: n = 3 replicas (R1, R2, R3); each tracks its own counter and others'

After write at R1:    [R1: 1, R2: 0, R3: 0]
After write at R2:    [R1: 1, R2: 1, R3: 0]
After replication:    R1, R2 both at [R1: 1, R2: 1, R3: 0]

If new write arrives at R1 with vector [R1: 1, R2: 0, R3: 0]:
  → Concurrent with the R2 write, kept as sibling.

If new write arrives at R1 with vector [R1: 1, R2: 1, R3: 0]:
  → Causally after R2's write, overwrites it.
```

Riak serializes the version vector as a string called "causal context" sent with every read response and required on every write.

## Monitoring Staleness Metrics (Cassandra Example)

Leaderless systems lack a replication log, so staleness metrics are indirect:

```
nodetool repair                # trigger anti-entropy repair on a keyspace
nodetool tpstats               # thread pool stats; see ReadRepairStage activity
nodetool netstats              # see hints in flight (HintsService)
```

Key metrics to alert on:

| Metric | Meaning | Alert when |
|--------|---------|------------|
| Pending hints | Writes waiting for handoff | Growing unboundedly |
| Hints delivered | Successful handoff catch-up | Drops to zero (delivery stalled) |
| Repair lag | Time since last anti-entropy run | Exceeds SLA |
| Read repair count | Stale reads detected | Sudden spike (replication issue) |
| ReadRepairStage backlog | Queued read repairs | Backed up |

## Multi-Region Operation

### Cassandra/ScyllaDB Pattern

```
Client → local-region coordinator
  → fans out to all replicas in local region
  → forwards to ONE replica in each remote region
    → that replica fans out within its region
```

Consistency-level options:

- `LOCAL_QUORUM`: quorum within local region only (low latency, can be stale across regions)
- `EACH_QUORUM`: quorum in every region (high latency, consistent)
- `QUORUM`: quorum across all regions combined

### Riak Pattern

- All client-DB communication stays within one region
- `n` describes replicas within ONE region
- Cross-region replication runs asynchronously in background (multi-leader-style)
