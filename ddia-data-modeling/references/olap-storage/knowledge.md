# OLAP / Analytical Storage Knowledge

Core concepts for column-oriented storage and analytical query engines used in data warehouses and lakes.

## Overview

Analytical (OLAP) workloads scan large numbers of rows but only a few columns, aggregating values like SUM/COUNT/AVG. Column-oriented storage flips the row-major layout used by OLTP databases so each column is stored contiguously, enabling massive I/O savings, strong compression, and CPU-efficient batch query execution. Modern cloud data warehouses build on this by separating storage (object storage) from compute (elastic query engines).

## Key Concepts

### Column-Oriented (Columnar) Storage

**Definition**: A layout that stores all values from a single column contiguously, instead of storing all values from a single row contiguously.

**Key points**:
- A query reads only the columns it references, not the whole row
- Each column stores rows in the same order, so the *k*th value in every column belongs to row *k*
- Tables are split into row-group blocks (thousands to millions of rows) so each block holds per-column slices
- Used by Snowflake, BigQuery, Redshift, DuckDB, Druid, Pinot, Parquet, ORC, Apache Arrow

### Separation of Storage and Compute

**Definition**: Cloud data-warehouse architecture that persists data in scalable object storage and runs query compute as elastic, independently scaled services.

**Key points**:
- Storage capacity and query compute scale independently
- Enables serverless and on-demand cluster sizing
- Pioneered by BigQuery, Redshift, and Snowflake
- Encourages decomposed open systems: query engine + storage format + table format + data catalog

### Run-Length Encoding (RLE)

**Definition**: A compression scheme that stores consecutive runs of the same value as `(value, count)` pairs instead of repeating the value.

Especially effective on the primary sort column of a column store, where long runs of identical values appear, and on sparse bitmaps with many zeros.

### Bitmap Encoding

**Definition**: For a column with *n* distinct values, store *n* bitmaps, one per distinct value, with one bit per row indicating whether that row has that value.

**Key points**:
- Ideal for low-cardinality columns (e.g., 100k products across billions of rows)
- Sparse bitmaps are further compressed with RLE; *roaring bitmaps* switch between bitmap and RLE per chunk
- Boolean operators (AND, OR) over bitmaps execute extremely quickly via bitwise CPU instructions

### Dictionary Encoding

**Definition**: Replace each value with a small integer that indexes into a per-column dictionary of distinct values.

Reduces storage when columns have repeated string or wide values; bitmap encoding is essentially dictionary encoding plus a bitmap per dictionary entry.

### Vectorized Execution

**Definition**: Query execution that processes batches of column values at once through a fixed library of operators, rather than interpreting one row at a time.

**Key points**:
- Operators consume and produce columnar batches (often a bitmap or array)
- Keeps CPU caches warm and instruction pipelines full
- Enables SIMD instructions and operating directly on compressed data

### Query Compilation (JIT)

**Definition**: At query time, generate machine code (often via LLVM) tailored to the specific SQL query and column layouts, then execute the compiled code over in-memory column data.

Trades compile-time overhead for tight, branch-light inner loops; analogous to JVM JIT compilation.

### Materialized View

**Definition**: A precomputed, persisted copy of a query result, refreshed when underlying data changes (vs a virtual view, which is a query alias rewritten on read).

Speeds up repeated queries at the cost of extra write work and refresh logic.

### Data Cube (OLAP Cube)

**Definition**: A materialized aggregate that stores precomputed totals (SUM/COUNT/AVG/etc.) along multiple grouping dimensions, forming a multi-dimensional grid.

**Key points**:
- A 2D cube: rows = dates, columns = products, cells = aggregate (e.g., SUM(net_price))
- Real cubes have many dimensions (date, product, store, promotion, customer, ...)
- Aggregates can be summed along any dimension to drop a dimension
- Inflexible: only the precomputed aggregates are fast; ad-hoc dimensions still need raw data

## Terminology

| Term | Definition |
|------|------------|
| Fact table | Wide central table holding events/transactions, often hundreds of columns |
| Dimension table | Smaller descriptive tables referenced by fact-table foreign keys |
| Row group / block | Per-block slice of a column store (thousands to millions of rows) |
| Sort key | Column(s) whose order determines on-disk row ordering |
| Storage format | Byte layout of table files (Parquet, ORC, Lance, Nimble) |
| Table format | Logical metadata defining a table over many files (Iceberg, Delta) |
| Data catalog | Service mapping table names to table-format metadata (Polaris, Unity) |
| HTAP | Hybrid Transactional / Analytical Processing in one engine |
| Drill-down / slicing | Interactive analytic operations on a cube |

## How It Relates To

- **OLTP storage**: Row-oriented; opposite optimization target. OLAP loses on single-row reads, OLTP loses on bulk scans.
- **Star/snowflake schema**: Columnar storage targets the wide fact table; dimensions stay row-oriented and small.
- **ETL pipelines**: Writes to columnar stores are bulk loads, often via log-structured merging into immutable column files.
- **Stream processing**: Materialized views in DW echo the same idea as continuously maintained stream views (Materialize, Flink).

## Common Misconceptions

- **Myth**: Column-oriented databases are the same as wide-column / column-family stores (Bigtable, HBase, Cassandra).
  **Reality**: Wide-column stores are row-oriented; they store all values of a row together. Naming collision only.

- **Myth**: Columnar means no indexes or sort order.
  **Reality**: Sort order is a primary indexing tool; bitmap indexes are heavily used.

- **Myth**: Sorting each column independently saves space.
  **Reality**: Rows must be sorted together; the *k*th element of every column must still belong to the same row.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Columnar layout | Store columns contiguously to read only what the query needs |
| Bitmap encoding | One bitmap per distinct value; great for low cardinality |
| RLE | Compress runs of identical values; shines on sort key |
| Vectorization | Operate on batches of column values, not row-at-a-time |
| Query compilation | Generate machine code per query for tight inner loops |
| Data cube | Precomputed multi-dimensional aggregate grid |
