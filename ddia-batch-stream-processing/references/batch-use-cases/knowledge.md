# Batch Use Cases Knowledge

Core concepts for applying batch processing to ETL, analytics, ML, and serving derived data.

## Overview

Batch jobs excel at processing large datasets in bulk where data freshness is not critical. They power a wide range of workloads: ETL/ELT pipelines into warehouses, analytical (OLAP) queries, ML feature engineering and training, and the production of derived datasets (recommendations, search indexes, ML features) that are served back to live systems.

## Key Concepts

### ETL and ELT (Extract-Transform-Load)

**Definition**: A pipeline that extracts data from a production database, transforms it, and loads results into a downstream system (commonly a data warehouse).

- **ETL**: Transformation happens in flight before loading.
- **ELT**: Raw data is loaded into the target warehouse first, then transformed there (modern norm with Snowflake, BigQuery).
- Many transformations (filter, project, join) are *embarrassingly parallel* — a natural fit for batch frameworks.
- Often orchestrated by workflow schedulers (Airflow, Dagster) which manage retries, dependencies, and source/sink connectors.

### Analytics (OLAP)

**Definition**: Queries that scan many records performing groupings and aggregations to answer business questions.

- Run atop query engines reading from distributed filesystems / object stores; metadata managed via table formats (Apache Iceberg) and catalogs (Unity). This is the *data lakehouse* architecture.
- **Pre-aggregation queries**: Roll data into OLAP cubes / data marts on a schedule; often pushed to real-time OLAP systems (Druid, Pinot).
- **Ad hoc queries**: Iterative analyst queries; response time matters.
- Integrates with BI tools (Tableau, Power BI, Looker, Apache Superset) via SparkSQL, Trino, Presto connectors.

### Machine Learning Pipelines

**Definition**: Batch workflows that prepare data, train models, and produce predictions.

- **Feature engineering**: Filter and transform raw data (text, categories) into numeric features models can consume.
- **Model training**: Training data is input; trained model weights are output.
- **Batch inference**: Apply a trained model to large datasets where real-time results aren't needed (also used for test-set evaluation).
- Spark MLlib, FlinkML provide feature engineering, statistics, classifiers.
- Graph processing for recommendations/ranking uses the *Bulk Synchronous Parallel (BSP)* / Pregel model (Giraph, Spark GraphX, Flink Gelly).
- LLM data prep (HTML extraction, dedup, tokenization, embeddings) runs on Kubeflow, Flyte, Ray.
- Notebooks (Jupyter, Hex) drive batch via DataFrame APIs or SQL.

### Serving Derived Data

**Definition**: Precomputed datasets (recommendations, reports, ML features) built by batch jobs and served from a production database, key-value store, or search engine.

- Output must move from the batch processor's filesystem/object store back into the live-serving system.
- Direct writes to production DBs from inside batch tasks are an anti-pattern (slow, overwhelms DB, breaks all-or-nothing guarantee).
- Preferred patterns: push to a stream (Kafka), or build a brand-new database inside the job and bulk-load atomically.

## Terminology

| Term | Definition |
|------|------------|
| ETL | Extract, transform in flight, then load |
| ELT | Extract, load raw, then transform in target warehouse |
| Data lakehouse | Lake-style storage + warehouse-style table formats and catalogs |
| OLAP | Online Analytical Processing — large-scan, aggregating queries |
| Data mart / OLAP cube | Pre-aggregated data structure for fast querying |
| BSP / Pregel | Bulk Synchronous Parallel model for graph batch processing |
| Derived dataset | Precomputed output (recs, indexes, features) served to clients |
| DMZ | Demilitarized zone — buffer network between batch and production |
| Bulk import | Loading prebuilt files (e.g. SST) directly into a database |

## How It Relates To

- **Batch foundations**: Use cases sit on top of MapReduce / Spark / Flink batch primitives.
- **Stream processing**: Streaming systems (Kafka) are the recommended bridge between batch output and serving systems.
- **Data integration**: Schedulers, connectors, and lakehouse formats glue source DBs, batch engines, and serving systems together.

## Common Misconceptions

- **Myth**: Batch is only for nightly reports.
  **Reality**: Batch underpins ML training, recommendation generation, search index builds, and most analytics — central to many products.

- **Myth**: ETL is the only valid model.
  **Reality**: ELT is now the dominant pattern with cloud warehouses; transformation runs inside Snowflake/BigQuery/DuckDB with SQL.

- **Myth**: It's fine to write directly to the production DB from a batch job.
  **Reality**: It's slow, overloads the DB, and breaks the all-or-nothing guarantee — push through Kafka or bulk-import instead.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| ETL | Transform in flight, then load |
| ELT | Load raw, then transform in warehouse |
| Lakehouse | Object store + table format (Iceberg) + catalog (Unity) |
| Pre-aggregation | Scheduled rollup into cubes/marts/Druid/Pinot |
| Ad hoc query | Interactive analyst query, response time matters |
| Feature engineering | Transform raw data into numeric model inputs |
| BSP / Pregel | Graph batch model — propagate along edges until converged |
| Serve derived | Push via Kafka or bulk-import into a fresh DB; never direct writes |
