# OLTP Storage Engine Rules

Decision rules for choosing and configuring an OLTP storage engine: LSM vs B-tree vs in-memory, secondary indexes, durability.

## Core Rules

### 1. Choose LSM when writes dominate

LSM-trees handle higher write throughput on the same hardware because they convert random writes into large sequential writes.

- Workload: ingestion, time-series, event logging, append-mostly tables
- Disks: spinning HDDs benefit most; SSDs still see meaningful gains
- Bonus: SSTable block compression yields smaller on-disk files
- Bonus: less SSD wear (lower write amplification)

**Use when**: write throughput is the bottleneck; you need compression; data is roughly insert-only or has frequent overwrites of the same hot keys.

### 2. Choose B-tree when reads dominate or latency must be predictable

B-trees give one disk read per tree level (typically 3-4), so read latency is bounded and predictable.

- Workload: transactional OLTP, point lookups, mixed read/write with read-heavy skew
- Range queries: B-trees scan the sorted leaves directly; LSM must merge across segments and Bloom filters don't help
- Transactional support: in-place updates align well with row-level locking and 2PL

**Use when**: you need predictable p99 read latency; your workload has many range queries; you want mature transactional semantics (most SQL DBs).

### 3. Always pair B-trees with a write-ahead log (WAL)

B-tree page overwrites and especially page splits are not atomic; without a WAL, a mid-write crash leaves the tree corrupted (orphan pages, torn pages).

- Every modification is appended to the WAL *before* being applied to pages
- Buffered page writes are safe because the WAL has the change
- A write counts as durable only after `fsync` flushes WAL bytes to disk
- LMDB's copy-on-write is an alternative — replaces WAL with new page allocations

**Rule**: never let a B-tree implementation skip its WAL or `fsync` for performance.

### 4. Pick the compaction strategy from the workload

| If your workload is... | Use |
|------------------------|-----|
| Write-heavy, few reads | Size-tiered |
| Read-heavy or balanced | Leveled |
| Few hot keys updated often + many cold keys | Leveled |
| Tight on disk space | Leveled (less temporary overhead) |
| Bursty high-throughput writes | Size-tiered (fewer rewrites of old data) |

Most LSM engines (RocksDB, Cassandra) ship multiple strategies and let you choose per table.

### 5. Choose in-memory only when the dataset fits

In-memory engines win on latency and on data models awkward on disk (priority queues, sets), but cost-per-GB of RAM is much higher than disk.

- Use when: dataset fits comfortably in RAM (with growth headroom) OR latency matters more than cost
- Acceptable durability: log of changes to disk + periodic snapshots + replicas
- Cache-only acceptable: Memcached pattern — data loss on restart is fine
- Hard constraint: a "single machine" budget grows by adding replicas/shards, not RAM-per-node forever

### 6. Add secondary indexes deliberately, not by default

Every additional index slows down every write to the indexed table.

- Add only when a query pattern requires it and the table is queried more than written
- Prefer covering indexes when a small set of columns answers a hot query — saves a heap lookup
- Remember: secondary indexes are non-unique; engines use either postings lists or row-id suffix
- Both LSM and B-tree primary engines can host secondary indexes

### 7. Don't index "everything just in case"

Indexes consume disk space and write throughput. Most databases require you to choose indexes manually because only you know the query patterns.

- Measure read patterns before adding an index
- Drop indexes that aren't used — `pg_stat_user_indexes`, `sys.dm_db_index_usage_stats`, etc.

### 8. Plan for backpressure on LSM write spikes

If incoming writes exceed compaction throughput, the memtable backs up. RocksDB and similar engines suspend reads and writes until the memtable flushes — visible as latency spikes.

- Provision compaction parallelism for peak load, not average
- Watch SSTable count and L0 backlog as leading indicators

## Guidelines

- For *snapshots/backups*, LSM segments are immutable so a snapshot is just a list of segment files; B-tree snapshots need page-level copy-on-write or filesystem snapshots
- Block compression in SSTables is usually cheap and worth enabling
- Bloom filters cost ~1.25 bytes per key for 1% FPR — almost always worth it for LSM
- Heap files allow in-place updates only if the new value fits in the old slot; larger values force a move plus index updates
- Embedded engines (RocksDB, SQLite, LMDB, DuckDB) suit single-machine, multi-tenant per-tenant DB scenarios

## Exceptions

- **Object storage backends**: SlateDB, Delta Lake put SSTable segments on S3-like storage; the LSM model fits naturally because segments are immutable
- **Hybrid engines**: some systems blend B-trees with LSM-style merging
- **Time-to-delete compliance**: standard LSM tombstones may take many compaction cycles to fully erase data; choose engines with fast deletion paths if this matters legally

## Quick Reference

| Rule | Summary |
|------|---------|
| Writes dominate | LSM |
| Reads dominate or need predictable latency | B-tree |
| B-tree durability | Always WAL + fsync |
| Range-heavy LSM workload | Use leveled compaction |
| Small dataset, low latency | In-memory |
| New secondary index | Justify per query pattern |
| Write spikes on LSM | Plan compaction headroom |
