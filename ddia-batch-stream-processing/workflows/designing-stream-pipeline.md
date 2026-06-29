# Designing a Stream Processing Pipeline Workflow

Step-by-step process for designing a fault-tolerant stream processing pipeline with correct time semantics, windowing, joins, and exactly-once delivery.

## When to Use

- Building real-time analytics, alerting, materialized views, or CEP from event streams
- Migrating a batch job to a continuous pipeline for lower latency
- Replacing per-event remote DB lookups with stateful stream operators

## Prerequisites

- Source events available on a log-based broker (Kafka, Kinesis, Pulsar) — see `references/event-streams/rules.md`
- A durable sink (DB, search index, broker topic) for the output
- Clear correctness vs latency target (e.g., "p99 lag < 5s, no double-counting")

**Reference**: `references/stream-processing/rules.md`

---

## Workflow Steps

### Step 1: Define the Use Case
**Goal**: Pin down the pipeline kind — it dictates everything downstream.
- [ ] Categorize: **analytics** (aggregations), **materialized view** (derived store), **alerting**, or **CEP** (multi-event patterns)
- [ ] State the SLO: target lag, correctness model (exactly-once? at-least-once?), tolerable straggler loss
- [ ] Identify input streams and their partition key

**Ask**: "Does this need to be reproducible from the input log, or is freshness all that matters?"
**Reference**: `references/stream-processing/knowledge.md` (Uses of Stream Processing)

### Step 2: Pick a Stream Processor
**Goal**: Match the engine to the use case and team skill set.

**Decision Tree** (use case → recommended processor):

| Use Case | Primary Choice | Alternatives |
|----------|----------------|--------------|
| Low-latency analytics with complex state | **Flink** | Kafka Streams, Beam |
| SQL-first materialized views from CDC | **Materialize / RisingWave** | ksqlDB, Flink SQL |
| Already in Spark / batch ecosystem | **Spark Structured Streaming** | Flink |
| Lightweight library inside JVM apps | **Kafka Streams** | Samza |
| Declarative SQL on Kafka | **ksqlDB** | Flink SQL |
| Portable across runners (Dataflow/Flink/Spark) | **Apache Beam** | — |
| CEP / pattern matching | **Flink CEP**, Esper | Apama, TIBCO StreamBase |

- [ ] Engine matches team skill set; supports required state size, window types, and integrations

**Reference**: `references/stream-processing/knowledge.md` (Stream Processor)

### Step 3: Decide Event Time vs Processing Time
**Goal**: Pick the time semantic that matches the correctness model.
- [ ] **Event time** for analytics, billing, fraud — anything reproducible from input
- [ ] **Processing time** ONLY for hot-path alerting (sub-second lag, small errors tolerable)
- [ ] Mobile/offline clients: log three timestamps (event-occurred, event-sent, event-received) to correct clock skew

**Pitfall**: Processing time produces fake spikes after redeploys, backlogs, or fault recovery.
**Reference**: `references/stream-processing/rules.md` (Rule 1)

### Step 4: Set Watermarks and Allowed Lateness
**Goal**: Tell the engine when a window can close and how to handle stragglers.
- [ ] Measure observed lateness (e.g., 99p) from a sample of traffic
- [ ] Set watermark = expected lateness; set **allowed lateness** for the long tail
- [ ] Multi-producer (mobile especially): track watermark **per producer**, not globally
- [ ] Straggler policy: **drop + alert** (high-volume metrics) OR **publish corrections** (billing/financial)

**Pitfall**: Tight watermark drops real events; loose watermark delays results.
**Reference**: `references/stream-processing/rules.md` (Rules 2, 3)

### Step 5: Choose the Window Type
**Goal**: Pick the window shape that matches the aggregation semantics.

| Goal | Window | Notes |
|------|--------|-------|
| Per-bucket counts (no overlap) | **Tumbling** | Cheapest; constant state for counters |
| Smoothed rolling average | **Hopping** | Window length > hop step |
| "Within X minutes of each other" | **Sliding** | Buffers all events in window — expensive |
| Per-user activity grouping | **Session** | Variable length; ends after inactivity gap |

- [ ] Don't reach for sliding when tumbling/hopping suffices
- [ ] Plan state: counter = constant; sliding/joins = events × throughput

**Reference**: `references/stream-processing/rules.md` (Rule 4); `references/stream-processing/knowledge.md` (Window Types)

### Step 6: Design the Joins
**Goal**: Choose the right join shape and avoid the per-event-DB-lookup trap.

| Join Type | Shape | Notes |
|-----------|-------|-------|
| **Stream–stream** | Two unbounded inputs, time-windowed | Window must cover realistic lag (hours/days) |
| **Stream–table** | Enrich events with reference data | Hold table **locally**; update via **CDC**, never remote DB lookup per event |
| **Table–table** | Two CDC streams | Continuously updated materialized view; product rule `(u·v)' = u'·v + u·v'` |

- [ ] SCDs (tax rates, prices): pin a **version ID** or denormalize value into event
- [ ] State cost = window size × throughput

