# ACID Transaction Fundamentals Rules

When and how to use transactions, retries, and single-object atomic operations.

## Core Rules

### 1. Use multi-object transactions when invariants span objects

If a single logical change touches more than one row, document, or index, wrap it in a transaction. Without one, partial failures and concurrent reads can leave the data in a state no application invariant covers.

Trigger conditions:
- **Foreign key references**: inserting parent + child must commit together
- **Secondary indexes**: an indexed write updates the row and every index — they must be consistent
- **Denormalized / derived data**: counters, materialized aggregates, cached fields that mirror authoritative state
- **Cross-account moves**: any "subtract from A, add to B" pattern (transfers, inventory moves)

**Example**:
```sql
-- Bad: two statements, no atomicity — a crash between them leaves an orphan row
INSERT INTO emails (mailbox_id, body) VALUES (42, '...');
UPDATE mailboxes SET unread_count = unread_count + 1 WHERE id = 42;

-- Good: one transaction, all-or-nothing
BEGIN TRANSACTION;
  INSERT INTO emails (mailbox_id, body) VALUES (42, '...');
  UPDATE mailboxes SET unread_count = unread_count + 1 WHERE id = 42;
COMMIT;
```

### 2. Use single-object atomic operations for simple counters and flags

When the entire change fits inside one row/document/key, a built-in increment or compare-and-set (CAS) is enough — no transaction needed. This avoids the read-modify-write race in [Figure 8-1].

- Use atomic `INCR` / `DECR` for counters
- Use compare-and-set (`UPDATE ... WHERE version = ?`) to prevent lost updates
- Reach for a transaction only when the change spans more than one object

**Example**:
```sql
-- Bad: read-modify-write race; two clients can both write the same incremented value
SELECT counter FROM stats WHERE id = 1;       -- both read 42
UPDATE stats SET counter = 43 WHERE id = 1;   -- both write 43, lose one increment

-- Good: server-side atomic increment, no race
UPDATE stats SET counter = counter + 1 WHERE id = 1;
```

### 3. Always handle aborts properly — retry transient errors with backoff

ACID databases prefer to abort rather than commit a half-finished transaction. The point of abort is to enable safe retries — but retries have failure modes of their own.

Retry rules:
- **Retry only transient errors**: deadlock, isolation conflict, temporary network blip, failover
- **Do not retry permanent errors**: constraint violations, malformed input — a retry is pointless
- **Cap retries and use exponential backoff**: retrying under contention or overload makes things worse, not better
- **Treat overload errors specially**: drop load, don't pile on
- **Do not rely on ORM defaults**: Rails ActiveRecord and Django do not retry aborted transactions — you have to wire it in yourself

### 4. Use idempotency keys when retries cross network/RPC boundaries

If a commit succeeded but the acknowledgment was lost, the client retries — and the transaction runs twice. The DB cannot help you here; deduplicate at the application layer.

- Pass a client-generated unique request ID on every retry
- Server checks "have I seen this ID?" before applying
- Persist the dedup record inside the same transaction as the work

### 5. Beware non-idempotent side effects during retry

Anything outside the database (emails, payments, webhook calls, push notifications) will not roll back when the transaction aborts. Retrying the transaction can re-trigger them.

- Defer side effects until *after* commit (outbox pattern, transactional task queue)
- Or use two-phase commit when several systems must agree
- Never embed `send_email()` inside a retry loop without dedup

### 6. Don't conflate ACID definitions across vendors

"ACID compliant" is a marketing label. Two databases claiming ACID may give very different guarantees, especially for isolation.

- Always check the **default isolation level** your DB ships (often weaker than serializable)
- Oracle's "serializable" is actually snapshot isolation
- A multi-key API in a NoSQL store is not the same as a transaction
- Document the level your application actually relies on

## Guidelines

- Prefer the database's built-in constraints over application-level invariant checks (FKs, uniqueness, CHECK)
- For document stores, design documents so logically-grouped fields live in one document — single-object atomicity is then enough
- Treat secondary indexes as additional objects: assume you need a transaction when inserting indexed rows on systems that lack atomic index updates
- For replicated durability, decide explicitly: ack after local fsync? after N replicas? after quorum? Don't let it be implicit.
- Combine durability techniques — disk + replication + backups — none is sufficient alone

## Exceptions

- **Pure key-value workloads** with no cross-object invariants: single-object atomic ops are enough
- **Leaderless replication systems** (Cassandra, DynamoDB style): they explicitly do *not* roll back; build idempotent operations and accept best-effort semantics
- **Read-only analytical work**: a consistent snapshot is often all you need; a full transaction may be overkill

## Quick Reference

| Rule | Summary |
|------|---------|
| Multi-object transactions for cross-object invariants | FKs, indexes, denormalized data |
| Single-object atomic ops for counters/flags | INCR, CAS — no transaction needed |
| Retry transient errors with capped exponential backoff | Skip retries on constraint violations |
| Idempotency keys at network boundaries | Dedup duplicate retried commits |
| Defer side effects past commit | Emails/payments don't roll back |
| Verify the isolation level you actually get | Don't trust the "ACID" label alone |
