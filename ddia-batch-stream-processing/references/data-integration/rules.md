# Data Integration Rules

Design guidance for architects integrating multiple specialized data systems.

## Core Rules

### 1. Pick One Source of Truth and Derive Everything Else

Funnel all user input through a single system that decides the ordering of writes. Every other store (search index, cache, warehouse, ML features, notifications) is derived from that ordered log.

- Use CDC or event sourcing to capture the ordered stream
- Stream processors fan the log out to each downstream sink
- Adding a new sink later means replaying history — no schema migration on the source needed

**Anti-pattern**: Application code writes directly to the database AND the search index. Two clients can apply conflicting writes in different orders to each system, leaving them permanently inconsistent.

### 2. Avoid Distributed Transactions Across Heterogeneous Systems

XA and similar 2PC protocols have poor fault tolerance and operational cost. They abort if any one participant fails, amplifying failures across the system.

- Prefer asynchronous, log-based derivation between systems
- Reserve distributed transactions for environments already paying their cost (legacy enterprise stacks)
- A failure in one derived sink should stay local, not block writes to the source

### 3. Use Total Ordering When Throughput Allows

A totally ordered event log (single-leader, single Kafka partition, or hash-partitioned-by-key) is the simplest way to keep derived data consistent. Recipients replay the log in order and reach the same state deterministically.

- Single-key total order: route all events for one entity to the same partition (e.g. partition by user_id)
- Beyond a single machine's throughput, sharding breaks cross-shard order — accept causal ordering instead

### 4. Capture Causality Explicitly When Total Order Breaks Down

When sharding, geo-distribution, microservices, or offline clients prevent total order:

- Use logical timestamps (Lamport, vector clocks) to provide ordering without coordination
- Log the state the user saw before a decision and reference its event ID — later events carry the causal link
- Apply conflict resolution algorithms for state — but remember they don't help with side effects (like already-sent notifications)

### 5. Make Derivations Deterministic and Idempotent

A stream processor that consumes the log and updates a derived sink must produce the same output for the same input, every time, even when retried after failure.

- Pure functions of inputs, no hidden dependencies
- Idempotent writes (upsert by key, dedup on event ID)
- Enables safe retry and exactly-once effective semantics

### 6. Reprocess to Evolve Schema and Logic

One of stream processing's biggest wins. Replay the event log through new code to generate a new derived view alongside the old one.

- Keep old and new views side by side; route a small fraction of users to the new one
- Increase rollout gradually; revert by switching the router if anything breaks
- Without reprocessing you are limited to additive schema changes (new optional fields)

### 7. Unify Batch and Stream Where Possible

Avoid maintaining two code paths (batch + stream) for the same logic. Use engines that handle both modes through one API.

- Apache Beam over Flink or Dataflow — same pipeline runs on bounded or unbounded inputs
- Lambda architecture (separate batch and speed layers) has fallen out of use; don't build it new
- Required ingredients: replayable log, exactly-once semantics, event-time (not processing-time) windowing

## Guidelines

- Default to asynchronous derivation; reserve synchronous updates for cases that genuinely need read-your-writes against the derived view
- Partition the event log by the natural entity key when possible (preserves per-entity total order)
- Document your dataflow: which system is source-of-truth, which are derived, and what the derivation function is
- Treat new derived stores as cheap — adding a search index or analytics warehouse is "replay the log into it"

## Exceptions

When these rules may be relaxed:

- **Small system, single node, low throughput**: Direct dual writes inside one transaction may be simpler than running Kafka and stream processors.
- **Hard read-your-writes requirement on a derived view**: May justify synchronous updates or distributed transactions despite their cost.
- **Legacy XA already in production**: Migration to log-based derivation may not be worth the disruption.
- **External side effects with strict ordering (notifications, payments)**: Conflict resolution alone is insufficient; design idempotent external actions or block on causal predecessors.

## Quick Reference

| Rule | Summary |
|------|---------|
| Single source of truth | One ordered log, many derived sinks |
| Avoid distributed transactions | Use log-based async derivation |
| Total order when feasible | Single leader / hash partition |
| Capture causality | Logical clocks, event references |
| Deterministic + idempotent | Safe retry, exactly-once effects |
| Reprocess for evolution | Replay log into new schema view |
| Unify batch + stream | Beam/Flink, not Lambda |
