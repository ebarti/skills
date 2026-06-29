---
name: ddia-replication-sharding
description: |
  Distilled guidance from "Designing Data-Intensive Applications" (Kleppmann, 2nd ed) chapters 6-7 on replication topologies, sharding strategies, conflict resolution, and request routing for distributed data systems.

  Use this skill when:
  - Choosing a replication topology (single-leader, multi-leader, leaderless)
  - Designing a sharding scheme (range vs hash, multi-tenant, hot keys)
  - Resolving write conflicts in distributed databases
  - Building offline-first / sync-engine apps
  - Designing global secondary indexes for sharded systems
  - Diagnosing replication lag, stale reads, or hot-shard problems
---

# DDIA Replication & Sharding

A reference skill covering the design space for replicated and sharded data systems, drawn from Martin Kleppmann's "Designing Data-Intensive Applications" (2nd edition), chapters 6-7. Use it when picking a replication topology, deciding a partition key, planning rebalancing, choosing a conflict resolution policy, or designing secondary indexes that span shards.

## Quick Start

1. Read `guidelines.md` to find the right reference file(s) for your task.
2. Load only the files relevant to your scenario (most tasks need 1-3 files).
3. For multi-step design tasks, see the `workflows/` directory.
4. Apply the rules and patterns to your specific system.

## Contents

### References

| Category | Files | Purpose |
|----------|-------|---------|
| `single-leader-replication/` | knowledge, rules, examples | Primary-backup, sync vs async, lag, failover, replication log formats |
| `multi-leader-replication/` | knowledge, rules, examples | Multi-region, sync engines, offline-capable clients, topology choices |
| `conflict-resolution/` | knowledge, rules, examples | Avoidance, LWW, CRDTs, OT, manual resolution, concurrency detection |
| `leaderless-replication/` | knowledge, rules, examples | Dynamo-style, quorums, read repair, sloppy quorums, vector clocks |
| `sharding-strategies/` | knowledge, rules, examples | Range vs hash partitioning, hot spots, rebalancing, multitenancy |
| `routing-and-secondary-indexes/` | knowledge, rules, examples | Request routing, local vs global secondary indexes, ZooKeeper-style coordination |

## Workflows

| Task | Workflow |
|------|----------|
| Choose replication topology (single-leader, multi-leader, leaderless) | `workflows/choosing-replication-topology.md` |
| Design a sharding scheme (key, strategy, hot-spot mitigation) | `workflows/designing-sharding-scheme.md` |
| Handle write conflicts (LWW, CRDT, OT, manual) | `workflows/handling-replication-conflicts.md` |

## Guidelines

See `guidelines.md` for:

- Task-based file selection (replication design, conflict strategy, sharding design, index design)
- Symptom-based lookup (stale reads, hot keys, multi-region latency, etc.)
- Topic-by-topic file index
- Decision tree for replication and sharding strategy
