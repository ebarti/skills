# Choosing Isolation Level Workflow

Pick the right database isolation level by mapping invariants to anomalies, then to the cheapest mechanism that prevents them.

## When to Use

- Designing a new transactional code path
- Reviewing a concurrent path for correctness
- Diagnosing a race / lost-update / phantom bug
- Migrating between databases (e.g., MySQL → Postgres) where "repeatable read" means different things

## Prerequisites

- Knowledge of which database engine and version you target
- A list of invariants the transaction must preserve
- Awareness that vendor isolation names lie (see naming confusion table)

**Reference**: `references/isolation-levels/rules.md`, `references/isolation-levels/knowledge.md`, `references/serializability/rules.md`

---

## Workflow Steps

### Step 1: Identify the invariants the transaction must preserve

**Goal**: Make the correctness contract explicit before picking a mechanism.

- [ ] List every invariant in plain language (e.g., "balance never negative", "no double-booking", "username unique", "at least one doctor on call")
- [ ] Note whether each invariant spans one row, multiple rows, or *absence* of rows
- [ ] Mark which reads in the transaction the invariant depends on

**Ask**: "If two copies of this transaction ran concurrently, which invariant could break?"

**Reference**: `references/acid-fundamentals/rules.md`

---

### Step 2: Map each invariant to a concurrency anomaly

**Goal**: Translate "what could break" into the named anomaly that breaks it.

- [ ] Reading uncommitted state matters? → **dirty read**
- [ ] Two writers clobbering each other on the same row? → **dirty write** / **lost update**
- [ ] Reading two related rows and seeing them in inconsistent states? → **read skew**
- [ ] Two transactions read overlapping data, write *different* rows, break a shared invariant? → **write skew**
- [ ] Invariant depends on the *absence* of rows (no booking, no duplicate)? → **phantom**

**Reference**: `references/isolation-levels/knowledge.md` (anomaly definitions and table)

---

### Step 3: Set the floor at read committed

**Goal**: Establish the minimum bar — never go below this in production.

- [ ] Confirm engine default is read committed or stronger
- [ ] Reject read uncommitted unless this is monitoring/dashboard code tolerant of in-flight values
- [ ] Verify no dirty reads or dirty writes are possible at this level

**Reference**: `references/isolation-levels/rules.md` Rule 1

---

### Step 4: Escalate to snapshot isolation if read consistency matters

**Goal**: Get a consistent point-in-time view for any multi-row read.

- [ ] Long-running read or report? → snapshot isolation
- [ ] Backup that must be internally consistent? → snapshot isolation
- [ ] Engine uses MVCC? Snapshot is essentially free — turn it on
- [ ] Confirm the vendor name: PostgreSQL `REPEATABLE READ` and Oracle `SERIALIZABLE` both = snapshot isolation

**Reference**: `references/isolation-levels/rules.md` Rule 2

---

### Step 5: Handle lost updates explicitly

**Goal**: Don't assume the engine catches read-modify-write races.

- [ ] If logic is `x = x + delta`: use atomic `UPDATE x = x + delta`
- [ ] If atomic op can't express it but contention is low: use CAS / version column with rowcount check + retry
- [ ] If multi-row coordination needed: `SELECT ... FOR UPDATE`
- [ ] If relying on DB lost-update detection: verify (Postgres RR yes, MySQL RR no, MS SQL snapshot yes, Oracle serializable yes)
- [ ] Audit ORM-generated SQL — frameworks routinely emit read-modify-write

**Reference**: `references/isolation-levels/rules.md` Rules 3–6

---

### Step 6: For write skew or phantoms, escalate to serializable or materialize the conflict

**Goal**: Snapshot isolation does **not** prevent write skew. Pick a real fix.

- [ ] Best fix: serializable isolation (single-node engine: SSI on Postgres, 2PL on MySQL, serial execution on VoltDB)
- [ ] Single-row reads in step 1 of the txn: `SELECT FOR UPDATE` may suffice
- [ ] Absence-check phantom (uniqueness): use a `UNIQUE` constraint
- [ ] No serializable available or too costly: materialize the conflict (lock-only table such as `(room, time_slot)` rows)
- [ ] Confirm low contention before picking SSI; high contention favors 2PL or weaker level + explicit checks

**Reference**: `references/isolation-levels/rules.md` Rule 7, `references/serializability/rules.md` Rules 5–6, 10

---

### Step 7: Verify the engine implements what its level claims

**Goal**: Vendor labels lie. Confirm the actual mechanism.

