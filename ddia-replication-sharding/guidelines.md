# DDIA Replication & Sharding Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use**: Find your situation below, then load ONLY the listed files. Most tasks need 1-3 files.

---

## Workflows

| Task | Workflow |
|------|----------|
| Choose replication topology (single-leader, multi-leader, leaderless) | `workflows/choosing-replication-topology.md` |
| Design a sharding scheme (key, strategy, hot-spot mitigation) | `workflows/designing-sharding-scheme.md` |
| Handle write conflicts (LWW, CRDT, OT, manual) | `workflows/handling-replication-conflicts.md` |

---

## By Task

### Replication Design

| What you're doing | Load these files |
|-------------------|------------------|
| Choosing single-leader vs multi-leader vs leaderless | `workflows/choosing-replication-topology.md` (then `single-leader-replication/knowledge.md`, `multi-leader-replication/knowledge.md`, `leaderless-replication/knowledge.md`) |
| Sync vs async replication, semi-synchronous setup | `single-leader-replication/knowledge.md`, `single-leader-replication/rules.md` |
| Handling replication lag (read-your-writes, monotonic reads) | `single-leader-replication/rules.md`, `single-leader-replication/examples.md` |
| Failover plan for a leader-based DB | `single-leader-replication/knowledge.md`, `single-leader-replication/rules.md` |
| Multi-region active/active deployment | `multi-leader-replication/knowledge.md`, `multi-leader-replication/rules.md` |
| Quorum sizing (n, w, r) for a Dynamo-style store | `leaderless-replication/knowledge.md`, `leaderless-replication/rules.md` |

### Conflict Strategy

| What you're doing | Load these files |
|-------------------|------------------|
| Choosing a conflict resolution approach | `workflows/handling-replication-conflicts.md` (then `conflict-resolution/knowledge.md`, `conflict-resolution/rules.md`) |
| Implementing avoidance via leader pinning | `conflict-resolution/rules.md`, `multi-leader-replication/rules.md` |
| Choosing LWW vs CRDT vs OT | `workflows/handling-replication-conflicts.md` (then `conflict-resolution/knowledge.md`, `conflict-resolution/examples.md`) |
| Designing for concurrent edits (collaborative apps) | `conflict-resolution/knowledge.md`, `multi-leader-replication/knowledge.md` |
| Detecting concurrency with vector clocks | `leaderless-replication/knowledge.md`, `conflict-resolution/knowledge.md` |

### Sharding Design

| What you're doing | Load these files |
|-------------------|------------------|
| Choosing range vs hash partitioning | `workflows/designing-sharding-scheme.md` (then `sharding-strategies/knowledge.md`, `sharding-strategies/rules.md`) |
| Picking a partition key | `workflows/designing-sharding-scheme.md` (then `sharding-strategies/rules.md`, `sharding-strategies/examples.md`) |
| Mitigating hot keys / celebrity problem | `workflows/designing-sharding-scheme.md` (then `sharding-strategies/knowledge.md`, `sharding-strategies/rules.md`) |
| Multi-tenant sharding (per-customer) | `workflows/designing-sharding-scheme.md` (then `sharding-strategies/knowledge.md`, `sharding-strategies/examples.md`) |
| Planning rebalancing strategy | `workflows/designing-sharding-scheme.md` (then `sharding-strategies/rules.md`, `sharding-strategies/examples.md`) |

### Index Design (Sharded Systems)

| What you're doing | Load these files |
|-------------------|------------------|
| Routing a client to the right shard | `routing-and-secondary-indexes/knowledge.md`, `routing-and-secondary-indexes/rules.md` |
| Local secondary index (document-partitioned) | `routing-and-secondary-indexes/knowledge.md`, `routing-and-secondary-indexes/examples.md` |
| Global secondary index (term-partitioned) | `routing-and-secondary-indexes/knowledge.md`, `routing-and-secondary-indexes/rules.md` |
| Choosing between scatter-gather vs term-partitioned | `routing-and-secondary-indexes/rules.md`, `routing-and-secondary-indexes/examples.md` |

---

## By Problem/Symptom

| If you notice... | Load these files |
|------------------|------------------|
| Reads see stale data after a recent write | `single-leader-replication/knowledge.md` (lag section), `leaderless-replication/knowledge.md` (quorum section) |
| Same record getting overwritten / lost updates | `conflict-resolution/knowledge.md`, `conflict-resolution/rules.md` |
| Hot key / celebrity problem (one shard saturated) | `sharding-strategies/knowledge.md`, `sharding-strategies/rules.md` |
| Multi-region write latency too high | `multi-leader-replication/knowledge.md`, `multi-leader-replication/rules.md` |
| Offline-first app needs sync after reconnect | `multi-leader-replication/knowledge.md` (sync engines), `conflict-resolution/knowledge.md` |
| Need to find data by non-key field at scale | `routing-and-secondary-indexes/knowledge.md`, `routing-and-secondary-indexes/rules.md` |
| Cassandra / DynamoDB / Riak modeling | `leaderless-replication/knowledge.md`, `sharding-strategies/knowledge.md` |
| PostgreSQL / MySQL replica setup | `single-leader-replication/knowledge.md`, `single-leader-replication/rules.md` |
| Failover caused data loss | `single-leader-replication/rules.md`, `single-leader-replication/examples.md` |
| Write conflicts on concurrent edits | `conflict-resolution/knowledge.md`, `conflict-resolution/examples.md` |
| Rebalancing causes load spikes | `sharding-strategies/rules.md`, `sharding-strategies/examples.md` |
| Quorum reads still see stale values | `leaderless-replication/knowledge.md`, `leaderless-replication/rules.md` |

