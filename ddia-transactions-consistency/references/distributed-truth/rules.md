# Knowledge, Truth, and Lies Rules

Rules for building distributed coordination, locking, and verification correctly.

## Core Rules

### 1. Truth is established by quorum, not by any single node

A node may be wrong about itself or others. Decisions — including "node X is dead" — must come from a vote of multiple nodes, not from one node's opinion.

- Use an absolute majority (> n/2) so two conflicting majorities cannot exist.
- A node declared dead by quorum must step down even if it feels alive.
- Tolerate (n-1)/2 faulty nodes with n total (3 → 1, 5 → 2, 7 → 3).

### 2. ALWAYS pair leases with fencing tokens

A lease alone is unsafe — a paused, partitioned, or delayed holder becomes a zombie that corrupts data. Every lock must produce a monotonically increasing token, and every protected operation must carry it.

```
// Bad: lease only
lease = lockService.acquire("file-x")
storage.write("file-x", data)        // zombie write may overwrite newer data

// Good: lease + fencing token
{lease, token} = lockService.acquire("file-x")
storage.write("file-x", data, ifTokenAtLeast=token)  // storage rejects stale tokens
```

### 3. Storage must enforce the fencing token

Tokens stamped by clients are useless if the storage layer doesn't reject lower tokens. Use:
- Server-side max-token-seen check, or
- Atomic CAS / preconditions: S3 conditional writes, GCS request preconditions, Azure conditional headers, ZooKeeper `zxid`/`cversion`, etcd revision number.

### 4. STONITH is not a substitute for fencing

Shooting a node down (network kill, VM stop, power off) cannot:
- Stop already-in-flight delayed packets reaching storage.
- Prevent racing nodes from shooting each other.
- Always act fast enough to prevent corruption.

Use STONITH (if at all) as defense in depth, never as the primary mechanism.

### 5. Don't deploy BFT unless you actually need it

Byzantine fault tolerance is expensive and rarely justified for typical server-side systems. Use it only for:
- Aerospace / safety-critical embedded systems (radiation-induced corruption).
- Multi-organization systems with no central authority (blockchains).
- Adversarial peer-to-peer networks.

For datacenter systems (single trust domain), assume nodes are honest-but-faulty.

### 6. BFT does not save you from bugs or compromises

Same software on all nodes ⇒ the same bug runs everywhere. Same compromise yields control of all nodes. BFT requires *independent implementations* to defend against shared bugs — almost no one does this.

Defenses against bugs and attackers stay traditional: testing, code review, authentication, access control, encryption, firewalls.

### 7. Add cheap checks against weak lying

Even when nodes are trusted, hardware and software occasionally produce garbage. Add:
- **Application-level checksums** (TCP/UDP checksums miss errors).
- **TLS** for in-transit corruption protection.
- **Input validation and sanitization** at every boundary, including internal services.
- **Quorum-of-clocks** for NTP (multiple servers, exclude outliers).

### 8. Pick the weakest system model your environment satisfies

Stronger models (synchronous, crash-stop) are easier to reason about but rarely hold in practice. Weaker models (partially synchronous, crash-recovery, fail-slow) are realistic but harder.

- Default to **partially synchronous + crash-recovery** for real systems.
- Treat fail-slow ("limping nodes") as a real failure mode, not an edge case.
- Document which faults the algorithm assumes do *not* happen, then add a printf-and-exit handler for when they do anyway.

### 9. Safety properties must hold ALWAYS; liveness may have caveats

- Safety (uniqueness, monotonicity, no double-spend, no split brain) must hold under every fault the system model allows — including total network failure or all-node crash.
- Liveness (availability, eventual response) may be conditional ("if a majority is up and the network eventually recovers").
- A safety violation cannot be undone — design conservatively.

### 10. Use formal methods or DST for critical consensus code

Concurrency, partial failure, and timing produce too many states for hand-written tests.

- **TLA+ / FizzBee** for protocol specification (caught data loss in viewstamped replication, used by AWS, CockroachDB, TiDB, Kafka).
- **Jepsen** for fault injection in CI.
- **Deterministic Simulation Testing** (FoundationDB Flow, TigerBeetle, MadSim, Antithesis) for actual code with replayable failures.
- Combine techniques — formal methods catch design bugs, DST catches implementation bugs.

### 11. Make code deterministic where you can

Determinism is a force multiplier. It enables:
- Event-sourcing replay to reconstruct materialized views.
- Workflow engines for durable execution.
- State machine replication.
- Deterministic simulation testing.

Beware lurking nondeterminism: hash-table iteration order, allocation failures, stack overflow, OS scheduling.

## Guidelines

- A new leaseholder should immediately make a write to "claim" the lock and fence off zombies.
- Embed the fencing token in the high bits of a timestamp for leaderless replication with LWW conflict resolution.
- For multi-replica writes, the fencing token guarantees safety even if you can't reach a quorum on every write.
- Lock service is somewhat redundant if you only write to one CAS-capable storage — the storage itself can serve as the lease coordinator.
- Specifications drift from implementations; instrument the real system to compare behaviors against the model.

## Exceptions

- **Single-storage CAS-only systems**: a separate lock service may be unnecessary; the storage's preconditions provide ordering.
- **Soft locks for waste prevention only**: where consequences are wasted CPU, not corruption (e.g., dedup of work items), tokens may be optional — but document this explicitly.
- **Web-app client trust**: don't try BFT for browser clients; make the server the authority and validate all inputs.

## Quick Reference

| Rule | Summary |
|------|---------|
| Quorum truth | Decisions need majority votes |
| Fencing tokens | Always pair with leases |
| Storage enforcement | Token check must happen at storage |
| STONITH alone | Insufficient — use fencing |
| BFT scope | Only adversarial / safety-critical |
| Weak-lying defenses | Checksums, TLS, input validation, NTP quorum |
| System model | Partially synchronous + crash-recovery |
| Safety always | No exceptions even on total failure |
| Liveness caveats | OK to require majority + network recovery |
| Formal methods | TLA+, FizzBee for consensus protocols |
| DST | For actual code: FoundationDB, TigerBeetle, Antithesis |
| Determinism | Enables replay, simplifies reasoning |
