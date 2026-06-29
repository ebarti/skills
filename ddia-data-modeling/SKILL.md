---
name: ddia-data-modeling
description: |
  Data modeling, storage engines, and encoding choices distilled from "Designing Data-Intensive Applications" (Kleppmann, 2nd ed) chapters 3-5. Covers relational, document, graph, and event-sourced models; LSM, B-tree, in-memory, and columnar storage; specialized indexes; encoding formats; and modes of dataflow.

  Use this skill when:
  - Choosing a database (relational/document/graph)
  - Picking a storage engine (LSM/B-tree/columnar)
  - Designing an analytics warehouse
  - Selecting a wire format (JSON/Avro/Protobuf)
  - Deciding REST vs RPC vs messaging
  - Modeling event-sourced systems
  - Building search/vector/geo indexes
---

# DDIA Data Modeling

A reference skill for designing data models, picking storage engines, and choosing encoding/dataflow strategies. Knowledge is split across 8 categories with progressive disclosure: load only the references relevant to the decision in front of you.

## Quick Start

1. Open `guidelines.md` — find your task, symptom, or topic.
2. Load only the listed reference files (typically 1-3).
3. Apply the rules and patterns; consult `examples.md` files for concrete code/schema.
4. For multi-step decisions, follow the relevant workflow under `workflows/`.

## Contents

### References

| Category | Files | Purpose |
|----------|-------|---------|
| `relational-document-models` | knowledge, rules, examples | Relational vs document trade-offs, joins, schema-on-write vs schema-on-read |
| `graph-models` | knowledge, rules, examples | Property graphs, triple stores, Cypher/SPARQL/Datalog, traversal patterns |
| `event-sourcing-cqrs` | knowledge, rules, examples | Append-only event logs, CQRS read views, DataFrames for analytics |
| `oltp-storage` | knowledge, rules, examples | LSM-trees, B-trees, in-memory engines, write/read trade-offs |
| `olap-storage` | knowledge, rules, examples | Columnar layout, vectorized execution, separation of storage and compute |
| `specialized-indexes` | knowledge, rules, examples | Multidimensional, geo (R-tree), full-text, vector indexes |
| `encoding-formats` | knowledge, rules, examples | JSON, Protobuf, Avro, Thrift; schema evolution and compatibility |
| `dataflow-modes` | knowledge, rules, examples | Databases, REST/RPC services, messaging, durable execution |

### Workflows

- `workflows/choosing-database-type.md` — relational vs document vs graph vs columnar
- `workflows/choosing-storage-engine.md` — LSM vs B-tree vs in-memory vs columnar
- `workflows/choosing-encoding-format.md` — JSON vs Avro vs Protobuf vs Thrift
- `workflows/designing-event-sourced-system.md` — event log + CQRS read views

## Workflows

| Task | Workflow |
|------|----------|
| Choose between relational/document/graph/columnar database | `workflows/choosing-database-type.md` |
| Choose storage engine (LSM/B-tree/in-memory/columnar) | `workflows/choosing-storage-engine.md` |
| Pick wire encoding format & schema evolution strategy | `workflows/choosing-encoding-format.md` |
| Design an event-sourced system with CQRS | `workflows/designing-event-sourced-system.md` |

## Guidelines

See `guidelines.md` for:

- Task-based file selection (database choice, storage choice, analytics, encoding, services)
- Symptom/question lookup (joins, connected data, audit, write throughput, etc.)
- Topic-by-topic file index (8 categories, 24 files)
- Decision trees for the most common selection paths