---

## Decision Tree

### Replication Strategy

```
Need to replicate data?
├─► Single primary write source acceptable?
│   ├─► Yes → single-leader-replication/
│   │   ├─► Need read-your-writes / strong reads → single-leader-replication/rules.md (lag section)
│   │   └─► Failover concerns → single-leader-replication/rules.md
│   └─► No, multiple writers needed
│       ├─► Across regions or offline devices → multi-leader-replication/
│       │   └─► Concurrent writes will conflict → conflict-resolution/
│       └─► Want no leader, high availability → leaderless-replication/
│           └─► Tune (n, w, r) → leaderless-replication/rules.md
```

### Sharding Strategy

```
Need to shard?
├─► Range queries on partition key common?
│   ├─► Yes → range partitioning → sharding-strategies/knowledge.md
│   │   └─► Risk of hot ranges (timestamps) → sharding-strategies/rules.md
│   └─► No → hash partitioning → sharding-strategies/knowledge.md
│       └─► Hot key on one value → sharding-strategies/rules.md (key splitting)
│
├─► Need to query by non-key field?
│   ├─► Local (per-shard) is enough → routing-and-secondary-indexes/ (document-partitioned)
│   └─► Need fast global lookup → routing-and-secondary-indexes/ (term-partitioned)
│
└─► How does the client find the right shard?
    └─► routing-and-secondary-indexes/knowledge.md (Request Routing)
```

---

## File Index

Complete list of all 18 knowledge files:

### Single-Leader Replication
| File | Purpose |
|------|---------|
| `single-leader-replication/knowledge.md` | Leader/follower roles, sync vs async, replication log formats, failover |
| `single-leader-replication/rules.md` | When to use, lag mitigation, semi-sync, failover safety |
| `single-leader-replication/examples.md` | Read-your-writes patterns, replica setup, failover scenarios |

### Multi-Leader Replication
| File | Purpose |
|------|---------|
| `multi-leader-replication/knowledge.md` | Geo-distributed leaders, sync engines, topologies (star, ring, all-to-all) |
| `multi-leader-replication/rules.md` | When multi-leader is appropriate, schema change pitfalls, topology choice |
| `multi-leader-replication/examples.md` | Multi-region setups, offline-capable clients, sync engine patterns |

### Conflict Resolution
| File | Purpose |
|------|---------|
| `conflict-resolution/knowledge.md` | Avoidance, LWW, CRDTs, OT, manual merge, concurrency definition |
| `conflict-resolution/rules.md` | Picking a strategy, avoiding silent data loss, custom resolvers |
| `conflict-resolution/examples.md` | LWW pitfalls, CRDT use, on-read vs on-write resolution |

### Leaderless Replication
| File | Purpose |
|------|---------|
| `leaderless-replication/knowledge.md` | Dynamo model, quorum (n, w, r), read repair, sloppy quorums, hinted handoff |
| `leaderless-replication/rules.md` | Quorum sizing, when leaderless fits, anti-entropy maintenance |
| `leaderless-replication/examples.md` | Cassandra/Riak patterns, vector clock usage, sibling resolution |

### Sharding Strategies
| File | Purpose |
|------|---------|
| `sharding-strategies/knowledge.md` | Partition key, range vs hash, hot spots, rebalancing approaches |
| `sharding-strategies/rules.md` | Choosing partition key, mitigating hot keys, rebalancing safely |
| `sharding-strategies/examples.md` | Multi-tenant sharding, key splitting, fixed vs dynamic partition counts |

### Routing & Secondary Indexes
| File | Purpose |
|------|---------|
| `routing-and-secondary-indexes/knowledge.md` | Request routing approaches, document- vs term-partitioned indexes |
| `routing-and-secondary-indexes/rules.md` | Routing tier vs partition-aware client, index sharding tradeoffs |
| `routing-and-secondary-indexes/examples.md` | ZooKeeper coordination, scatter-gather queries, global SI patterns |

---

## Common Combinations

Frequently used together:

| Scenario | Files to load |
|----------|---------------|
| Designing a Postgres read-replica setup | `single-leader-replication/knowledge.md` + `single-leader-replication/rules.md` |
| Building an offline-first mobile app | `multi-leader-replication/knowledge.md` + `conflict-resolution/knowledge.md` |
| Bootstrapping a Cassandra schema | `leaderless-replication/knowledge.md` + `sharding-strategies/knowledge.md` |
| DynamoDB single-table design | `sharding-strategies/knowledge.md` + `routing-and-secondary-indexes/knowledge.md` |
| Multi-region active/active rollout | `multi-leader-replication/knowledge.md` + `multi-leader-replication/rules.md` + `conflict-resolution/rules.md` |
| Diagnosing a hot shard | `sharding-strategies/knowledge.md` + `sharding-strategies/rules.md` |
| Sharding a relational DB | `sharding-strategies/rules.md` + `routing-and-secondary-indexes/rules.md` |
