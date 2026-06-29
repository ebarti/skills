# Designing Sharding Scheme Workflow

Choose a partition key, sharding strategy, rebalancing approach, and routing layer that match the workload — without painting yourself into a corner.

## When to Use

- Designing a new sharded data system
- Re-evaluating partitioning after observing hot spots, scaling pain, or skew
- Onboarding a new tenant tier; justifying a sharding choice in an architecture review

## Prerequisites

- Workload profile: read/write ratio, dominant access patterns, top queries
- Data volume + growth rate, write throughput target
- Cardinality and distribution estimates for candidate keys
- Tenancy / isolation / compliance requirements (GDPR, residency)

**Reference**: `references/sharding-strategies/rules.md`, `references/routing-and-secondary-indexes/rules.md`

---

## Workflow Steps

### Step 1: Decide If Sharding Is Needed

**Goal**: Avoid the complexity tax until a single node truly cannot cope.

- [ ] Confirm dataset / write throughput exceeds one beefy node
- [ ] Rule out replication-only fix for read scaling and vertical scale-up
- [ ] Accept that the partition key will be hard to change

**Ask**: "What single-node bottleneck am I hitting — storage, write IOPS, or CPU?"

**Reference**: `references/sharding-strategies/rules.md` (Rule 1)

---

### Step 2: Identify Partition Key Candidates

**Goal**: Find a key that is high-cardinality, evenly accessed, and co-locates records read together.

- [ ] List the 5 most frequent / latency-critical queries; note filter fields
- [ ] Rank candidates by cardinality (millions+, not tens)
- [ ] Eliminate skewed-access keys (raw timestamp, country code, status enum)
- [ ] Verify records read together share the candidate key

**Reference**: `references/sharding-strategies/rules.md` (Rule 2)

---

### Step 3: Choose Sharding Strategy

**Goal**: Pick range, hash, fixed shards, or consistent hashing per access pattern.

- [ ] Range scans matter → **range sharding** (composite key, time as sort component)
- [ ] Exact-key lookups only → **hash sharding** (lose range queries)
- [ ] Stable cluster, bounded dataset → **fixed shards** (e.g., 1000 shards / 10 nodes)
- [ ] Frequent topology changes → **consistent hashing / hash range**
- [ ] Reject `hash(key) % N` outright (catastrophic rebalancing)

**Reference**: `references/sharding-strategies/rules.md` (Rules 3–6)

---

### Step 4: Detect and Mitigate Hot Spots

**Goal**: Address skewed keys that no even-distribution algorithm can save.

- [ ] List known celebrity / fat-tail keys (top users, tenants, SKUs)
- [ ] Identify time-based skew (writes all going to "today")
- [ ] Read-hot key → front with cache (Redis/Memcached)
- [ ] Write-hot key → salt the key + scatter-gather reads, OR per-key write queue
- [ ] Range schemes → isolate hot key on its own shard
- [ ] Consider DBs with auto heat management (DynamoDB adaptive capacity)

**Ask**: "If our biggest 1% of users 10x their activity tomorrow, what happens?"

**Reference**: `references/sharding-strategies/rules.md` (Rule 8)

---

### Step 5: Plan Rebalancing Strategy

**Goal**: Ensure adding/removing nodes does not move most of the data.

- [ ] Confirm strategy is fixed shards OR consistent hashing (never mod-N)
- [ ] Pick a shard count divisible by many factors (240, 1024); aim GB-scale shards
- [ ] Manual vs automatic — prefer human-in-the-loop in prod
- [ ] Rate-limit data movement; pre-emptively rebalance for known load events

**Reference**: `references/sharding-strategies/rules.md` (Rules 5, 6, 9)

---

### Step 6: Design Secondary Indexes

**Goal**: Decide local vs global SIs based on read/write balance.

- [ ] Writes dominate / queries usually include partition key → **local (document-partitioned)** SI (cheap write, scatter-gather read)
- [ ] Reads dominate / queries filter by SI alone → **global (term-partitioned)** SI (cheap read, multi-shard write)
- [ ] For global SIs, pick consistency: distributed txn (sync, slow) or async (fast, stale)
- [ ] Document whether SI reads can lag

**Reference**: `references/routing-and-secondary-indexes/rules.md` (Rules 4–6)

---

### Step 7: Design the Routing Approach

**Goal**: Pick how clients find the right shard, matching ops maturity.

