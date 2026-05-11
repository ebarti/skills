# Multi-Leader Replication Knowledge

Core concepts for replication architectures where multiple nodes accept writes.

## Overview

Multi-leader replication (also *active/active* or *bidirectional*) extends single-leader replication by allowing more than one node to accept writes. Each leader simultaneously acts as a follower to the other leaders, asynchronously propagating its writes. It is most useful for multi-region deployments and for offline-capable client apps where each device is itself a replica.

## Key Concepts

### Multi-Leader Replication

**Definition**: A replication architecture where multiple nodes ("leaders") each accept writes and asynchronously forward those writes to all other leaders.

**Key points**:
- Each leader acts as both a writer and a follower of the others
- Replication is almost always asynchronous (synchronous reduces to single-leader)
- Used across regions, devices, or browser tabs

### Geographically Distributed (Geo-Replicated) Operation

**Definition**: A deployment with replicas spread across multiple regions, often with one leader per region, replicating asynchronously between regions.

**Key points**:
- Hides inter-region latency from local users
- Each region keeps writing during inter-region network problems
- Each region can survive failure of other regions

### Sync Engine

**Definition**: A library that captures local edits, replicates them to other replicas (devices, browser tabs, or servers), and merges remote changes into the local copy.

**Key points**:
- Treats network as a background process; UI reads/writes local state
- Supports both real-time collaboration and offline editing
- Pioneered by Lotus Notes; modern examples: Replicache, Yjs, Automerge

### Offline-First Software

**Definition**: An app that lets users continue editing while disconnected; changes sync when connectivity returns.

**Key points**:
- Local replica acts as a leader during disconnection
- Replication lag may be hours or days
- "Being offline is the same as having a very large network delay"

### Local-First Software

**Definition**: Offline-first software that also keeps working if the original developer shuts down all online services, typically via an open sync protocol with multiple providers.

**Key points**:
- Requires open standard sync protocol
- Example: Git (works with GitHub, GitLab, self-hosted, etc.)
- Stronger guarantee than offline-first alone

### Replication Topology

**Definition**: The graph of communication paths along which writes propagate between leaders.

**Key points**:
- With 2 leaders, only one topology is possible (bidirectional)
- With 3+ leaders, choices appear: circular, star, all-to-all (mesh)
- Loops are prevented by tagging each write with the IDs of nodes it has visited

## Topologies

| Topology | Shape | Pros | Cons |
|----------|-------|------|------|
| Circular | Each node forwards to one neighbor | Simple, low fan-out | Single node failure breaks the ring |
| Star | One root forwards to all others (generalizes to tree) | Simple, predictable | Root is a SPOF |
| All-to-all (mesh) | Every leader sends to every other leader | Fault-tolerant; multiple paths | Causality bugs from out-of-order delivery |

## Terminology

| Term | Definition |
|------|------------|
| Active/active | Synonym for multi-leader; every leader actively serves writes |
| Bidirectional replication | Two-leader case where each forwards writes to the other |
| Geo-distributed / geo-replicated | Deployment spanning multiple regions |
| Sync engine | Library managing local-first replication and merge |
| Netcode | Game-development equivalent of a sync engine |
| Reactive programming | UI model that re-renders as local state changes (pairs well with sync engines) |

## How It Relates To

- **Single-leader replication**: Multi-leader is a generalization; synchronous multi-leader collapses back to single-leader
- **Conflict resolution**: Concurrent writes on different leaders create conflicts; see `conflict-resolution/`
- **Leaderless replication**: Another way to allow writes anywhere, but without designated leaders
- **Causality and version vectors**: Needed to order causally related writes across leaders
- **Consistent prefix reads**: Same family of causality problems that arise here

## Common Misconceptions

- **Myth**: Multi-leader gives you the same consistency as single-leader, just faster.
  **Reality**: Consistency is much weaker; you cannot guarantee uniqueness or non-negative balances across leaders.

- **Myth**: Multi-leader within a single datacenter is a good way to scale writes.
  **Reality**: Inside one region the added complexity rarely outweighs the benefits.

- **Myth**: Timestamps are enough to order writes across leaders.
  **Reality**: Clocks drift; use version vectors for causal ordering.

- **Myth**: Real-time collab apps are special; they aren't really multi-leader.
  **Reality**: Each browser tab editing the file is itself a leader replica.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Multi-leader | Multiple nodes accept writes and async replicate to each other |
| Geo-distributed | One leader per region; local writes, async cross-region sync |
| Sync engine | Library that makes local state the source of truth and syncs in background |
| Offline-first | App keeps working while disconnected |
| Local-first | Offline-first + survives the vendor going away |
| All-to-all topology | Most resilient; vulnerable to causality bugs |
| Circular/star topology | Simple but contain single points of failure |
