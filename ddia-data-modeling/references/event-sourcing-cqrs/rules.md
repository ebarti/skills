# Event Sourcing, CQRS, and DataFrames Rules

Decision and design guidance for choosing event sourcing / CQRS, evolving event schemas, and using DataFrames for analytics.

## When Event Sourcing Fits

### 1. Audit and regulatory requirements

Use event sourcing when you must reconstruct who did what and when. The log is itself a complete audit trail.

### 2. Complex business domain

When state changes carry strong intent (`BookingCancelled` vs. setting `active = false`), events communicate the *why*, not just the *what*. Especially valuable for DDD-style domains.

### 3. Multiple read shapes from one write shape

When the same data must be presented many ways (dashboard, badge printer, confirmation emails), CQRS lets each view be denormalized for its query pattern.

### 4. Time-travel and bug-fixable derived state

If you anticipate needing to recompute state with corrected logic, an event log lets you delete a view and rebuild it deterministically.

### 5. Evolving requirements

Adding new event types or new fields on existing events is trivial; old events stay intact. Good when product requirements move fast.

### 6. Bursty write throughput

Append-only sequential writes absorb spikes; downstream views can catch up at their own pace.

## When NOT to Use Event Sourcing

- **Plain CRUD apps with no audit need**: The complexity isn't justified.
- **No domain richness**: If state changes have no semantic meaning beyond field updates, events add ceremony without insight.
- **Heavy externally-visible side effects on replay**: If rebuilding views would resend emails or charge cards, event sourcing requires extra care.
- **Personal data subject to deletion (GDPR)**: Immutable events conflict with right-to-be-forgotten unless you isolate per-user logs or use crypto-shredding.

## Core CQRS Rules

### 1. Validate commands; never reject events

Validation belongs at the command boundary. Once an event is in the log it is a fact and downstream consumers must accept it.

### 2. Use past-tense event names

`OrderShipped`, not `ShipOrder`. An event is a record that something happened.

### 3. Order is part of the contract

Materialized view consumers must process events in the exact same order as the log. Distributed systems make this non-trivial (Chapter 10 territory).

### 4. Derived state must be reproducible

Deleting a view and recomputing from the log + same code must yield the same result. No nondeterminism in projection logic.

### 5. Make event processing deterministic

Don't fetch live external data (e.g., today's exchange rate) inside a projection. Either embed the value in the event itself or query a historical-by-timestamp source.

### 6. Reverse mistakes with compensating events

Don't mutate prior events. Append a deletion or correction event; downstream views incorporate it.

### 7. Plan for replay side effects

Guard externally-visible actions (email, charges, webhooks) so they don't fire when a view is rebuilt.

## Schema Evolution for Events

- **Add new event types freely** — old events keep working.
- **Add new optional fields** — older events lack them; consumers must tolerate missing fields.
- **Never edit historical events in place**.
- **Version event schemas** when shape changes break consumers; upcast old versions to the new shape on read.
- **Keep events self-contained** — include the data needed to interpret them later, since referenced external data may have changed.

## DataFrame Use Cases

### When to reach for a DataFrame

- ML feature engineering and training data prep
- Exploratory data analysis and statistics
- Data visualization pipelines
- Time-series data (e.g., financial prices)
- Pivoting relational data into matrix form

### When NOT to use a DataFrame

- OLTP workloads (use a relational/document DB)
- Multi-user concurrent writes (DataFrames are typically single-user copies)
- Long-term durable system-of-record storage

## Personal Data in Events

When events may contain personal data subject to deletion:

- **Per-user log isolation** — delete the whole log on request (works only when events relate to a single user).
- **External storage for personal fields** — keep a pointer in the event, store the data elsewhere, delete it from there.
- **Crypto-shredding** — encrypt personal data with a per-user key; delete the key to render it unreadable. Trade-off: harder to recompute derived state.

## Quick Reference

| Rule | Summary |
|------|---------|
| Validate at command boundary | Events in the log are accepted facts |
| Past-tense event names | `OrderPlaced`, not `PlaceOrder` |
| Order matters | Replay in log order, always |
| Reproducible projections | Same events + code = same view |
| Deterministic processing | No live external lookups in projections |
| Compensate, don't mutate | Append correction events |
| Guard side effects on replay | Don't resend emails when rebuilding |
| Schema evolves additively | New event types and optional fields only |
