# Sharding Strategies Rules

Decision guidance for choosing and operating a partitioning scheme.

## Core Rules

### 1. Don't shard until you have to

Sharding adds permanent complexity (cross-shard queries, distributed transactions, harder migrations). A single modern machine handles a lot of traffic.

- If the problem is read throughput, scale reads with replicas first
- If write throughput or data volume exceeds one node, then shard
- Once you shard, the partition key is hard to change

### 2. Choose the partition key for your access pattern

The partition key dictates which queries are fast (single-shard) versus slow (scatter across all shards).

- Co-locate records that are read together under one partition key
- Pick a key with high cardinality and roughly even access
- Avoid keys that concentrate writes on one shard (e.g., raw timestamp)

### 3. Use range sharding when range scans matter

Key-range sharding keeps keys sorted within each shard, so range queries are efficient.

- Good fit: time-series with `(sensor_id, timestamp)` composite key
- Bad fit: raw timestamp as partition key — all writes go to "this month's" shard
- If you need range queries, push the time dimension into the *sort key*, not the partition key

### 4. Use hash sharding when even distribution matters more than scans

Hashing turns skewed input keys into evenly distributed slots — at the cost of losing range query efficiency on the partition key.

- Good fit: tenant_id, user_id where you read records by exact key
- Bad fit: any workload that scans across the partition key
- You can still range-query on *secondary* columns of a composite key within one shard

### 5. Avoid `hash(key) % N` for shard assignment

Mod-N is the textbook trap: changing N moves nearly every key, causing catastrophic rebalancing.

```text
# Bad — adding one node remaps almost all keys
shard = hash(key) % num_nodes

# Good — fixed shard count, then map shards to nodes separately
shard = hash(key) % num_shards   # num_shards >> num_nodes, never changes
node = shard_to_node[shard]      # cheap to update
```

### 6. Pick fixed shards or consistent hashing instead of mod-N

Both schemes minimize data movement on topology changes:

- **Fixed shards**: Create many more shards than nodes (e.g., 1,000 shards / 10 nodes). Add a node → reassign whole shards. Used by Citus, Riak, Elasticsearch, Couchbase.
- **Hash-range / consistent hashing**: Number of shards adapts to data volume. Used by Cassandra, ScyllaDB, DynamoDB, YugabyteDB.

### 7. Pick the multitenancy isolation level deliberately

Higher isolation means more cost and operational overhead:

| Need | Strategy |
|------|----------|
| Many tiny tenants, lowest cost | Shared schema with tenant_id column |
| Moderate isolation, easier per-tenant backup | Schema-per-tenant |
| Strong perf/security isolation, GDPR delete, data residency | Database-per-tenant (or cell) |

- Don't put noisy or untrusted tenants on shared infrastructure
- Compliance (GDPR/CCPA delete, data residency) almost forces db-per-tenant
- For very large tenants, shard *within* the tenant too

### 8. Combat hot keys at the application layer

Even-distribution algorithms cannot help a single hot key. Choose:

- **Salt the key**: append a random suffix (`key + ":" + rand(0..99)`) to spread *writes*. Reads must scatter-gather; only do this for known hot keys, with bookkeeping.
- **Cache reads**: front the hot key with an in-memory cache (Redis/Memcached) — usually the cheapest fix for read-hot keys
- **Fan out writes**: write to a per-key queue / aggregate, periodically materialize
- **Dedicate a shard / machine**: range-based schemes can isolate one hot key on its own shard
- **Use a DB with auto heat management**: DynamoDB adaptive capacity does this automatically

### 9. Be cautious with fully automatic rebalancing

Auto-rebalance + auto-failure-detection can cascade: a slow node is declared dead, load shifts, neighbors get overloaded, declared dead in turn.

- Prefer human-in-the-loop for production rebalancing (Couchbase/Riak suggest, admin commits)
- Pre-emptively rebalance for known load events (Cyber Monday, ticket release)
- If using auto-rebalancing, rate-limit data movement so it doesn't saturate the network

## Guidelines

- Aim for shard size in the GB range (HBase splits at 10 GB by default) — neither tiny nor huge
- Pick a shard count divisible by many factors (so nodes don't have to be a power of 2)
- Assign more shards to bigger machines for heterogeneous clusters
- Splitting a hot shard is dangerous: the split itself piles more load on it
- Keep the partition key simple — composite partition keys complicate routing

## Exceptions

- **Single-node "sharding"**: Redis, VoltDB, FoundationDB shard across CPU cores on one machine using one process per core
- **Analytics workloads**: Data warehouses (BigQuery, Snowflake, Delta Lake) shard differently — partitioning + cluster keys, queries fan out across shards by design
- **Tiny dataset**: If everything fits comfortably on one node, don't shard at all

## Quick Reference

| Rule | Summary |
|------|---------|
| Defer sharding | Single node first; replicate for reads |
| Partition key = access pattern | Co-locate what you read together |
| Range for scans | Composite key, time as sort component |
| Hash for evenness | Lose range queries on partition key |
| Never mod-N | Catastrophic rebalancing |
| Fixed shards or consistent hashing | Move minimum data on topology change |
| Multitenancy isolation = needs | Shared / schema / database per tenant |
| Hot key = app-level fix | Salt, cache, fan-out, isolate |
| Manual rebalance in prod | Avoid cascading-failure auto-loops |
