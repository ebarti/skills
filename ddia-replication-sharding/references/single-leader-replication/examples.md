# Single-Leader Replication Examples

Real-world systems, replication lag scenarios, and failover incidents.

## Real Systems Using Single-Leader Replication

### Relational Databases
- **PostgreSQL**: Streaming replication via WAL shipping; logical replication via WAL decoding (row-level events).
- **MySQL**: Binary log (binlog) for row-based logical replication; switches automatically from statement-based to row-based when nondeterminism is detected.
- **Oracle Data Guard**: WAL-style physical replication.
- **SQL Server Always On**: Availability groups with sync/async modes.

### Document & NoSQL Databases
- **MongoDB replica sets**: Single primary accepts writes; secondaries replicate the oplog.
- **DynamoDB**: Single-leader replication internally.

### Other Systems
- **Kafka**: Each partition has a single leader broker; followers replicate the log.
- **DRBD**: Replicated block device.
- **Consensus-based systems** (CockroachDB, TiDB, etcd, RabbitMQ quorum queues): Use Raft, which has a single leader and elects new leaders automatically.

### Bootstrap & Backup Tools
- **WAL-G**: Archives WAL + snapshots to object storage for PostgreSQL, MySQL, SQL Server.
- **Litestream**: Same idea for SQLite.
- **Percona XtraBackup**: Snapshot tool for MySQL.

## Replication Lag Scenarios

### Scenario 1: "Where's my comment?" (Read-Your-Writes Violation)

**Setup**: User submits a comment on a discussion thread (write to leader). Page reloads and reads from a lagging async follower.

**Result**: User's own comment is missing from the page. They think it was lost and re-submit, possibly creating duplicates.

**Fix**:
- Always read the user's own posts from the leader for 1 minute after the write.
- Or remember the LSN from the write and require the read replica to be caught up to it.

### Scenario 2: Disappearing Comment (Monotonic Reads Violation)

**Setup**: User 2345 refreshes a page twice. First request hits a fresh follower; second request hits a lagging follower (round-robin load balancing).

**Result**:
- First read shows User 1234's recent comment.
- Second read shows the comment is gone.
- User sees time go backward.

**Fix**: Route all of User 2345's reads to the same replica (hash of user ID).

### Scenario 3: Psychic Mrs. Cake (Consistent Prefix Violation)

**Setup**: A conversation is replicated through two followers with different lags.

```
Leader writes:
  Mr. Poons: "How far into the future can you see, Mrs. Cake?"
  Mrs. Cake: "About 10 seconds usually, Mr. Poons."
```

**Observer reading from out-of-order followers sees**:

```
  Mrs. Cake: "About 10 seconds usually, Mr. Poons."  // arrived first
  Mr. Poons: "How far into the future can you see, Mrs. Cake?"  // arrived later
```

The answer appears before the question. This is especially common in sharded databases where different shards have independent ordering.

**Fix**: Write causally-related data to the same shard, or use algorithms that track causal dependencies (happens-before).

## Failover Incidents

### GitHub MySQL Incident: Primary Key Reuse

**What happened**:
1. The MySQL leader failed.
2. An out-of-date follower was promoted to leader.
3. The new leader's autoincrement counter had not caught up to the old leader's.
4. The new leader started reusing primary key values that the old leader had already assigned.
5. Those primary keys were also used as keys in a Redis cache.
6. Redis returned data associated with the old assignment of those IDs.
7. **Private data was disclosed to the wrong users.**

**Lessons**:
- Discarded writes during async failover are not just "data loss" — they corrupt downstream systems that share IDs.
- Don't let async failover discard writes silently when external systems depend on the IDs.
- Prefer UUIDs or globally-unique IDs over autoincrementing counters when keys cross system boundaries.

### Split Brain Anti-Pattern

**What happens**:
- Network partition isolates the leader.
- Followers elect a new leader.
- Old leader rejoins, still believes it is the leader.
- Both leaders accept writes; data diverges or is corrupted.

**Mitigation (fencing)**:
- Have a coordinator that revokes the old leader's lease.
- Some systems shut down a node detected as a "second leader."
- **Caveat**: Naive shutdown logic can cause both nodes to shut down simultaneously, taking the whole cluster offline.

### Timeout Tuning Mistakes

- **30-second timeout** during a load spike → node response time crosses 30s → unnecessary failover triggered.
- Failover during high load makes the situation worse, not better.
- Use **adaptive thresholds** or longer timeouts for production-tuned systems.

## Setting Up a New Follower

Standard process (works in PostgreSQL, MySQL, etc.):

1. Take a consistent snapshot of the leader (without locking) — record the log position (LSN, binlog coordinate, GTID).
2. Copy the snapshot to the new follower (often from object storage with WAL-G or similar).
3. Follower connects to leader and requests all changes since the snapshot's log position.
4. Follower processes the backlog. When the backlog is drained, it has "caught up."
5. Follower continues consuming the live replication stream.

## Replication Log Type Comparison

| System | Log Type | Cross-Version Upgrades | Notes |
|--------|----------|------------------------|-------|
| MySQL (5.1+) | Row-based (binlog) | Yes | Falls back from statement-based on nondeterminism |
| PostgreSQL streaming | WAL shipping | No | Same major version required |
| PostgreSQL logical | Row-based | Yes | Decodes WAL into row events |
| Oracle | WAL shipping | No | |
| MongoDB | Logical (oplog) | Yes | Idempotent ops |
| VoltDB | Statement-based | Yes | Requires deterministic transactions |
| MySQL pre-5.1 | Statement-based | Limited | Many nondeterminism issues |
