# Event Sourcing, CQRS, and DataFrames Knowledge

Core concepts for representing state as an append-only event log (with derived read views) and for modeling analytical/numeric data as DataFrames and arrays.

## Overview

In complex applications, no single representation serves all reads and writes well. Event sourcing makes the write side an append-only log of immutable events; CQRS derives multiple read-optimized views from that log. Separately, DataFrames and multidimensional arrays are the dominant data models for analytics, ML, and scientific computing.

## Key Concepts

### Event Log

**Definition**: An append-only, ordered sequence of immutable events. Each event is a self-contained record (often JSON) with a timestamp and arbitrary properties.

- Events are never modified or deleted, only superseded by later events
- Order matters (a cancellation must follow its booking)
- Sequential writes scale better than random updates

### Event Sourcing

**Definition**: Using events as the source of truth and expressing every state change as an event.

- Derives current state by replaying events
- Events named in the past tense (e.g., `SeatsBooked`, `BookingCancelled`)
- Originated in the DDD community; related to state machine replication

### Command vs. Event

**Command**: An incoming request asking for a change. Must be validated; can be rejected.

**Event**: A fact recording that something already happened. Once in the log, consumers cannot reject it.

Validation happens before the event is appended; the log contains only valid events.

### CQRS (Command Query Responsibility Segregation)

**Definition**: The principle of maintaining separate read-optimized representations and deriving them from the write-optimized representation (the event log).

- Write model = the event log (optimized for appends)
- Read models = materialized views (optimized for queries)
- The two sides can use entirely different data models and storage engines

### Materialized View / Projection / Read Model

**Definition**: A query-optimized representation built by processing events from the log in order.

- Multiple views can exist for one log, each tuned to a query pattern
- Can be denormalized, in-memory, or stored in any database
- Must be reproducible: deleting and recomputing yields the same result
- Consumers must process events in the exact log order

### DataFrame

**Definition**: A tabular data model supporting bulk relational-like operators (filter, group, aggregate, merge), manipulated through a series of imperative commands rather than a declarative query.

- Used for data exploration, statistics, ML feature prep, visualization
- Often a private, local copy of the dataset is wrangled, then shared
- Bridge between relational tables and numeric matrices

### Sparse Matrix / Array

**Definition**: A multidimensional numeric array where most entries are absent (sparse) or filled (dense).

- Many ML algorithms expect matrix input
- DataFrames pivot relational data into matrix form
- Non-numeric values converted via scaling (dates) or one-hot encoding (categories)

### Array Database

**Definition**: A database specialized for large multidimensional numeric arrays (e.g., TileDB).

- Used for geospatial raster data, medical imaging, telescope observations

## Terminology

| Term | Definition |
|------|------------|
| Event | Immutable past-tense fact appended to the log |
| Command | Incoming request that may be accepted or rejected |
| Projection | A read model derived from the event log |
| Snapshot | Cached intermediate state to avoid full log replay (implied) |
| Crypto-shredding | Deleting an encryption key to render encrypted personal data unreadable |
| One-hot encoding | Encoding a categorical value as a vector of 0s with one 1 |
| Pivot | Reshaping rows-as-records into a matrix layout |

## How It Relates To

- **Star schemas**: Both event logs and fact tables collect past events, but fact tables share one schema and are unordered; event logs have many event types and require ordering.
- **CDC (Change Data Capture)**: CDC derives an event-like stream from an existing mutable database; event sourcing makes the event log the primary source of truth (covered in another skill).
- **Stream processing**: Kafka + stream processors are a common substrate for event-sourced systems (Chapter 12 territory).
- **Schema evolution**: Append-only events make adding new event types or new fields easy; old events stay unmodified.

## Common Misconceptions

- **Myth**: Event sourcing is the same as CDC.
  **Reality**: CDC reverse-engineers events from a mutable DB; event sourcing makes the event log the system of record.

- **Myth**: A DataFrame is just an in-memory SQL table.
  **Reality**: DataFrames support matrix-style operations and imperative wrangling that go far beyond SQL.

- **Myth**: Materialized views must be persistent.
  **Reality**: A view can be in-memory only and rebuilt from the log on restart.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Event log | Append-only sequence of immutable, ordered events |
| Event sourcing | Events are the source of truth |
| CQRS | Separate write-optimized log from read-optimized views |
| Projection | Derived read model rebuilt by replaying events |
| Command | Request that may be validated and rejected |
| DataFrame | Tabular model wrangled imperatively, bridges to matrices |
| Sparse matrix | Mostly-empty numeric grid for ML inputs |
