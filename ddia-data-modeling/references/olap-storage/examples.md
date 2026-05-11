# OLAP / Analytical Storage Examples

Concrete examples of analytical engines, file/table formats, columnar compression, and materialized aggregates.

## Cloud Data Warehouses

| System | Notes |
|--------|-------|
| Google BigQuery | Serverless, separated storage/compute, massive parallelism |
| Amazon Redshift | Columnar MPP DW; managed clusters and serverless variants |
| Snowflake | Object-storage-backed, virtual warehouses (compute), Polaris catalog |
| Databricks SQL | Lakehouse; built on Delta + Spark; Unity Catalog |
| Teradata, Vertica, SAP HANA | Established vendors with on-prem + cloud offerings |

## Embedded / Single-Node Analytical Engines

| System | Notes |
|--------|-------|
| DuckDB | In-process columnar OLAP; great for local analytics on Parquet |
| ClickHouse | High-throughput columnar DBMS for real-time analytics |
| Apache Druid, Apache Pinot | Real-time analytics over event streams |
| InfluxDB IOx, TimescaleDB | Time-series databases on columnar foundations |

## Open Storage and Table Formats

**Storage formats** (file byte layout):

- **Parquet** — Columnar, supports nested data via Dremel-style shredding/striping
- **ORC** — Columnar, common in the Hive ecosystem
- **Lance** — Columnar format optimized for ML/AI workloads
- **Nimble** — Columnar format for analytics
- **Apache Arrow** — In-memory columnar standard for inter-engine data exchange

**Table formats** (metadata over many immutable files):

- **Apache Iceberg** — Snapshots, time travel, schema evolution, transactions
- **Delta Lake** — Databricks-originated; ACID transactions atop Parquet
- Both define which files belong to a table and support row-level inserts/deletes/GC

**Data catalogs**:

- Snowflake **Polaris**, Databricks **Unity Catalog**, Iceberg's REST catalog

## Decomposed Data Warehouse Stack

```
[ Query engine: Trino / Spark / DataFusion / Presto ]
                    |
[ Table format: Iceberg / Delta ]   <-- snapshots, schema, transactions
                    |
[ Storage format: Parquet / ORC ]   <-- columnar bytes
                    |
[ Object storage: S3 / GCS / Azure Blob ]
                    |
[ Catalog: Polaris / Unity / Iceberg REST ]  <-- table discovery
```

## Column Compression Worked Examples

### Bitmap encoding on a low-cardinality column

`product_sk` column with 4 distinct products across many rows:

```
Row:        1  2  3  4  5  6  7  8
product_sk: 31 31 68 31 69 68 31 69
```

Three bitmaps, one bit per row:

```
product_sk = 31 : 1 1 0 1 0 0 1 0
product_sk = 68 : 0 0 1 0 0 1 0 0
product_sk = 69 : 0 0 0 0 1 0 0 1
```

Query `WHERE product_sk IN (68, 69)` becomes a fast bitwise OR of two bitmaps.
Query `WHERE product_sk = 30 AND store_sk = 3` becomes a bitwise AND of two bitmaps.

### Run-length encoding on a sparse bitmap

```
Bitmap : 0 0 0 0 0 0 0 0 1 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0
RLE    : 8 zeros, 1 one, 4 zeros, 2 ones, 10 zeros
Stored as integer counts: [8, 1, 4, 2, 10]
```

Roaring bitmaps switch between raw bitmap and RLE per chunk to stay smallest.

### RLE on a sorted primary key column

If rows are sorted by `date_key` and there are 100M rows per day:

```
date_key sequence: 2024-01-01 (×100,000,000), 2024-01-02 (×100,000,000), ...
RLE-encoded: [(2024-01-01, 100000000), (2024-01-02, 100000000), ...]
```

Billions of rows compress to a few kilobytes for that column.

## Materialized View (Snowflake / BigQuery style)

A specific recurring query, persisted and auto-refreshed:

```sql
-- Snowflake
CREATE MATERIALIZED VIEW mv_daily_product_sales AS
SELECT
  date_key,
  product_sk,
  SUM(quantity)  AS units_sold,
  SUM(net_price) AS revenue
FROM fact_sales
GROUP BY date_key, product_sk;

-- BigQuery
CREATE MATERIALIZED VIEW project.dataset.mv_daily_product_sales AS
SELECT
  date_key,
  product_sk,
  SUM(quantity)  AS units_sold,
  SUM(net_price) AS revenue
FROM `project.dataset.fact_sales`
GROUP BY date_key, product_sk;
```

Subsequent queries that match the view's grouping read precomputed rows instead of scanning `fact_sales`.

## Data Cube (Two-Dimensional Example)

`fact_sales` aggregated by `date_key` × `product_sk`, cells = `SUM(net_price)`:

```
              product_A  product_B  product_C   |  SUM (by date)
2024-01-01      1,200       800        500      |     2,500
2024-01-02      1,500       900        650      |     3,050
2024-01-03      1,100     1,100        700      |     2,900
---------------------------------------------------------------
SUM (by prod)   3,800     2,800      1,850      |     8,450
```

- "Total sales per product, all dates" = column totals (one dimension dropped).
- "Total sales per day, all products" = row totals (other dimension dropped).
- Real cubes generalize to N dimensions (date × product × store × promotion × customer).
- Cannot answer "what fraction of sales were items > $100" because price isn't a cube dimension; need raw data.

## Vectorized vs Compiled Execution

- **Vectorized** (DuckDB, ClickHouse, Snowflake, Vertica): batches of column values flow through prebuilt operators; great cache and SIMD utilization.
- **Compiled** (HyPer, Apache Impala, Spark Tungsten): per-query LLVM code generation produces tight loops over column data; high one-time compile cost, then very fast execution.
- Both: prefer sequential memory access, keep inner loops small, use SIMD, and operate directly on compressed data.
