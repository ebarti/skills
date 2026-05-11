# OLTP Storage Engine Examples

Real engines, their architectures, and worked numbers for the design choices in `knowledge.md` and `rules.md`.

## LSM-Based Engines

### RocksDB (and LevelDB ancestor)

- Embedded library; most popular LSM engine
- Default: leveled compaction; size-tiered also available
- Bloom filters per SSTable
- Applies *backpressure* when the memtable cannot flush fast enough — suspends reads and writes
- Used inside Kafka Streams, CockroachDB, TiKV, MyRocks (MySQL storage engine alternative)

### Cassandra and ScyllaDB

- Distributed wide-column stores using LSM per node
- Default historically: size-tiered compaction (good for write-heavy time-series)
- Leveled compaction available for read-heavy column families
- Tombstones plus compaction handle deletes

### HBase

- Distributed; modeled after Google Bigtable (the paper that introduced "SSTable" and "memtable")
- LSM with HDFS-backed segment files

**Pattern across all four**: memtable buffers writes -> immutable SSTables flushed to disk -> background compaction reclaims space.

## B-Tree Engines

### PostgreSQL

- Default index type is a B-tree (or B+ tree)
- Page size: 8 KiB
- WAL + `fsync` for durability
- Heap-file storage; secondary indexes point to heap tuples
- Vacuum process reclaims fragmented space (because deleted tuples leave gaps)

### MySQL InnoDB

- B+ tree primary index is *clustered* — rows live inside the leaf pages
- Page size: 16 KiB by default
- Secondary indexes store the primary key, not a heap pointer (so PK lookup follows)
- WAL = "redo log"; uses double-write buffer to defend against torn pages

### SQLite

- Embedded, single-file database; B-tree throughout
- WAL mode is opt-in but recommended for concurrency
- Lives inside browsers, phones, and countless apps

### LMDB

- Embedded; uses *copy-on-write* B-tree variant instead of WAL
- New writes go to fresh pages, with a new root page committed atomically — no WAL needed
- Old pages reclaimed via free-list once no reader needs them

## In-Memory Engines

### Redis

- In-memory key-value with rich data structures (lists, sets, sorted sets, hashes, streams)
- Weak durability via async disk writes (RDB snapshots, AOF append-only file)
- Justifies in-memory choice on data-model grounds, not just speed

### Memcached

- In-memory cache only; data is lost on restart, by design
- Used as a hot-data cache in front of a durable database

### VoltDB / SingleStore / Oracle TimesTen

- In-memory *relational* databases targeting high-throughput OLTP
- Achieve performance by removing on-disk-format encoding overhead

### RAMCloud

- Open-source in-memory K-V with strong durability via log-structured layout for both RAM and disk

## Bloom Filter Math

Goal: choose bits-per-key for a false-positive probability target.

| Bits per key | False positive rate |
|--------------|--------------------|
| 5 | ~10% |
| 10 | ~1% |
| 15 | ~0.1% |
| 20 | ~0.01% |
| 25 | ~0.001% |

**Rule of thumb**: ~10 bits per key gives ~1% FPR; every additional 5 bits per key cuts the rate by ~10×.

**Worked example**: an SSTable with 1,000,000 keys at 10 bits/key needs:

```
1,000,000 keys × 10 bits = 10,000,000 bits = 1.25 MB
```

For ~1% FPR. That overhead is tiny relative to even a moderately-sized SSTable, which is why LSM engines almost always enable Bloom filters.

## Compaction Strategy Comparison

### Size-Tiered (e.g., Cassandra default historically)

```
L0: [256 MB] [256 MB] [256 MB] [256 MB]
              |  merge  |
              v
L1: [~898 MB]                              # 4×256 minus deletes/expirations
```

- Bigger files get bigger over time
- Pros: minimal rewrite overhead, tolerates very high write throughput
- Cons: temporary disk usage spikes during merges; reads check more files

### Leveled (e.g., RocksDB default, BigTable-style)

```
L0: [a-z]                                  # newest, may overlap
L1: [a-m] [n-z]                            # ~10× L0 capacity, key ranges disjoint
L2: [a-c][d-f][g-i][j-l][m-o][p-r][s-u][v-x][y-z]  # ~10× L1, disjoint
...
```

- Each level ~10× the previous; SSTables in L1+ have disjoint key ranges
- Compactions move one SSTable from level i to level i+1 incrementally
- Pros: fewer SSTables to check on read; lower space amplification
- Cons: more total bytes written (higher write amplification)

### Picking Between Them

| Workload | Strategy |
|----------|----------|
| Time-series ingest, occasional scans | Size-tiered |
| Read-heavy KV store with point lookups | Leveled |
| Few hot keys updated often, many cold | Leveled |
| Disk space tight | Leveled |
| Want simplicity and write absorption | Size-tiered |

## Secondary Index Storage

### As a postings list (one entry per indexed value)

```
index: "city = London" -> [row_id_42, row_id_88, row_id_115]
```

### With row identifier appended (one entry per row)

```
index entry: ("London", row_id_42)
index entry: ("London", row_id_88)
index entry: ("London", row_id_115)
```

Both work on top of either LSM or B-tree primary storage.

### Covering Index Example

A query `SELECT name, email FROM users WHERE org_id = ?` on `users(org_id, name, email)` answers entirely from the index — no heap lookup needed. Trade-off: index now duplicates `name` and `email`, costing disk and slowing writes.

## Engine Selection Cheat-Sheet

| Need | Pick |
|------|------|
| Write-heavy ingest, lots of compression | RocksDB / Cassandra |
| Bigtable-style wide-column on HDFS | HBase |
| General-purpose SQL with mature transactions | PostgreSQL / MySQL InnoDB |
| Single-file embedded SQL | SQLite |
| Embedded K-V without WAL overhead | LMDB (copy-on-write) |
| Hot-data cache, OK to lose on restart | Memcached |
| In-memory K-V with rich data structures | Redis |
| In-memory relational OLTP | VoltDB / SingleStore |
| K-V on object storage (S3) | SlateDB / Delta Lake |
