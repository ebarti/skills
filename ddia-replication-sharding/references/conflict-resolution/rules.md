# Conflict Resolution Rules

Guidelines for choosing and applying conflict resolution strategies in multi-leader and local-first systems.

## Core Rules

### 1. Prefer Conflict Avoidance When Possible

The cheapest conflict to resolve is the one that never happens. Route all writes for a given record to a single designated leader.

- Pin a user's traffic to one "home" region for per-user data.
- Use disjoint ID generators per leader (odd/even, prefix per region) for inserts.
- Document the failure mode: leader changes during failover or user relocation can still produce conflicts.
- Avoidance is impossible for offline-first sync engines — plan for resolution there.

### 2. Use LWW Only Where Data Loss Is Acceptable

Last write wins silently discards concurrent writes. Only use it when the lost write is recoverable or doesn't matter.

- Safe for: insert-only workloads with unique keys, idempotent "set this value" semantics, caches.
- Unsafe for: updates to existing records, counters, collections, anything users care about preserving.
- If using LWW, prefer logical clocks over wall-clock timestamps to avoid clock-skew bugs.

### 3. Use CRDTs When Operations Are Commutative

CRDTs converge automatically when concurrent operations can be expressed as commutative merges. They preserve every update's intent.

- Counters → G-Counter (increment-only) or PN-Counter (increment + decrement).
- Unordered collections → OR-Set (preserves removals correctly) over LWW-Set.
- Ordered lists / text → RGA, LSEQ, or off-the-shelf libraries (Yjs, Automerge).
- Key-value maps → recursively merge per-key with the appropriate CRDT.
- Accept the trade-off: CRDTs carry metadata overhead (tombstones, IDs).

### 4. Use OT for Real-Time Collaborative Text

Operational transformation excels when there is a central server coordinating ordering and you need fine-grained text editing.

- Best fit: Google Docs-style real-time editing where latency to a central server is acceptable.
- Requires careful transformation function design — bugs in OT are notoriously subtle.
- Prefer CRDT text libraries (Yjs, Automerge) for peer-to-peer or offline-first scenarios.

### 5. Manual Resolution Is a Last Resort

Bothering the user is expensive in UX and engineering. Reserve it for cases where humans genuinely add value (semantic merges, irreconcilable intents).

- Always provide a sensible default automatic merge alongside the manual UI.
- Beware: if multiple nodes resolve concurrently, resolution itself can introduce new conflicts.
- Order siblings deterministically (e.g., by timestamp + node ID) to keep merges reproducible.

### 6. Pre-Define Merge Logic for Known Conflict Shapes

Don't surprise users with ad-hoc behavior at conflict time. Decide the merge strategy when you design the schema.

- Document per-field strategy: LWW, CRDT counter, OR-set, manual, etc.
- Test merge logic with property-based tests (associativity, commutativity, idempotence).
- Reject naive set-union merges for collections that support removal — they resurrect deleted items.

### 7. Detect Intent-Violation Conflicts at the Application Level

Some conflicts (overlapping bookings, over-budget allocations) cannot be detected by per-record concurrency.

- Use single-leader writes for invariants that span records (consider the relevant `single-leader-replication/` patterns).
- Or accept after-the-fact detection + compensating actions (e.g., cancel one booking, notify users).
- Or use serializable transactions (covered in transactions chapter).

## Guidelines

- Start by enumerating which fields can conflict and how — most fields rarely conflict.
- For collaborative apps, choose CRDT/OT libraries rather than rolling your own; subtle bugs are common.
- For server-side multi-leader, prefer avoidance + LWW for cache-like data + CRDTs for counters.
- Track conflict rates in production telemetry; spikes indicate routing or design problems.
- Prefer libraries (Automerge, Yjs, Riak data types) over custom merge code.

## Exceptions

- **Insert-only logs / event streams**: LWW is fine because there are no updates to lose.
- **Append-only data with unique IDs**: Conflicts are mathematically impossible; no resolution needed.
- **Single-region multi-leader for HA**: Conflict rate is so low that manual resolution may be acceptable.
- **Hard real-time invariants** (inventory, seat booking): Don't rely on multi-leader — use single-leader or coordination.

## Quick Reference

| Rule | Summary |
|------|---------|
| Avoidance first | Pin records to a single leader if you can |
| LWW only for set semantics | Tolerate data loss only when safe |
| CRDTs for commutative ops | Counters, sets, sequences |
| OT for live text | Google Docs–style editing |
| Manual as last resort | Use only when humans add value |
| Pre-define merges | Decide per field at schema time |
| App-level intent checks | Per-record concurrency can't catch invariant breaks |

## Anti-Patterns

- Naive set-union merge for shopping carts → deleted items reappear (Amazon anomaly).
- Wall-clock LWW across nodes with unsynchronized clocks → silent overwrites of newer writes.
- Letting conflict resolution diverge per node (B/C vs C/B) → resolution introduces conflicts.
- Asking the end user to merge JSON → guaranteed bad UX.
- Building bespoke OT/CRDT logic without test coverage → subtle, undetected divergence.
