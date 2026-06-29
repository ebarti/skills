---
name: ddia-transactions-consistency
description: |
  Distilled knowledge from "Designing Data-Intensive Applications" (Kleppmann, 2nd ed.) chapters 8-10 on transactions, distributed system fundamentals, and consistency/consensus. Covers ACID semantics, weak/strong isolation, distributed failure modes, time/clocks, linearizability, and consensus protocols.

  Use this skill when:
  - Picking a database isolation level
  - Diagnosing race conditions, lost updates, or write skew
  - Designing for distributed failures (network/clocks/processes)
  - Choosing a consensus tool (ZooKeeper, etcd, Raft)
  - Building distributed locks safely (with fencing)
  - Implementing distributed transactions or 2PC
  - Reasoning about CAP/linearizability
  - Debugging stale reads, split-brain, or zombie writers
  - Reviewing database, replication, or coordination service choices
---

# DDIA Transactions and Consistency

A reference skill covering the safety properties of single-node transactions (chapter 7/8) and the additional difficulties that distributed systems impose on those properties (chapters 8-9). Organized into 9 categories that can be loaded individually as needed.

## Quick Start

1. Open `guidelines.md` to find which files match your task or symptom
2. Load only the listed files — most tasks need 1-3 reference files
3. For a multi-step process (e.g., picking an isolation level), check `workflows/` instead

## Contents

### References

| Category | Files | Purpose |
|----------|-------|---------|
| `acid-fundamentals/` | knowledge, rules, examples | What ACID actually means; transaction model basics |
| `isolation-levels/` | knowledge, rules, examples | Read committed, snapshot isolation, lost updates, write skew |
| `serializability/` | knowledge, rules, examples | Serial execution, 2PL, SSI |
| `distributed-transactions/` | knowledge, rules, examples | 2PC, XA, atomic commit across nodes |
| `distributed-failures/` | knowledge, rules, examples | Partial failure, network partitions, faults |
| `distributed-time/` | knowledge, rules, examples | Wall vs monotonic clocks, NTP, process pauses |
| `distributed-truth/` | knowledge, rules, examples | Quorums, leases, fencing tokens, system models |
| `linearizability/` | knowledge, rules, examples | Strong consistency, CAP, logical clocks |
| `consensus/` | knowledge, rules, examples | Paxos/Raft, ZooKeeper, etcd, leader election |

### Workflows

| Task | Workflow |
|------|----------|
| Choose database isolation level (read committed, snapshot, serializable) | `workflows/choosing-isolation-level.md` |
| Diagnose a distributed bug (lost write, stale read, race condition) | `workflows/diagnosing-distributed-bug.md` |
| Design a fault-tolerant distributed system | `workflows/designing-fault-tolerant-system.md` |
| Choose consensus / coordination tool (ZooKeeper, etcd, Consul) | `workflows/choosing-consensus-tool.md` |

## Guidelines

See `guidelines.md` for:
- Task-based file selection (transaction design, concurrency bugs, distributed coordination, failure modes)
- Symptom/question lookup ("two updates raced and one was lost", "clock skew causing weird ordering", etc.)
- Topic index across all 9 categories
- Decision trees for isolation level, consensus tool, and distributed lock design
- Complete file index (27 reference files)
