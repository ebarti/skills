# Designing an Event-Sourced System Workflow

End-to-end design process for a CQRS / event-sourced system: validating fit, modeling commands and events, choosing storage, designing projections, and planning evolution and erasure.

## When to Use

- Designing a new system where intent and history matter
- Replacing CRUD-with-audit-columns with a richer model
- Adding a second read shape over an existing write model

## Prerequisites

- Domain experts available to define commands and events
- Decision on serialization format (Avro / Protobuf preferred)

**Reference**: `references/event-sourcing-cqrs/rules.md`, `references/event-sourcing-cqrs/knowledge.md`

## Workflow Steps

### Step 1: Validate Fit
**Goal**: Confirm event sourcing is justified before paying its complexity cost.
- [ ] Audit / regulatory requirement to reconstruct who-did-what-when?
- [ ] Domain has rich intent (`BookingCancelled` ≠ `active = false`)?
- [ ] Multiple read shapes from one write shape needed?
- [ ] Requirements evolving fast (new event types likely)?
- [ ] Need to recompute derived state with corrected logic?

**If none apply**: Abort. Use plain CRUD. Event sourcing adds ceremony without payoff.
**Reference**: `references/event-sourcing-cqrs/rules.md` (When NOT to Use)

### Step 2: Model Commands and Events
**Goal**: Capture domain as imperative commands (validatable, rejectable) and past-tense events (immutable facts).
- [ ] List commands: `PlaceOrder`, `CancelBooking` (imperative)
- [ ] List events: `OrderPlaced`, `BookingCancelled` (past tense)
- [ ] For each command, define validation rules (run before append)
- [ ] For each event, define which command(s) produce it
- [ ] Events are self-contained (carry data needed to interpret them later)

**Ask**: "What does the business *say* happened, in their own words?"

### Step 3: Define the Event Schema
**Goal**: Choose a serialization format that supports additive evolution.
- [ ] Pick Avro or Protobuf (NOT raw JSON for long-lived logs)
- [ ] Define schema per event type with version field
- [ ] All new fields are optional with defaults
- [ ] Include event id, timestamp, type, version, payload
- [ ] Register schemas in a schema registry if using Kafka

**Reference**: `references/encoding-formats/rules.md`

### Step 4: Pick the Event Store
**Goal**: Choose storage matching scale, ecosystem, and durability needs.

| Choice | Use When |
|--------|----------|
| EventStoreDB | Purpose-built event log + projections; smaller scale |
| MartenDB | Already on Postgres; want event sourcing without new infra |
| Apache Kafka | High throughput; pair with stream processors for views |
| Custom on Postgres | Full control; small team; transactional outbox pattern |

- [ ] Atomic append-only writes
- [ ] Strict ordering (per-aggregate at minimum)
- [ ] Consumers can read from arbitrary offsets (replay)

### Step 5: Design Projections (Read Models)
**Goal**: One denormalized read model per query pattern, each rebuildable from the log.
- [ ] List query patterns (dashboard, search, report)
- [ ] One projection per pattern; pick storage per projection
- [ ] Write `apply(event, view)` as a pure function — no live external calls
- [ ] Embed values in events when needed (e.g., FX rate at time of payment)
- [ ] Confirm consumers process events in log order

**Reference**: `references/event-sourcing-cqrs/examples.md` (CQRS pattern, anti-pattern)

### Step 6: Plan Reprocessing Strategy
**Goal**: Make rebuilding any view from scratch a routine operation.
- [ ] Document: "delete view + replay log = same result"
- [ ] Identify side-effecting code paths (email, webhooks, charges)
- [ ] Guard side effects with a replay flag
- [ ] Dual-write window if replacing live view (write old + new, switch reads, drop old)

### Step 7: Define Snapshot Strategy
**Goal**: Avoid full-log replay when aggregates accumulate many events.

