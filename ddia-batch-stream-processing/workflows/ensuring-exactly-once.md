# Ensuring Exactly-Once Workflow

Step-by-step process for designing effectively-once / end-to-end correctness in distributed pipelines, where every layer is at-least-once + dedup.

## When to Use

- Building payment, billing, ledger, or inventory flows where double effects are catastrophic
- Wiring stream processors to non-idempotent external sinks (DBs, payment APIs, email)
- Auditing a "Kafka exactly-once" or "transactional sink" claim end-to-end
- Designing retry/redelivery behavior across HTTP, broker, and storage hops

## Prerequisites

- Map of every hop the message traverses (client → API → broker → processor → sink)
- Knowledge of which hops can retry and which sinks are naturally idempotent
- Ability to add a uniqueness constraint at the persistence boundary

**Reference**: `references/end-to-end-correctness/rules.md`

---

## Workflow Steps

### Step 1: Acknowledge There Is No Network-Layer Exactly-Once
**Goal**: Reset expectations before designing.
- [ ] Accept: TCP, Kafka EOS, Flink checkpoints each suppress duplicates only within their scope
- [ ] Accept: a user reload, proxy reconnect, or broker redelivery punches through any single layer
- [ ] Frame the goal as **effectively-once = at-least-once delivery + dedup at the boundary**

**Ask**: "Where is the boundary at which a duplicate becomes a real-world double effect?"
**Reference**: `references/end-to-end-correctness/knowledge.md` (End-to-End Argument; Exactly-Once Semantics)

### Step 2: Apply the End-to-End Argument
**Goal**: Locate the only layer that can fully enforce correctness — the application boundary.
- [ ] Identify the durable store of record (DB row, ledger event, payment provider call)
- [ ] Place idempotency enforcement **at that boundary**, not inside the broker or framework
- [ ] Treat lower-layer "exactly-once" features as performance optimizations, not guarantees

**Reference**: `references/end-to-end-correctness/rules.md` (Rule 2)

### Step 3: Generate the Idempotency Key at the Originating Client
**Goal**: Make retries collapse instead of multiplying.
- [ ] Generate a UUID (or hash of intent fields) at the true endpoint — browser, mobile app, originating service
- [ ] Pass it as `Idempotency-Key` header / top-level field through every hop
- [ ] Never let a middle hop invent a fresh ID — duplicates would re-bill

**Reference**: `references/end-to-end-correctness/rules.md` (Rule 1)

### Step 4: Dedupe at Every Boundary
**Goal**: Make downstream writes safe under at-least-once.
- [ ] Add a `UNIQUE (request_id)` constraint at the persistence layer
- [ ] Maintain a `seen_ids` table keyed by idempotency key, with TTL covering the longest realistic retry window (hours to days)
- [ ] On duplicate, return the original result rather than re-executing

**Pitfall**: TTL too short → late retry re-executes silently. TTL too long → table grows unbounded.

### Step 5: Make Broker → Consumer Atomic
**Goal**: Avoid the "wrote to sink, crashed before commit" duplicate.

**Decision Tree** (sink type → mechanism):

| Sink characteristic | Mechanism |
|---------------------|-----------|
| Sink is Kafka topic | **Kafka transactions** (atomic offset commit + produce) |
| Sink is a DB you control | **Single atomic write**: business write + offset/dedup row in same transaction |
| Sink is third-party (payment, email, webhook) | Idempotency key passed to the provider; persist response |
| Sink is naturally idempotent (PUT, set-membership) | Offset checkpoint suffices; no extra dedup |

- [ ] Combine: durable checkpoint of operator state + idempotent or transactional sink
- [ ] Verify replay is **deterministic** and **in the same order** (log-based broker, not a queue)
- [ ] Use **fencing tokens** to block zombie writers during failover

**Reference**: `references/stream-processing/rules.md` (Rules 8, 10)

### Step 6: Avoid 2PC for Multi-Shard Operations
**Goal**: Get cross-shard correctness without distributed transaction coordinators.
- [ ] Default: **idempotent operation + retry** at the application layer
- [ ] For loose constraints, use optimistic write + compensating transaction
- [ ] Reserve consensus for **hard uniqueness** (account allocation, payment dedup) — single leader per shard, sharded by the value being made unique

**Reference**: `references/end-to-end-correctness/rules.md` (Rules 4, 7); cross-skill `ddia-transactions-consistency/references/distributed-transactions/rules.md`

