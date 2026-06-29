# DDIA Data Modeling Guidelines

Quick reference for finding the right knowledge file for your task. **How to use**: Find your situation below, then load ONLY the listed files.

Path prefix `R/` = `references/`. Each category folder has `knowledge.md`, `rules.md`, `examples.md`.

---

## Workflows

For multi-step decisions, load the workflow first — it sequences which references to consult and in what order.

| Task | Workflow |
|------|----------|
| Choose between relational/document/graph/columnar database | `workflows/choosing-database-type.md` |
| Choose storage engine (LSM/B-tree/in-memory/columnar) | `workflows/choosing-storage-engine.md` |
| Pick wire encoding format & schema evolution strategy | `workflows/choosing-encoding-format.md` |
| Design an event-sourced system with CQRS | `workflows/designing-event-sourced-system.md` |

---

## By Task

### Database Selection

| What you're doing | Load these files |
|-------------------|------------------|
| Relational vs document trade-off | `workflows/choosing-database-type.md` + `R/relational-document-models/rules.md` |
| Modeling many-to-many or connected data | `workflows/choosing-database-type.md` + `R/graph-models/rules.md` |
| Choosing a query language for graphs | `R/graph-models/examples.md` |
| Document model schema design | `R/relational-document-models/examples.md` |

### Storage Engine Selection

| What you're doing | Load these files |
|-------------------|------------------|
| LSM vs B-tree vs in-memory | `workflows/choosing-storage-engine.md` + `R/oltp-storage/rules.md` |
| Tuning compaction or write amplification | `R/oltp-storage/rules.md`, `R/oltp-storage/examples.md` |
| Row-store vs column-store | `workflows/choosing-storage-engine.md` + `R/olap-storage/knowledge.md` |
| Choosing index strategy | `R/oltp-storage/rules.md`, `R/specialized-indexes/knowledge.md` |

### Analytics Architecture

| What you're doing | Load these files |
|-------------------|------------------|
| Designing a data warehouse / lakehouse | `R/olap-storage/knowledge.md`, `R/olap-storage/rules.md` |
| Picking a columnar format (Parquet/ORC/Arrow) | `R/olap-storage/examples.md`, `R/encoding-formats/knowledge.md` |
| Materialized views and aggregates | `R/olap-storage/rules.md`, `R/event-sourcing-cqrs/knowledge.md` |
| DataFrames for ML pipelines | `R/event-sourcing-cqrs/knowledge.md`, `R/event-sourcing-cqrs/examples.md` |

### Schema / Format Design

| What you're doing | Load these files |
|-------------------|------------------|
| Picking JSON vs Avro vs Protobuf vs Thrift | `workflows/choosing-encoding-format.md` + `R/encoding-formats/rules.md` |
| Evolving a schema without breaking clients | `workflows/choosing-encoding-format.md` + `R/encoding-formats/rules.md` |
| DB schema migration strategy | `R/encoding-formats/rules.md`, `R/dataflow-modes/knowledge.md` |

### Service Design

| What you're doing | Load these files |
|-------------------|------------------|
| REST vs gRPC vs messaging vs durable execution | `R/dataflow-modes/knowledge.md`, `R/dataflow-modes/rules.md` |
| Designing async/event-driven services | `workflows/designing-event-sourced-system.md` + `R/dataflow-modes/rules.md` |
| Cross-team API compatibility | `R/dataflow-modes/rules.md`, `R/encoding-formats/rules.md` |
| Event-driven microservices | `workflows/designing-event-sourced-system.md` + `R/event-sourcing-cqrs/rules.md` |

---

## By Symptom / Question

| If you notice / ask... | Load these files |
|------------------------|------------------|
| "We have lots of joins" | `R/relational-document-models/knowledge.md` |
| "Highly connected social/recommendation data" | `R/graph-models/knowledge.md` |
| "Need full audit trail / time travel" | `workflows/designing-event-sourced-system.md` + `R/event-sourcing-cqrs/rules.md` |
| "Write throughput is the bottleneck" | `R/oltp-storage/knowledge.md` (LSM section) |
| "Read latency is critical" | `R/oltp-storage/knowledge.md` (B-tree section) |
| "Aggregate queries on huge tables are slow" | `R/olap-storage/knowledge.md` |
| "Need similarity / semantic search" | `R/specialized-indexes/knowledge.md` (vectors) |
| "Geo or range-on-multiple-dimensions search" | `R/specialized-indexes/knowledge.md` (R-tree) |
| "Full-text keyword search" | `R/specialized-indexes/knowledge.md`, `R/specialized-indexes/examples.md` |
| "Schemas evolving across services" | `R/encoding-formats/knowledge.md`, `R/encoding-formats/rules.md` |
| "Designing service-to-service communication" | `R/dataflow-modes/knowledge.md` |
| "Object-relational impedance mismatch" | `R/relational-document-models/examples.md` |
| "DataFrame vs SQL for ML pipeline" | `R/event-sourcing-cqrs/examples.md` |

---

## By Topic

Each category folder contains three required files: `knowledge.md` (concepts), `rules.md` (do's/don'ts), `examples.md` (concrete code/schema).

| Category | Folder |
|----------|--------|
| Relational & Document Models | `R/relational-document-models/` |
| Graph Models | `R/graph-models/` |
| Event Sourcing, CQRS, DataFrames | `R/event-sourcing-cqrs/` |
| OLTP Storage Engines | `R/oltp-storage/` |
| OLAP / Analytical Storage | `R/olap-storage/` |
| Specialized Indexes | `R/specialized-indexes/` |
| Encoding Formats | `R/encoding-formats/` |
| Modes of Dataflow | `R/dataflow-modes/` |

