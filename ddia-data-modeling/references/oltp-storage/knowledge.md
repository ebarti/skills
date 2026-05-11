# OLTP Storage Engines Knowledge

Core concepts for storage and indexing in OLTP databases: log-structured (LSM) vs page-oriented (B-tree) vs in-memory engines.

## Overview

OLTP storage engines persist key-value data on disk (or in RAM) so reads are fast and writes survive crashes. Two dominant on-disk families compete: log-structured merge trees (LSM) optimize for writes via append-only segments, while B-trees optimize for predictable reads via in-place page updates. In-memory engines skip disk encoding entirely when datasets fit in RAM.

## Key Concepts

### Log-Structured Storage

**Definition**: A storage approach where data is written as an append-only sequence of records (a *log*) and never modified in place.

Appending is the fastest possible write. The trade-off is that lookups, deletes, and space reclamation require separate machinery (indexes, compaction, tombstones).

### SSTable (Sorted String Table)

**Definition**: An immutable file of key-value pairs sorted by key, with each key appearing exactly once.

**Key points**:
- Sorting enables a *sparse index* (only first key per block in memory)
- Blocks (a few KB) can be compressed to save disk and I/O bandwidth
- Once written, the file is never modified

### Memtable

**Definition**: An in-memory ordered map (red-black tree, skip list, or trie) that buffers recent writes before they are flushed to disk as an SSTable.

A separate write-ahead log on disk protects the memtable's contents against crash.

### LSM-Tree (Log-Structured Merge Tree)

**Definition**: A storage engine that buffers writes in a memtable, flushes them as immutable SSTable segments, and merges those segments in the background.

**Key points**:
- Reads check memtable first, then segments newest-to-oldest
- A *tombstone* record marks deletions; compaction discards them later
- Segments can live on local disk or on object storage

### B-Tree

**Definition**: A balanced tree of fixed-size *pages* (typically 4-16 KiB), where each page holds keys and references to child pages, and pages are overwritten in place.

**Key points**:
- Branching factor is typically several hundred; depth is O(log n)
- A 4-level tree of 4 KiB pages with branching factor 500 stores up to 250 TB
- Inserts that overflow a page trigger a *page split* that may cascade upward

### Page

**Definition**: The fixed-size unit of disk I/O in a B-tree (4 KiB classical, 8 KiB Postgres, 16 KiB MySQL InnoDB), addressable by page number.

### Bloom Filter

**Definition**: A compact bitmap probabilistic data structure that quickly answers "is this key definitely *not* in this SSTable?"

**Key points**:
- Hashes a key to several bit positions; if any bit is 0, key is absent
- *False positives* possible; false negatives are not
- Rule of thumb: 10 bits per key gives 1% false-positive rate; +5 bits per key reduces it 10×

### Compaction

**Definition**: A background process that merges multiple SSTables into fewer, larger files, dropping overwritten values and tombstones.

### Write Amplification

**Definition**: Ratio of bytes written to disk vs bytes the application asked to write.

Both LSM (log + memtable flush + compactions) and B-tree (WAL + full page writes) inflate writes; LSM typically wins on this metric for write-heavy workloads.

### Read Amplification

**Definition**: Number of disk reads needed to serve a single application read (LSM may check several segments; B-tree reads one page per level).

### Space Amplification

**Definition**: Ratio of disk space used to live data size (LSM size-tiered uses extra during merges; B-tree fragments after deletes).

### Write-Ahead Log (WAL)

**Definition**: An append-only file in which a B-tree records every modification *before* applying it to pages, enabling crash recovery.

### Clustered vs Non-Clustered Index

| Type | Stores | Examples |
|------|--------|----------|
| **Clustered** | The full row inside the index | InnoDB primary key; SQL Server's one-per-table clustered index |
| **Non-clustered (heap)** | A reference (PK or disk pointer) to the row in a *heap file* | Postgres tables, InnoDB secondary indexes |
| **Covering** | Some columns inline so common queries skip the heap | Index-only scans |

### In-Memory Database

**Definition**: A database that serves all reads from RAM, optionally persisting writes via a log, snapshots, replication, or special hardware (battery-backed RAM).

The performance win comes from skipping the encoding of in-memory data structures into disk-friendly formats — not from avoiding disk reads.

## Compaction Strategies

| Strategy | Behavior | Best For |
|----------|----------|----------|
| **Size-tiered** | Merge small SSTables into bigger ones; bigger files get even bigger | Write-heavy, few reads |
| **Leveled** | Fixed-size SSTables organized into levels L0..Ln, each ~10× the previous; merge level i into i+1 incrementally | Read-heavy; lower disk overhead |

## Terminology

| Term | Definition |
|------|------------|
| Log | Append-only sequence of records on disk (not human-readable application logs) |
| Segment | One immutable on-disk SSTable file in an LSM engine |
| Sparse index | Index that stores only the first key of each block, not every key |
| Tombstone | Special record that marks a key as deleted |
| Torn page | A partially-written page after a crash mid-write |
| Heap file | An unsorted file storing rows referenced by non-clustered indexes |
| Branching factor | Number of child references per B-tree page (typically several hundred) |
| Embedded engine | Storage engine running in your process as a library (RocksDB, SQLite, LMDB, DuckDB) |

## How It Relates To

- **Replication and sharding**: Same engines used in single-node and distributed systems
- **Transactions**: WAL + page atomicity underpin durability and crash recovery
- **Secondary indexes**: Built on top of either LSM or B-tree primary indexes

## Common Misconceptions

- **Myth**: LSM beats B-tree because writes don't hit disk.
  **Reality**: Both hit disk; LSM wins via *sequential* writes and lower write amplification.

- **Myth**: In-memory DBs are fast because they avoid disk reads.
  **Reality**: A warm B-tree never reads disk either; in-memory wins by skipping disk-format encoding.

- **Myth**: Bloom filters can falsely report a key is missing.
  **Reality**: Bloom filters never false-negative; they only false-positive.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| LSM-tree | Append, sort in memory, flush to immutable SSTables, merge later |
| B-tree | In-place page updates with WAL for durability |
| Bloom filter | Probabilistic "definitely not here" check per SSTable |
| Compaction | Background merge of SSTables to reclaim space and speed reads |
| WAL | Durability log for B-tree page updates |
| Clustered index | Row data lives inside the index |
