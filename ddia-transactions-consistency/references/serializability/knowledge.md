# Serializability Knowledge

Core concepts and foundational understanding for serializable isolation in databases.

## Overview

Serializable isolation is the strongest isolation level: it guarantees that even though transactions execute in parallel, the end result is the same as if they had executed one at a time, serially. It prevents all possible race conditions (lost updates, write skew, phantoms) — if transactions are individually correct, they remain correct under concurrency. Three implementation techniques dominate: actual serial execution, two-phase locking (2PL), and serializable snapshot isolation (SSI).

## Key Concepts

### Serializability

**Definition**: Isolation guarantee that the result of executing transactions concurrently is equivalent to some serial (one-at-a-time) execution order.

**Key points**:
- Strongest standard isolation level
- Prevents lost updates, write skew, and phantoms
- Implementation, not order, is what varies

### Actual Serial Execution

**Definition**: Run all transactions on a single thread, one at a time, removing concurrency entirely.

**Key points**:
- Made feasible by cheap RAM (in-memory data) and short OLTP transactions
- Used by VoltDB/H-Store, Redis, Datomic
- Throughput limited to a single CPU core per shard
- Requires stored procedures (no interactive multi-statement transactions)

### Two-Phase Locking (2PL)

**Definition**: Pessimistic concurrency control using shared/exclusive locks per object, held until end of transaction.

**Key points**:
- Two phases: growing (acquire locks) then shrinking (release at commit/abort) — phases must not overlap
- Readers block writers and writers block readers (opposite of snapshot isolation)
- Prone to deadlocks (database detects and aborts one)
- Used in MySQL/InnoDB and SQL Server serializable; Db2 repeatable-read

### Serializable Snapshot Isolation (SSI)

**Definition**: Optimistic concurrency control built on snapshot isolation, with conflict detection at commit time.

**Key points**:
- Transactions execute hopefully; database checks at commit whether isolation was violated
- Detects two patterns: stale MVCC reads (write committed after read) and writes affecting prior reads
- Aborts on conflict; application must retry
- Used in PostgreSQL serializable, SQL Server In-Memory OLTP/Hekaton, CockroachDB, FoundationDB, BadgerDB

### Stored Procedure

**Definition**: Transaction code submitted to the database ahead of time and executed entirely server-side.

**Key points**:
- Required for serial execution (no network round-trips per statement)
- Modern engines use general-purpose languages (Java, JavaScript, Lua, Clojure, Groovy)
- Must be deterministic when used for state-machine replication (VoltDB)

### Predicate Lock

**Definition**: A lock attached to a search condition (not a specific object) that also covers objects matching the predicate that don't yet exist.

**Key points**:
- Conceptually clean way to prevent phantoms under 2PL
- Performs poorly: checking many active predicates is expensive
- Mostly replaced in practice by index-range locks

### Index-Range Lock (Next-Key Lock)

**Definition**: A simpler approximation of a predicate lock attached to a range of an index entry.

**Key points**:
- Safe to over-approximate (lock more objects than strictly necessary)
- Falls back to whole-table shared lock if no usable index exists
- Standard 2PL phantom-prevention technique

### Optimistic vs. Pessimistic Concurrency Control

**Definition**: Pessimistic blocks pre-emptively when a hazard might exist; optimistic proceeds and verifies at commit.

**Key points**:
- Pessimistic: 2PL (mutual exclusion), serial execution (extreme — exclusive lock on whole DB/shard)
- Optimistic: SSI (proceed, then check at commit; abort if conflict)
- Optimistic wins on low contention; pessimistic safer under high contention

## Terminology

| Term | Definition |
|------|------------|
| Serializability | Concurrent execution equivalent to some serial order |
| 2PL | Two-phase locking (serializability via locks) |
| SS2PL | Strong strict 2PL — the variant in practice |
| SSI | Serializable snapshot isolation (optimistic) |
| MVCC | Multi-version concurrency control (basis for snapshot isolation and SSI) |
| Predicate lock | Lock on a query condition, covering future matches |
| Index-range lock | Practical approximation of predicate lock |
| Stored procedure | Server-side transaction code |
| Deadlock | Two transactions waiting on each other's locks |
| Premise | Fact a transaction observed and acted on; SSI checks if it became false |
| Tripwire (SSI) | Lock that notifies but does not block |

## How It Relates To

- **Snapshot Isolation**: SSI is built on top of MVCC snapshots; adds conflict detection
- **Write Skew & Phantoms**: Serializable isolation prevents both; weaker levels do not
- **Two-Phase Commit (2PC)**: Different concept entirely (atomic commit across nodes); see misconception below
- **State-Machine Replication**: Deterministic stored procedures replicated to replicas (VoltDB)
- **Sharding**: Required to scale serial execution beyond one CPU core

## Common Misconceptions

- **Myth**: 2PL and 2PC are related.
  **Reality**: They are entirely separate. 2PL is an isolation algorithm; 2PC is a distributed-commit protocol. Treat the names as a coincidence.

- **Myth**: Serializable means transactions actually run serially.
  **Reality**: Only "actual serial execution" runs them serially; 2PL and SSI run concurrently with extra machinery.

- **Myth**: Serializable is always slow.
  **Reality**: 2PL is slow; serial execution scales poorly past one core; SSI has only modest overhead vs. snapshot isolation when contention is low.

- **Myth**: Predicate locks are what 2PL databases actually use.
  **Reality**: Almost all use index-range (next-key) locks as a cheaper approximation.

- **Myth**: Snapshot isolation = "readers never block writers" applies to 2PL too.
  **Reality**: Under 2PL, readers block writers and vice versa.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Serial execution | One transaction at a time, single thread, in-memory, stored procedures |
| 2PL | Shared/exclusive locks held until commit; deadlock-prone; pessimistic |
| SSI | Snapshot reads + commit-time conflict detection; optimistic; abort and retry |
| Predicate lock | Conceptual lock on a query condition (covers phantoms) |
| Index-range lock | Cheap approximation of predicate lock; standard in 2PL implementations |
| Stored procedure | Whole transaction server-side; required for serial execution |
