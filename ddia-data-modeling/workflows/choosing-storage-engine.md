# Choosing a Storage Engine Workflow

Pick the right storage engine family (LSM-tree, B-tree, in-memory, columnar) and a specific implementation by reasoning from workload, data volume, and access patterns — then plan amplification and compaction.

## When to Use

- Starting a new service and selecting its primary database
- Migrating an existing system that has outgrown its current engine
- Sizing infrastructure for a write-heavy or latency-sensitive feature
- Adding a new data store alongside an existing one (polyglot persistence)

## Prerequisites

- Rough estimate of read/write QPS and request mix
- Estimate of total dataset size today and 12-month growth
- Knowledge of dominant query patterns (point lookup, range scan, aggregate)
- Latency / durability SLOs

**Reference**: `references/oltp-storage/rules.md`, `references/oltp-storage/knowledge.md`

---

## Workflow Steps

### Step 1: Characterize the Workload

**Goal**: Decide whether the system is write-heavy, read-heavy, or balanced, and how strict latency must be.

- [ ] Estimate write QPS, read QPS, and ratio
- [ ] Classify reads: point lookup vs range scan vs full-table aggregate
- [ ] Define latency budget (p50, p99) for reads and writes
- [ ] Note durability requirement (sync fsync, async, replicated)

**Ask**: "If writes spike 10x, what breaks first — disk bandwidth, CPU, or read latency?"

**Reference**: `references/oltp-storage/rules.md` (Rules 1-2)

---

### Step 2: Estimate Data Volume

**Goal**: Decide whether the dataset can live in RAM or must spill to disk.

- [ ] Compute current dataset size including indexes
- [ ] Project 12- and 36-month growth
- [ ] Compare to single-node RAM budget (and replicated cluster RAM)
- [ ] Flag if dataset > RAM — in-memory is off the table for the primary store

**If dataset comfortably fits in RAM with growth headroom**: in-memory becomes viable.
**If not**: choose an on-disk family (LSM, B-tree, or columnar).

**Reference**: `references/oltp-storage/rules.md` (Rule 5)

---

### Step 3: Assess Range Query Needs

**Goal**: Determine whether sorted access matters.

- [ ] List the top 5 query patterns
- [ ] Mark each as point lookup, prefix range, or full scan + aggregate
- [ ] If many range queries: B-tree gives best predictability; LSM works but pays a multi-segment merge cost; columnar handles range scans well over compressed columns
- [ ] If aggregates dominate over many rows / few columns: this is OLAP — pivot to columnar (see `references/olap-storage/rules.md`)

---

### Step 4: Pick the Storage Engine Family

**Goal**: Select LSM, B-tree, in-memory, or columnar.

Use the decision tree:

```
What dominates?
├── Bulk scans + aggregates over many rows / few columns
│   └── Columnar
├── Single-row CRUD by key
│   ├── Dataset fits in RAM AND latency-critical
│   │   └── In-memory
│   ├── Writes dominate (ingest, time-series, append-mostly)
│   │   └── LSM-tree
│   └── Reads dominate OR predictable p99 needed OR many ranges OR transactions
│       └── B-tree
```

- [ ] Apply the tree using outputs from Steps 1-3
- [ ] Sanity-check: would the opposite choice be defensible? If yes, document why this one wins

**Reference**: `references/oltp-storage/rules.md` (Rules 1, 2, 5), `references/olap-storage/rules.md` (Rules 1-2)

---

### Step 5: Pick a Specific Engine

**Goal**: Map the family to a concrete implementation.

| Family | Common Choices |
|--------|----------------|
| LSM-tree | RocksDB (embedded), Cassandra, ScyllaDB, LevelDB, HBase |
| B-tree | PostgreSQL, MySQL/InnoDB, SQLite, LMDB, SQL Server |
| In-memory | Redis, Memcached, VoltDB, MemSQL/SingleStore |
| Columnar | Snowflake, BigQuery, ClickHouse, DuckDB, Parquet+Iceberg |

- [ ] Match operational model: managed service vs self-hosted vs embedded
- [ ] Check ecosystem fit: drivers, ORMs, replication, backup tools
- [ ] Confirm transactional semantics if needed (ACID, isolation level)
- [ ] Verify license and cost model

