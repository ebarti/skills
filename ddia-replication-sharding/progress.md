# ddia-replication-sharding - Creation Progress

Source: "Designing Data-Intensive Applications" (Kleppmann, 2nd ed), Chapters 6-7.

## Status Overview

| Phase | Files | Complete |
|-------|-------|----------|
| Foundation | 3 | 3/3 |
| Workflows | 3 | 3/3 |
| Single-Leader Replication | 3 | 3/3 |
| Multi-Leader Replication | 3 | 3/3 |
| Conflict Resolution | 3 | 3/3 |
| Leaderless Replication | 3 | 3/3 |
| Sharding Strategies | 3 | 3/3 |
| Routing & Secondary Indexes | 3 | 3/3 |
| **Total** | **24** | **24/24** |

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

- [x] workflows/choosing-replication-topology.md — pick single/multi/leaderless given requirements
- [x] workflows/designing-sharding-scheme.md — partition key + method + rebalancing plan
- [x] workflows/handling-replication-conflicts.md — pick conflict resolution mechanism

## Phase 3: Single-Leader Replication

Source: Chapter 6 (single-leader sections)

- [x] single-leader-replication/knowledge.md
- [x] single-leader-replication/rules.md
- [x] single-leader-replication/examples.md

## Phase 4: Multi-Leader Replication

Source: Chapter 6 (multi-leader sections)

- [x] multi-leader-replication/knowledge.md
- [x] multi-leader-replication/rules.md
- [x] multi-leader-replication/examples.md

## Phase 5: Conflict Resolution

Source: Chapter 6 (conflict resolution sections)

- [x] conflict-resolution/knowledge.md
- [x] conflict-resolution/rules.md
- [x] conflict-resolution/examples.md

## Phase 6: Leaderless Replication

Source: Chapter 6 (leaderless / Dynamo-style sections)

- [x] leaderless-replication/knowledge.md
- [x] leaderless-replication/rules.md
- [x] leaderless-replication/examples.md

## Phase 7: Sharding Strategies

Source: Chapter 7 (partitioning sections)

- [x] sharding-strategies/knowledge.md
- [x] sharding-strategies/rules.md
- [x] sharding-strategies/examples.md

## Phase 8: Routing & Secondary Indexes

Source: Chapter 7 (routing and secondary index sections)

- [x] routing-and-secondary-indexes/knowledge.md
- [x] routing-and-secondary-indexes/rules.md
- [x] routing-and-secondary-indexes/examples.md

## Notes

- All 6 reference categories are complete with 3 files each (knowledge/rules/examples).
- Foundation files (SKILL.md, guidelines.md, progress.md) are complete.
- All 3 workflows in `workflows/` are complete and referenced from `SKILL.md` and `guidelines.md`.
- Every category is referenced from `guidelines.md` (Workflows, By Task, By Symptom, Decision Tree, File Index, Common Combinations).
