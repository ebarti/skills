# Weak Isolation Levels Knowledge

Core concepts for transaction isolation levels weaker than serializable.

## Overview

Concurrency bugs occur when transactions read data being concurrently modified, or when two transactions modify the same data. Databases offer transaction isolation to hide these issues, but stronger isolation has performance costs, so most systems default to weaker levels that protect against some but not all race conditions.

## Key Concepts

### Isolation Level

**Definition**: A guarantee about which concurrency anomalies a transaction is protected against.

**Hierarchy** (weakest to strongest):
- **Read uncommitted**: Prevents dirty writes only.
- **Read committed**: Prevents dirty reads and dirty writes.
- **Snapshot isolation / Repeatable read**: Adds consistent point-in-time snapshots; prevents read skew.
- **Serializable**: Behaves as if transactions ran one at a time.

### Dirty Read

**Definition**: Reading data written by a transaction that has not yet committed.

A reader sees uncommitted state which may later be rolled back. Prevented at read committed and above.

### Dirty Write

**Definition**: Overwriting a value written by another transaction that has not yet committed.

Causes interleaved updates across rows (e.g., sale awarded to one buyer, invoice sent to another). Prevented by row-level write locks at read committed and above.

### Read Skew (Non-repeatable Read)

**Definition**: A transaction reads two related values at different points in time and observes inconsistent state (e.g., money "vanishing" mid-transfer).

Allowed under read committed; prevented by snapshot isolation.

### Lost Update

**Definition**: Two transactions perform a read-modify-write cycle on the same value; the later write clobbers the earlier modification.

Common with counter increments, JSON edits, wiki page saves. Not prevented by read committed.

### Write Skew

**Definition**: Two transactions read overlapping data and each modify different rows in a way that violates an invariant that depended on the data they both read.

Generalization of lost update where transactions write to *different* objects. Doctor on-call, meeting bookings, double-spending. Requires serializable or explicit locking to prevent.

### Phantom

**Definition**: A write in one transaction changes the result of a search query in another transaction.

Particularly tricky when the query checks for *absence* of rows (no booking exists, username free) — `SELECT FOR UPDATE` cannot lock rows that don't exist yet.

### MVCC (Multiversion Concurrency Control)

**Definition**: Storage technique where the database keeps multiple committed versions of each row, tagged with the transaction ID that created or deleted them.

**Visibility rules**: A row is visible to a reader iff:
- The inserting transaction had committed before the reader started.
- The deleting transaction (if any) had not committed before the reader started.

**Key property**: Readers never block writers, writers never block readers.

### Snapshot Isolation

**Definition**: Each transaction reads from a consistent snapshot of the database as of its start time.

Built on MVCC. Ideal for backups, analytics, long-running read-only queries.

### Compare-and-Set (CAS) / Conditional Write

**Definition**: An update that applies only if the current value matches what was last read.

Database equivalent of CPU atomic CAS. Often called *optimistic locking* when implemented with a version-number column.

### Explicit Locking (`SELECT ... FOR UPDATE`)

**Definition**: Application explicitly locks rows it intends to modify, forcing concurrent transactions to wait.

Required when atomic ops can't express the logic; risks deadlock.

## Naming Confusion

The SQL standard predates snapshot isolation, so vendors map terms differently:

| Vendor Term | Actual Meaning |
|-------------|----------------|
| PostgreSQL "repeatable read" | Snapshot isolation |
| Oracle "serializable" | Snapshot isolation |
| MySQL/InnoDB "repeatable read" | Weaker than snapshot isolation; no lost-update detection |
| IBM Db2 "repeatable read" | True serializability |

> "Nobody really knows what repeatable read isolation means."

## Quick Reference

| Anomaly | Read Committed | Snapshot Isolation | Serializable |
|---------|----------------|-------------------|--------------|
| Dirty read | Prevented | Prevented | Prevented |
| Dirty write | Prevented | Prevented | Prevented |
| Read skew | Allowed | Prevented | Prevented |
| Lost update | Allowed | Detected (some DBs) | Prevented |
| Write skew | Allowed | Allowed | Prevented |
| Phantom | Allowed | Allowed in r/w | Prevented |
