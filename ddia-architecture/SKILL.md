---
name: ddia-architecture
description: |
  Foundational architectural concepts for data-intensive applications, distilled from "Designing Data-Intensive Applications" (Kleppmann, 2nd ed) chapters 1-2. Covers the operational vs analytical split, cloud vs self-hosted trade-offs, distributed systems trade-offs, and the core nonfunctional requirements (performance, reliability, scalability, maintainability).

  Use this skill when:
  - Choosing between OLTP (operational) and analytical (OLAP) storage
  - Deciding cloud vs self-hosted / managed service vs build-your-own
  - Evaluating distributed (microservices, multi-node) vs single-node architectures
  - Defining performance SLOs and reasoning about response-time percentiles
  - Designing for reliability, defining a fault model, and choosing fault tolerance strategies
  - Planning capacity / scalability and choosing scale-up vs scale-out
  - Architecting for long-term maintainability (operability, simplicity, evolvability)
  - Reviewing an architecture proposal against DDIA fundamentals
---

# DDIA Architecture

Foundational concepts every data-intensive system architect needs: how operational and analytical systems differ, when to use cloud vs self-hosted, when to distribute, and how to reason about performance, reliability, scalability, and maintainability. Built from chapters 1-2 of "Designing Data-Intensive Applications" (Kleppmann, 2nd ed).

## Quick Start

1. Read `guidelines.md` first — it routes you from your task or symptom to the right files.
2. Load only the files relevant to your task (each category has `knowledge.md`, `rules.md`, `examples.md`).
3. Apply the concepts to the architecture decision at hand.

## Contents

### References

| Category | Files | Purpose |
|----------|-------|---------|
| `references/operational-vs-analytical/` | knowledge, rules, examples | OLTP vs OLAP; warehouses, lakes, lakehouses; system of record vs derived data |
| `references/cloud-vs-self-hosted/` | knowledge, rules, examples | Build vs buy; IaaS/PaaS/SaaS; cloud-native vs on-prem trade-offs |
| `references/distributed-systems-intro/` | knowledge, rules, examples | When to distribute; partial failure; microservices vs monolith vs serverless |
| `references/performance/` | knowledge, rules, examples | Response time vs throughput; percentiles; tail latency; SLOs/SLAs |
| `references/reliability/` | knowledge, rules, examples | Fault vs failure; fault tolerance; hardware/software/human faults |
| `references/scalability/` | knowledge, rules, examples | Load parameters; scale-up vs scale-out; shared-nothing |
| `references/maintainability/` | knowledge, rules, examples | Operability, simplicity, evolvability; abstractions; legacy systems |

### Workflows

| Task | Workflow |
|------|----------|
| Decide cloud vs self-hosted deployment | `workflows/choosing-cloud-vs-self-hosted.md` |
| Define performance SLOs (latency, throughput, error budget) | `workflows/defining-performance-slos.md` |
| Assess reliability requirements & identify SPOFs | `workflows/assessing-reliability-requirements.md` |

## Guidelines

See `guidelines.md` for:
- Task-based file selection (architecture decisions, capacity planning, operational design)
- Symptom/question lookup ("latency is unpredictable", "system breaks on deploy", etc.)
- Topic index with paths to every reference file
- Decision tree for common architecture questions
- Complete file index
