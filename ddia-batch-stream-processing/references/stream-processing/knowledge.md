# Stream Processing Knowledge

Core concepts for processing unbounded event streams: time semantics, windows, joins, and fault tolerance.

## Overview

A stream processor consumes input streams read-only and writes output streams append-only. Unlike batch jobs, streams never end, so sorting, sort-merge joins, and "restart from beginning" don't apply. Stream processing must reason about time explicitly and recover state without reprocessing the full history.

## Stream Processor

**Definition**: A long-running operator/job that consumes one or more input streams and produces one or more output streams in an acyclic pipeline.

**Real systems**: Apache Flink, Spark Streaming (microbatch) / Structured Streaming, Kafka Streams, ksqlDB, Apache Beam, Apache Storm, Samza, Google Cloud Dataflow, Azure Stream Analytics.

**Use cases**: writing to a derived store, pushing notifications to humans, or producing further derived streams (option 3 — the focus here).

## Uses of Stream Processing

| Use | Description |
|-----|-------------|
| Complex Event Processing (CEP) | Search for event *patterns* via standing queries (Esper, Apama, TIBCO StreamBase, Flink/Spark SQL). Queries are persistent; data is transient. |
| Stream analytics | Aggregations and statistics over windows (rates, rolling averages, trend comparisons). May use Bloom filters / HyperLogLog / percentile sketches as optimization. |
| Materialized view maintenance | Keep caches, indexes, OLAP views in sync with source data using *all* events (window stretches to beginning of time). Tools: Kafka Streams, ksqlDB, Materialize, RisingWave, ClickHouse, Feldera. |
| Search on streams | Match each incoming document against many standing queries (Elasticsearch percolator). |
| Event-driven / RPC | Distinct from streams: actor messages are ephemeral and 1:1, may form cycles, and aren't fault-tolerant by default. |

## Reasoning About Time

### Event Time vs Processing Time

**Event time**: timestamp embedded in the event by its producer (when it actually occurred).
**Processing time**: local clock on the processor when the event is handled.

Confusing them produces bad data. Example: a redeploy creates a backlog; rate measured by processing time shows a fake spike, but the true event-time rate was steady.

### Stragglers

Events arriving after their window was declared "complete." You cannot ever be sure all events for a window have arrived. Two responses:
- **Drop** them (track and alert if drop rate climbs).
- **Publish a correction** with retraction of the prior result.

A *watermark* is a "no more events with timestamp < t" signal. With multiple producers, consumers must track each producer's watermark.

### Whose Clock?

Mobile/offline devices buffer for hours/days; local clocks may be wrong or tampered with. Mitigation — log three timestamps:
1. Event-occurred (device clock)
2. Event-sent (device clock)
3. Event-received (server clock)

Subtract (2) from (3) to estimate clock skew, then correct (1).

## Window Types

| Window | Length | Overlap | Use |
|--------|--------|---------|-----|
| Tumbling | Fixed | None — every event in exactly one window | Per-minute counts, billing buckets |
| Hopping | Fixed | Hop step < window length (e.g., 5-min window, 1-min hop) | Smoothed moving aggregates |
| Sliding | Fixed interval, anchored on events | Continuous — any two events within interval are grouped | Detecting events close in time |
| Session | Variable — ends after inactivity gap (e.g., 30 min) | None | Per-user activity sessionization |

State cost: a counter is constant size; sliding windows and joins need to *buffer events*, so high-throughput streams require ample state capacity (memory or disk).

## Stream Joins

Three kinds, all requiring the processor to maintain state derived from one input and query it when the other input arrives.

### Stream–Stream (window join)
Both sides are unbounded streams; join within a time window (e.g., search + click within 1 hour, by session ID). Maintain indexes for both sides; emit a match (or a "no-click" event) when window expires.

### Stream–Table (enrichment)
Augment events with reference data (e.g., user activity + user profile). Don't query a remote DB per event — load a local copy and update via CDC on the table changelog. Effectively a stream–stream join where the table side has an infinite window with last-write-wins.

### Table–Table (materialized view maintenance)
Both inputs are CDC streams of tables. Join produces a continuously updated materialized view (e.g., social timeline cache from `posts` ⋈ `follows`). Stream of changes obeys the product rule: `(u·v)' = u'·v + u·v'`.

### Time Dependence
If event order across streams is undefined, joins are nondeterministic. For *slowly changing dimensions* (e.g., tax rate at sale time), use a unique version ID for each version of the joined record (prevents log compaction) or denormalize the value into the event.

## Fault Tolerance

**Goal**: exactly-once (better: *effectively-once*) — output looks as if every input was processed exactly once, even with retries.

| Mechanism | What it does |
|-----------|--------------|
| Microbatching (Spark) | Treat ~1s blocks as mini-batches; tumbling window on processing time. |
| Checkpointing (Flink) | Periodic state snapshots to durable storage, triggered by stream barriers. On crash, restart from last checkpoint and discard intermediate output. |
| Atomic commit | All side effects (state, outputs, offsets) commit together — internal 2PC inside the framework (Dataflow, VoltDB, Kafka transactions). |
| Idempotence | Tag each write with a monotonic ID (e.g., Kafka offset); ignore duplicates. Requires deterministic replay, no concurrent writers (use fencing). |

**State recovery**: keep state local and replicate (Flink snapshots to DFS; Kafka Streams to a compacted topic; VoltDB redundant execution). Or rebuild from input — replay short windows, or recover a CDC-derived table from the log.

## Terminology

| Term | Definition |
|------|------------|
| Operator / Job | A piece of code that processes streams |
| Watermark | Signal that no more events with timestamp < t will arrive |
| Straggler | An event arriving after its window closed |
| Microbatch | Treating a small time block as a batch (~1s, Spark Streaming) |
| Checkpoint | Durable snapshot of operator state (Flink) |
| Barrier | Marker injected into the stream that triggers a checkpoint |
| Effectively-once | Output equivalent to exactly-once even with retries |
| CDC | Change Data Capture — stream of inserts/updates/deletes from a database |
| SCD | Slowly Changing Dimension — a join target whose value changes over time |

## Common Misconceptions

- **Myth**: Stream processing is inherently approximate.
  **Reality**: Probabilistic algorithms (Bloom, HyperLogLog) are an optimization, not a requirement.

- **Myth**: Microbatching/checkpointing alone gives exactly-once.
  **Reality**: External side effects (DB writes, emails) escape the framework — pair with idempotence or atomic commit.

- **Myth**: A stream–table join can be done with a remote DB lookup per event.
  **Reality**: It works but is slow and overloads the DB. Hold a local copy and update via CDC.
