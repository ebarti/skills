# Serializability Rules

Engine-selection guidance and operational rules for using serializable isolation correctly.

## Core Rules

### 1. Use serial execution only when constraints fit

Single-threaded serial execution (VoltDB, Redis) requires:

- Every transaction is small and fast — one slow transaction stalls everything
- Active dataset fits in RAM — disk I/O inside the serial loop kills throughput
- Write throughput sustainable on a single CPU core, OR data shardable so each transaction touches one shard
- Transactions are stored procedures (no interactive multi-statement flows)

If any of these fail, do not pick a serial-execution engine.

### 2. Stored procedures are mandatory for serial execution

Interactive transactions force the database to wait on application network I/O — fatal under single-threaded execution.

- Submit the entire transaction as a stored procedure (Java, JavaScript, Lua, Clojure, Groovy)
- Make procedures deterministic if they are replicated as state-machine commands (e.g., VoltDB)
- Use special deterministic APIs for time, randomness, etc.

**Tradeoff**: harder to deploy, version, debug, monitor, and test than application-server code; security concern in multitenant systems.

### 3. Avoid 2PL for high-throughput, latency-sensitive workloads

2PL provides strong correctness but at heavy cost:

- Readers block writers and writers block readers
- Deadlocks are frequent under serializable 2PL — aborts and retries waste work
- Long read transactions can block writes for the entire duration
- Tail latency (high percentiles) becomes unstable; one slow transaction can stall the system

Pair 2PL with transaction timeouts and slow-query monitoring.

### 4. Always include phantom protection in 2PL

Plain row-level shared/exclusive locks do not prevent phantoms.

- Use predicate locks conceptually; expect index-range (next-key) locks in practice
- Ensure the columns in your `WHERE` clauses are indexed — without an index, the database falls back to a full-table shared lock
- Verify your engine actually attaches range locks (e.g., MySQL/InnoDB next-key locks)

### 5. Prefer SSI for low-contention workloads

SSI gives serializability with snapshot-isolation-like performance when contention is low.

- Best when transactions rarely conflict and there is spare capacity
- Reads never block writes and vice versa — predictable latency
- Read-only queries can run on a snapshot with no locks at all
- Long-running read-only transactions are fine; long-running read/write transactions are likely to abort

### 6. Avoid SSI on high-contention workloads

Optimistic concurrency degrades under contention:

- Many transactions abort and retry, multiplying load
- Near maximum throughput, retries push the system over the edge
- Reduce contention with commutative operations (e.g., counter increments) where possible
- Otherwise consider 2PL or pick a weaker level + explicit invariant checks

### 7. Keep SSI read/write transactions short

- Long read/write transactions accumulate read sets and conflict windows
- Likelihood of abort grows with transaction duration
- Long read-only transactions remain safe (no abort risk)

### 8. Plan for retries on every serializable engine

- 2PL: deadlock detection aborts losers
- SSI: commit-time conflict detection aborts conflicters
- Serial execution (sharded): cross-shard coordination may fail

Application code must wrap transactions in retry loops with bounded attempts and backoff.

### 9. Single-shard transactions only, when possible

Under serial execution, cross-shard transactions need lockstep coordination across all touched shards.

- VoltDB cross-shard throughput around 1,000 writes/sec — orders of magnitude below single-shard
- Cannot be increased by adding more machines
- Design schema and shard key to keep transactions single-shard; secondary indexes commonly force cross-shard work

### 10. Do not pick serializable just to "be safe"

Serializable has real cost. Consider:

- Weaker isolation level (read committed or snapshot isolation) plus explicit application-level invariant checks (e.g., conditional writes, materialized conflicts, explicit locking via `SELECT ... FOR UPDATE`)
- Reserve serializable for transactions where invariants are hard to express otherwise

## Guidelines

- 2PL is not 2PC — different concepts despite the name; do not confuse
- Use snapshot isolation as the default and escalate to SSI when write skew is a real risk
- Profile contention before choosing optimistic vs. pessimistic
- Monitor abort rate as a first-class signal under SSI
- Monitor lock-wait time and deadlock rate under 2PL

## Exceptions

When these rules may be relaxed:

- **Embedded / single-process**: Engines like BadgerDB use SSI even for single-process workloads — overhead is small
- **Read-heavy workloads**: SSI shines because read-only queries take no locks
- **Tiny in-memory key-value workloads**: Serial execution can outperform locking-based engines
- **Very high contention on a single hot row**: No isolation level fixes a hot-row bottleneck — restructure the data model (sharding, sharded counters, commutative ops)

## Quick Reference

| Rule | Summary |
|------|---------|
| Serial execution constraints | Short transactions, in-memory, single CPU or shardable, stored procedures |
| Stored procedures required | Mandatory for serial execution; deterministic for replication |
| Avoid 2PL when latency matters | Blocks readers/writers, deadlock-prone, unstable tail latency |
| Phantom protection in 2PL | Predicate or index-range locks; index your `WHERE` columns |
| Prefer SSI on low contention | Snapshot-like throughput with serializability |
| Avoid SSI under contention | Abort retries amplify load |
| Keep SSI write transactions short | Long writers almost always abort |
| Always retry | All three engines abort under conflict |
| Single-shard only when possible | Cross-shard coordination tanks throughput |
| Don't pick serializable by default | Weaker level + explicit checks may be cheaper |
