---
name: ddia-batch-stream-processing
description: |
  Knowledge from "Designing Data-Intensive Applications" (Kleppmann, 2nd ed) chapters 11-13 on batch processing, stream processing, and the future of data systems — covering MapReduce/dataflow engines, message brokers, change data capture, stream-processing time semantics, dataflow architectures, and end-to-end correctness.

  Use this skill when:
  - Choosing batch vs stream architecture
  - Designing an ETL/ELT pipeline
  - Implementing CDC (change data capture)
  - Picking a stream processor (Flink, Spark, Kafka Streams)
  - Designing real-time materialized views
  - Architecting a data lake/lakehouse
  - Ensuring exactly-once / end-to-end correctness
  - Building event-driven applications
  - Picking a message broker (Kafka, RabbitMQ, Pulsar, Kinesis)
  - Unbundling a monolithic database into composable systems
  - Deciding between event sourcing and CRUD
  - Reasoning about windowing, watermarks, and out-of-order events
---

# DDIA Batch & Stream Processing

Reference for derived-data systems: how to compute, transmit, and reconcile data across batch jobs, message streams, and the heterogeneous storage tools modern applications depend on. Distilled from DDIA chapters 11 (Batch Processing), 12 (Stream Processing), and 13 (Doing the Right Thing).

## Quick Start

1. **Open `guidelines.md`** to find the right files for your task — by task, by symptom, or via the decision tree.
2. **Load only the files relevant** to your situation; each is under 200 lines.
3. **Apply the knowledge** to your design, code review, or implementation.

## Contents

### References (8 categories, 24 files)

| Category | Files | Use When |
|----------|-------|----------|
| `batch-foundations` | knowledge / rules / examples | Designing MapReduce/Spark jobs, joins, partitioning, fault tolerance |
| `batch-use-cases` | knowledge / rules / examples | ETL/ELT pipelines, OLAP/lakehouse, ML feature engineering |
| `event-streams` | knowledge / rules / examples | Picking message brokers, partitioning, consumer groups, retention |
| `databases-and-streams` | knowledge / rules / examples | CDC, log shipping, event sourcing, dual-write hazards |
| `stream-processing` | knowledge / rules / examples | Time semantics, windows, stream joins, fault tolerance |
| `data-integration` | knowledge / rules / examples | Combining heterogeneous tools, derived data, reprocessing |
| `unbundling-databases` | knowledge / rules / examples | Dataflow architectures, microservices state, application as DB |
| `end-to-end-correctness` | knowledge / rules / examples | Idempotency, exactly-once, integrity, auditing, request IDs |

## Workflows

| Task | Workflow |
|------|----------|
| Choose batch vs stream processing architecture | `workflows/choosing-batch-vs-stream.md` |
| Implement CDC (change data capture) pipeline | `workflows/implementing-cdc-pipeline.md` |
| Design a stream processing pipeline (windows, joins, fault tolerance) | `workflows/designing-stream-pipeline.md` |
| Ensure exactly-once / end-to-end correctness | `workflows/ensuring-exactly-once.md` |

## Guidelines

See `guidelines.md` for:
- Task-based file selection (Pipeline Design, Event-Driven, Stream Processing, Data Architecture)
- Symptom/question lookup ("Need to keep search index in sync", "Want exactly-once", ...)
- Topic-based browsing (all 8 categories)
- Decision tree (batch vs stream, broker selection, exactly-once recipe)
- Complete file index (all 24 references)
