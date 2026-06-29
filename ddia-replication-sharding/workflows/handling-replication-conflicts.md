# Handling Replication Conflicts Workflow

Pick and apply a conflict-resolution strategy for a replicated system: avoid conflicts when possible, then choose LWW, CRDT, OT, or manual merge based on the data shape.

## When to Use

- Designing a multi-leader or leaderless replicated store
- Building an offline-first / sync-engine client (mobile, edge, local-first)
- Adding real-time collaboration to an existing app
- Diagnosing data loss, resurrected deletes, or divergent replicas in production

## Prerequisites

- Topology already chosen (see `workflows/choosing-replication-topology.md`)
- Schema fields and their semantics enumerated
- Awareness of which invariants span records (booking, inventory, balances)

**Reference**: `references/conflict-resolution/rules.md`, `references/conflict-resolution/knowledge.md`

---

## Workflow Steps

### Step 1: Identify the Conflict Types Possible

**Goal**: Enumerate which conflict shapes the system can produce, per field.

- [ ] List fields that accept concurrent writes
- [ ] Mark each as **write-write** (same field, different values), **lost-update** (read-modify-write race), or **intent-violation** (invariant across records)
- [ ] Note which fields are insert-only (no conflict possible) vs mutable
- [ ] Flag invariants that cannot be enforced by per-record concurrency

**Ask**: "If two users edit this offline simultaneously, what bad outcome could result?"

**Reference**: `references/conflict-resolution/knowledge.md` (Types of Conflict)

---

### Step 2: Try Conflict Avoidance First

**Goal**: Eliminate conflicts by routing writes for each record to a single leader.

- [ ] Pin per-user data to a "home" region/leader
- [ ] Use disjoint ID generators per leader (odd/even, region prefix) for inserts
- [ ] Document failure modes: failover or user relocation can still produce conflicts
- [ ] If conflicts are unavoidable (offline-first, multi-region collab), proceed to Step 3

**Ask**: "Can I make this single-leader-per-record without hurting latency or availability?"

**Reference**: `references/conflict-resolution/rules.md` (Rule 1)

---

### Step 3: Classify the Data Shape

**Goal**: Map each conflicting field to its data category — that drives strategy selection.

- [ ] **Counter** (likes, view counts, balances)
- [ ] **Set / collection** (tags, cart items, members)
- [ ] **Ordered list / text** (document body, todo order)
- [ ] **Scalar with set semantics** (status flag, last-known location)
- [ ] **Complex/nested document** (semantic merge required)
- [ ] **Cross-record invariant** (booking slot, unique username) — handled at app/transaction layer

**Reference**: `references/conflict-resolution/knowledge.md` (Strategy Comparison)

---

### Step 4: Pick a Strategy per Field

**Goal**: Match each field's data shape to the cheapest sufficient strategy.

- [ ] **LWW** — only for set semantics where lost concurrent writes are acceptable (caches, "last-known" values, idempotent inserts)
- [ ] **CRDT** — counters (G/PN-Counter), sets (OR-Set), text/lists (RGA, Yjs, Automerge), recursive maps
- [ ] **OT** — real-time collaborative text with a central server (Google Docs–style)
- [ ] **Manual** — rare conflicts on complex documents where humans add semantic value
- [ ] **App-level / single-leader** — cross-record invariants (bookings, inventory, uniqueness)
- [ ] If using LWW, prefer logical clocks (version vectors) over wall-clock timestamps

**Ask**: "Is this field commutative? If yes, CRDT. If not, what semantics do users expect?"

**Reference**: `references/conflict-resolution/rules.md` (Rules 2–5)

---

### Step 5: Pre-Define Merge Logic for Known Conflict Shapes

**Goal**: Decide merge behavior at schema-design time, not at conflict time.

- [ ] Document per-field strategy in the schema (LWW / OR-Set / counter / manual)
- [ ] Reject naive set-union for collections that allow removal — they resurrect deletes (Amazon cart anomaly)
- [ ] Order siblings deterministically (timestamp + node ID) for reproducibility
- [ ] Prefer libraries (Automerge, Yjs, Riak data types) over rolling custom merge code
- [ ] Add property-based tests for associativity, commutativity, idempotence

**Reference**: `references/conflict-resolution/rules.md` (Rule 6)

---

### Step 6: Plan UX for Manual Resolution (If Needed)

**Goal**: If manual merge is unavoidable, design the user-facing flow before launch.

