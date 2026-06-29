# ACID Transaction Fundamentals Examples

Worked transaction scenarios from the book, plus a reference of which real systems provide which guarantees.

## Worked Scenarios

### Bank Transfer (canonical multi-object atomicity)

The textbook ACID example: move money from account A to account B. The invariant is `sum(balances) = constant`.

```sql
-- Bad: two independent statements; crash between them loses or duplicates money
UPDATE accounts SET balance = balance - 100 WHERE id = 'A';
-- crash here -> A is debited, B never credited
UPDATE accounts SET balance = balance + 100 WHERE id = 'B';

-- Good: atomic transaction; either both happen or neither
BEGIN TRANSACTION;
  UPDATE accounts SET balance = balance - 100 WHERE id = 'A';
  UPDATE accounts SET balance = balance + 100 WHERE id = 'B';
COMMIT;
```

**Why it works**: Atomicity guarantees no half-finished state. Isolation prevents another transaction from observing A debited but B not yet credited.

### Foreign Key as a Consistency Check

The application invariant "every order belongs to a real customer" is enforced by the DB as a foreign-key constraint. A transaction violating it aborts cleanly — no partial state.

```sql
CREATE TABLE customers (id INT PRIMARY KEY);
CREATE TABLE orders (
  id INT PRIMARY KEY,
  customer_id INT REFERENCES customers(id)
);

BEGIN TRANSACTION;
  INSERT INTO orders (id, customer_id) VALUES (1, 999);  -- 999 doesn't exist
  -- DB raises foreign key violation; whole transaction aborts
COMMIT;  -- never reached
```

**Why it works**: The "C" in ACID — declared as a constraint, enforced by the DB. Atomicity ensures no partial insert.

### Email Notification Side Effect During Retry (anti-pattern)

A transaction that sends an email inside its body, then is retried after an aborted commit attempt — the user gets two emails.

```python
# Bad: side effect inside a retried transaction
def place_order(item_id):
    for attempt in range(3):
        try:
            with db.transaction():
                db.insert("orders", item_id=item_id)
                send_email(user, "Order placed")  # external side effect
                return
        except TransientError:
            continue   # email already sent; retrying sends it again

# Good: defer side effects via an outbox row inside the transaction
def place_order(item_id):
    for attempt in range(3):
        try:
            with db.transaction():
                db.insert("orders", item_id=item_id)
                db.insert("outbox", kind="order_email", user_id=user.id)
            return
        except TransientError:
            continue
    # A separate worker reads "outbox" and sends emails idempotently after commit.
```

**Why the bad version fails**: External side effects do not roll back when the transaction aborts. Retrying the transaction re-triggers them. The book recommends deferring until after commit, or using two-phase commit when multiple systems must agree.

### Counter Race Without Isolation

Two clients both increment the unread-message counter; without isolation, one increment is lost.

```python
# Bad: read-modify-write outside any transaction
current = db.get("unread_count")     # both read 42
db.set("unread_count", current + 1)  # both write 43 — final value 43, not 44

# Good: atomic single-object increment, no transaction needed
db.incr("unread_count")              # final value 44 guaranteed
```

**Why it works**: The atomic `INCR` is an isolated single-object operation, sufficient when the change fits in one object.

### Lost Acknowledgment Causing a Duplicate Commit

The transaction commits successfully, but the network drops the ack. The client retries — and the work runs twice.

```python
# Bad: retry without idempotency — payment may be charged twice
def charge(payment_id, amount):
    with db.transaction():
        db.insert("charges", payment_id=payment_id, amount=amount)
    # ack lost on the wire -> client retries -> duplicate insert succeeds

# Good: idempotency key + UNIQUE constraint inside the transaction
def charge(payment_id, amount):
    with db.transaction():
        # UNIQUE(payment_id) makes the second attempt fail-safely
        db.insert("charges", payment_id=payment_id, amount=amount)
        # caller treats UniqueViolation as "already done" — no double charge
```

**Why it works**: The DB enforces dedup as a constraint; a retried commit is a no-op rather than a duplicate.

## Real Systems and Their Guarantees

### Systems claiming ACID for multi-object transactions

| System | Notes |
|--------|-------|
| **PostgreSQL** | Full ACID; default isolation is read committed; serializable available |
| **MySQL (InnoDB)** | Full ACID; default isolation is repeatable read |
| **SQL Server** | Full ACID; default is read committed; serializable available |
| **Oracle** | Full ACID; "serializable" is actually snapshot isolation per the book |
| **MongoDB (4.0+)** | Multi-document ACID transactions across replica sets/sharded clusters |
| **Spanner** | Globally distributed ACID via TrueTime + Paxos |
| **FoundationDB** | Strict serializability across multi-key transactions |
| **CockroachDB / TiDB / YugabyteDB** | NewSQL: ACID at scale via consensus + sharding |

### Systems with weaker / single-object guarantees

| System | What you actually get |
|--------|------------------------|
| **Cassandra / ScyllaDB** | "Lightweight transactions": linearizable reads + conditional writes on a *single* partition; no multi-object atomicity |
| **DynamoDB** | Single-item ACID by default; multi-item transactions exist but with size and throughput limits |
| **Aerospike** | "Strong consistency" mode: linearizable single-object ops; not multi-object |
| **Leaderless stores (general)** | "Best effort" — won't undo work on error; idempotency is the application's problem |
| **Most "multi-put" key-value APIs** | A batch of writes, not a transaction — partial success is possible |

### Refactoring Walkthrough: from "best effort" to atomic

#### Before

```python
# Two separate writes; user 2 may observe an inserted email with counter = 0
db.insert("emails", mailbox_id=42, body="...")
# crash or concurrent reader window
db.update("mailboxes", id=42, unread_count="+1")
```

Problems:
- No atomicity: a crash between writes leaves an orphan email
- No isolation: a concurrent reader can see the email but not the counter (dirty-read style anomaly)

#### After

```python
with db.transaction():
    db.insert("emails", mailbox_id=42, body="...")
    db.update("mailboxes", id=42, unread_count="+1")
```

#### Changes Made

1. Wrapped both writes in a single transaction so they commit or abort together (atomicity)
2. Concurrent readers either see both new states or neither (isolation)
3. On any transient error, the caller can safely retry the whole block — no risk of partial state
