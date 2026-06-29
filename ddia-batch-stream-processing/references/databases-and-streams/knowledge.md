# Databases and Streams Knowledge

Core concepts for connecting databases to event streams via change data capture and immutable event logs.

## Overview

Every database write is an event. By exposing those events as a stream, you can keep multiple data systems (cache, search index, warehouse, derived views) in sync from a single source of truth — avoiding the race conditions and atomicity problems of dual writes.

## Key Concepts

### Change Data Capture (CDC)

**Definition**: The process of observing all data changes written to a database and extracting them as a stream that can be replicated to other systems.

CDC reads the database's existing replication log at a low level. The source database remains the leader; derived systems become followers of its change stream.

**Key points**:
- Application uses the database normally (mutable updates/deletes)
- Changes captured from physical/logical replication log
- Order extracted matches actual write order — solves the dual-write race
- Usually asynchronous; consumers can lag behind the source

### Database Log Shipping

**Definition**: Taking the replication log a database produces for its own followers and using it as a public stream for external consumers.

Historically replication logs were treated as private internal details. CDC repurposes them as a documented stream API.

### Dual Write

**Definition**: Application code writing the same change to multiple systems explicitly (e.g., DB then search index then cache).

**Why it fails**:
- **Race conditions**: Concurrent clients can interleave writes so each system ends up with a different "winner"
- **Partial failure**: One write succeeds, another fails — no atomic commit across heterogeneous systems
- **No single leader**: Each system has its own ordering; conflicts go undetected without version vectors

### Event Sourcing

**Definition**: Application logic explicitly built on immutable events written to an append-only log; the event log is the system of record, mutable state is derived.

See `references/event-sourcing/` for details. Distinguished from CDC below.

### CDC vs Event Sourcing

| Aspect | CDC | Event Sourcing |
|--------|-----|----------------|
| Source of truth | Mutable database | Append-only event log |
| Event level | Low-level row changes | High-level user intent |
| Adoption cost | Low — bolt onto existing DB | High — rewrite app logic |
| Log compaction | Works (latest value per key wins) | Limited (later events don't supersede earlier ones) |
| Order guarantee | DB decides write order | App appends in intent order |

### Log Compaction

**Definition**: A retention strategy (used by Apache Kafka) that periodically scans a log topic for records with the same key and discards all but the most recent value for each key.

**Key points**:
- Disk usage depends on number of distinct keys, not write volume
- Lets you rebuild a derived system from offset 0 without a separate snapshot
- Requires every change event to carry a primary key
- Background process; merges segments as it compacts

### Tombstone

**Definition**: A special record with a null value for a key, signaling deletion. Log compaction removes the key entirely once the tombstone is processed.

Used to propagate deletes through a compacted topic.

### Retention Policy

**Definition**: The rule for how long events remain in a log. Two main flavors in Kafka:
- **Time/size retention** — keep raw events for N days/GB (suits event sourcing)
- **Compaction** — keep latest value per key forever (suits "current state" CDC topics)

### Initial Snapshot

**Definition**: A consistent point-in-time copy of the source database, taken so a new consumer can build full state before tailing the live change log.

The snapshot must correspond to a known offset in the change log so the consumer knows where to resume. Debezium uses Netflix's DBLog watermarking for incremental snapshots.

### Immutable Event Log → Multiple Views

The core insight: state is the integral of an event stream over time; a change stream is the derivative of state. Storing the changelog durably makes state reproducible and lets you derive any number of read-optimized views (search index, cache, materialized OLAP cube) from one write-optimized log.

## Terminology

| Term | Definition |
|------|------------|
| CDC | Change data capture — stream of database changes |
| Changelog | Log of all changes to state over time |
| Source connector | Component that tails a DB log and emits events (e.g., Debezium for Postgres) |
| Sink connector | Component that consumes events and writes to a target system |
| Outbox pattern | Dedicated table written in same DB transaction as domain data, then captured by CDC |
| Crypto-shredding | Encrypt data at rest; "delete" by destroying the key |
| Excision | Truly removing past events from history (Datomic term) |
| Derived data system | Search index, cache, warehouse — any consumer of the change stream |

## How It Relates To

- **Event Sourcing**: Both write changes to a log; CDC infers events from DB writes, event sourcing makes events the source.
- **Replication**: CDC repurposes the leader's replication log as a public stream.
- **Stream Processing**: CDC topics feed stream processors that maintain derived state.
- **CQRS**: CDC enables separating write side (DB) from many read-optimized views.
- **Batch Processing**: Same "immutable input → derived output" principle, applied continuously instead of in batches.

## Common Misconceptions

- **Myth**: Dual writes are fine if you wrap them in a try/catch.
  **Reality**: Even with no errors, concurrent writes interleave non-deterministically across systems. You need a single ordering authority.

- **Myth**: CDC requires changing your application.
  **Reality**: A pure CDC pipeline can be added with zero application code changes — the app keeps writing to the DB normally.

- **Myth**: Log compaction loses data.
  **Reality**: Compaction loses *superseded* values per key; the latest value for every key is preserved indefinitely.

- **Myth**: Immutable logs make GDPR impossible.
  **Reality**: Tombstones plus compaction, or crypto-shredding, give practical paths to deletion.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| CDC | Tail the DB's replication log; publish writes as a stream |
| Dual write | Anti-pattern; causes silent inconsistency under concurrency |
| Log compaction | Keep only the most recent value per key in a topic |
| Tombstone | Null-valued record that signals deletion under compaction |
| Initial snapshot | Bootstrap consumers with full state before tailing live changes |
| Outbox pattern | Decouple DB schema from CDC schema via an explicit outbox table |
