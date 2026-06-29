# End-to-End Correctness Examples

Concrete patterns for end-to-end idempotency, uniqueness via consensus, audit trails, and coordination avoidance.

## Bad Examples

### Non-Idempotent Money Transfer

```sql
BEGIN;
UPDATE accounts SET balance = balance - 11 WHERE id = 'alice';
UPDATE accounts SET balance = balance + 11 WHERE id = 'bob';
COMMIT;
```

**Problems**:
- Client retry after `COMMIT` timeout transfers $22 instead of $11
- TCP dedup ends at the connection; a reconnect is a fresh transaction
- 2PC also doesn't help: a user clicking "submit" twice is two distinct requests

### Server-Generated Request ID

```python
def transfer(from_acct, to_acct, amount):
    request_id = uuid.uuid4()  # Bad: regenerated on every retry
    db.execute("INSERT INTO requests (id, ...) VALUES (?, ...)", request_id)
```

**Problems**:
- Each user retry produces a fresh UUID; dedup is impossible
- The endpoint of correctness is the user's intent, not the server entry

## Good Examples

### Stripe-Style Idempotency Key

```http
POST /v1/charges HTTP/1.1
Idempotency-Key: 7c0f8c1b-9b2d-4a8e-b8a7-3a1f4d2c8e2a
Content-Type: application/json

{ "amount": 1100, "currency": "usd", "source": "tok_..." }
```

```sql
-- Server side
ALTER TABLE requests ADD UNIQUE (request_id);

BEGIN;
INSERT INTO requests (request_id, from_acct, to_acct, amount)
  VALUES ('7c0f...', 'alice', 'bob', 11);    -- fails on duplicate
UPDATE accounts SET balance = balance - 11 WHERE id = 'alice';
UPDATE accounts SET balance = balance + 11 WHERE id = 'bob';
COMMIT;
```

**Why it works**:
- Key originates at the client, survives retries through every hop
- Uniqueness constraint enforces dedup even at weak isolation levels
- The `requests` table doubles as an event log usable for CDC and event sourcing

### Username Uniqueness in Log-Based Messaging

```text
1. Client appends   { request_id, "claim_username", "alice" }
   to log shard = hash("alice") % N

2. Stream processor for that shard:
     - Reads sequentially on a single thread
     - Looks up "alice" in its local KV store
     - If free: marks taken, emits { request_id, "ok" }
     - If taken: emits { request_id, "rejected" }

3. Client subscribes to output stream, waits for its request_id
```

**Why it works**:
- Sharding by the unique value routes all conflicting requests to one decider
- Single-threaded sequential processing gives consensus without a separate protocol
- Scales by adding shards; each shard processes independently
- Asynchronous multi-leader is ruled out (it would allow concurrent acceptance)

### Multishard Payment Without Atomic Commit

```text
Shard A (source)             Shard B (dest)            Shard C (fees)
  request{id=R}
  reserve funds
  emit outgoing{id=R} ----->  incoming{id=R}: dedup, credit
  emit incoming{id=R}  ----------------------> incoming{id=R}: dedup, credit
  consume own outgoing,
  finalize debit (dedup by id)
```

**Why it works**:
- Atomicity comes from the single atomic write of the request to one log
- All downstream state is deterministic; crash recovery replays safely
- `request_id` flows through every emitted event for end-to-end dedup
- No 2PC; throughput per shard is independent of cross-shard coordination

### Audit Log with Merkle Root (Certificate Transparency)

```text
log: e1, e2, e3, e4, ...

       root_hash             <- signed periodically by HSM
      /         \
   h(1,2)     h(3,4)
   /   \       /   \
 h(e1) h(e2) h(e3) h(e4)
```

**Why it works**:
- Tamper-evident: any single-byte change in an event changes the root
- O(log n) inclusion proofs vs scanning the full dataset
- Auditors only need the trusted root, not consensus participation
- Used by: Certificate Transparency, Sigstore (software supply chain log)

### Coordination-Avoiding Cart with CRDTs

```text
Region US: cart.add("book-42"); cart.remove("book-42")
Region EU: cart.add("pen-7")
After async merge, both converge to: { "pen-7" }
```

**Why it works**:
- No synchronous cross-region coordination on the write path
- CRDT (OR-Set) merges concurrent edits deterministically
- Strong integrity, weak timeliness; works through partitions

### Eventually-Unique Identifiers (UUID)

```python
order_id = uuid.uuid4()  # 122 random bits, no central allocator
db.put(order_id, order)
```

**Why it works**: collisions astronomically unlikely; no consensus, no hot-spotting.

## Real Systems


- **TigerBeetle** (financial integrity): single-writer-per-account, client-generated request IDs, deterministic state machine derives balances from an append-only log
- **Sigstore Rekor** (transparency log): append-only Merkle log of signing events; signed tree heads let clients verify inclusion without trusting the operator
- **Bitcoin / Ethereum**: Byzantine-tolerant append-only ledger; heavyweight, Merkle trees alone suffice for non-adversarial cases

## Refactoring Walkthrough

### Before: Best-Effort Payment

```python
def charge(card_token, amount):
    response = payment_gateway.charge(card_token, amount)
    db.execute("INSERT INTO payments (token, amount, status) VALUES (?, ?, ?)",
               card_token, amount, response.status)
```

### After: End-to-End Idempotent Payment

```python
def charge(idempotency_key, card_token, amount):
    # 1. Reserve idempotency key at the application boundary
    try:
        db.execute("INSERT INTO payment_requests (key, card, amount) "
                   "VALUES (?, ?, ?)", idempotency_key, card_token, amount)
    except UniqueViolation:
        return db.fetch_one("SELECT * FROM payment_requests WHERE key = ?",
                            idempotency_key)

    # 2. Pass key through to the gateway (Stripe accepts Idempotency-Key)
    response = payment_gateway.charge(
        card_token, amount, idempotency_key=idempotency_key
    )

    # 3. Record outcome against the same key
    db.execute("UPDATE payment_requests SET status = ? WHERE key = ?",
               response.status, idempotency_key)
    return response
```

### Changes Made

1. Idempotency key passed in by the caller (originates at user's client)
2. Key reserved with a `UNIQUE` constraint before any side effect
3. Same key forwarded to the gateway so retries dedup downstream too
4. Result is keyed by the original request, not by a fresh server-side ID
