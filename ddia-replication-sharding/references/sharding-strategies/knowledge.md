# Sharding Strategies Knowledge

Core concepts for partitioning data across nodes in distributed databases.

## Overview

Sharding (a.k.a. partitioning) splits a dataset across multiple nodes so each node holds only a subset. It is the primary tool for horizontal scaling when data volume or write throughput exceeds a single machine. The choice of strategy determines how evenly load is distributed, what queries remain efficient, and how painful rebalancing is.

## Key Concepts

### Sharding (Partitioning)

**Definition**: Splitting a large dataset into smaller subsets (shards/partitions) distributed across multiple nodes.

**Key points**:
- Solves write throughput and storage limits, not just read scaling (replication handles reads)
- Enables shared-nothing horizontal scale-out
- Adds complexity: cross-shard queries, distributed transactions, harder schema changes
- Avoid sharding until a single node truly cannot cope

### Shard / Partition

**Definition**: A subset of the dataset, owned by one node (or replica group). All records with the same partition key live in the same shard.

### Partition Key

**Definition**: The field whose value determines which shard a record lives in. In key-value stores it's usually the key; in relational stores, a chosen column (not necessarily the primary key).

The choice is hard to reverse and dictates which queries are fast (single-shard) versus slow (scatter-gather).

### Skew and Hot Spots

**Definition**: Skew = uneven distribution of data or load across shards. A *hot shard* / *hot spot* carries disproportionate load; a *hot key* is a single key under disproportionate load (e.g., celebrity user). Skew defeats the purpose of sharding by bottlenecking on one node.

### Rebalancing

**Definition**: Moving shards (or data within shards) between nodes to restore even load when nodes are added, removed, or skew develops.

A good algorithm minimizes data movement and keeps the system available during the move.

### Sharding Strategies

| Strategy | Mechanism | Use When |
|----------|-----------|----------|
| Key range | Each shard owns a contiguous key range | Range scans matter (e.g., timestamps) |
| Hash modulo N | shard = hash(key) % N | Almost never — catastrophic rebalancing |
| Fixed shards | Many shards (>> nodes), assign shards to nodes | Cluster size known, dataset size stable |
| Hash range | Range over hashed keys, splittable | Number of shards must adapt |
| Consistent hashing | Variant where new node steals roughly fair share from others | Frequent topology changes |

### Multitenancy

**Definition**: A SaaS pattern where each customer (tenant) has a self-contained dataset. Three common implementations:

- **Shared schema**: All tenants share tables; rows tagged with tenant_id
- **Schema-per-tenant**: One schema per tenant inside a shared database
- **Database-per-tenant (shard-per-tenant)**: Physically separate database per tenant

Sharding-by-tenant brings resource/permission/fault isolation, easier per-tenant backup, GDPR/CCPA delete, data residency, and gradual schema rollout.

### Hot Key / Celebrity Problem

**Definition**: A single partition key that receives orders of magnitude more traffic than others (e.g., a celebrity's user ID on a social network when they post). Even perfect hash distribution cannot help — all requests target one key, hence one shard.

Mitigation requires application-level help: salting the key, fan-out, or in-memory caching of hot reads.

### Cell-Based Architecture

**Definition**: Sharding extended above the data layer — services and storage for a tenant group are bundled into an isolated *cell*. A failure in one cell does not propagate to others (fault isolation).

## Terminology

| Term | Definition |
|------|------------|
| Shard / Partition | One subset of the dataset on one node group |
| Partition key | Field deciding shard placement |
| Skew | Uneven load distribution |
| Hot shard / hot spot | Shard with disproportionate load |
| Hot key | Single key driving most of a shard's load |
| Rebalancing | Moving shards across nodes to even out load |
| Pre-splitting | Configuring initial shard boundaries on an empty database |
| Salting | Appending randomness to a hot key to spread its writes |
| Consistent hashing | Hash-based assignment that minimizes data movement on topology changes |
| Heat management / adaptive capacity | Cloud DB feature that auto-isolates hot keys (e.g., DynamoDB) |

## How It Relates To

- **Replication**: Orthogonal — each shard is typically replicated. Sharding scales writes; replication scales reads and provides fault tolerance.
- **Secondary indexes**: Sharding makes secondary indexes hard (covered separately).
- **Distributed transactions**: Cross-shard writes require them and they're slow.
- **Request routing**: Once sharded, clients need to find the right node.

## Common Misconceptions

- **Myth**: Hash sharding eliminates hot spots.
  **Reality**: It eliminates hot *partitions* from skewed *keys*, not hot *keys*. A celebrity user is still one key, still one shard.

- **Myth**: "Consistent hashing" relates to ACID consistency.
  **Reality**: It refers to keys staying *consistently* in the same shard across topology changes.

- **Myth**: More shards always help.
  **Reality**: Too many shards means high overhead per shard; too few means expensive splits. There's a "just right" size (typically GB-scale).

- **Myth**: Sharding is always needed at scale.
  **Reality**: A single beefy node handles a lot. Replication often solves read scaling without sharding's complexity.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Sharding | Split dataset across nodes for write/storage scale |
| Range sharding | Contiguous key ranges per shard, great for scans, prone to write hot spots |
| Hash sharding | Even key distribution, kills range queries on the partition key |
| Fixed shards | More shards than nodes; rebalance by reassigning whole shards |
| Consistent hashing | Topology change moves the minimum data possible |
| Hot key | One key, one shard, no escape without app-level salting |
| Multitenancy sharding | One shard (or DB) per tenant for isolation |