**Decision: snapshot when** aggregate has > ~1000 events, OR replay-from-zero exceeds your cold-start SLO, OR hot aggregates dominate cost.
- [ ] Snapshot = (aggregate state, last applied event id)
- [ ] On read: load latest snapshot, replay events after it
- [ ] Snapshots are derived data — safe to delete and rebuild
- [ ] Version snapshots; rebuild on schema change

**If aggregates stay small (< few hundred events)**: Skip snapshots; full replay is fine.

### Step 8: Plan GDPR / Right-to-Erasure
**Goal**: Reconcile immutable events with deletion requests for personal data.

| Strategy | When |
|----------|------|
| Per-user log isolation | Events relate to a single user; delete the whole log |
| External storage for personal fields | Event holds pointer; data lives elsewhere; delete from there |
| Crypto-shredding | Encrypt personal fields with per-user key; delete key on request |

- [ ] Identify which event fields are personal data
- [ ] Confirm strategy still allows projection rebuild (crypto-shredding limits this)
- [ ] Document the deletion procedure

### Step 9: Define Versioning + Upcasting
**Goal**: Evolve schemas without rewriting history.

**Decision: Upcast vs. Migrate**
- **Upcast** (preferred): Transform old event versions to new shape on read; history untouched.
- **Migrate** (rare): Rewrite the log only when upcasting becomes too costly (many versions deep, hot read path).

- [ ] Add new event types freely (old consumers ignore them)
- [ ] Add new fields as optional with defaults
- [ ] Bump version when shape changes break consumers; write upcaster
- [ ] Never edit historical events in place
- [ ] Reverse mistakes via compensating events, not mutation

### Step 10: Document Architecture and Taxonomy
**Goal**: Make the design discoverable for new contributors.
- [ ] Diagram: command boundary → event log → projections
- [ ] Command catalog (name, validation, produces which events)
- [ ] Event catalog (name, schema version, fields, producing command)
- [ ] Projection catalog (name, query pattern, source events, storage)
- [ ] Replay runbook + GDPR runbook

## Quick Checklist

```
[ ] 1. Fit validated     [ ] 6. Reprocessing safe; side effects guarded
[ ] 2. Commands + events [ ] 7. Snapshot strategy decided
[ ] 3. Schema additive   [ ] 8. GDPR strategy picked
[ ] 4. Event store       [ ] 9. Versioning + upcasting defined
[ ] 5. Projections pure  [ ] 10. Architecture documented
```

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Imperative event names (`ShipOrder`) | Event is a fact, not a command | Past tense: `OrderShipped` |
| Mutable / edited events | Breaks audit trail and reproducibility | Append compensating event |
| Non-deterministic projections (live FX, current profile) | Replay yields different views | Embed value in event or query historical-by-timestamp source |
| Validating in projections | Projections can't reject log facts | Validate at the command boundary |
| Raw JSON for long-lived events | Schema evolution becomes painful | Avro / Protobuf with version field |
| No replay guard on side effects | Rebuilding view resends emails | Replay flag skips externally-visible actions |
| Event references mutable external data | Referenced data may have changed | Embed needed values in the event |
| GDPR ignored until production | Deletion requests force log rewrites | Pick erasure strategy in Step 8, before launch |

## Cross-References

- `references/event-sourcing-cqrs/` — Rules, knowledge, examples
- `references/encoding-formats/` — Avro / Protobuf schema evolution
- `references/dataflow-modes/` — Databases-and-streams overlap
- Cross-skill: `ddia-batch-stream-processing` — Kafka as event-store substrate, stream-processed projections (Ch 12-13)

## Exit Criteria

- [ ] Command and event catalogs reviewed by domain experts
- [ ] At least one projection designed end-to-end (apply function + storage)
- [ ] Replay procedure documented and tested in non-prod
- [ ] GDPR strategy chosen and personal-data fields tagged
- [ ] Schema evolution rules (additive only, version + upcast) agreed
