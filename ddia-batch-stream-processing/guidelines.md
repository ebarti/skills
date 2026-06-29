# DDIA Batch & Stream Processing Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use**: Find your situation below, then load ONLY the listed files.

---

## Workflows

| Task | Workflow |
|------|----------|
| Choose batch vs stream processing architecture | `workflows/choosing-batch-vs-stream.md` |
| Implement CDC (change data capture) pipeline | `workflows/implementing-cdc-pipeline.md` |
| Design a stream processing pipeline (windows, joins, fault tolerance) | `workflows/designing-stream-pipeline.md` |
| Ensure exactly-once / end-to-end correctness | `workflows/ensuring-exactly-once.md` |

---

## By Task

### Pipeline Design

| What you're doing | Load these files |
|-------------------|------------------|
| Choosing ETL vs ELT | `batch-use-cases/knowledge.md`, `batch-use-cases/rules.md` |
| Designing a MapReduce/Spark job | `batch-foundations/knowledge.md`, `batch-foundations/rules.md` |
| Picking batch vs stream | `workflows/choosing-batch-vs-stream.md`, `batch-foundations/knowledge.md`, `stream-processing/knowledge.md` |
| Orchestrating multi-step pipelines (Airflow, Dagster) | `batch-use-cases/rules.md`, `batch-foundations/examples.md` |
| Reprocessing historical data after a bug/schema change | `data-integration/knowledge.md`, `data-integration/rules.md` |
| Building a data lake / lakehouse (Iceberg, Delta) | `batch-use-cases/knowledge.md`, `batch-use-cases/examples.md` |

### Event-Driven Architecture

| What you're doing | Load these files |
|-------------------|------------------|
| Choosing a message broker | `event-streams/knowledge.md`, `event-streams/rules.md` |
| Implementing CDC | `workflows/implementing-cdc-pipeline.md`, `databases-and-streams/knowledge.md`, `databases-and-streams/rules.md` |
| Adopting event sourcing | `databases-and-streams/knowledge.md`, `databases-and-streams/examples.md` |
| Sharing state across microservices | `unbundling-databases/knowledge.md`, `event-streams/knowledge.md` |
| Designing partitioning / consumer groups | `event-streams/rules.md`, `event-streams/examples.md` |
| Avoiding dual-write race conditions | `databases-and-streams/knowledge.md`, `databases-and-streams/rules.md` |

### Stream Processing

| What you're doing | Load these files |
|-------------------|------------------|
| Choosing time semantics (event vs processing) | `stream-processing/knowledge.md`, `stream-processing/rules.md` |
| Designing windows (tumbling, hopping, session) | `stream-processing/knowledge.md`, `stream-processing/examples.md` |
| Implementing a stream-stream / stream-table join | `stream-processing/rules.md`, `stream-processing/examples.md` |
| Handling out-of-order / late events | `stream-processing/knowledge.md`, `stream-processing/rules.md` |
| Fault tolerance, checkpoints, state backends | `workflows/designing-stream-pipeline.md`, `stream-processing/rules.md`, `end-to-end-correctness/knowledge.md` |
| Building a real-time materialized view | `stream-processing/knowledge.md`, `unbundling-databases/knowledge.md` |

### Data Architecture

| What you're doing | Load these files |
|-------------------|------------------|
| Integrating multiple data systems | `data-integration/knowledge.md`, `data-integration/rules.md` |
| Unbundling a monolithic database | `unbundling-databases/knowledge.md`, `unbundling-databases/rules.md` |
| Designing dataflow / event-log-centric apps | `unbundling-databases/knowledge.md`, `unbundling-databases/examples.md` |
| Ensuring end-to-end correctness | `workflows/ensuring-exactly-once.md`, `end-to-end-correctness/knowledge.md`, `end-to-end-correctness/rules.md` |
| Auditing, integrity checks, dataset diffs | `end-to-end-correctness/rules.md`, `end-to-end-correctness/examples.md` |

---

## By Problem/Symptom

