# Implementing a CDC Pipeline Workflow

Step-by-step process for capturing database changes and replicating them to derived systems via a durable event log.

## When to Use

- Keeping a search index, cache, warehouse, or analytics store in sync with an OLTP database
- Replacing dual-write code paths with a single ordering authority
- Bootstrapping event-driven consumers from an existing mutable database

## Prerequisites

- Source DB with replication log access (Postgres logical, MySQL binlog, etc.)
- Durable broker available (Kafka, Kinesis, Pulsar)
- Schema registry or contract mechanism for evolving payloads

**Reference**: `references/databases-and-streams/rules.md`

---

## Workflow Steps

### Step 1: Identify Source DB and Downstream Consumers
**Goal**: Map the data flow before picking tools.
- [ ] List source DB(s): Postgres, MySQL, Mongo, DynamoDB
- [ ] List consumers: search index, cache, warehouse, analytics, ML feature store
- [ ] Identify tables/collections in scope (avoid full-DB capture)

**Ask**: "Do all consumers need the same ordering, or can some lag independently?"
**Reference**: `references/databases-and-streams/knowledge.md`

### Step 2: Pick a CDC Tool
**Goal**: Choose a battle-tested connector instead of rolling your own log parser.

**Decision Tree** (source DB → recommended tool):

| Source DB | Primary Choice | Alternatives |
|-----------|----------------|--------------|
| Postgres | Debezium (pgoutput) | AWS DMS, pgcapture, Datastream |
| MySQL | Debezium (binlog) | Maxwell, AWS DMS |
| MongoDB | Mongo Change Streams (native) | Debezium MongoDB |
| DynamoDB | DynamoDB Streams (native) | Kinesis adapter |
| SQL Server / Oracle | Debezium | GoldenGate, Striim |
| Cassandra | Per-node Debezium | Merge in consumer |
| Volatile schema | **Outbox pattern** + any tool | Direct event publishing |

- [ ] Tool matches operational expertise on the team
- [ ] Confirmed it supports incremental snapshotting (e.g., Debezium DBLog)
- [ ] If schema is volatile, plan **outbox pattern** as fallback

**Reference**: `references/databases-and-streams/rules.md` (Rules 2 and 6)

### Step 3: Configure Source Replication
**Goal**: Grant the connector low-level log access without destabilizing the source.
- [ ] **Postgres**: `wal_level=logical`, create publication + replication slot, grant `REPLICATION` role
- [ ] **MySQL**: enable binlog (row-based, full image), grant `REPLICATION SLAVE` + `REPLICATION CLIENT`
- [ ] **Mongo**: confirm replica set (oplog required); grant `read` on relevant DBs
- [ ] **DynamoDB**: enable Streams with `NEW_AND_OLD_IMAGES`
- [ ] Monitor replication slot lag — an abandoned slot fills the source disk

### Step 4: Take Initial Snapshot
**Goal**: Bootstrap consumers with full state before tailing live changes.
- [ ] Trigger snapshot (Debezium does this automatically by default)
- [ ] Verify completion at a known log offset (LSN, GTID, oplog position)
- [ ] Confirm streaming resumes from that exact offset
- [ ] For large tables, prefer **incremental snapshotting** (DBLog watermarking)

**Pitfall**: Skipping snapshot leaves consumers missing rows not updated since CDC started.

### Step 5: Pipe to a Durable Broker
**Goal**: Route changes through a replayable log keyed by the entity that requires ordering.
- [ ] Provision Kafka topic per source table (or per logical entity)
- [ ] **Partition key = primary key** of the source row (preserves per-row order)
- [ ] Right-size partitions: 2–4x consumer count
- [ ] Set replication factor >= 3 for durability

**Reference**: `references/event-streams/rules.md` (Rule 3 — partition key matches ordering)

### Step 6: Decide Compaction vs Time Retention
**Goal**: Match retention strategy to topic purpose.

| Topic purpose | Retention |
|---------------|-----------|
| Current-state mirror of a table (CDC) | **Log compaction** |
| Raw historical event log | Time/size (or infinite) |
| Transient inter-service events | Hours to days |

**If compacted**: every event carries the primary key; deletes emit **tombstones** (null value).
**If retained**: retention >= longest expected outage + replay window.
**Reference**: `references/databases-and-streams/rules.md` (Rule 4)

