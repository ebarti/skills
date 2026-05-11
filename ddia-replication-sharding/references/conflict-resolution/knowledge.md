# Conflict Resolution Knowledge

Core concepts for resolving conflicting writes in multi-leader and local-first replicated systems.

## Overview

When concurrent writes occur on different leaders (or offline devices), they can produce conflicting versions of the same record. Conflict resolution strategies range from avoidance (route writes to one leader) to automatic merging via CRDTs/OT, with simple options like last write wins (LWW) and manual resolution in between.

## Key Concepts

### Write Conflict

**Definition**: Two writes are *concurrent* if neither was aware of the other when made — that is, neither write occurred in a state where the other had already taken effect.

**Key points**:
- Concurrency is logical, not wall-clock based; offline writes hours apart can still be concurrent.
- Single-leader systems do not produce write conflicts; multi-leader and leaderless systems do.
- See `leaderless-replication/` for the vector-clock mechanism that detects concurrency.

### Conflict Avoidance

**Definition**: Preventing conflicts by ensuring all writes for a given record go through the same leader.

Routes a user's (or a record's) traffic to a single "home" leader, making the system effectively single-leader from that record's perspective. Breaks down when the designated leader changes (failover, user moves regions).

### Last Write Wins (LWW)

**Definition**: A conflict resolution algorithm that attaches a timestamp to each write and keeps only the value with the greatest timestamp.

For concurrent writes, "last" is undefined — the winner is essentially random, and the losing writes are silently discarded (data loss). Sensitive to clock skew when wall-clock timestamps are used; logical clocks help.

### Manual Conflict Resolution (Siblings)

**Definition**: The database stores all concurrently written values (called *siblings*) and returns them on read; the application or user picks/merges.

Used by CouchDB and Riak. Burdens the application API (a value becomes a set of values) and can introduce new conflicts if multiple nodes resolve concurrently.

### Automatic Conflict Resolution

**Definition**: An algorithm merges concurrent writes into a single converged state without human input.

Goal: *strong eventual consistency* — all replicas that received the same set of writes end up in the same state, regardless of arrival order. Preserves the intended effect of every update where possible.

### CRDT (Conflict-free Replicated Data Type)

**Definition**: A data structure designed so that concurrent operations on different replicas commute and converge without coordination.

Each element gets a unique, immutable ID; insert/delete operations reference IDs rather than positions, so replicas converge without transformation. Used in Riak, Redis Enterprise, Azure Cosmos DB, Automerge, Yjs.

### OT (Operational Transformation)

**Definition**: Records each edit as an operation (e.g., insert at index 0) and *transforms* the indices of incoming concurrent operations to account for changes already applied locally.

Used in Google Docs and ShareDB. Same goal as CRDTs (deterministic merge) but with a different mechanism — index transformation instead of stable IDs.

### Merge Function

**Definition**: Application or library code that combines sibling values into one converged value.

Can be application-defined (for manual resolution) or built into the data type (for CRDT/OT). Must be associative, commutative, and idempotent for correctness.

### Vector Clock

**Definition**: A per-replica counter vector used to determine whether two versions are concurrent or causally ordered.

Used to *detect* conflicts; covered in detail in `leaderless-replication/`. Conflict resolution then decides what to do once detection has occurred.

## Types of Conflict

| Type | Description | Example |
|------|-------------|---------|
| Write-write | Same field in same record set to different values | Wiki title B vs C |
| Lost update | One write silently overwrites another | LWW dropping a concurrent edit |
| Intent-violation | Concurrent inserts violate an invariant the app must maintain | Two bookings for the same room/time slot |

Intent-violation conflicts are harder to detect: each individual write looks valid, but their combination breaks an invariant. Detection often requires app-level constraint checks beyond per-record concurrency.

## Strategy Comparison

| Strategy | Data loss | Effort | Best for |
|----------|-----------|--------|----------|
| Avoidance | None | Routing layer | Server-side geo-replication of per-user data |
| LWW | Yes (silent) | Trivial | Set semantics, idempotent inserts |
| Manual | None (user picks) | High (UI + API change) | Rare conflicts where humans add value |
| CRDT | None (preserves intent) | Library + schema design | Counters, sets, lists, JSON, text |
| OT | None (preserves intent) | Server coordination usually needed | Real-time collaborative text |

## Terminology

| Term | Definition |
|------|------------|
| Concurrent writes | Writes where neither was aware of the other |
| Sibling | One of multiple stored concurrent values for a key |
| Convergence | All replicas reaching the same state given the same writes |
| Strong eventual consistency | Eventual consistency + convergence guarantee |
| Logical clock | Counter-based clock that orders events without wall time |

## How It Relates To

- **Multi-leader replication**: The architecture that produces conflicts.
- **Leaderless replication**: Uses similar techniques (siblings, vector clocks, LWW) to handle concurrent writes from different clients.
- **Local-first / sync engines**: Offline edits are inherently concurrent; conflict resolution is unavoidable.

## Common Misconceptions

- **Myth**: LWW means "the most recently written value wins."
  **Reality**: For concurrent writes, "most recent" is undefined; the winner is effectively random and other writes are lost.

- **Myth**: Automatic merging always preserves user intent.
  **Reality**: Naive merges (e.g., set union for shopping carts) can resurrect deleted items. CRDTs solve this by tracking deletions explicitly.

- **Myth**: CRDTs and OT are interchangeable.
  **Reality**: OT typically requires a central server to order operations; CRDTs work peer-to-peer. They have different performance and functionality trade-offs.

- **Myth**: Conflict avoidance via leader pinning eliminates all conflicts.
  **Reality**: Leader changes (failover, user relocation) reintroduce them.
