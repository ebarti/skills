# Stream Processing Rules

Operational rules for time semantics, windowing, joins, and exactly-once delivery in stream processors.

## Core Rules

### 1. Use Event Time When Correctness Matters

Window by **event time** for analytics, billing, fraud detection, and any computation whose result must be reproducible from the input.

- Use **processing time** only when latency dominates (alerting, dashboards) AND end-to-end lag is negligible.
- Mixing them silently produces fake spikes after redeploys, backlogs, or fault recovery.
- Event timestamps make reprocessing deterministic; processing-time windows do not.

### 2. Set Watermarks Generously — But Not Too Generously

A watermark says "no events with timestamp < t will arrive." Get it wrong in either direction and results suffer.

- **Too tight**: real events get dropped as stragglers; metrics under-report.
- **Too loose**: results are delayed; user-visible latency grows.
- Tune from observed lateness percentiles (e.g., 99p arrival lateness).
- For multi-producer streams (mobile clients especially), track the watermark per producer, not globally.

### 3. Decide a Straggler Policy Up Front

You will get late events. Pick one:

- **Drop and alert**: simplest, fine for high-volume metrics where small loss is tolerable. Track drop count as a metric.
- **Publish corrections**: emit retraction + updated value. Required for billing, financial, and aggregation-of-record use cases.

### 4. Pick the Right Window Type

| Goal | Window |
|------|--------|
| Per-bucket counts/aggregates (no overlap) | Tumbling |
| Smoothed rolling average (overlap) | Hopping |
| "Within X minutes of each other" detection | Sliding |
| Per-user activity grouping | Session |

Don't use sliding windows when tumbling/hopping suffices — sliding requires buffering all events in the window.

### 5. Don't Query a Remote DB Per Event in Stream–Table Joins

For enrichment, hold the table side **locally** in the operator's state.

- Initial load from a snapshot.
- Keep up-to-date via a **CDC stream** of the table's changelog.
- The table's changelog conceptually has an infinite window with last-write-wins.
- Per-event remote lookups are slow and risk overloading the source DB.

### 6. Choose a Join Window Long Enough for Real-World Lag

For stream–stream joins (e.g., search ⋈ click on session ID), the window must cover the realistic time gap between related events. Days is plausible (user reopens a tab). State cost grows linearly with window size × throughput — plan capacity.

### 7. For Slowly Changing Dimensions, Pin a Version

When joining against state that changes over time (tax rates, product prices), the result depends on join ordering and is otherwise nondeterministic.

- Tag each version of the joined record with a unique version ID and reference that ID in events.
- Or denormalize the value into the event at write time.
- Note: versioning prevents log compaction of that table.

### 8. Achieve Exactly-Once via Combination, Not Any Single Mechanism

For external side effects, microbatching/checkpointing alone is insufficient. Combine:

1. **Checkpoint** operator state durably (Flink) or treat each microbatch atomically (Spark).
2. **Idempotent producer / sink** — tag every write with the input message offset; sink dedupes.
3. **Transactional sink** — wrap state change + offset commit + output in one atomic commit (Kafka transactions, Dataflow).

### 9. Plan State Recovery Before Production

Every stateful operator needs a recovery plan:

- Local state + periodic snapshot to DFS (Flink).
- Local state + replicate to compacted Kafka topic (Kafka Streams).
- Redundant execution on N nodes (VoltDB).
- Replay from input (short windows; CDC-rebuilt tables).

### 10. Idempotence Has Preconditions

Relying on idempotence to dedupe assumes:

- Replay is **deterministic** and **in the same order** (log-based broker, not a queue).
- No concurrent writer touches the same value (use **fencing tokens** during failover).
- The processor is itself deterministic.

Violate any precondition and "exactly-once via idempotence" silently breaks.

## Guidelines

- Prefer log-based brokers (Kafka) over queue-based brokers when you need replay or exactly-once semantics.
- Log three timestamps from mobile clients (event-occurred, event-sent, event-received) so you can correct device clock skew.
- For time-windowed counters, prefer state of fixed size; reserve event buffering for sliding windows and joins.
- For materialized views, treat the maintenance job as long-lived — its window stretches to the beginning of time.
- Use SQL-based engines (ksqlDB, Flink SQL, Materialize) when the team is more comfortable with declarative queries than imperative DAGs.

## Exceptions

- **Hot-path alerting**: processing time is acceptable when freshness beats correctness and lag is sub-second.
- **One-shot batch reprocessing of a stream**: sort-merge joins on the bounded window become viable again — treat as batch.
- **Single-producer, low-lag streams**: a simple single-watermark scheme works; per-producer tracking is overkill.
- **Pure read-only analytics on append-only data**: idempotence is "free," so transactional sinks may be unnecessary.

## Quick Reference

| Rule | Summary |
|------|---------|
| Event vs processing time | Event time for correctness; processing time only for low-lag alerting |
| Watermarks | Tune to observed lateness; track per producer for multi-source streams |
| Stragglers | Drop+alert OR publish corrections — decide early |
| Windows | Tumbling for buckets, hopping for smoothing, sliding for "near in time," session for users |
| Stream–table join | Local copy + CDC, never per-event remote DB query |
| SCD joins | Pin a version ID or denormalize |
| Exactly-once | Checkpoint + idempotent producer + transactional sink |
| State recovery | Local state + periodic snapshot is the common pattern |
| Idempotence | Requires deterministic replay + fencing during failover |