| If you notice / are asked... | Load these files |
|------------------------------|------------------|
| "Need to keep search index in sync with DB" | `databases-and-streams/knowledge.md`, `databases-and-streams/rules.md` |
| "Building real-time dashboard" | `stream-processing/knowledge.md`, `unbundling-databases/knowledge.md` |
| "Need to recompute history after schema change" | `data-integration/knowledge.md`, `data-integration/rules.md` |
| "Want exactly-once delivery" | `workflows/ensuring-exactly-once.md`, `end-to-end-correctness/knowledge.md`, `stream-processing/rules.md` |
| "Choosing between Kafka and RabbitMQ" | `event-streams/knowledge.md`, `event-streams/rules.md` |
| "Daily batch report from data lake" | `batch-foundations/knowledge.md`, `batch-use-cases/knowledge.md` |
| "Microservices need to share state" | `unbundling-databases/knowledge.md`, `event-streams/knowledge.md` |
| "ML feature pipeline" | `batch-use-cases/knowledge.md`, `stream-processing/knowledge.md` |
| "Coordinating multiple data systems" | `data-integration/knowledge.md`, `unbundling-databases/knowledge.md` |
| "Slow consumer, queue backing up" | `event-streams/rules.md`, `event-streams/examples.md` |
| "Late / out-of-order events" | `stream-processing/knowledge.md`, `stream-processing/rules.md` |
| "Duplicate writes after retry" | `end-to-end-correctness/knowledge.md`, `end-to-end-correctness/examples.md` |
| "Cache and DB drift over time" | `databases-and-streams/knowledge.md`, `unbundling-databases/knowledge.md` |
| "Want auditability of business state" | `databases-and-streams/knowledge.md`, `end-to-end-correctness/rules.md` |
| "Mapper / reducer / partitioning" | `batch-foundations/rules.md`, `batch-foundations/examples.md` |
| "Idempotency key / fencing token" | `end-to-end-correctness/rules.md`, `end-to-end-correctness/examples.md` |

---

## By Topic

Each category provides the same trio (`knowledge.md` / `rules.md` / `examples.md`):

- **batch-foundations** — Unix philosophy, DFS, MapReduce, dataflow engines, joins, fault tolerance
- **batch-use-cases** — ETL/ELT, OLAP/lakehouse, ML pipelines, derived data products
- **event-streams** — events, topics, brokers (log vs traditional), partitions, retention
- **databases-and-streams** — CDC, log shipping, dual-write hazards, event sourcing
- **stream-processing** — time semantics, windows, joins, fault tolerance, watermarks
- **data-integration** — derived data, source-of-truth, total order broadcast, reprocessing
- **unbundling-databases** — meta-DB, app-as-derivation, dataflow apps, push-based UIs
- **end-to-end-correctness** — end-to-end argument, idempotency, exactly-once, integrity, audit

---

## Decision Tree

```
What are you doing?
│
├─► Choosing a processing model
│   ├─► Bounded dataset, latency in minutes-hours
│   │   → batch-foundations/knowledge.md + batch-use-cases/knowledge.md
│   ├─► Unbounded events, latency in seconds
│   │   → stream-processing/knowledge.md + event-streams/knowledge.md
│   └─► Need both fresh + historical view (Lambda/Kappa)
│       → data-integration/knowledge.md
│
├─► Picking a message broker
│   ├─► Replay, multiple consumers, high throughput
│   │   → event-streams/knowledge.md (log-based: Kafka, Pulsar, Kinesis)
│   ├─► Transient task queue, complex routing
│   │   → event-streams/knowledge.md (AMQP/JMS: RabbitMQ, ActiveMQ)
│   └─► Cloud-managed simplicity
│       → event-streams/rules.md (Kinesis, Pub/Sub, EventBridge)
│
├─► Getting data out of a database
│   ├─► Read replica + transform → batch-use-cases/rules.md (ETL)
│   ├─► Real-time stream of changes → databases-and-streams/knowledge.md (CDC)
│   ├─► App emits events as truth → databases-and-streams/knowledge.md (event sourcing)
│   └─► Avoiding dual-write race → databases-and-streams/rules.md (outbox/CDC)
│
├─► Achieving exactly-once / effectively-once
│   ├─► Make every write idempotent → end-to-end-correctness/rules.md
│   ├─► Add request IDs end-to-end → end-to-end-correctness/knowledge.md
│   ├─► Stream processor with checkpointing → stream-processing/rules.md
│   └─► Audit + reconcile downstream → end-to-end-correctness/examples.md
│
├─► Architecting an event-driven app
│   ├─► Decompose monolith DB → unbundling-databases/knowledge.md
│   ├─► Dataflow / push-based UI → unbundling-databases/rules.md
│   └─► Microservices share state → unbundling-databases/knowledge.md + event-streams/knowledge.md
│
└─► Reviewing / debugging a pipeline
    ├─► Slow batch job → batch-foundations/rules.md
    ├─► Out-of-order events → stream-processing/knowledge.md
    ├─► Duplicates / lost messages → end-to-end-correctness/knowledge.md
    └─► Drift between systems → data-integration/rules.md + databases-and-streams/rules.md
```

