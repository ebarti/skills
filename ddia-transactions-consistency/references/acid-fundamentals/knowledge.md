# ACID Transaction Fundamentals Knowledge

Core concepts of database transactions and the ACID properties as defined in DDIA Chapter 8.

## Overview

A transaction groups several reads and writes into a single logical unit so the application can treat partial failure and concurrency as solved problems. ACID (Atomicity, Consistency, Isolation, Durability) is the canonical safety contract — but its meaning varies across vendors, and "ACID compliant" has become a marketing term as much as a technical one.

## Key Concepts

### Transaction

**Definition**: A group of reads and writes executed as one logical unit, which either commits (all changes take effect) or aborts (none take effect).

The transaction model originates with IBM System R (1975); MySQL, PostgreSQL, Oracle, and SQL Server still follow that style 50 years later.

### Atomicity

**Definition**: If a fault occurs partway through a sequence of writes, the transaction is aborted and all writes made so far are discarded — an "all-or-nothing" guarantee.

ACID atomicity is **not about concurrency** (that's isolation). It is about partial-failure recovery: process crashes, network interruptions, full disks, integrity violations.

**Key points**:
- Without atomicity, a retry might re-apply changes that did succeed, causing duplicates
- The book notes "abortability" would have been a more accurate name
- Enables safe retries: if aborted, the application knows nothing changed

### Consistency (in ACID)

**Definition**: An application-specific notion that the database is in a "good state" — its invariants (e.g., credits = debits) hold before and after every transaction.

The "C" in ACID is **not** the same as the "C" in CAP (which means linearizability). It's also distinct from replica consistency, consistent snapshots, and consistent hashing.

**Key points**:
- The database can enforce invariants only when declared as constraints (foreign keys, uniqueness, check constraints)
- Complex invariants are the application's responsibility
- Consistency depends on how the application uses the database — it is not a property of the database alone

### Isolation

**Definition**: Concurrently executing transactions are insulated from each other; they cannot observe each other's intermediate state.

Classic textbook isolation is **serializability**: the result is as if transactions ran one at a time, in some serial order. Most databases ship weaker levels by default (snapshot isolation, read committed) for performance. Oracle's "serializable" actually implements snapshot isolation.

### Durability

**Definition**: Once a transaction has committed, its writes will not be lost — even on crash, power loss, or hardware failure.

**Key points**:
- Single-node: typically `fsync` to nonvolatile storage + write-ahead log + checksums
- Replicated: writes copied to N nodes before acknowledging commit
- Perfect durability does not exist; `fsync` and SSDs both have known failure modes — combine disk + replication + backups

### Commit, Abort, Rollback

**Definition**:
- **Commit**: finalize all writes from a transaction — they become visible and durable
- **Abort**: cancel a transaction in progress; the database discards any writes already made
- **Rollback**: synonym for the discarding step performed during abort

### Single-Object vs Multi-Object Operations

**Single-object writes**: Storage engines almost universally guarantee atomicity and isolation for a single object (e.g., one key, one row, one document). Implemented via a per-object log + lock.

**Multi-object transactions**: Group writes to several objects so they commit or abort together. Required when invariants span objects: foreign keys, secondary indexes, denormalized derived data.

In SQL, a multi-object transaction is bracketed by `BEGIN TRANSACTION` ... `COMMIT` on a single TCP connection. Many NoSQL systems offer multi-key APIs (e.g., multi-put) without true transaction semantics — partial success is possible.

### BASE

**Definition**: "Basically Available, Soft state, Eventual consistency" — a marketing term for systems that don't meet ACID. The book notes the only sensible reading of BASE is "not ACID" (i.e., almost anything).

### NoSQL "Transaction" Misnomers

Several NoSQL systems use "transaction" or "atomic" loosely:
- **Atomic increment**: an operation atomic in the multithreaded-programming sense — really an *isolated* single-object op, not an ACID transaction
- **Multi-put**: writes several keys in one call, but may succeed for some and fail for others
- **Cassandra/ScyllaDB "lightweight transactions"**, **Aerospike "strong consistency"**: linearizable reads and conditional writes on a single object — no cross-object guarantees

## Terminology

| Term | Definition |
|------|------------|
| Transaction | A group of reads/writes treated as one unit (commit or abort) |
| Atomicity | All-or-nothing on partial failure (a.k.a. abortability) |
| Consistency | Application invariants hold across the transaction |
| Isolation | Concurrent transactions don't observe each other's intermediate state |
| Durability | Committed data survives crashes |
| Commit | Finalize a transaction's writes |
| Abort | Cancel and discard an in-progress transaction |
| Rollback | The discarding step during abort |
| Invariant | A statement about data that must always hold (e.g., balance >= 0) |
| Constraint | A schema-level invariant the DB enforces (FK, uniqueness, check) |
| Serializability | Strongest isolation: result equivalent to some serial execution |
| Snapshot isolation | Each transaction sees a consistent snapshot; weaker than serializable |
| BASE | "Not ACID"; eventual consistency framing |

## How It Relates To

- **Isolation levels** (separate file): refines what "isolation" actually means in shipping databases
- **Distributed transactions / 2PC**: extend atomicity across multiple data systems
- **Replication**: durability in replicated systems = N-node confirmation
- **CAP theorem**: the "C" there is linearizability, not ACID consistency

## Common Misconceptions

- **Myth**: "ACID compliant" means the same thing across vendors.
  **Reality**: Implementations vary widely — especially the "I". Always check what isolation level your DB ships by default.

- **Myth**: The "C" in ACID is the same as the "C" in CAP.
  **Reality**: ACID consistency is application-level invariants. CAP consistency is linearizability (single-copy semantics).

- **Myth**: Atomicity and isolation are about the same thing.
  **Reality**: Atomicity handles partial *failure*. Isolation handles concurrent *access*.

- **Myth**: NoSQL "transactions" provide ACID.
  **Reality**: Many provide only single-object atomicity, or compare-and-set, with no multi-object guarantees.

- **Myth**: Transactions are fundamentally unscalable.
  **Reality**: NewSQL systems (Spanner, CockroachDB, TiDB, FoundationDB, YugabyteDB) provide ACID at scale via consensus + sharding.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Atomicity | All-or-nothing on partial failure |
| Consistency | Application invariants preserved (app's responsibility too) |
| Isolation | Concurrent transactions appear sequential |
| Durability | Committed data survives crash |
| Commit | Make writes permanent and visible |
| Abort/Rollback | Discard everything written in the transaction |
| Single-object atomic op | Not a transaction; a per-object isolated write |
| Multi-object transaction | Required when invariants span rows/docs/indexes |
