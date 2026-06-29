# Unbundling Databases Rules

Guidelines for designing applications as dataflow systems built from event logs and derived views, with state changes pushed end-to-end.

## Core Rules

### 1. Structure apps as event log + derived views

Treat the durable event log as the source of truth. Every cache, index, search engine, ML feature store, or aggregate is a **derived view** computed by a pure function over the log.

- Do not mix mutation logic (writing to the source of truth) with derivation logic (computing views).
- Derived views must be rebuildable from the log — never store data only in a derived view.

**Example**:
```
// Bad: write directly to multiple stores from app code
db.users.insert(u);
search.index(u);
cache.set(u.id, u);  // tangled — partial failure leaves stores inconsistent

// Good: write to log; derived stores are maintained by stream operators
log.append({type: "UserCreated", user: u});
// indexer service consumes log -> updates search
// cache service consumes log -> updates cache
```

### 2. Keep application code stateless; persist state in the storage layer

Stateless services scale horizontally and roll out cleanly. Use streams (not direct DB calls between services) to connect them. "Separation of Church and state."

- App servers should hold no durable state — any request can hit any instance.
- Inter-service communication for derived data should be pub/sub on a log, not synchronous RPC.

### 3. Use idempotent, ordered event logs across heterogeneous systems

Distributed transactions across systems written by different teams are fragile. An ordered log with idempotent consumers is simpler and survives faults.

- Every consumer must tolerate replay (idempotent writes via deterministic keys, dedup tables, or upserts).
- Preserve per-key order in the log; let consumers track offsets so they catch up after outages.

### 4. Push state changes to clients for real-time UIs

For UIs that must reflect server state without polling, extend the write path to the device using WebSocket / SSE / sync engines (Replicache, Linear-style, Figma, Liveblocks).

- Initial load uses a read path; thereafter the client subscribes to a stream of changes.
- Use consumer-offset semantics so a reconnecting client resumes without missing events.
- Treat on-device state as a cache/replica of server state; the UI is a materialized view of the model.

### 5. Multishard: route events to the shard owning the key, collect at the edge

For queries spanning shards, do not have one node fan out and aggregate by hand — use the routing/join machinery of a stream processor (or a database that supports this natively).

- Send each event/read to the shard responsible for its partition key.
- Collect partial results into an output stream; aggregate at the requesting edge.

### 6. Treat reads as events when you need audit, causal tracking, or consistent invalidation

A one-off read is a transient stream-table join; a subscription is a persistent join. Logging reads enables reconstructing what a user saw before they acted (e.g., shipping date shown at checkout).

- Use this pattern when provenance / "what did the user see?" matters.
- Accept extra storage and I/O cost; reuse existing request logs when possible.

### 7. Don't unbundle if one product already meets your needs

Unbundling adds operational complexity. If a single integrated database satisfies your workload, use it. Unbundling pays off when **no single product covers your full set of requirements** — it buys breadth, not depth.

## Guidelines

- Prefer subscribing to a stream over polling whenever the source can publish changes.
- Replace synchronous RPC with stream joins (e.g., subscribe to exchange-rate stream, join locally with purchase events) when latency / availability matters.
- For time-dependent joins (purchases × exchange rate), keep enough history to reconstruct historical values.
- Use sync engines on the client to handle offline, reconciliation, and replay automatically.
- Choose stream operators over user-defined functions inside a database — separate code lifecycle from data lifecycle.

## Exceptions

When these rules may be relaxed:

- **Single-shard, simple CRUD with one DB**: skip the event log; use the DB directly.
- **Strict transactional invariants across two stores**: if you can keep both inside one stream processor or one DB, do that — don't span teams.
- **Tiny scale**: a monolith on Postgres is often the right answer; don't pre-architect dataflow.
- **Read-heavy aggregation across one DB**: a federated query (Trino) may be enough; you don't need write-side unbundling.

## Quick Reference

| Rule | Summary |
|------|---------|
| Log + views | Source of truth in log; derived stores are recomputable |
| Stateless code | App servers hold no durable state |
| Idempotent + ordered | Use logs not 2PC across heterogeneous systems |
| Push to client | WebSocket/SSE/sync engine extends write path to UI |
| Per-key routing | Multishard via stream processor partitioning |
| Reads as events | Log reads when you need audit/causal/consistency |
| Don't over-unbundle | Use one product if it meets all your needs |
