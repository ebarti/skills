# Unbundling Databases Knowledge

Core concepts for decomposing databases into composable storage components glued together by event streams, and for designing applications around dataflow.

## Overview

A traditional database bundles many features (indexes, materialized views, replication logs, full-text search) into one product. **Unbundling** breaks these features into separate tools, run on different machines, connected by event logs. Applications built this way are structured as **dataflow systems**: stateless code that derives views from event logs, with state changes pushed end-to-end from source to UI.

## Key Concepts

### Unbundling Databases

**Definition**: Decomposing the features of a monolithic database (storage, indexer, cache, query engine, replication) into separate tools that communicate through event logs (CDC, Kafka), in the Unix tradition of small composable utilities.

**Key points**:
- Synchronizes **writes** across heterogeneous storage systems via ordered, idempotent event logs
- Avoids distributed transactions across systems written by different teams
- Provides **loose coupling**: a slow/failed consumer doesn't take down producers or other consumers
- Sister concept: **federation** unifies *reads* (Trino, PostgreSQL FDW); unbundling unifies *writes*

### Meta-Database of Everything

**Definition**: The view that an organization's entire dataflow (batch jobs, stream processors, ETL) functions like one giant distributed database — each transport pipeline is analogous to an internal index-maintenance subsystem.

Derived data systems become "different index types" provided by different software, not features of one product.

### Application Code as Derivation Function

**Definition**: A pure function that transforms an event log (or upstream dataset) into a derived view. Examples: secondary index builder, full-text indexer, ML feature extractor, UI cache populator.

**Key points**:
- Built-in in databases for simple cases (`CREATE INDEX`)
- Custom code is needed for app-specific derivations (feature engineering, UI-shaped caches)
- Stream processors run derivation functions as operators on event streams
- Equivalent to spreadsheet formulas: when input cells change, derived cell auto-updates

### Materialized View

**Definition**: A precomputed cache of query results, derived from base data, that is automatically maintained as the base data changes.

A materialized view shifts work from read time to write time. Caches, indexes, and materialized views all play the same role: shifting the boundary between the **write path** and the **read path**.

### Dataflow Application

**Definition**: An application structured as event log + stateless derivation operators + derived views, with state changes propagated through the system rather than fetched on demand.

**In contrast to** request/response microservices: instead of calling an exchange-rate service per purchase, subscribe to an exchange-rate stream and join locally.

### Reads as Events

**Definition**: A pattern where read queries are also published to a stream and processed by the same operator that handles writes — turning each read into a stream-table join.

A one-off read is a transient join; a subscribe is a persistent join with future events. Useful for audit logs, causal-dependency tracking, and consistent cache invalidation.

### Pushing State Changes to Clients

**Definition**: Extending the write path all the way to end-user devices. The server actively pushes state-change events over WebSocket / SSE / sync protocols, so the client UI re-renders without polling.

**Key points**:
- On-device state becomes a *cache of server state*; the UI is a materialized view of the model
- Enables offline-capable apps (state lives locally, syncs when connected)
- Reuses log-based broker offsets so a reconnecting client doesn't miss events
- Pairs naturally with React/Elm-style reactive UIs

### Multishard Data Processing

**Definition**: Distributing complex queries across shards by routing each event/read to the shard owning the relevant key, then collecting/aggregating partial results — reusing the same routing infrastructure stream processors use for joins.

Examples: counting URL reach across a sharded follower graph; fraud scoring that joins reputation databases for IP, email, billing, shipping each sharded independently.

## Terminology

| Term | Definition |
|------|------------|
| Unbundling | Splitting database features into separate tools connected by streams |
| Federation | Single query interface over multiple storage backends (read-side) |
| Polystore | Synonym for federated database |
| Write path | Eager precomputation: ingest → derive → store |
| Read path | Lazy serving: query the precomputed derived view |
| Derivation function | Pure transform from base data to derived view |
| Materialized view | Auto-maintained precomputed query result |
| Sync engine | Client library that subscribes to server state changes |
| Distributed RPC | Treating reads as events routed via stream infrastructure |

## How It Relates To

- **Event streams (Ch 12)**: Provides the durable, ordered, replayable transport that unbundling depends on
- **CDC**: The mechanism for emitting state changes from existing databases into the meta-database
- **Stream processing**: Runs the derivation functions as operators on the event log
- **Microservices**: Dataflow is an alternative communication style — pub/sub instead of REST
- **Lambda calculus / FP**: "Separation of Church and state" — stateless code, state in the database

## Common Misconceptions

- **Myth**: Unbundling means replacing your database.
  **Reality**: Databases are still needed for state and querying derived views. Unbundling complements them; you only unbundle when one product can't satisfy all your requirements.

- **Myth**: Unbundling is faster than an integrated DBMS for any workload.
  **Reality**: Integrated systems often win on a *specific* workload. Unbundling wins on **breadth** — combining storage technologies for a wider range of workloads.

- **Myth**: You need distributed transactions to keep multiple systems in sync.
  **Reality**: An ordered event log with idempotent consumers is simpler and more robust across heterogeneous tech.

- **Myth**: Pushing changes to clients is only for chat / games.
  **Reality**: It's a general technique. Sync engines (Linear, Figma, Replicache) prove it scales to general SaaS.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Unbundling | Database = log + indexer + cache + query engine, connected by streams |
| Federation | Unified read interface over heterogeneous stores |
| Derivation function | Pure transform from base data to derived view |
| Materialized view | Auto-maintained precomputed cache |
| Dataflow app | Event log + stateless ops + derived views, no synchronous fetches |
| Reads as events | Treat each read as a stream-table join |
| Push to client | Extend the write path through WebSocket/SSE to the UI |
| Multishard | Route per-key, collect at edge — reuse stream-processor join machinery |
