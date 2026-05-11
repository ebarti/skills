# Distributed Transactions Knowledge

Core concepts for atomic commitment across multiple nodes, shards, or heterogeneous systems.

## Overview

A distributed transaction spans multiple nodes (e.g., shards, databases, message brokers). Achieving atomicity — all participants commit or all abort — is the central challenge, since simply broadcasting commit requests can lead to partial commits and inconsistent state.

## Key Concepts

### Distributed Transaction

**Definition**: A transaction whose reads and writes touch more than one node — multiple shards of a sharded database, a global secondary index, or independent systems (DB + queue).

Concurrency control (2PL, SSI) extends to the distributed setting; the new problem is **atomic commitment**.

### Atomic Commitment

**Definition**: The property that all participating nodes either commit or all abort, never a mix.

A naive "send commit to everyone" fails: some nodes may abort due to constraints, others time out, others crash mid-write — producing irreconcilable inconsistency once committed data is read by other transactions.

### Two-Phase Commit (2PC)

**Definition**: A blocking atomic commit protocol that splits commit into a *prepare* phase and a *commit* phase, coordinated by a single coordinator.

**Key points**:
- Phase 1 (prepare): coordinator asks each participant "can you commit?"; participants force-write data to disk and reply yes/no.
- Phase 2 (commit/abort): coordinator gathers votes, writes its decision to its own log (the **commit point**), then broadcasts commit or abort.
- Two points of no return: a yes vote (participant surrenders right to abort) and the coordinator's logged decision (irrevocable).

### Coordinator (Transaction Manager)

**Definition**: The component that drives 2PC — assigns global transaction IDs, sends prepare/commit messages, and durably logs the commit decision.

Often a library embedded in the application process (Narayana, JOTM, BTM, MSDTC), sometimes a separate service.

### Participant

**Definition**: A database or service node that holds part of the transaction's state and votes in 2PC.

When a participant votes yes, it has already made the writes durable and promises to be able to commit on demand.

### Prepare Phase

**Definition**: Phase 1 of 2PC — coordinator sends prepare to each participant; participant writes data durably, checks constraints, and votes yes (committing to be able to commit) or no (aborting).

### Commit Phase

**Definition**: Phase 2 of 2PC — coordinator decides commit (only if all yes) or abort, durably logs the decision (commit point), then notifies all participants. Retries forever on failure.

### In-Doubt / Uncertain State

**Definition**: A participant that voted yes but has not yet heard the commit/abort decision from the coordinator.

In-doubt transactions hold their locks indefinitely; they cannot abort unilaterally (other participants may have committed) nor commit unilaterally (others may have aborted). The only safe path is waiting for the coordinator to recover and consult its log.

### XA (X/Open eXtended Architecture)

**Definition**: A 1991 C API standard for 2PC across heterogeneous technologies — relational DBs (PostgreSQL, MySQL, Oracle, Db2, SQL Server) and message brokers (ActiveMQ, IBM MQ, MSMQ).

**Key points**:
- Not a network protocol — a C API; Java exposes it via JTA, with JDBC and JMS drivers wiring participants in.
- Coordinator is typically a library in the application process, with its log on the application server's local disk.
- Application crash = coordinator dies = participants stuck in doubt until the app server is restarted and the log replayed.

### Heuristic Decisions

**Definition**: An XA escape hatch allowing a participant to unilaterally commit or abort an in-doubt transaction without the coordinator's verdict.

"Heuristic" is a euphemism for *probably breaking atomicity*. For catastrophic recovery only, never routine use.

### Database-Internal Distributed Transaction

**Definition**: A distributed transaction where every participant runs the same database software (e.g., Spanner, CockroachDB, TiDB, FoundationDB, YugabyteDB, VoltDB, MySQL NDB, Kafka).

Free of XA's lowest-common-denominator constraints — designers can replicate the coordinator with consensus, allow direct coordinator-to-shard communication, and integrate concurrency control with commitment.

### Heterogeneous Distributed Transaction

**Definition**: A distributed transaction spanning two or more independent technologies (e.g., two vendors' databases, or a DB plus a message broker).

Requires XA or similar; suffers operational pain, performance cost, and lowest-common-denominator semantics (no cross-system deadlock detection, no SSI).

### Exactly-Once Message Processing

**Definition**: The guarantee that a message's side effects take effect once and only once, even with retries after crashes.

Two paths:
- **2PC across broker + DB** (XA): atomically commit message ack with DB writes.
- **At-least-once + idempotency**: dedupe via a message-ID table inside the DB transaction; broker may redeliver, but the dedup table makes reprocessing a no-op.

The second path needs only single-database transactions and is far simpler to operate.

## Terminology

| Term | Definition |
|------|------------|
| Atomic commitment | All-or-nothing commit across nodes |
| Coordinator / TM | Drives 2PC, owns the commit decision log |
| Participant | Node that votes and holds locks during 2PC |
| Prepare | Phase 1 vote request |
| Commit point | Moment coordinator's decision is durably logged |
| In-doubt | Voted yes but awaiting coordinator's verdict |
| Blocking protocol | Can stall indefinitely if a node fails (2PC) |
| XA | C API standard for cross-vendor 2PC |
| JTA | Java binding for XA |
| Heuristic decision | Manual override of in-doubt state (breaks atomicity) |
| 3PC | Nonblocking variant; assumes bounded delays — impractical |
| Orphaned transaction | In-doubt forever because coordinator log is lost |

## How It Relates To

- **Consensus**: a fault-tolerant coordinator can be built from a consensus protocol (Paxos/Raft) — see Chapter 10. Spanner and CockroachDB do this.
- **Stream processing**: Kafka transactions enable exactly-once semantics inside Kafka; cross-system exactly-once typically uses idempotency, not 2PC.
- **Locking and isolation**: 2PC participants hold locks for the entire in-doubt window — coupling commit duration to lock duration.

## Common Misconceptions

- **Myth**: 2PC guarantees atomicity even when the coordinator fails.
  **Reality**: 2PC is *blocking* — if the coordinator crashes after participants vote yes, participants are stuck in doubt holding locks until the coordinator returns. Lose its log and you need manual intervention.

- **Myth**: 3PC fixes 2PC's blocking problem.
  **Reality**: 3PC requires bounded network delays and bounded process pauses — assumptions that don't hold in real systems. Use a consensus-replicated coordinator instead.

- **Myth**: Exactly-once messaging requires distributed transactions.
  **Reality**: At-least-once delivery + idempotent processing (message-ID dedup in the DB) achieves the same effective guarantee with a single-DB transaction.

- **Myth**: XA is fine because it's a standard.
  **Reality**: XA is a lowest-common-denominator C API: no cross-system deadlock detection, no SSI, application code is the single point of failure, and the coordinator log lives on one app server's local disk.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| 2PC | Prepare-then-commit; blocks on coordinator failure |
| Coordinator | Owns commit decision; its log is the commit point |
| In-doubt | Voted yes, waiting — locks stay held |
| XA | Cross-vendor 2PC via C API; operationally painful |
| Heuristic decision | Emergency override — breaks atomicity |
| Internal distributed txn | Same-software 2PC + consensus; works well |
| Exactly-once via idempotency | Dedup table + at-least-once delivery |
