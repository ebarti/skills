# OLAP / Analytical Storage Rules

Guidelines for choosing column-oriented storage, compression strategies, sort orders, and aggregation layers in analytical systems.

## Core Rules

### 1. Use Columnar Storage for Analytical Workloads

Choose column-oriented storage when queries scan many rows but reference few columns and primarily aggregate.

- Wide fact tables (often 100+ columns) where typical queries touch 4-5
- Bulk scans, GROUP BY, SUM/COUNT/AVG over millions to billions of rows
- Read-heavy workloads with bulk-import writes (ETL, CDC batches)
- Examples: Snowflake, BigQuery, Redshift, ClickHouse, DuckDB, Druid, Pinot

### 2. Use Row-Oriented Storage for OLTP

Stay row-oriented when queries fetch or modify whole records by primary key.

- Single-row lookups dominate
- Frequent point inserts, updates, and deletes
- Low-latency transactional reads/writes
- Examples: PostgreSQL, MySQL, document stores

### 3. Choose Compression by Column Cardinality and Pattern

Pick the encoding that matches the column's value distribution.

- **Low cardinality** (small fixed set of values): bitmap encoding or dictionary encoding
- **Sparse bitmaps**: layer run-length encoding on top, or use roaring bitmaps to switch automatically
- **Sequential numeric** (timestamps, IDs): delta encoding + RLE / frame-of-reference
- **Strings with repetition**: dictionary encoding
- **High cardinality unique**: general byte-level compression (LZ4, Zstd, Snappy)

### 4. Sort by the Most-Common-Filter Column First

Sort order is the column store's primary index; the first sort key determines compression and scan pruning.

- First sort key = the column most queries filter on (commonly `date_key` for time-series facts)
- Second sort key groups related rows within the first key (e.g., `product_sk` after `date_key`)
- Only the first key compresses dramatically (long runs); later keys compress less and look random by the third or fourth level

### 5. Write in Bulk, Not Row-at-a-Time

Columnar files are immutable once written; per-row inserts are catastrophically expensive.

- Buffer writes in a row-oriented, sorted in-memory store first
- Flush in batches as new column-encoded files (log-structured merge)
- Run periodic compaction to merge files
- Object storage is well-suited; new immutable files match its append-only model

### 6. Use Materialized Views or Cubes for Repeated Aggregates

Cache precomputed answers when the same aggregates run repeatedly across many queries.

- **Raw query**: ad-hoc analytics, exploratory drill-downs, dimensions not known in advance
- **Materialized view**: a specific query (or join) that runs often and is expensive to recompute
- **Data cube**: a small, fixed set of dimensions with many overlapping aggregate queries (dashboards, reports)
- Keep raw data alongside cubes; cubes can't answer questions about un-cubed dimensions

## Guidelines

- Decouple storage and compute when possible — use object storage + elastic query engines for cloud DW workloads.
- Prefer open storage + table formats (Parquet/ORC + Iceberg/Delta) when multiple engines must read the same data.
- Choose row-group / block size to align with common date-range filters so scans can skip entire blocks.
- Operate on compressed data directly in vectorized engines; avoid materializing decoded columns.
- Refresh materialized views asynchronously unless strong consistency is required.

## Exceptions

- **HTAP / mixed workloads**: SQL Server, SAP HANA, SingleStore can serve both, but increasingly use two engines under one SQL surface; expect trade-offs vs specialized stores.
- **Small tables (dimensions)**: row-oriented or simple files often suffice; columnar overhead isn't worth it.
- **Streaming low-latency analytics**: row-oriented in-memory + later columnar conversion is common (Pinot, Druid).
- **Frequent updates to a few rows in a fact table**: consider a table format (Iceberg, Delta) that supports row-level operations atop columnar files.

## Quick Reference

| Decision | Rule |
|----------|------|
| Workload is bulk scan + aggregate | Use columnar |
| Workload is single-row CRUD | Use row-oriented |
| Column has < ~10k distinct values | Bitmap or dictionary encoding |
| Column is sparse boolean | RLE on top of bitmap |
| Primary filter is `date_key` | Sort by `date_key` first |
| Same aggregate runs constantly | Materialized view or data cube |
| Need ad-hoc exploration | Query raw data; keep cubes as boost only |
| Many engines read same data | Open formats: Parquet + Iceberg/Delta |
| Need elastic scaling | Separate storage and compute |
