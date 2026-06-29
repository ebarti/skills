# Databases and Streams Rules

Design guidance for keeping heterogeneous data systems in sync via CDC and immutable event logs.

## Core Rules

### 1. Don't dual-write to DB and queue

Never have application code write to the database and a message queue (or search index, cache, warehouse) as separate, sequential operations.

- Concurrent clients will interleave writes; each system ends up with a different winner
- Partial failures leave systems permanently inconsistent — there's no atomic commit across heterogeneous stores
- Even retries don't help: order, not just delivery, is the problem

**Example**:
```python
# Bad — dual write, no shared ordering
db.update(user_id, new_email)
search_index.update(user_id, new_email)
cache.invalidate(user_id)

# Good — write only to the DB, let CDC fan out
db.update(user_id, new_email)
# Debezium tails the WAL and publishes to Kafka;
# search-index and cache consumers apply changes in DB order.
```

### 2. Use a CDC tool, don't roll your own log parser

Replication-log formats are tricky (schema evolution, transaction boundaries, ordering across tables). Use battle-tested connectors:

- **Debezium** — MySQL, PostgreSQL, Oracle, SQL Server, Db2, Cassandra, MongoDB
- **Maxwell** — MySQL binlog
- **Kafka Connect** source connectors
- **AWS DMS** / **DynamoDB Streams** / **Kinesis Data Streams**
- **Striim**, **GoldenGate** (Oracle), **pgcapture** (Postgres)
- **Datastream** (Google Cloud)

### 3. Take an initial snapshot before tailing the log

Replaying only recent changes misses records that haven't been updated lately. To bootstrap a new consumer:

- Take a consistent snapshot of the source DB at a known log offset
- Load the snapshot into the target system
- Resume from that offset on the change stream

Prefer tools with built-in incremental snapshotting (Debezium's DBLog watermarking). Otherwise plan a manual snapshot procedure.

### 4. Choose retention strategy by topic purpose

| Topic purpose | Retention |
|---------------|-----------|
| Current-state replication of a table (CDC) | **Log compaction** — disk size = current row count |
| Raw event sourcing log | **Time/size retention** (or infinite) — preserve full history |
| Transient inter-service events | Time-based (hours to days) |

For compacted topics, every event must carry a primary key, and updates must replace prior values for that key.

### 5. Treat the CDC stream as the source of truth for derived systems

Once CDC is in place, derived systems (search index, cache, warehouse, recommendation engine) should read only from the stream — never query the source DB directly for data they need.

- Single ordering authority (the DB's log) eliminates conflicts
- Adding a new consumer (new view, new analytics workload) doesn't impact the source
- Old derived systems can be retired by simply unsubscribing

### 6. Decouple internal schema from CDC schema

CDC turns your database schema into a public API — dropping a column breaks downstream consumers. Mitigate with:

- **Outbox pattern**: write domain changes and an outbox row in the same DB transaction; CDC reads only the outbox table
- **Data contracts**: enforce schema compatibility for CDC topics
- **Schema registry** (e.g., Confluent Schema Registry) for compatibility checks

### 7. Plan for GDPR / right-to-erasure on immutable logs

Append-only logs are at odds with "delete this user's data on demand." Options:

- **Tombstones + log compaction** — emit a null-valued record for the key; compaction physically removes it
- **Crypto-shredding** — encrypt per-user data with a per-user key; "delete" by destroying the key
- **Excision / shunning** — true history rewrite (Datomic, Fossil); rare and operationally heavy

Don't assume `append delete event` is enough — the original data is still in the log.

## Guidelines

- Prefer asynchronous CDC; it has better operational properties (slow consumers don't stall the source) at the cost of replication lag
- For "read your own writes" UX, keep the originating user pinned to the source DB until their write is reflected downstream
- Shard the event log and the derived state the same way — single-threaded per-shard consumers need no concurrency control
- Capture richer events than just "current value": e.g., "item added to cart" then "item removed" preserves intent that "cart is empty" loses
- Run new and old derived views side-by-side during migration; cut over once the new view is caught up

## Exceptions

- **Outbox is a sanctioned dual-write**: it works because both writes go to the same database in one transaction
- **Synchronous read-after-write** may justify writing the read view in the same transaction (rare; usually impractical)
- **Quorum-based stores (Cassandra)**: per-node CDC streams must be merged by the consumer — there's no single authoritative log

## Quick Reference

| Rule | Summary |
|------|---------|
| No dual writes | Use CDC; let the DB's log be the single ordering authority |
| Use proven CDC tools | Debezium, Maxwell, AWS DMS, GoldenGate, pgcapture |
| Snapshot first | Bootstrap consumers at a known offset before tailing |
| Compaction vs retention | Compact for "current state"; retain for raw event history |
| CDC = source of truth | Derived systems read the stream, not the source DB |
| Decouple schemas | Outbox pattern + data contracts to prevent breakage |
| Plan for deletion | Tombstones, crypto-shredding, or excision for GDPR |