### Step 7: Build Audit Trails as Append-Only Signed Logs
**Goal**: Enable after-the-fact proof that no double effect slipped through.
- [ ] Append-only event log is the source of truth; all other state derives deterministically
- [ ] Periodically sign the log (HSM, transparency-log style)
- [ ] Use **Merkle trees** to prove inclusion of any record without revealing the rest (TigerBeetle / Certificate Transparency pattern)
- [ ] Re-derive state from the log periodically; diff against live state

**Reference**: `references/end-to-end-correctness/rules.md` (Rule 5); `references/databases-and-streams/rules.md`

### Step 8: Test Failure Modes With Kill-and-Resume
**Goal**: Prove the pipeline survives realistic faults without double effects.
- [ ] Inject crashes between sink write and offset commit; assert no duplicate effect
- [ ] Inject duplicate broker delivery; assert dedup catches it
- [ ] Inject client retry of the same idempotency key; assert single result returned
- [ ] Inject failover with stale leader; assert fencing token blocks the zombie write
- [ ] Run a deterministic re-derivation; diff against live — must be byte-identical

### Step 9: Don't Trust Any Single Layer's Claim
**Goal**: Verify continuously rather than assume.
- [ ] End-to-end checksums on records you care about (not just per-hop)
- [ ] Background scrubbers comparing replicas (HDFS / S3 model)
- [ ] Periodically restore from backups to confirm they actually work
- [ ] Document which guarantees come from the framework and which from your code

**Reference**: `references/end-to-end-correctness/rules.md` (Rule 6)

---

## Quick Checklist

```
[ ] 1. Accepted: no network exactly-once; design for at-least-once + dedup
[ ] 2. Idempotency enforced at the application boundary (end-to-end)
[ ] 3. Idempotency key generated at the originating client
[ ] 4. Dedup table + UNIQUE constraint at persistence layer; TTL set
[ ] 5. Broker→sink atomic via Kafka tx OR single-atomic-write to sink
[ ] 6. No 2PC for multi-shard; idempotent retry + compensating tx
[ ] 7. Audit trail = append-only signed log + Merkle root
[ ] 8. Kill-and-resume tests pass with no double effects
[ ] 9. Continuous verification (checksums, scrubbers, backup restores) in place
```

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Trust Kafka EOS as end-to-end | Only covers broker→consumer; user retry bypasses it | Add app-level idempotency key from client |
| Server-generated request ID | Retried POST gets a new ID, double-charges | Client-generated UUID; persist with UNIQUE constraint |
| Non-idempotent sink with checkpointing | Crash between write and checkpoint duplicates | Transactional sink OR idempotent upsert keyed by event id |
| No TTL on dedup table | Table grows unbounded | TTL longer than max retry window; archive old keys |
| TTL too short on dedup table | Late retry slips through and re-executes | Tune to observed retry tail (often hours–days) |
| 2PC across shards for "exactly-once" | Coordinator failure, blocked locks, poor throughput | Idempotent retry + compensating transaction |
| Audit table updated alongside writes | Can be tampered or drift from real state | Append-only signed log; derive everything from it |
| Multi-leader async replication for unique IDs | Concurrent leaders both accept conflicting values | Single leader per shard, sharded by the unique value |
| Skipping fencing during failover | Zombie processor double-writes | Monotonic fencing token rejected at the storage layer |
| Treating one layer's "exactly-once" as enough | Punch-throughs at every other layer | Defense-in-depth: dedup at the application boundary |

## Cross-References

- `references/end-to-end-correctness/rules.md` — idempotency, end-to-end argument, hard vs loose constraints
- `references/end-to-end-correctness/knowledge.md` — exactly-once semantics, timeliness vs integrity
- `references/stream-processing/rules.md` — Rule 8 (combine checkpoint + idempotent + transactional sink), Rule 10 (idempotence preconditions)
- `references/databases-and-streams/rules.md` — log-based brokers, CDC, derived state
- Cross-skill: `ddia-transactions-consistency/references/distributed-transactions/rules.md` — 2PC, XA, why dataflow alternatives often win

## Exit Criteria

Exactly-once design is production-ready when:
- [ ] Idempotency key originates at the client and traverses every hop unchanged
- [ ] Persistence layer enforces uniqueness; dedup TTL covers retry window
- [ ] Broker→sink path is either transactional or idempotent — no "fire and hope" writes
- [ ] No 2PC across shards for the hot path; consensus scoped per-shard if needed
- [ ] Audit log is append-only, signed, and re-derivation matches live state
- [ ] Kill-and-resume chaos tests show zero double effects across all injected faults
