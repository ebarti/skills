# Conflict Resolution Examples

Concrete conflict scenarios, the strategies that fit them, and the tools that implement those strategies.

## Scenario: Wiki Page Concurrent Edit

Two users on different leaders rename the same page: User 1 sets title to `B`, User 2 sets it to `C`.

### Bad: Naive LWW

```text
write(title, "B", t=1000)  // leader A
write(title, "C", t=1001)  // leader B
// After replication: title = "C", "B" silently dropped.
```

**Problems**: User 1's edit vanishes with no notification. If clocks are skewed, the wrong write may win.

### Good: Manual Resolution with Siblings (CouchDB-style)

```text
read(title) -> ["B", "C"]   // both siblings returned
// App shows merge UI: "Two concurrent edits — keep B, C, or merge?"
write(title, "B/C", resolves=["B","C"])
```

**Why it works**: No data loss; user disambiguates. Suitable because wiki edits are infrequent and human attention adds value.

### Better: CRDT Text (Yjs / Automerge)

```js
import * as Y from 'yjs'
const doc = new Y.Doc()
const title = doc.getText('title')
title.insert(0, 'New Title')        // edits applied locally
// Sync: doc.applyUpdate(remoteUpdate) — converges automatically
```

**Why it works**: Character-level merge preserves both users' insertions and deletions deterministically.

## Scenario: Calendar / Meeting Room Booking

Two users book the same room at overlapping times. Each insert looks valid in isolation; the *combination* violates the invariant.

### Bad: Multi-Leader Inserts with Per-Record LWW

Both inserts succeed on different leaders, replicate, and now the room is double-booked. Per-record concurrency detection finds nothing wrong because the records are different rows.

### Good: Single-Leader Writes for Bookings

Route all booking inserts through a single leader, where a uniqueness constraint or transaction enforces the invariant:

```sql
INSERT INTO bookings (room_id, time_range, group_id)
VALUES ($1, $2, $3)
ON CONFLICT (room_id, time_range) DO NOTHING
RETURNING *;
```

**Why it works**: Sidesteps multi-leader for the data with the cross-record invariant.

### Acceptable: Detect-and-Compensate

Allow multi-leader inserts, then run a reconciliation job that detects overlaps and cancels the later one with a notification.

## Scenario: Counter Conflict (Likes, Views)

Two leaders each increment a counter that started at 10. Naive LWW keeps only one increment.

### Bad: Field LWW

```text
leader A: write(likes, 11, t=1000)
leader B: write(likes, 11, t=1001)
// Result: likes = 11 — one increment lost
```

### Good: CRDT Counter

**G-Counter** (increment-only): each replica keeps its own counter; the merge is per-replica max + sum.

```text
state per replica: {A: 1, B: 1}
merge: sum of per-replica maxes = 2 increments preserved
result: likes = 12
```

**PN-Counter** (increment + decrement): two G-Counters, one for `+`, one for `-`; value = positive − negative.

**Tools**: Riak `counter` data type, Redis Enterprise CRDT counters, Azure Cosmos DB.

## Scenario: Shopping Cart (the Amazon Anomaly)

Device 1 removes `Book` from cart; Device 2 concurrently removes `DVD`. Naive set union merges them back.

### Bad: Set-Union Merge

```text
sibling 1: {DVD, Soap}        // Book removed
sibling 2: {Book, Soap}       // DVD removed
union:     {Book, DVD, Soap}  // both deleted items reappear
```

**Problems**: Deleted items resurrect. Customer is confused and possibly overcharged.

### Good: OR-Set (Observed-Remove Set)

Tracks each add and remove with unique tags. A remove only nullifies adds it has actually observed; concurrent adds survive removes.

```text
sibling 1: {Soap@x, Book@removed:y, DVD@y}
sibling 2: {Soap@x, Book@y, DVD@removed:x}
merge:     {Soap@x}    // both removes observed their respective adds
```

**Tools**: Riak `set` data type, Automerge sets, Yjs Y.Map / Y.Array.

### Avoid: LWW-Set

A simpler set CRDT where each element has add/remove timestamps. Easier but loses concurrent removes — same class of bug as plain LWW.

## Scenario: Real-Time Collaborative Text

Both replicas start with `ice`. One prepends `n` -> `nice`; the other appends `!` -> `ice!`.

### OT Approach (Google Docs, ShareDB)

```text
op1: insert("n", index=0)
op2: insert("!", index=3)
// op2 transformed against op1: index 3 -> 4
// final: "nice!"
```

**Notes**: Requires server-mediated ordering. Transformation function must be carefully proved correct.

### CRDT Approach (Yjs, Automerge, Y-CRDT)

```text
ids: i=1A, c=2A, e=3A
op1: insert "n" with id=1B before id=1A
op2: insert "!" with id=4B after id=3A
// merge by ID — converges to "nice!" with no transformation
```

**Notes**: Works peer-to-peer and offline. Carries per-character metadata.

## Scenario: ID Generation Across Leaders

Two leaders need to generate unique row IDs for inserts.

### Good: Disjoint Generators (Conflict Avoidance)

```text
leader A: ids 1, 3, 5, 7, ...   // odd
leader B: ids 2, 4, 6, 8, ...   // even
```

**Why it works**: Conflicts are mathematically impossible.

### Better: UUIDs or Snowflake-style IDs

128-bit random IDs or per-node prefixed sequences avoid conflicts without coordination.

## Tool Selection Reference

| Need | Tool / Library |
|------|----------------|
| CRDT counters / sets in a database | Riak data types, Redis Enterprise CRDTs, Azure Cosmos DB |
| CRDT JSON / text in app code | Automerge, Yjs, Y-CRDT |
| OT for collaborative text | ShareDB, Google Docs (proprietary) |
| Sibling-based manual resolution | CouchDB, early Riak (Dynamo-style) |
| Multi-leader with per-row LWW | Cassandra, ScyllaDB, BigTable |
| Local-first sync with CRDTs | Automerge + sync server, Yjs + y-websocket |

## Refactoring Walkthrough

### Before: LWW Counter

```js
// Each like sets the new total — concurrent likes lost
async function like(postId) {
  const post = await db.get(postId)
  await db.put(postId, { likes: post.likes + 1 })
}
```

### After: CRDT Counter

```js
// Increments commute and are merged per-replica
async function like(postId) {
  await db.increment(postId, 'likes', 1)   // CRDT op
}
```

### Changes Made

1. Replaced read-modify-write with a commutative increment, pushing merge logic into the CRDT layer.
2. Eliminated the lost-update bug class.
