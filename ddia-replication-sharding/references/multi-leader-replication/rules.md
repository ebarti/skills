# Multi-Leader Replication Rules

Decision guidance for when, where, and how to deploy multi-leader replication.

## Core Rules

### 1. Use multi-leader for multi-region writes, not within a single datacenter

The added complexity of multi-leader (conflicts, causality, retrofit pitfalls) rarely pays off inside one region.

- Single region with high write volume? Prefer single-leader plus sharding
- Multi-region for latency, residency, or regional outage tolerance? Multi-leader is reasonable
- A common rule: "if you can answer with single-leader, do"

### 2. Use multi-leader when offline operation is required

Devices that must read and write while disconnected need a local leader.

- Mobile calendars, notes, drawing apps, journal apps
- Each device is its own "region"; replication lag may be hours or days
- If app must work offline, single-leader is not an option

### 3. Treat collaborative client apps as multi-leader

Even apps that don't claim to be offline-capable are multi-leader if multiple users edit the same document concurrently.

- Each browser tab/editor is a replica
- Local input must reflect immediately; round-trips are unacceptable
- Conflict resolution must be designed in from the start

### 4. Prefer all-to-all topology for resilience

A more densely connected topology survives node failures because messages can travel via alternate paths.

- All-to-all: best fault tolerance, vulnerable to causal-ordering bugs
- Circular: simple but one failed node breaks the ring
- Star: simple but the root node is a SPOF
- Choose all-to-all unless you have a specific reason for the others

### 5. Use only async multi-leader replication

Synchronous multi-leader gives you the latency and availability of single-leader without the benefits, so it isn't worth doing.

- If A must wait for B before completing a write, you might as well make B the leader
- Async is what makes regional failure tolerance and offline operation possible

### 6. Plan for causality bugs (out-of-order delivery)

In all-to-all topologies, replication messages can overtake each other and arrive in the wrong order.

- An update may arrive before its corresponding insert
- Wall-clock timestamps are NOT sufficient for ordering
- Use version vectors (see `conflict-resolution/`) for causal ordering
- Read the database documentation carefully; test the actual guarantees

### 7. Don't rely on global uniqueness or invariant constraints

Multi-leader cannot enforce constraints that span leaders.

- No guarantee that a username is unique across regions
- No guarantee that an account balance won't go negative
- If you need such constraints, use single-leader (or accept eventual reconciliation)

### 8. Beware of retrofitted multi-leader features

Multi-leader is often bolted onto single-leader databases and interacts badly with other features.

- Autoincrement keys can collide across leaders (use UUIDs or per-leader ID ranges)
- Triggers may run twice or in surprising order
- Integrity constraints may be violated cross-leader even if locally satisfied
- Treat multi-leader as "dangerous territory" requiring extra testing

## Guidelines

- Sync engines work best when all data the user needs can be downloaded in advance
- Don't try to replicate an entire ecommerce catalog to every client device
- For local-first guarantees, use an open sync protocol with multiple providers (e.g., CouchDB, Yjs, Automerge)
- Pair sync engines with reactive programming to make UI updates flow naturally
- Aim for next-frame UI responsiveness (~16 ms at 60 Hz) when using sync engines
- Treat "offline" as just "very high network latency" in your programming model

## Exceptions

When the rules may be relaxed:

- **Game netcode**: Has multi-leader-like requirements but uses very different techniques specific to games; don't reuse general sync-engine patterns directly
- **Read-mostly workloads**: A multi-leader-within-region setup may make sense if writes are extremely rare and you need local-write capability per zone
- **Regulatory data residency**: Sometimes you must keep writes in-region even if a single-leader design would have sufficed technically

## Quick Reference

| Rule | Summary |
|------|---------|
| Multi-region writes | Multi-leader fits; one leader per region |
| Single datacenter | Avoid multi-leader; complexity > benefit |
| Offline editing | Each device is a leader; sync async |
| Collab apps | Each tab is a leader; design for conflicts |
| Topology | Prefer all-to-all for resilience |
| Sync mode | Always async; sync collapses to single-leader |
| Causality | Use version vectors, not clocks |
| Constraints | Don't expect uniqueness or invariants across leaders |
| Retrofit | Test autoincrement, triggers, constraints carefully |