---

### Step 6: Plan Write/Read Amplification Budget

**Goal**: Avoid surprise disk and SSD wear costs.

- [ ] Estimate write amplification: LSM ~5-30x via compaction; B-tree ~2-5x via WAL + page rewrites
- [ ] Estimate read amplification: B-tree = tree depth (3-4); LSM = number of segments checked (mitigated by Bloom filters)
- [ ] Provision SSD endurance accordingly (DWPD rating)
- [ ] Plan to enable Bloom filters on LSM (~1.25 bytes/key for 1% FPR)

**Reference**: `references/oltp-storage/knowledge.md` (Write/Read/Space Amplification)

---

### Step 7: Plan Compaction Tuning (LSM Only)

**Goal**: Choose size-tiered vs leveled compaction and provision headroom.

- [ ] **If write-heavy with bursty load**: size-tiered compaction (fewer rewrites)
- [ ] **If read-heavy or balanced or tight on disk**: leveled compaction (lower space amplification, lower read amplification)
- [ ] Provision compaction parallelism for **peak**, not average, write rate
- [ ] Add monitoring: SSTable count, L0 backlog, compaction queue depth

**Skip this step** for B-tree, in-memory, or columnar engines.

**Reference**: `references/oltp-storage/rules.md` (Rules 4, 8)

---

### Step 8: Document the Choice and Tradeoffs

**Goal**: Record the decision so the next engineer (or future you) understands why.

- [ ] Write 1-page ADR: workload, alternatives considered, choice, rejected options + reasons
- [ ] List known weaknesses (e.g., "p99 read latency may spike during compaction")
- [ ] Define monitoring SLOs and alert thresholds tied to the weaknesses
- [ ] Note the migration trigger ("revisit if write QPS exceeds X" or "if dataset exceeds Y")

---

## Quick Checklist

```
[ ] Step 1: Workload characterized (R/W ratio, latency budget)
[ ] Step 2: Data volume vs RAM assessed
[ ] Step 3: Range query needs identified
[ ] Step 4: Engine family chosen via decision tree
[ ] Step 5: Specific engine selected
[ ] Step 6: Amplification budget planned
[ ] Step 7: Compaction strategy chosen (LSM only)
[ ] Step 8: Decision documented with tradeoffs
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Picking in-memory for a dataset that exceeds RAM | OOM, eviction storms, or unbounded RAM cost | Verify dataset + 36-month growth fits with headroom |
| Picking LSM for predictable read latency | Compaction stalls and multi-segment merges create p99 spikes | Use B-tree when p99 read latency is the SLO |
| Picking B-tree for ingest-heavy time-series | Random page writes saturate disk; write amplification hurts SSDs | Use LSM with size-tiered compaction |
| Skipping the WAL "for performance" on a B-tree | Crash leaves torn pages and orphan entries — silent corruption | Always WAL + fsync; tune group commit instead |
| Adding indexes "just in case" | Every write pays the cost of every index | Add only when a query pattern justifies it |
| Choosing leveled compaction for bursty write spikes | Leveled rewrites old data continuously, amplifying spikes | Use size-tiered for write-heavy bursty loads |
| Using OLTP row store for big aggregate scans | Reads load entire rows when 4 columns are needed | Use columnar (Snowflake, ClickHouse, DuckDB) |
| No compaction headroom on LSM | Memtable backs up, reads and writes stall | Provision compaction for peak, monitor L0 backlog |

---

## Cross-References

- **OLTP storage details**: `references/oltp-storage/rules.md`, `references/oltp-storage/knowledge.md`
- **OLAP / columnar choice**: `references/olap-storage/rules.md`, `references/olap-storage/knowledge.md`
- **Secondary index strategies**: `references/specialized-indexes/rules.md`, `references/specialized-indexes/knowledge.md`

---

## Exit Criteria

Task is complete when:

- [ ] One specific engine is chosen and named
- [ ] The decision tree path that led to it is recorded
- [ ] Amplification and (if LSM) compaction strategy are documented
- [ ] Monitoring SLOs and a re-evaluation trigger are defined
- [ ] An ADR or equivalent decision record is checked into the repo
