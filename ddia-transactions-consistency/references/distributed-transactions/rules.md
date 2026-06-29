# Distributed Transactions Rules

Design and operational guidance for atomic commit across nodes, shards, and heterogeneous systems.

## Core Rules

### 1. Treat the 2PC Coordinator as a Single Point of Failure

If the coordinator crashes after participants vote yes, every in-doubt participant blocks — holding locks until the coordinator's log is read on recovery.

- The coordinator's on-disk log is as critical as the database itself.
- Lose the log (corruption, disk failure) and in-doubt transactions become orphaned, requiring manual administrator intervention.
- Embedding the coordinator inside the application process makes the application server's local disk part of your durable system state — a brittle coupling.

**Mitigation**: replicate the coordinator with a consensus protocol (Paxos/Raft); never run a single-node coordinator for production multi-system 2PC.

### 2. Avoid XA Across Heterogeneous Systems Unless You Truly Need It

XA's pain is structural, not implementation-bound:

- It is a lowest-common-denominator C API — no cross-system deadlock detection, no SSI.
- The coordinator and participants cannot communicate directly; everything goes through application code, making the app a single point of failure even if the coordinator is replicated.
- Heuristic decisions exist as an emergency hatch — and they break atomicity.
- Vendor lock-in: switching transaction managers or adding a non-XA participant (e.g., an email server) is painful.

**Prefer**: idempotent message processing, the outbox pattern, or change-data-capture pipelines.

### 3. Prefer At-Least-Once Delivery + Idempotency Over 2PC for Messaging

Recording a message ID in a dedup table inside the database transaction makes reprocessing safe:

- Only single-DB transactions are required.
- Crashes at any step (before commit, before ack, after ack) recover correctly.
- A uniqueness constraint on the message-ID table catches concurrent retries.
- Works across any broker — no XA support required from the broker.

This gives you *effectively exactly-once* without the operational tax of distributed transactions.

### 4. Use Database-Internal Distributed Transactions for Cross-Shard ACID

When the work is "atomic write to several shards of the same database," use a system that supports internal distributed transactions natively:

- Spanner, CockroachDB, TiDB, FoundationDB, YugabyteDB, VoltDB, MySQL NDB.
- These pair 2PC with consensus-replicated coordinators and shards, direct coordinator-to-shard channels, and integrated concurrency control (snapshot isolation, SSI).
- Avoid bolting XA onto sharded MySQL/Postgres yourself.

### 5. Don't Combine 2PC with High-Throughput Stream Processing

2PC adds extra `fsync` operations and network round trips per transaction. The blocking lock-hold window during in-doubt periods compounds the latency cost:

- Stream processors handle thousands to millions of events per second — 2PC overhead per event is fatal.
- Use Kafka transactions (internal 2PC) for exactly-once *within* Kafka.
- Use idempotency keys for cross-system exactly-once at scale.

### 6. Never Use Heuristic Decisions Routinely

Heuristic commit/abort exists to escape catastrophic situations only:

- Each heuristic decision risks splitting atomicity (some participants commit, others abort).
- If you find yourself reaching for heuristics regularly, your coordinator architecture is wrong — replicate it with consensus.

### 7. Recognize the Lock-Hold Cost of In-Doubt Transactions

Locks acquired during 2PC cannot be released until the coordinator decides:

- A 20-minute coordinator outage = 20 minutes of held row locks.
- Other transactions touching those rows block; in serializable mode, even readers block.
- Plan for cascading unavailability when designing 2PC-using systems — include coordinator-failure runbooks.

### 8. 3PC Is Not a Real Alternative

Three-phase commit assumes bounded network delays and bounded process pauses — neither holds in production networks (see Chapter 9 of DDIA). Don't pick 3PC; pick a consensus-replicated coordinator instead.

## Guidelines

- If you only have one database and one external side effect (email, payment), use idempotency, not XA.
- Keep transactions short to minimize the in-doubt window if 2PC is unavoidable.
- Monitor in-doubt transaction counts as a first-class production metric.
- Document the manual recovery procedure for orphaned in-doubt transactions before going live.
- Design APIs to accept idempotency keys from clients — push exactly-once semantics to the application layer, not the storage layer.

## Exceptions

- **Legacy systems**: an existing XA deployment with operations playbooks may be cheaper to maintain than rewriting.
- **Regulatory requirements**: some financial systems mandate 2PC across systems; in that case, invest heavily in coordinator HA and runbooks.
- **Same-vendor sharding**: internal distributed transactions in Spanner-class databases are a perfectly fine default.

## Quick Reference

| Rule | Summary |
|------|---------|
| Coordinator = SPOF | Replicate via consensus or accept blocking |
| Avoid XA cross-vendor | Lowest-common-denominator + lock-in pain |
| Idempotency > 2PC for messaging | Dedup table beats XA every time |
| Internal distributed txn for sharding | Use Spanner/CockroachDB, not bolted-on XA |
| 2PC + streams = no | Per-event `fsync` and round trips kill throughput |
| Heuristics are atomicity violations | Last resort only, never routine |
| In-doubt = locks held | Plan for cascading outage |
| Skip 3PC | Consensus-replicated coordinator is the real fix |