- [ ] PostgreSQL `SERIALIZABLE` = SSI (optimistic, abort on commit conflict)
- [ ] MySQL/InnoDB `SERIALIZABLE` = 2PL with next-key locks
- [ ] Oracle `SERIALIZABLE` = snapshot isolation (NOT true serializable)
- [ ] PostgreSQL `REPEATABLE READ` = snapshot isolation with lost-update detection
- [ ] MySQL/InnoDB `REPEATABLE READ` = weaker than snapshot, no lost-update detection
- [ ] SQL Server `SNAPSHOT` = snapshot isolation with lost-update detection
- [ ] Plan retry loops for any serializable level (deadlocks under 2PL, abort-on-conflict under SSI)

**Reference**: `references/isolation-levels/knowledge.md` Naming Confusion table, `references/serializability/rules.md` Rule 8

---

### Step 8: Document the choice and acknowledged anomalies

**Goal**: Make the trade-off visible to future maintainers.

- [ ] Record chosen isolation level + engine in code comments or ADR
- [ ] List anomalies still possible at the chosen level (e.g., "snapshot isolation — write skew still possible, mitigated by `UNIQUE` constraint")
- [ ] Note retry strategy and deadlock/abort handling
- [ ] Add a concurrent-fuzz test if the path is security-sensitive

---

## Decision Tree: Anomaly → Required Level

| Anomaly to prevent | Minimum level / mechanism |
|--------------------|---------------------------|
| Dirty read | Read committed |
| Dirty write | Read committed |
| Read skew | Snapshot isolation |
| Lost update | Snapshot + DB detection, OR atomic op, OR CAS, OR `FOR UPDATE` |
| Write skew | Serializable, OR `SELECT FOR UPDATE` on read rows, OR materialized conflict |
| Phantom (presence) | Serializable, OR predicate/range locks (2PL) |
| Phantom (absence) | `UNIQUE` constraint, OR materialized conflict, OR serializable |

---

## Quick Checklist

```
[ ] Step 1: Invariants listed in plain language
[ ] Step 2: Each invariant mapped to a named anomaly
[ ] Step 3: Floor set at read committed
[ ] Step 4: Snapshot isolation chosen if read consistency matters
[ ] Step 5: Lost updates handled (atomic / CAS / lock / DB detection verified)
[ ] Step 6: Write skew / phantoms escalated (serializable or materialize)
[ ] Step 7: Engine's actual mechanism for the chosen label confirmed
[ ] Step 8: Choice + remaining anomalies documented
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Assuming MySQL `REPEATABLE READ` = snapshot | InnoDB RR is weaker; no lost-update detection — silent races | Use Postgres RR, atomic ops, CAS, or explicit locking |
| Expecting MS SQL `SNAPSHOT` to prevent write skew | Snapshot only detects lost updates on the same row, not write skew | Escalate to `SERIALIZABLE` or materialize the conflict |
| Picking Oracle `SERIALIZABLE` for write-skew safety | Oracle "serializable" is snapshot isolation — write skew still possible | Add explicit locks or restructure schema for materialized conflicts |
| Defaulting to `SERIALIZABLE` "to be safe" | Real cost: aborts under SSI, deadlocks under 2PL, blocked tail latency | Use weakest level + explicit invariant checks (CAS, `FOR UPDATE`) |
| Trusting ORM-generated `UPDATE` to be atomic | ORMs often emit read-modify-write; lost updates slip through | Audit SQL, prefer atomic `UPDATE x = x + 1` or CAS with version |
| Forgetting retry loops on serializable | SSI aborts at commit, 2PL deadlocks — both surface as exceptions | Wrap every serializable txn in bounded retry with backoff |
| `SELECT FOR UPDATE` on rows that don't exist yet | Cannot lock absence — phantoms slip through | `UNIQUE` constraint or materialize conflict (lock-only table) |
| Indexless `WHERE` under MySQL 2PL serializable | Falls back to full-table shared lock — throughput collapses | Index every column referenced in `WHERE` of serializable txns |

---

## Exit Criteria

Task is complete when:
- [ ] Every invariant has a named anomaly and a chosen prevention mechanism
- [ ] The chosen isolation level matches the engine's *actual* implementation, not just its label
- [ ] Lost-update behavior is verified (not assumed) for the target engine
- [ ] Retry strategy exists for any serializable-level transaction
- [ ] Choice and residual anomalies are documented in code or an ADR

---

## Cross-References

- `references/isolation-levels/rules.md` — decision rules for weak isolation levels
- `references/isolation-levels/knowledge.md` — anomaly and isolation-level definitions
- `references/serializability/rules.md` — engine-selection and operational rules for serializable
- `references/acid-fundamentals/rules.md` — invariants, atomicity, and consistency context