### Step 7: Implement Idempotent Consumers
**Goal**: Survive at-least-once delivery without corrupting derived state.
- [ ] Key writes by primary key + offset (or event id) so duplicates are no-ops
- [ ] Use upserts, not inserts, in the sink
- [ ] Co-shard the consumer with source partitioning (single-threaded per partition)
- [ ] Wrap deserialization + business logic in try/catch; route failures to DLQ
- [ ] Acknowledge only after successful sink write

**Reference**: `references/event-streams/rules.md` (Rules 6, 7, 8) and `references/end-to-end-correctness/rules.md`

### Step 8: Plan Schema Evolution
**Goal**: Survive `ALTER TABLE` without breaking consumers.
- [ ] Use Avro / Protobuf with a **Schema Registry** (Confluent or equivalent)
- [ ] Configure compatibility: `BACKWARD` or `FULL`
- [ ] Add columns with defaults; avoid renames and drops on captured tables
- [ ] If schema churn is high, isolate via **outbox pattern**

**Reference**: Cross-skill `ddia-data-modeling/references/encoding-formats/rules.md`

### Step 9: Plan GDPR / Right-to-Erasure
**Goal**: Make deletion possible despite an immutable log.
- [ ] Choose a strategy: **tombstones + compaction** (null record removes the key); **crypto-shredding** (encrypt per-user, destroy key on erasure); **excision / shunning** (true history rewrite — Datomic, Fossil; rare)
- [ ] Document retention windows for legal/compliance audit
- [ ] Confirm strategy works for non-compacted topics with user data

**Reference**: `references/databases-and-streams/rules.md` (Rule 7)

### Step 10: Monitor Lag and Plan Replay
**Goal**: Make the pipeline observable and recoverable.
- [ ] Dashboard: source slot lag, broker offset lag per consumer, sink write rate
- [ ] Alert on consumer lag well before retention boundary
- [ ] Document replay procedure: stop consumer → reset offset → drain → resume
- [ ] Test replay in staging on representative volume
- [ ] Run new and old derived views side-by-side during migration; cut over once caught up

**Reference**: `references/event-streams/rules.md` (Rules 4 and 6)

---

## Quick Checklist

```
[ ] 1. Source DB and consumers identified
[ ] 2. CDC tool chosen (Debezium / DMS / native / outbox)
[ ] 3. Source replication configured
[ ] 4. Initial snapshot completed at known offset
[ ] 5. Broker topics partitioned by primary key
[ ] 6. Retention strategy chosen (compaction vs time)
[ ] 7. Consumers idempotent + DLQ wired
[ ] 8. Schema registry + compatibility mode set
[ ] 9. GDPR strategy documented
[ ] 10. Lag monitoring + replay procedure tested
```

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Dual-write to DB and queue from app code | Race conditions cause silent divergence | Write only to DB; let CDC fan out |
| Skipping the initial snapshot | Consumers miss rows not updated since CDC started | Snapshot at a known offset, then tail |
| Non-idempotent consumer | At-least-once delivery duplicates records | Upsert by primary key; key by offset |
| Random partitioning | Per-key order destroyed | Partition by primary key |
| Time retention on "current state" topic | Disk explodes; full history forever | Use log compaction for CDC mirrors |
| Capturing internal schema directly | `DROP COLUMN` breaks every consumer | Outbox pattern + schema registry |
| Append-only "delete" event for GDPR | Original PII still in the log | Tombstone + compaction, or crypto-shredding |
| No lag alerts | Consumer falls past retention; permanent loss | Alert well before retention boundary |
| Querying source DB from derived consumers | Reintroduces ordering conflicts | Read only from the CDC stream |

## Cross-References

- `references/databases-and-streams/rules.md` — CDC fundamentals; dual-write avoidance
- `references/databases-and-streams/knowledge.md` — CDC vs event sourcing; log compaction
- `references/event-streams/rules.md` — broker choice, partitioning, lag, replay, DLQs
- `references/end-to-end-correctness/rules.md` — idempotency and exactly-once semantics
- Cross-skill: `ddia-data-modeling/references/encoding-formats/rules.md` — Avro, Protobuf, schema evolution

## Exit Criteria

CDC pipeline is production-ready when:
- [ ] Source replication is stable; no slot/binlog lag accumulating
- [ ] Initial snapshot loaded all consumers to a consistent offset
- [ ] Each consumer is idempotent and survives a staging replay test
- [ ] Schema evolution path documented and a backward-incompatible change rehearsed
- [ ] GDPR erasure procedure documented and tested on a sample key
- [ ] Lag dashboards and alerts are live; on-call playbook references replay steps