---

## Decision Tree

```
START — What kind of decision?
│
├─► DATA MODEL
│   ├─► Hierarchical, one-doc-per-entity → R/relational-document-models/  (document)
│   ├─► Many-to-many, joins everywhere   → R/relational-document-models/  (relational)
│   ├─► Highly connected (social, KG)    → R/graph-models/
│   └─► Audit / time travel / many views → R/event-sourcing-cqrs/
│
├─► STORAGE ENGINE
│   ├─► OLTP write-heavy   → R/oltp-storage/  (LSM)
│   ├─► OLTP read/range    → R/oltp-storage/  (B-tree)
│   ├─► OLTP fits in RAM   → R/oltp-storage/  (in-memory)
│   ├─► OLAP / analytics   → R/olap-storage/  (columnar)
│   └─► Specialized lookup
│       ├─► Geo / multidim → R/specialized-indexes/  (R-tree)
│       ├─► Text           → R/specialized-indexes/  (full-text)
│       └─► Similarity     → R/specialized-indexes/  (vectors)
│
├─► ENCODING FORMAT
│   ├─► Human-readable, debuggable     → R/encoding-formats/  (JSON/CSV)
│   ├─► Compact, schema-evolvable      → R/encoding-formats/  (Avro/Protobuf/Thrift)
│   └─► Big-data file w/ schema-on-read → R/encoding-formats/  (Avro container)
│
└─► DATAFLOW MODE
    ├─► Persistent state         → R/dataflow-modes/  (database)
    ├─► Sync request/response    → R/dataflow-modes/  (REST/RPC)
    ├─► Async, decoupled         → R/dataflow-modes/  (messaging)
    └─► Long-running orchestration → R/dataflow-modes/  (durable execution)
```

---

## File Index

All 24 knowledge files (3 per category):

### Relational & Document Models
| File | Purpose |
|------|---------|
| `R/relational-document-models/knowledge.md` | Relational vs document, impedance mismatch, schema-on-read/write |
| `R/relational-document-models/rules.md` | Choosing between models, normalization, denormalization |
| `R/relational-document-models/examples.md` | Profile schemas in SQL vs JSON, joins vs nesting |

### Graph Models
| File | Purpose |
|------|---------|
| `R/graph-models/knowledge.md` | Property graphs vs triple stores, vertices/edges, traversal models |
| `R/graph-models/rules.md` | When to pick a graph DB; node/edge modeling guidelines |
| `R/graph-models/examples.md` | Cypher, SPARQL, Datalog query examples |

### Event Sourcing, CQRS, DataFrames
| File | Purpose |
|------|---------|
| `R/event-sourcing-cqrs/knowledge.md` | Event logs, commands vs events, CQRS read views, DataFrames |
| `R/event-sourcing-cqrs/rules.md` | When to event-source; designing events; replay pitfalls |
| `R/event-sourcing-cqrs/examples.md` | Booking system, derived views, DataFrame transforms |

### OLTP Storage Engines
| File | Purpose |
|------|---------|
| `R/oltp-storage/knowledge.md` | LSM, B-tree, in-memory; SSTables, memtables, WAL |
| `R/oltp-storage/rules.md` | Engine selection, compaction tuning, secondary indexes |
| `R/oltp-storage/examples.md` | RocksDB, LevelDB, Postgres, Redis configurations |

### OLAP / Analytical Storage
| File | Purpose |
|------|---------|
| `R/olap-storage/knowledge.md` | Columnar layout, separation of storage/compute, warehouse vs lake |
| `R/olap-storage/rules.md` | Schema design (star/snowflake), materialized views, partitioning |
| `R/olap-storage/examples.md` | Snowflake, BigQuery, DuckDB, Parquet patterns |

### Specialized Indexes
| File | Purpose |
|------|---------|
| `R/specialized-indexes/knowledge.md` | Concatenated, multidim (R-tree), full-text, vector indexes |
| `R/specialized-indexes/rules.md` | When to add a specialized index vs reuse generic ones |
| `R/specialized-indexes/examples.md` | Geo queries, ElasticSearch, vector embeddings (HNSW/IVF) |

### Encoding Formats
| File | Purpose |
|------|---------|
| `R/encoding-formats/knowledge.md` | JSON/XML/CSV, Protobuf/Thrift/Avro, schema evolution mechanics |
| `R/encoding-formats/rules.md` | Backward/forward compatibility rules per format |
| `R/encoding-formats/examples.md` | Schema evolution scenarios, field tag rules, defaults |

### Modes of Dataflow
| File | Purpose |
|------|---------|
| `R/dataflow-modes/knowledge.md` | Databases, REST/RPC, messaging, durable execution |
| `R/dataflow-modes/rules.md` | Compatibility direction per mode, idempotency, error handling |
| `R/dataflow-modes/examples.md` | gRPC service contract, Kafka topic, Temporal workflow |

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| Event-sourced microservice | `R/event-sourcing-cqrs/knowledge.md` + `R/dataflow-modes/knowledge.md` + `R/encoding-formats/rules.md` |
| Analytics pipeline | `R/olap-storage/knowledge.md` + `R/encoding-formats/knowledge.md` + `R/event-sourcing-cqrs/knowledge.md` |
| Primary OLTP store choice | `R/oltp-storage/knowledge.md` + `R/relational-document-models/knowledge.md` |
| Adding search | `R/specialized-indexes/knowledge.md` + `R/specialized-indexes/examples.md` |
| Service contracts | `R/dataflow-modes/rules.md` + `R/encoding-formats/rules.md` |
