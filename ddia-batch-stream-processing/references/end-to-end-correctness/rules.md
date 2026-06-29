# End-to-End Correctness Rules

Operational rules for building correctness-critical systems (payments, inventory, audit, identity).

## Core Rules

### 1. Generate Idempotency Keys at the True Endpoint

The idempotency key must originate where the user's intent is formed (browser, mobile app, originating service), not where it lands.

- Use a UUID or a hash of request fields that uniquely identify the intent
- Include it as a hidden form field, header, or top-level field; never let an intermediate hop invent it
- Persist it with a uniqueness constraint in the same write that performs the operation

**Example**:
```http
// Bad: server-generated, lost on retry
POST /transfer  { from, to, amount }
// Server: id = uuid()  -- a duplicate POST gets a NEW id, double-charges

// Good: client-generated, survives retry
POST /transfer
Idempotency-Key: 7c0f...e2a
{ from, to, amount }
```

### 2. Never Trust "Exactly-Once" of a Single Layer

TCP, database transactions, 2PC coordinators, and stream processors each only suppress duplicates within their own scope. The user's retry, a proxy reconnect, or a redelivered Kafka message can punch through any one of them.

- Design every layer for at-least-once + dedup
- Pass the end-to-end key through all hops to the durable store
- Add a `UNIQUE` constraint on `(request_id)` at the persistence boundary

### 3. Distinguish Loose Constraints from Hard Constraints

Most "hard" constraints are actually loose business constraints with an apology workflow.

| Type | Examples | Approach |
|------|----------|----------|
| Hard | Account never double-spends, payment never duplicated | Consensus, single-writer per partition |
| Loose | Inventory, seat booking, rate limits, hotel/airline overbooking | Optimistic write + compensating transaction |

If you already have an apology workflow for forklift damage, weather cancellations, or refunds, the constraint is loose — design accordingly.

### 4. Hard Uniqueness Requires Consensus

Truly unique values (usernames, account ID allocation, payment idempotency keys) need a single decider per value.

- Single-leader per shard, sharded by the value being made unique (`hash(username)`)
- Or: log-based messaging with a stream processor that reads the shard sequentially
- Ruling out: asynchronous multi-leader replication (concurrent leaders can both accept conflicting writes)

### 5. Build Audit Trails as Append-Only Signed Logs

Plain audit tables are not enough — they can be tampered with or get out of sync with the database state.

- Append-only event log as the source of truth
- All other state is deterministically derived from the log
- Periodically sign the log (HSM, transparency-log style)
- Use Merkle trees so any record can be cheaply proven against a published root
- Re-derive state from the log periodically and compare to live state

### 6. Don't Blindly Trust Storage — Verify Continuously

Disks lose bits. RAM corrupts. Backups break. Bugs in well-tested databases (MySQL uniqueness bugs, PostgreSQL serializable write skew) have all happened in production.

- End-to-end checksums on the data you care about (not just per-layer checksums)
- Background scrubbers that read replicas and compare (HDFS/S3 model)
- Periodically restore from backups to verify they actually work
- Re-run deterministic derivations and diff against current state

### 7. Coordination-Avoiding by Default for Scale

Synchronous coordination cuts throughput, multiplies tail latency, and forecloses multi-region designs. Reach for it only where a constraint truly cannot be relaxed.

- Default: optimistic write + later validation + compensating transaction
- Reserve coordination for actions that are expensive to undo (irrevocable payouts, physical shipments, ATM cash dispense)
- Run consensus at small scope (per-shard, per-aggregate) rather than globally

## Guidelines

- Treat integrity as non-negotiable; treat timeliness as tunable
- Prefer immutable, append-only data over in-place mutation — easier to recover from bugs
- Make every derivation deterministic so it can be re-run and compared
- Surface idempotency keys in your API (Stripe-style `Idempotency-Key` header)
- Keep the dedup window in the database long enough to cover client retry windows (hours to days)

## Exceptions

Where end-to-end mechanisms can be relaxed:

- **Read-only or low-stakes data**: at-most-once delivery may be acceptable; no key needed
- **Internal RPC with synchronous response**: caller can recover from the response itself
- **Operations that are naturally idempotent** (PUT-style overwrites, set membership): no extra dedup needed
- **Single-process pipelines** with no external boundary: lower-layer guarantees may suffice

## Quick Reference

| Rule | Summary |
|------|---------|
| Client-generated key | Idempotency key originates at the true endpoint |
| Don't trust one layer | At-least-once + dedup, every hop |
| Loose vs hard | Most "hard" constraints are loose with apology workflow |
| Hard uniqueness = consensus | Single leader per shard, no async multi-leader |
| Audit = append-only + signed | Immutable log + Merkle root + replay verification |
| Trust but verify | End-to-end checksums, scrubbers, backup restores |
| Coordination-avoiding default | Use coordination only where recovery is expensive |
