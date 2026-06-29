# End-to-End Correctness Knowledge

Core concepts for building data systems that remain correct under failures, retries, bugs, and silent corruption.

## Overview

ACID transactions are necessary but not sufficient for application correctness. The end-to-end argument (Saltzer/Reed/Clark, 1984) holds that correctness properties like duplicate suppression, integrity checking, and encryption can only be fully guaranteed at the application boundary, not by lower layers (TCP, transactions, stream processors). Dataflow systems can preserve integrity without atomic commit by combining idempotent operations, deterministic derivation, end-to-end request IDs, and continuous auditing.

## Key Concepts

### The End-to-End Argument

**Definition**: A function can only be completely and correctly implemented with knowledge and help of the application at the endpoints of the communication system. Lower-layer implementations may be useful as performance enhancements, but cannot substitute for end-to-end logic.

**Examples of where it applies**:
- Duplicate suppression (TCP dedups within a connection, not across retries)
- Integrity checking (Ethernet/TCP checksums miss software bugs and disk corruption)
- Encryption (TLS protects the wire, not the server endpoints)

### Idempotency

**Definition**: An operation has the same effect whether executed once or many times. Naturally idempotent operations are safe to retry; non-idempotent ones (e.g., `balance += 11`) require a deduplication mechanism to become safe.

**Key points**:
- Achieved via metadata (set of processed operation IDs)
- Requires fencing during failover to prevent split-brain dual writes
- Combined with at-least-once delivery, yields effectively-once semantics

### Idempotency Key (Request ID)

**Definition**: A unique identifier (UUID or hash of request fields) generated at the originating client and passed through every layer to the durable store, used to detect and discard duplicate executions.

**Properties**:
- Generated at the true endpoint (browser, mobile client), not at the server
- Persisted with a uniqueness constraint at the destination
- Enables an event log usable for event sourcing or CDC

### Exactly-Once Semantics

**Definition**: Final effect equivalent to no-faults execution, even when retries occur. Always implemented as **at-least-once delivery + deduplication**, never as a true single delivery.

### Timeliness vs Integrity

| Property | Meaning | Violation Type | Recovery |
|----------|---------|----------------|----------|
| Timeliness | Users observe up-to-date state | Temporary inconsistency | Wait and retry |
| Integrity | No data loss, no contradictory data | Permanent corruption | Explicit repair |

**Slogan**: Violations of timeliness are allowed under eventual consistency; violations of integrity result in perpetual inconsistency.

In most applications, integrity matters far more than timeliness. A 24-hour delay on a credit card statement is normal; a missing transaction is catastrophic.

### Coordination-Avoiding Systems

**Definition**: Data systems that maintain integrity without synchronous cross-shard or cross-region coordination. Achieve strong integrity with weak timeliness, allowing multi-leader and multi-datacenter operation.

**How they work**:
- Loose constraints: violate temporarily, repair via compensating transactions
- Hard constraints (true uniqueness) still need consensus, but only at small scope
- Each datacenter operates independently; no synchronous cross-region path

### Compensating Transaction

**Definition**: A business-level correction applied after the fact when an optimistically-accepted operation turned out to violate a constraint (oversold inventory, overdrawn account, double charge). The "apology workflow" already exists for real-world incidents (warehouse damage, weather cancellations).

### Auditability

**Definition**: The ability to verify after the fact that a data system is internally consistent and uncorrupted. Built on immutable event logs plus deterministic derivation, so any derived state can be re-derived and compared.

**Tools**:
- Hashes over the event log to detect storage corruption
- Re-running deterministic batch/stream processors to verify derived state
- Merkle trees: prove a record exists in a dataset without revealing the rest
- Append-only signed logs (Certificate Transparency, transparency logs)
- Byzantine-fault-tolerant ledgers (blockchains) for the heaviest case

## Terminology

| Term | Definition |
|------|------------|
| End-to-end argument | Correctness must be enforced at endpoints, not at intermediate layers |
| Idempotency | Same effect for one or many executions |
| Idempotency key | Client-generated unique ID passed through all layers |
| Effectively-once | At-least-once delivery + deduplication on the receive side |
| Timeliness | Eventually-resolved freshness lag |
| Integrity | Absence of data loss and contradictions; permanent if violated |
| Coordination-avoiding | Strong integrity without synchronous cross-shard coordination |
| Compensating transaction | After-the-fact correction for an optimistically accepted write |
| Merkle tree | Tree of hashes proving record inclusion in a dataset |
| Self-auditing system | Continually re-verifies its own integrity rather than blind trust |

## How It Relates To

- **Stream processing**: Dataflow gives integrity (deterministic re-derivation, immutable log) but not timeliness — fits the end-to-end model
- **Consensus**: Required only for hard uniqueness constraints; coordination-avoiding designs minimize its scope
- **Event sourcing**: Provides the immutable log that makes auditing and end-to-end IDs natural
- **Distributed transactions (2PC/XA)**: Solve atomicity but not the end-to-end retry problem; expensive enough that dataflow alternatives often win

## Common Misconceptions

- **Myth**: Serializable transactions guarantee my application is correct.
  **Reality**: They only guarantee isolation; application bugs, retries across the network, and missing constraints still corrupt data.

- **Myth**: "Exactly-once" stream processors deliver each message once.
  **Reality**: They deliver at-least-once and deduplicate. A duplicate POST from the user's browser bypasses this entirely.

- **Myth**: TCP duplicate suppression is enough.
  **Reality**: It only works within one connection. Reconnects, proxies, and user retries break it.

- **Myth**: Strong consistency (linearizability) and integrity are the same thing.
  **Reality**: Linearizability is timeliness. A system can be eventually consistent yet have perfect integrity.

- **Myth**: Storage that checksums internally cannot lose data.
  **Reality**: HDFS and S3 still scrub continuously because silent corruption happens anyway. Trust, but verify.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| End-to-end argument | Only the endpoints can fully enforce correctness |
| Idempotency key | Client-generated ID, passed through every hop |
| Effectively-once | At-least-once + dedup, not literal single delivery |
| Timeliness | Freshness; temporary if violated |
| Integrity | Correctness; permanent if violated |
| Coordination-avoiding | Loose constraints + compensating transactions for scale |
| Merkle tree | Cryptographic proof of inclusion, no full-data reveal |
| Trust but verify | Continuously audit; never assume layers are bug-free |