---

## File Index

All 24 reference files (8 categories x 3 files):

| File | Purpose |
|------|---------|
| `batch-foundations/knowledge.md` | Unix philosophy, DFS, MapReduce, dataflow engines, joins |
| `batch-foundations/rules.md` | Partitioning, idempotency, atomic output, locality |
| `batch-foundations/examples.md` | Pipelines, mapper/reducer code, MapReduce/Spark patterns |
| `batch-use-cases/knowledge.md` | ETL/ELT, OLAP/lakehouse, ML pipelines, derived data products |
| `batch-use-cases/rules.md` | Orchestration, schema, idempotent loads, scheduling |
| `batch-use-cases/examples.md` | Warehouse loads, search index builds, ML feature jobs |
| `event-streams/knowledge.md` | Events, topics, brokers (log vs traditional), partitions |
| `event-streams/rules.md` | Broker choice, ordering, consumer groups, schema |
| `event-streams/examples.md` | Kafka topics, partition keys, queue patterns |
| `databases-and-streams/knowledge.md` | CDC, log shipping, dual-write, event sourcing |
| `databases-and-streams/rules.md` | Snapshot+log, schema evolution, ordering, retention |
| `databases-and-streams/examples.md` | Debezium, outbox, event-sourced aggregates |
| `stream-processing/knowledge.md` | Time semantics, windows, joins, fault tolerance |
| `stream-processing/rules.md` | Watermarks, state backends, checkpointing, exactly-once |
| `stream-processing/examples.md` | Flink/Kafka Streams patterns, windowed aggregations |
| `data-integration/knowledge.md` | Derived data, source-of-truth, total order broadcast, reprocessing |
| `data-integration/rules.md` | Single writer, schema discipline, replay safety |
| `data-integration/examples.md` | Lambda/Kappa, reconciliation, dual-pipeline migration |
| `unbundling-databases/knowledge.md` | Meta-DB, app-as-derivation, dataflow apps, push UIs |
| `unbundling-databases/rules.md` | Single source of truth, push not poll, code as pure function |
| `unbundling-databases/examples.md` | Materialize, push-based UIs, microservice CDC |
| `end-to-end-correctness/knowledge.md` | End-to-end argument, idempotency, exactly-once, integrity |
| `end-to-end-correctness/rules.md` | Request IDs, fencing, audit checks, integrity validation |
| `end-to-end-correctness/examples.md` | Idempotent receivers, dataset diffs, reconciliation |

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| Building CDC pipeline | `databases-and-streams/knowledge.md` + `event-streams/rules.md` + `end-to-end-correctness/rules.md` |
| Real-time materialized view | `stream-processing/knowledge.md` + `unbundling-databases/knowledge.md` |
| ETL into warehouse | `batch-foundations/rules.md` + `batch-use-cases/knowledge.md` |
| Event sourcing app | `databases-and-streams/knowledge.md` + `unbundling-databases/knowledge.md` |
| Lambda/Kappa architecture | `data-integration/knowledge.md` + `batch-foundations/knowledge.md` + `stream-processing/knowledge.md` |
| Exactly-once recipe | `end-to-end-correctness/knowledge.md` + `stream-processing/rules.md` |
| Microservices on event log | `unbundling-databases/knowledge.md` + `databases-and-streams/knowledge.md` |