- [ ] **Forwarding + gossip** (Cassandra, Riak): simplest; extra hop on misroute
- [ ] **Routing tier / proxy** (mongos, moxi): clean separation; extra component
- [ ] **Partition-aware client**: best latency; client tracks shard map
- [ ] Use ZooKeeper / etcd / Raft for the authoritative shard map (gossip only when DB is leaderless)
- [ ] Plan cutover: forward in-flight requests OR return "moved" for client retry
- [ ] DNS for stable node addresses; coordinator for the fast-changing shard map

**Reference**: `references/routing-and-secondary-indexes/rules.md` (Rules 1–3, 8)

---

### Step 8: Plan Multitenancy Strategy (If Applicable)

**Goal**: Match isolation level to cost, compliance, and noisy-neighbor risk.

- [ ] Many tiny tenants, lowest cost → **shared schema with tenant_id column**
- [ ] Moderate isolation, per-tenant backup → **schema-per-tenant**
- [ ] Strong isolation, GDPR delete, residency → **database-per-tenant** (or cell)
- [ ] Don't put noisy or untrusted tenants on shared infrastructure; shard *within* very large tenants

**Reference**: `references/sharding-strategies/rules.md` (Rule 7)

---

### Step 9: Document Scheme + Scaling Plan

**Goal**: Make the design and growth path explicit for reviewers and on-call.

- [ ] Record partition key, strategy, shard count, and target shard size
- [ ] Document rebalancing trigger / procedure, known hot keys + mitigations
- [ ] Document SI type + consistency contract; routing approach + coordinator
- [ ] List failure scenarios the design tolerates (and which it doesn't)

---

## Quick Checklist

```
[ ] 1: Sharding actually needed (not single-node-fixable)
[ ] 2: Partition key chosen (cardinality + access pattern)
[ ] 3: Strategy chosen (range / hash / fixed / consistent — never mod-N)
[ ] 4: Hot-spot mitigations planned (cache, salt, isolate)
[ ] 5: Rebalancing plan written (fixed shards or consistent hashing)
[ ] 6: SI type + consistency contract decided
[ ] 7: Routing approach + shard-map coordinator chosen
[ ] 8: Multitenancy strategy chosen (if SaaS)
[ ] 9: Scheme + scaling plan documented
```

## Decision Tree: Query Pattern → Strategy

```
Need range scans on the partition key (e.g., time series)?
  yes -> Range sharding (composite key; push time into sort component, NOT partition)
  no  -> Need exact-key lookups + even distribution?
           yes -> Cluster size stable, dataset bounded?
                    yes -> Fixed shards (>> nodes; reassign whole shards on add)
                    no  -> Consistent hashing / hash range (Cassandra, DynamoDB)
           no  -> Reconsider Step 2; the key probably doesn't match access pattern
```

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| `hash(key) % N` for shard assignment | Adding a node remaps nearly every key | Fixed shards or consistent hashing; map shards → nodes separately |
| Raw timestamp as partition key | All writes hit "today's" shard | Composite key; high-cardinality field as partition, time as sort |
| `user_id` as key with celebrity users | One key, one shard, hashing can't help | Salt hot keys + cache reads; consider auto heat management |
| Sharding too early | Permanent complexity for no benefit | Scale up, then replicate reads, then shard |
| Too few shards | Expensive splits when growing | Pick count divisible by many factors (240, 1024) |
| Auto-rebalance + auto-failure detection | Cascading failure: slow → dead → load shifts → neighbor dead | Human-in-the-loop in prod; rate-limit movement |
| Splitting a hot shard | The split itself piles more load on it | Pre-split or isolate the hot key first |
| Global SI in write-heavy workload | Every write fans out across SI shards | Use local SI; accept scatter-gather for rare SI-only reads |
| Rolling your own SI in app code | Race conditions desync index from primary | Use DB-native SI, or wrap in multi-object transactions |
| Treating "consistent hashing" as ACID | Name collision; unrelated concept | It refers to keys staying in same shard across topology changes |

## Exit Criteria

Task is complete when partition key + strategy are chosen and justified, hot-key mitigations and rebalancing plan are written, SI type + consistency contract are published, routing approach + shard-map coordinator are documented, and multitenancy isolation matches compliance needs.

## Cross-References

- `references/sharding-strategies/{rules,knowledge}.md`, `references/routing-and-secondary-indexes/{rules,knowledge}.md`
- `workflows/choosing-replication-topology.md` (sharding and replication are orthogonal — each shard is typically replicated)
- Other skill: `ddia-transactions-consistency` — cross-shard distributed transactions
