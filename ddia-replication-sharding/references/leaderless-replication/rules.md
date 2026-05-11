# Leaderless Replication Rules

Operational rules for configuring quorums, monitoring staleness, and resolving concurrent writes in Dynamo-style datastores.

## Core Rules

### 1. Set w + r > n for "Probably Newest" Reads

The quorum condition guarantees the read and write sets overlap on at least one replica.

- Common choice: odd `n` (3 or 5), set `w = r = (n+1)/2`
- Read-heavy workload: `w = n`, `r = 1` (faster reads, but one node failure stops writes)
- Write-heavy workload: lower `w`, higher `r`
- If `w` or `r` requirement cannot be met, return error to client

**Example**:
```
// Bad: w=1, r=1, n=3 → quorum NOT satisfied; reads often stale
// Good: w=2, r=2, n=3 → w+r=4 > 3, sets always overlap
```

### 2. Quorum Reads Are Not Linearizable

Even with `w + r > n`, edge cases break the "newest value" guarantee:

- Failed write that succeeded on some but fewer-than-`w` replicas is NOT rolled back
- Concurrent read with write may see new or old value (and order can flip)
- Sloppy quorum writes go to non-home replicas and may not be visible
- Restoring failed node from old replica drops new-value count below `w`
- Real-time clock timestamps (Cassandra/ScyllaDB LWW) can silently drop writes
- Rebalancing can cause read/write quorums to no longer overlap

Treat `w` and `r` as tunable probability levers, NOT absolute guarantees.

### 3. Use Sloppy Quorum + Hinted Handoff for High Availability

For writes during network partitions:

- Enable sloppy quorum (Riak/Dynamo) or `consistency level ANY` (Cassandra/ScyllaDB)
- Allows any reachable replica to accept the write
- Hinted handoff delivers the write back to the home replicas when reachable
- Trade-off: subsequent reads at home replicas may not see the value immediately

### 4. Use Version Vectors to Detect Concurrent Writes

Single version numbers are insufficient when multiple replicas accept writes:

- Use a version number per replica per key
- Each replica increments its own counter on write
- Each replica tracks the latest counter seen from every other replica
- Database returns version vector to client on every read
- Client must echo version vector back on subsequent write
- On write: server overwrites versions ≤ those in the vector, keeps higher ones as siblings
- Application must merge siblings correctly (LWW, CRDT, or manual)

### 5. Always Read Before Write (When Resolving Concurrency)

- A client must read a key (to learn the version vector) before writing
- A write without a version vector is concurrent with all other writes
- Such a write becomes a sibling rather than overwriting anything

### 6. Monitor Replication Staleness Explicitly

There is NO replication log, so leader-style "lag in writes" metric does not exist:

- Track number of pending hints stored for handoff (proxy for system health)
- Track anti-entropy / repair lag (e.g., Cassandra `nodetool repair`)
- Quantify "eventual" — eventual consistency is deliberately vague but operability requires bounds
- Alert when replication falls behind significantly
- Investigate causes: network problems, overloaded nodes

### 7. Pick Conflict Resolution Strategy Up Front

When concurrent writes happen, decide how siblings merge:

- LWW (Cassandra/ScyllaDB): easiest, but data loss risk; relies on clocks
- Manual merge: client picks resolution at read time
- CRDTs (Riak): automatic, mathematically sound merge
- LWW timestamps cannot detect whether values are actually concurrent

## Guidelines

- Keep `r` and `w` modest in practice — quorums are rarely more than 4 of 7 or 5 of 9 nodes; bigger quorums increase the chance of hitting a slow replica
- Use request hedging (use the fastest responses) to reduce tail latency
- For multi-region: choose between cross-region quorum, per-region quorum, or local-region quorum based on latency/staleness trade-off
- Consider Riak-style per-region clusters with async cross-region replication for the lowest latency

## Exceptions

When these rules may be relaxed:

- **Read-heavy with rare writes**: Use `w = n`, `r = 1` for fast reads (loses write availability on one node failure)
- **Lower latency over consistency**: Use `w + r ≤ n`; accepts higher staleness probability for faster ops
- **Network partitions**: Sloppy quorum may be better than failing every write

## Quick Reference

| Rule | Summary |
|------|---------|
| `w + r > n` | Required for read-write overlap (still not linearizable) |
| `n=3, w=2, r=2` | Default; tolerates 1 unavailable node |
| `n=5, w=3, r=3` | Tolerates 2 unavailable nodes |
| Sloppy quorum | Accept on any reachable node when partitioned |
| Hinted handoff | Catch up missed writes after recovery |
| Read repair | Fix stale replicas opportunistically during reads |
| Anti-entropy | Background sync (no order guarantees) |
| Version vector | Per-replica version numbers detect concurrent writes |
| Monitor hints | Best proxy for staleness in leaderless systems |