- [ ] Show both sibling values side-by-side (never raw JSON)
- [ ] Provide a sensible automatic default alongside the manual UI
- [ ] Detect re-conflicts: concurrent resolutions can themselves conflict
- [ ] Confirm the resolution writes back deterministically (so other replicas converge)
- [ ] Estimate conflict rate — if manual UI fires often, the strategy is wrong

**Reference**: `references/conflict-resolution/rules.md` (Rule 5)

---

### Step 7: Test Conflict Scenarios

**Goal**: Prove the strategy converges under partition + concurrent writes before shipping.

- [ ] Simulate network partition between leaders; write divergent values; heal; verify convergence
- [ ] Test offline write on a client → reconnect after long delay → verify merged state
- [ ] Run property tests: any order of operations yields the same final state
- [ ] Stress: many concurrent writers on the same key; assert no silent data loss
- [ ] For intent-violation: simulate the dual-booking case; confirm detection + compensating action

**Reference**: `references/conflict-resolution/rules.md` (Rule 7)

---

### Step 8: Document Conflict Policy and UX

**Goal**: Make per-field strategy and user-facing behavior explicit for reviewers and on-call.

- [ ] Per-field merge strategy table in the schema doc
- [ ] User-visible behavior on conflict (silent merge / sibling UI / compensating action)
- [ ] Telemetry: conflict rate per field; alert on spikes (indicates routing or design issue)

---

## Quick Checklist

```
[ ] Step 1: Conflict types enumerated per field
[ ] Step 2: Avoidance attempted; remaining conflicts identified
[ ] Step 3: Each field classified by data shape
[ ] Step 4: Strategy chosen per field (LWW / CRDT / OT / manual / app-level)
[ ] Step 5: Merge logic pre-defined; libraries preferred over custom code
[ ] Step 6: Manual UX designed (if needed)
[ ] Step 7: Conflict scenarios tested (partition + concurrent writes)
[ ] Step 8: Policy + UX + telemetry documented
```

---

## Decision Tree: Data Shape -> Strategy

```
Is the conflict avoidable by single-leader routing?
  yes -> Avoidance (no resolution code needed)
  no  -> Is it a cross-record invariant (booking, uniqueness)?
           yes -> App-level check OR single-leader OR serializable txn
           no  -> What is the data shape?
                    counter        -> CRDT (G-Counter / PN-Counter)
                    set/collection -> CRDT (OR-Set; never naive union)
                    ordered text   -> CRDT (Yjs/Automerge) OR OT (server-coordinated)
                    set-semantics  -> LWW (only if lost writes are acceptable)
                    complex doc    -> Manual merge w/ sensible default + sibling UI
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| LWW for counters | Concurrent +1s collapse to one, undercounting | Use PN-Counter CRDT |
| Naive set-union merge for carts | Deleted items resurrect (Amazon anomaly) | Use OR-Set with tombstones |
| Wall-clock LWW across nodes | Clock skew silently drops newer writes | Use logical clocks / version vectors |
| Manual resolution at scale | Users overwhelmed; UX disaster; conflicts of conflicts | Use CRDT/OT; reserve manual for rare semantic merges |
| Asking users to merge JSON | Guaranteed bad UX | Show domain-level diff or pick-one UI |
| Rolling custom OT or CRDT | Subtle bugs cause silent divergence | Use Automerge / Yjs / Riak data types |
| Per-record concurrency for invariants | Each write looks valid but combination breaks rule | App-level check or single-leader for that invariant |
| No conflict telemetry in production | Routing/design regressions go unnoticed | Track conflict rate per field; alert on spikes |
| Resolving differently on different nodes (B/C vs C/B) | Resolution itself introduces conflicts | Deterministic sibling ordering everywhere |

---

## Exit Criteria

Task is complete when:
- [ ] Per-field conflict strategy documented in the schema
- [ ] Avoidance applied where possible; remaining conflicts have a chosen merge
- [ ] Merge logic implemented (preferably via library) with property tests
- [ ] Partition + concurrent-write scenarios pass convergence tests
- [ ] Conflict-rate telemetry shipped and alerted on

---

## Cross-References

- Within: `references/conflict-resolution/{rules,knowledge}.md`, `references/multi-leader-replication/rules.md`, `references/leaderless-replication/rules.md`, `workflows/choosing-replication-topology.md`
- Other skill: `ddia-transactions-consistency` — serializable transactions for invariants that conflict resolution cannot enforce
