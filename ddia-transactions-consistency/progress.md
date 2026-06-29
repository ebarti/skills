# ddia-transactions-consistency - Creation Progress

Source: "Designing Data-Intensive Applications" (Kleppmann, 2nd ed.) chapters 8-10.

## Status Overview

| Phase | Files | Complete |
|-------|-------|----------|
| Foundation | 3 | 3/3 |
| Workflows | 4 | 4/4 |
| ACID Fundamentals | 3 | 3/3 |
| Isolation Levels | 3 | 3/3 |
| Serializability | 3 | 3/3 |
| Distributed Transactions | 3 | 3/3 |
| Distributed Failures | 3 | 3/3 |
| Distributed Time | 3 | 3/3 |
| Distributed Truth | 3 | 3/3 |
| Linearizability | 3 | 3/3 |
| Consensus | 3 | 3/3 |
| **Total** | **34** | **34/34** |

## Legend

- [ ] Not started
- [~] In progress
- [x] Completed
- [-] Skipped/Not needed

## Phase 1: Foundation

- [x] SKILL.md
- [x] progress.md
- [x] guidelines.md

## Phase 2: Workflows

Workflows are step-by-step processes for repeatable tasks.

- [x] workflows/choosing-isolation-level.md — pick the right database isolation level
- [x] workflows/diagnosing-distributed-bug.md — narrow a distributed bug to clocks/network/concurrency
- [x] workflows/designing-fault-tolerant-system.md — apply system-model thinking to a new design
- [x] workflows/choosing-consensus-tool.md — pick between ZooKeeper, etcd, Consul, or built-in consensus

## Phase 3: ACID Fundamentals

Source: Chapter 7/8 (transaction model, ACID properties)

Required files:
- [x] acid-fundamentals/knowledge.md
- [x] acid-fundamentals/rules.md
- [x] acid-fundamentals/examples.md

## Phase 4: Isolation Levels

Source: Chapter 7/8 (weak isolation: read committed, snapshot isolation, lost update, write skew, phantoms)

Required files:
- [x] isolation-levels/knowledge.md
- [x] isolation-levels/rules.md
- [x] isolation-levels/examples.md

## Phase 5: Serializability

Source: Chapter 7/8 (serial execution, 2PL, SSI)

Required files:
- [x] serializability/knowledge.md
- [x] serializability/rules.md
- [x] serializability/examples.md

## Phase 6: Distributed Transactions

Source: Chapter 9 (atomic commit, 2PC, XA)

Required files:
- [x] distributed-transactions/knowledge.md
- [x] distributed-transactions/rules.md
- [x] distributed-transactions/examples.md

## Phase 7: Distributed Failures

Source: Chapter 8 (partial failure, network partitions, faults)

Required files:
- [x] distributed-failures/knowledge.md
- [x] distributed-failures/rules.md
- [x] distributed-failures/examples.md

## Phase 8: Distributed Time

Source: Chapter 8 (wall vs monotonic clocks, NTP, process pauses)

Required files:
- [x] distributed-time/knowledge.md
- [x] distributed-time/rules.md
- [x] distributed-time/examples.md

## Phase 9: Distributed Truth

Source: Chapter 8 (quorums, leases, fencing tokens, Byzantine, system models)

Required files:
- [x] distributed-truth/knowledge.md
- [x] distributed-truth/rules.md
- [x] distributed-truth/examples.md

## Phase 10: Linearizability

Source: Chapter 9 (strong consistency, CAP, logical clocks)

Required files:
- [x] linearizability/knowledge.md
- [x] linearizability/rules.md
- [x] linearizability/examples.md

## Phase 11: Consensus

Source: Chapter 9 (Paxos/Raft, ZooKeeper, etcd, leader election)

Required files:
- [x] consensus/knowledge.md
- [x] consensus/rules.md
- [x] consensus/examples.md

## Notes

- All 9 reference categories have complete knowledge/rules/examples triples (27 files).
- Foundation files (SKILL.md, guidelines.md, progress.md) are complete and now reference the 4 workflows.
- All 4 workflow files are complete (isolation-level selection, distributed-bug diagnosis, fault-tolerant design, consensus tool selection).
- guidelines.md references all 27 knowledge files at least once across By Task, By Symptom, By Topic, Decision Tree, and File Index sections, and links to the 4 workflows from a top-level Workflows section and from relevant By-Task rows.
- Skill is complete: 34/34 files.