**Reference**: `references/stream-processing/rules.md` (Rules 5–7); `references/stream-processing/knowledge.md` (Stream Joins)

### Step 7: Pick a State Backend
**Goal**: Choose where operator state lives so it survives failures.

| Engine | State Backend |
|--------|---------------|
| Flink | **RocksDB** local + snapshot to DFS (S3, HDFS) |
| Kafka Streams | **RocksDB** local + replicate to compacted Kafka topic |
| Spark Structured Streaming | HDFS / S3 checkpoint dir |
| Materialize / RisingWave | Managed (built-in) |
| VoltDB | Redundant in-memory execution on N nodes |

- [ ] Backend handles state size (sliding windows + joins can be huge)
- [ ] Snapshot frequency = recovery time vs throughput overhead trade-off

**Reference**: `references/stream-processing/rules.md` (Rule 9)

### Step 8: Plan the Exactly-Once Recipe
**Goal**: Combine mechanisms — no single one suffices for external side effects.
- [ ] **Checkpoint** operator state (Flink barriers / Spark microbatch atomicity)
- [ ] **Idempotent producer/sink**: tag every write with input offset; sink dedupes
- [ ] **Transactional sink**: state + offset + output in one atomic commit (Kafka transactions, Dataflow)
- [ ] Idempotence preconditions: deterministic replay, log-based broker, fencing tokens during failover

**Pitfall**: Microbatching/checkpointing alone leaks duplicates to external sinks.
**Reference**: `references/stream-processing/rules.md` (Rules 8, 10); `references/end-to-end-correctness/rules.md`

### Step 9: Plan Replay and State Recovery
**Goal**: Make the pipeline restartable without manual surgery.
- [ ] Document recovery path per stateful operator: snapshot restore OR rebuild from input log
- [ ] Materialized views: window stretches to beginning of time — keep source log replayable (or compacted)
- [ ] Short windows: replay from broker may be cheaper than snapshotting
- [ ] Test replay in staging on representative volume

**Reference**: `references/event-streams/rules.md` (Rule 6); `references/databases-and-streams/rules.md`

### Step 10: Document Pipeline + SLO
**Goal**: Hand off to ops with a clear contract.
- [ ] Diagram: sources → operators → sinks, with partition keys at each edge
- [ ] SLO: target lag (e.g., p99 < 5s), correctness model (effectively-once)
- [ ] Dashboard: lag per operator, watermark progress, checkpoint duration, sink rate, dropped-straggler count
- [ ] On-call playbook: replay, lag-spike triage, snapshot restore

---

## Quick Checklist

```
[ ] 1. Use case categorized (analytics / view / alerting / CEP)
[ ] 2. Stream processor chosen
[ ] 3. Event time vs processing time decided
[ ] 4. Watermarks + allowed lateness set; straggler policy chosen
[ ] 5. Window type matches aggregation semantics
[ ] 6. Joins designed (no per-event remote DB lookups)
[ ] 7. State backend selected and sized
[ ] 8. Exactly-once recipe (checkpoint + idempotent + transactional)
[ ] 9. Replay + recovery path documented
[ ] 10. Pipeline diagram, SLO, and dashboards in place
```

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Processing time for billing | Fake spikes after redeploys; not reproducible from input | Event time + watermarks |
| Stream–table join via per-event DB lookup | Slow; overloads source DB | Local state + CDC stream of changelog |
| No allowed lateness | Real stragglers silently dropped | Tune from observed lateness percentiles |
| Sliding window when tumbling suffices | Buffers every event — state explodes | Tumbling/hopping unless "near in time" is the goal |
| Microbatching alone for exactly-once | External sinks see duplicates after restart | Pair with idempotent producer + transactional sink |
| One global watermark for many producers | Slow producer holds back all results | Per-producer watermark tracking |
| SCD join without version ID | Result depends on race with table update | Pin version ID or denormalize into event |
| No straggler policy | Surprise data loss OR unbounded lag | Decide drop+alert OR publish corrections up front |
| Idempotence without fencing | Old + new instance both write — state corrupts | Fencing tokens during failover |

## Cross-References

- `references/stream-processing/rules.md` — time semantics, windows, joins, exactly-once
- `references/stream-processing/knowledge.md` — stream processor concepts; window types; fault tolerance
- `references/event-streams/rules.md` — broker choice, partitioning, lag, replay
- `references/databases-and-streams/rules.md` — CDC for stream–table enrichment
- `references/end-to-end-correctness/rules.md` — idempotence, fencing, transactional sinks

## Exit Criteria

Pipeline design is ready for implementation when:
- [ ] Use case, time model, and SLO are written down
- [ ] Processor, state backend, and exactly-once recipe are picked and justified
- [ ] Window types and join shapes match the aggregation semantics
- [ ] Watermarks, allowed lateness, and straggler policy are defined
- [ ] Replay and recovery procedure documented and rehearsed
- [ ] Diagram + dashboards + on-call playbook exist
