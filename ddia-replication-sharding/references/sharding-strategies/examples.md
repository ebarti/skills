# Sharding Strategies Examples

Real systems and concrete scenarios for each partitioning strategy.

## Real-World System Mappings

### Range Sharding

| System | Notes |
|--------|-------|
| HBase | Auto-split on 10 GB default; range-partitioned regions |
| Bigtable | Original design; tablets split by row-key range |
| MongoDB (range option) | Ranged sharding configurable |
| CockroachDB | Auto range-sharded |
| RethinkDB, FoundationDB | Auto range sharding |
| Vitess | Manual key-range sharding for MySQL |
| YugabyteDB | Both manual and automatic tablet splitting |

**Why pick range**: Range queries on the partition key are efficient (sorted within shards).

### Hash Modulo (avoid)

| System | Notes |
|--------|-------|
| Naive Memcached client configurations | Use `hash(key) % N` — adding/removing a node invalidates most cache entries |

**Why avoid**: Catastrophic rebalancing on topology change.

### Fixed-Shard (more shards than nodes)

| System | Notes |
|--------|-------|
| Couchbase | 1,024 vBuckets by default |
| Riak | Fixed ring of partitions |
| Voldemort | Fixed partition count, configured at cluster creation |
| Citus (PostgreSQL) | Fixed shard count, reassign shards to nodes |
| Elasticsearch | Fixed primary shards per index |

**Why pick fixed**: Cheap rebalancing — only assignment of shards to nodes changes, not the hash function. Limit: cannot have more nodes than shards.

### Consistent Hashing / Hash-Range

| System | Notes |
|--------|-------|
| Cassandra | 16 vnodes per node by default; hash-range with random boundaries |
| ScyllaDB | 256 vnodes per node by default |
| DynamoDB | Hash-range; automatic with adaptive capacity |
| Riak (originally) | Original ring-based consistent hashing |
| YugabyteDB | Hash-range option |
| MongoDB (hashed option) | Hashed shard key |

**Why pick consistent hashing**: Number of shards adapts to data volume; topology changes move minimum data.

## Hot Key Scenarios

### Twitter Celebrity / Social-Media Storm

**Scenario**: A celebrity with millions of followers posts. The action_id (or celebrity user_id) becomes a hot key — all followers' replies, likes, and reads target one shard.

**What goes wrong**:
- Hash sharding does not help (one key, one shard)
- Range sharding does not help either (still one key)
- That shard's node saturates while others sit idle

**Mitigations** (combine as needed):
- Read-heavy: front with in-memory cache (Redis), serve hot reads from cache
- Write-heavy: salt the key with a random suffix to spread writes across shards
- Fan-out / pre-aggregation: write into a per-celebrity buffer, periodically aggregate
- Dedicated shard / machine: range-based schemes can pin the hot key alone
- Use DynamoDB-class adaptive capacity that auto-isolates hot partitions

### Salting a Hot Key (Write-Side Fix)

**Before** — single hot key, one shard overwhelmed:

```text
key = "celebrity:123:likes"
db.incr(key)                # all writes hit one shard
total = db.get(key)         # one read
```

**After** — salt the key, spread writes across 100 keys:

```text
suffix = random.randint(0, 99)
key    = f"celebrity:123:likes:{suffix}"
db.incr(key)                # writes split across ~100 shards

# Reads now fan out:
total = sum(db.get(f"celebrity:123:likes:{i}") for i in range(100))
```

**Trade-offs**:
- Splits *write* load only; total *read* volume is unchanged
- Reads now scatter-gather across 100 keys
- Requires bookkeeping: which keys are salted, when to revert
- Apply only to known hot keys, not the entire keyspace

### Time-Series Hot Spot from Raw-Timestamp Key

**Bad** — partition key is just `timestamp`, so all live writes pile on the "current month" shard:

```text
PRIMARY KEY (timestamp)
# Every sensor's write right now -> shard for 2026-05
```

**Good** — composite key with `sensor_id` first puts writes across many shards:

```text
PRIMARY KEY (sensor_id, timestamp)
# Writes spread across all sensors; range scan per-sensor still works
# Trade-off: cross-sensor scan in a time window now requires per-sensor query
```

## Multitenancy Patterns

### Shared Schema (tenant_id column)

```sql
CREATE TABLE invoices (
  tenant_id  uuid NOT NULL,
  invoice_id uuid NOT NULL,
  amount     numeric,
  PRIMARY KEY (tenant_id, invoice_id)
);
-- shard by hash(tenant_id)
```

**Use when**: Many tiny tenants, low isolation requirements, cost-sensitive.
**Avoid when**: GDPR delete, noisy neighbors, strong isolation needed.

### Schema-Per-Tenant

```text
database "saas_prod"
  schema "tenant_acme"   -> tables: invoices, users, ...
  schema "tenant_globex" -> tables: invoices, users, ...
```

**Use when**: Easier per-tenant backup; moderate isolation.
**Catch**: Schema migrations multiply by tenant count.

### Database-Per-Tenant (Stripe-style isolation, Shopify-style scale)

```text
shard-1.db.example.com  -> tenants {acme, globex}
shard-2.db.example.com  -> tenants {initech}
shard-3.db.example.com  -> tenants {bigco-A through bigco-Z}
```

**Use when**:
- Strong perf/security isolation (Stripe-like requirements)
- GDPR/CCPA delete is a one-shot drop database
- Data residency: assign shard to required region
- One huge tenant gets its own dedicated cluster (cell-based architecture)

**Catch**:
- Tiny tenants are wasteful — pack many into one database
- Moving a growing tenant to its own shard is non-trivial
- Cross-tenant analytics requires federation

### Cell-Based Architecture (large SaaS)

Group services + storage for a tenant set into an isolated *cell*. AWS, Slack, and others use this pattern. A bug or overload in one cell does not affect tenants in other cells (fault isolation).

## Decision Quick Reference

| Workload | Strategy | Example System |
|----------|----------|----------------|
| Time-series with per-entity range scans | Range, composite key | HBase, Bigtable |
| Multitenant SaaS, isolation matters | Hash by tenant_id, db-per-tenant | Citus, Stripe-style |
| Key-value, even distribution, frequent topology changes | Consistent hashing | Cassandra, DynamoDB |
| Stable cluster size, cache or KV | Fixed shards | Couchbase, Riak |
| Single hot key (celebrity) | Salt + cache + (optional) dedicated shard | App-level fix |
