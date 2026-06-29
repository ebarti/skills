# ddia-data-modeling - Creation Progress

Source material: "Designing Data-Intensive Applications" (Kleppmann, 2nd ed), chapters 3-5.

## Status Overview

| Phase | Files | Complete |
|-------|-------|----------|
| Foundation | 3 | 3/3 |
| Workflows | 4 | 4/4 |
| Relational & Document Models | 3 | 3/3 |
| Graph Models | 3 | 3/3 |
| Event Sourcing, CQRS, DataFrames | 3 | 3/3 |
| OLTP Storage Engines | 3 | 3/3 |
| OLAP / Analytical Storage | 3 | 3/3 |
| Specialized Indexes | 3 | 3/3 |
| Encoding Formats | 3 | 3/3 |
| Modes of Dataflow | 3 | 3/3 |
| **Total** | **31** | **31/31** |

## Legend

- [ ] Not started
- [~] In progress
- [x] Completed
- [-] Skipped/Not needed

## Phase 1: Foundation

- [x] SKILL.md
- [x] guidelines.md
- [x] progress.md

## Phase 2: Workflows

Step-by-step procedures for repeatable selection tasks.

- [x] workflows/choosing-database-type.md — relational vs document vs graph vs columnar decision flow
- [x] workflows/choosing-storage-engine.md — LSM vs B-tree vs in-memory vs columnar selection
- [x] workflows/choosing-encoding-format.md — JSON vs Avro vs Protobuf vs Thrift selection
- [x] workflows/designing-event-sourced-system.md — event log + CQRS derived views walk-through

## Phase 3: Relational & Document Models

Source: Chapter 3 (relational vs document)

Required files:
- [x] references/relational-document-models/knowledge.md
- [x] references/relational-document-models/rules.md
- [x] references/relational-document-models/examples.md

## Phase 4: Graph Models

Source: Chapter 3 (graph models, Cypher, SPARQL, Datalog)

Required files:
- [x] references/graph-models/knowledge.md
- [x] references/graph-models/rules.md
- [x] references/graph-models/examples.md

## Phase 5: Event Sourcing, CQRS, DataFrames

Source: Chapter 3 (event sourcing, CQRS, DataFrames/arrays)

Required files:
- [x] references/event-sourcing-cqrs/knowledge.md
- [x] references/event-sourcing-cqrs/rules.md
- [x] references/event-sourcing-cqrs/examples.md

## Phase 6: OLTP Storage Engines

Source: Chapter 4 (LSM-trees, B-trees, in-memory engines)

Required files:
- [x] references/oltp-storage/knowledge.md
- [x] references/oltp-storage/rules.md
- [x] references/oltp-storage/examples.md

## Phase 7: OLAP / Analytical Storage

Source: Chapter 4 (column-oriented storage, data warehouses, lakes)

Required files:
- [x] references/olap-storage/knowledge.md
- [x] references/olap-storage/rules.md
- [x] references/olap-storage/examples.md

## Phase 8: Specialized Indexes

Source: Chapter 4 (multidim, full-text, vector indexes)

Required files:
- [x] references/specialized-indexes/knowledge.md
- [x] references/specialized-indexes/rules.md
- [x] references/specialized-indexes/examples.md

## Phase 9: Encoding Formats

Source: Chapter 5 (JSON, Protobuf, Thrift, Avro; schema evolution)

Required files:
- [x] references/encoding-formats/knowledge.md
- [x] references/encoding-formats/rules.md
- [x] references/encoding-formats/examples.md

## Phase 10: Modes of Dataflow

Source: Chapter 5 (databases, REST/RPC services, messaging, durable execution)

Required files:
- [x] references/dataflow-modes/knowledge.md
- [x] references/dataflow-modes/rules.md
- [x] references/dataflow-modes/examples.md

## Notes

- All 8 reference categories complete with the 3 required files each (knowledge, rules, examples).
- Foundation layer (SKILL.md, guidelines.md, progress.md) complete and references all 4 workflows.
- All 4 workflows authored under `workflows/`.
- Every reference file is referenced at least once in `guidelines.md` (verified).
