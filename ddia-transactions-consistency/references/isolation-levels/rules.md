# Weak Isolation Levels Rules

Decision rules for choosing isolation levels and preventing concurrency anomalies.

## Core Rules

### 1. Default to Read Committed Minimum

Never run with read uncommitted in production application code. Read committed is the default in PostgreSQL, Oracle, SQL Server, and most relational databases for good reason.

- Prevents dirty reads (no observing in-flight uncommitted writes).
- Prevents dirty writes (no clobbering uncommitted concurrent writes).
- Avoids cascading aborts.

### 2. Use Snapshot Isolation for Read-Heavy and Analytics Workloads

Long-running reads benefit hugely; cost is small with MVCC.

- Backups: must see a single point-in-time view, otherwise restored data is internally inconsistent.
- Analytical / reporting queries scanning many rows.
- Periodic integrity checks.
- Mostly free with MVCC engines (PostgreSQL, Oracle, MySQL InnoDB, SQL Server).

### 3. Prefer Atomic Write Operations Over Read-Modify-Write

Atomic ops eliminate lost updates without application-level coordination.

**Bad** (read-modify-write race):
```sql
SELECT counter FROM counters WHERE key = 'x';
-- application increments
UPDATE counters SET counter = $new WHERE key = 'x';
```

**Good** (atomic):
```sql
UPDATE counters SET counter = counter + 1 WHERE key = 'x';
```

Watch ORM frameworks — they easily generate read-modify-write patterns by default.

### 4. Know Your Database's Lost-Update Behavior

Lost-update detection is **not** universal under "snapshot" / "repeatable read".

| Database / Level | Detects Lost Updates? |
|------------------|----------------------|
| PostgreSQL repeatable read | Yes |
| Oracle serializable | Yes |
| SQL Server snapshot isolation | Yes |
| MySQL/InnoDB repeatable read | No |

If your DB doesn't detect, use atomic ops, CAS, or explicit locking.

### 5. Try CAS / Optimistic Locking Before Pessimistic Locks

If atomic ops can't express the logic but contention is low:

```sql
UPDATE wiki SET content = $new
WHERE id = $id AND content = $old_content;
```

Or with a version column:
```sql
UPDATE wiki SET content = $new, version = version + 1
WHERE id = $id AND version = $old_version;
```

Always check rowcount and retry on conflict.

### 6. Use `SELECT FOR UPDATE` Only When Necessary

Reach for explicit locking after considering:
1. Can a built-in atomic op handle this?
2. Can CAS / version columns handle this?
3. Does this require multi-row coordination not expressible above?

Consider deadlock risk and retry handling.

### 7. For Write Skew, Use Serializable or Materialize Conflicts

Snapshot isolation does **not** prevent write skew. Options:

- **Best**: Serializable isolation (single-node) or SSI.
- **Single-row reads in step 1**: `SELECT FOR UPDATE` on those rows.
- **Phantom (absence check)**: Add a uniqueness constraint when possible (e.g., username).
- **Last resort**: Materialize the conflict — create a lock-only table whose rows can be locked with `SELECT FOR UPDATE` (e.g., a (room, time-slot) table).

## Guidelines

- Treat ORM-generated SQL with suspicion in concurrent paths.
- Assume an attacker may deliberately race your endpoints — test with concurrent fuzz, not just functional tests.
- Don't trust naming: read your DB's docs to confirm what "repeatable read" or "serializable" actually guarantees.
- For replicated databases, locks and CAS assume one up-to-date copy — multi-leader/leaderless systems need conflict resolution (CRDTs) instead.

## Exceptions

- **Read uncommitted**: Acceptable only for monitoring/dashboarding tolerant of stale or in-flight values.
- **Skip snapshot isolation**: When all reads are tiny single-row lookups and write throughput cost of versioning matters more than consistency.
- **Materializing conflicts**: Only when serializable is unavailable or too costly; ugly because the concurrency mechanism leaks into the data model.

## Quick Reference

| Problem | First Choice | Fallback |
|---------|-------------|----------|
| Counter / aggregate increment | Atomic `UPDATE x = x + 1` | CAS with version |
| Mutual modification of same row | DB lost-update detection (Postgres RR) | `SELECT FOR UPDATE` |
| Document patch | DB-native atomic op (e.g., MongoDB `$set`) | CAS on version field |
| Username uniqueness | `UNIQUE` constraint | Materialize conflict |
| Booking / scheduling | Serializable isolation | Materialize (slot table) |
| Doctor-on-call invariant | Serializable isolation | `SELECT FOR UPDATE` on read rows |
| Read-only analytics | Snapshot isolation | — |
