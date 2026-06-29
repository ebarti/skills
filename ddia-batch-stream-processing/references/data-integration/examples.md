# Data Integration Examples

Architecture patterns for integrating multiple specialized data systems.

## Bad Examples

### Direct Dual Writes

```
Client A ─┬─► Database  (writes A then B)
          └─► Search    (writes B then A — different order!)

Client B ─┬─► Database
          └─► Search
```

**Problems**:
- No system decides the global order of writes
- Two clients with conflicting writes can land in different orders in each store
- Database and search index drift permanently apart, no recovery path
- Failure of one write leaves the other store with orphan data

### XA Distributed Transaction Across Heterogeneous Systems

```
Begin XA tx
  Insert into Postgres
  Index into Elasticsearch
  Publish to Kafka
Commit (2PC across all three)
```

**Problems**:
- Any participant failure aborts the whole transaction — failures amplify
- XA has poor fault tolerance and performance
- In-doubt transactions block recovery, hold locks indefinitely
- Couples availability of every system to the slowest/least-reliable one

### Lambda Architecture (Legacy)

```
                    ┌─► Batch layer (Hadoop) ──► Batch view ─┐
Event log ──────────┤                                         ├─► Serving layer
                    └─► Speed layer (Storm) ──► Realtime view┘
```

**Problems**:
- Two codebases (batch + stream) implementing the same logic — must stay in sync
- Drift between layers causes subtle inconsistencies in merged output
- Operational cost of running and monitoring two pipelines
- Largely superseded by unified stream engines

## Good Examples

### Single Source of Truth, Multiple Sinks (Fan-Out)

```
                                    ┌─► Postgres (OLTP reads)
                                    │
Application writes ──► Kafka ───────┼─► Elasticsearch (full-text search)
(via API)             (event log)   │
                                    ├─► S3 / Parquet (data lake)
                                    │
                                    ├─► ClickHouse (analytics)
                                    │
                                    └─► Redis (cache / denormalized view)
```

**Why it works**:
- Kafka decides the order of all writes; every sink replays in the same order
- Each sink fails independently — a downed search cluster doesn't block writes
- Adding a sixth sink (e.g. ML feature store) is "replay history into it"
- Stream processors per sink are deterministic and idempotent — easy to recover

### Kappa Architecture (Unified Stream Engine)

```
Event log (Kafka, retained N days/forever)
        │
        ▼
  Stream processor (Flink job)
        │
        ├─► Derived view v1 (current production)
        │
        └─► Derived view v2 (new schema, parallel rebuild)
```

**Why it works**:
- One engine handles both live events and historical replay
- Schema migration = run the same job from offset 0 with new code → builds v2
- Switch traffic gradually from v1 to v2; revert by routing back if needed
- No separate batch pipeline to maintain

### Reprocessing for Schema Evolution

Scenario: search index needs a new field `normalized_address` derived from an existing `address` field.

```
1. Deploy new indexer code that emits the additional field
2. Create a new Elasticsearch index "products_v2"
3. Reset consumer offset to 0 — rebuild v2 from the entire Kafka log history
4. While v2 builds, v1 still serves production
5. When v2 catches up to head, switch a 1% canary of search traffic
6. Increase to 10%, 50%, 100% as confidence grows
7. Drop v1 once v2 is fully serving
```

**Why it works**:
- Old view stays live during the rebuild — zero downtime
- Reversible at every step — switch back if v2 has bugs
- Tests new schema on real production data before commitment
- Generalizes to ML model retraining, analytics schema changes, denormalization changes

### Causal Ordering With Event References

Scenario: social network where unfriend must precede message-send notification.

```
unfriend_event {
  event_id: "evt_123",
  user: "alice", removed: "bob",
  timestamp: ...
}

message_send {
  event_id: "evt_456",
  author: "alice", body: "...",
  observed_state: ["evt_123"]   // alice saw the unfriend before posting
}
```

**Why it works**:
- The notification service waits to process `evt_456` until `evt_123` is applied
- Captures causal dependency without requiring global total order broadcast
- Scales beyond a single-leader log
- Logical clocks (Lamport, vector) provide a generic version of this pattern

## Real Systems

### Apache Beam

Unified API for batch and stream. The same pipeline (`PCollection`, `ParDo`, `GroupByKey`, windowing) runs on:
- Bounded inputs → batch mode (Spark, Dataflow batch)
- Unbounded inputs → stream mode (Flink, Dataflow streaming)

Event-time windowing, watermarks, and triggers are first-class — required for correct reprocessing.

### Apache Flink

Stream-first engine that treats batch as a special case of stream (bounded). Provides exactly-once semantics, event-time processing, and stateful operators with checkpointing. Common backbone for kappa architectures.

### Materialize

SQL-based streaming database. Defines materialized views over Kafka topics; views update incrementally as new events arrive. Same SQL works for historical replay and live updates — kappa-style unification at the query layer.

### Debezium + Kafka

The canonical CDC stack. Debezium captures row-level changes from Postgres/MySQL/Mongo and emits them to Kafka topics. Downstream stream processors derive search indexes, caches, warehouses from the change stream. Source database remains the source-of-truth; everything else is derived.
