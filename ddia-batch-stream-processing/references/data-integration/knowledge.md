# Data Integration Knowledge

Core concepts for combining specialized data tools by deriving data from a common source.

## Overview

No single piece of software satisfies every data access pattern. Real applications cobble together OLTP databases, search indexes, caches, analytics warehouses, ML pipelines, and notification systems. Data integration is the discipline of getting the same data into all the right places, in the right formats, consistently.

## Key Concepts

### Data Integration

**Definition**: The practice of consuming inputs and routing them to multiple specialized systems (search, cache, analytics, ML, notifications) so each tool can serve the access pattern it does best.

**Key points**:
- Driven by the fact that each tool is designed for a particular usage pattern
- Becomes harder as the number of representations of the same data grows
- Solved either via distributed transactions or by deriving data from a single source

### Derived Data

**Definition**: Data computed from a source-of-truth dataset through a deterministic, repeatable process — search indexes, caches, materialized views, recommendations, aggregate metrics.

**Key points**:
- Outputs of batch and stream processors
- Can always be rebuilt by re-running the derivation against the source
- Updated asynchronously, so reads may lag the source
- Derivation steps are typically deterministic and idempotent — easy to recover from faults

### Source-of-Truth Dataset

**Definition**: The single authoritative store (often an event log via CDC or event sourcing) that decides the order of all writes and feeds every other system.

**Key points**:
- All user input funnels through it before fanning out
- Provides a total order that downstream consumers replay deterministically
- Application of state machine replication

### Fan-Out Architecture

**Definition**: One ordered event log feeding many derived data systems (database, search index, cache, warehouse, ML feature store) in parallel via stream processors.

**Key points**:
- Each consumer maintains its own derived state
- Faults in one sink stay local — they don't abort writes to others
- New sinks can be added later by replaying history

### Total Order vs Causal Order

**Total order**: Every event has a globally agreed position. Achievable with a single-leader log; equivalent to consensus (total order broadcast).

**Causal order**: Only events with a happens-before relationship are ordered. Concurrent events may be ordered arbitrarily.

**Key points**:
- Total order requires routing all events through one node — limits throughput
- Sharded, multi-region, microservice, and offline-client systems break total order
- Causal order is sufficient when there are no cross-event dependencies

### Lambda Architecture

**Definition**: An early dual-pipeline design with a batch layer (slow, accurate, reprocessable historical view) and a speed layer (fast, approximate, recent events), merged at a serving layer.

**Key points**:
- Has fallen out of use due to operational cost of maintaining two pipelines
- Two codebases must produce equivalent outputs — duplication and drift

### Kappa Architecture

**Definition**: A stream-only architecture that handles both real-time and historical reprocessing by replaying the event log through the same stream engine.

**Key points**:
- Single codebase, single engine
- Requires replayable log (Kafka), exactly-once semantics, and event-time windowing
- Apache Beam, Flink, and Google Dataflow embody this pattern

## Terminology

| Term | Definition |
|------|------------|
| CDC | Change Data Capture — extracts ordered change events from a database |
| Event sourcing | Application stores events as the primary source instead of mutable state |
| State machine replication | Apply same writes in same order to many replicas, all reach same state |
| Total order broadcast | Equivalent to consensus; single agreed order for all events |
| Logical timestamp | Provides ordering without coordination (e.g. Lamport, vector clocks) |
| Exactly-once semantics | Output equals what would have been produced with no faults |
| Reprocessing | Replaying historical events to derive new views or fix old derivations |

## How It Relates To

- **Stream processing**: The engine that maintains derived state from the event log
- **Batch processing**: Used for reprocessing historical data and bootstrapping new views
- **Distributed transactions (XA, 2PC)**: The alternative — atomic cross-system commits, but poor fault tolerance and performance
- **Idempotence**: Why log-based derivation tolerates retries and recovers from faults

## Common Misconceptions

- **Myth**: Distributed transactions are the only way to keep data systems consistent.
  **Reality**: Log-based derived data achieves consistency through deterministic replay and idempotence — without atomic commits.

- **Myth**: A single Kafka topic with one partition scales forever.
  **Reality**: Total ordering bottlenecks on a single node. Sharding, geo-distribution, microservices, and offline clients all break total order.

- **Myth**: Lambda architecture is the modern way to combine batch and stream.
  **Reality**: It has fallen out of use — kappa-style unified engines (Beam, Flink) replaced it.

- **Myth**: Derived data is "stale" and therefore worse than the source.
  **Reality**: Asynchrony is what makes the system robust — it contains failures locally instead of amplifying them across all participants.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Data integration | Routing data to many specialized tools |
| Derived data | Recomputable views from a source-of-truth dataset |
| Fan-out | One event log → many derived sinks |
| Total order | Globally agreed sequence; needs single-leader |
| Causal order | Only happens-before pairs ordered; scales further |
| Lambda | Batch + speed layers, two codebases (legacy) |
| Kappa | One stream engine handles real-time and replay |
