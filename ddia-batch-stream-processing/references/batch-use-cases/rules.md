# Batch Use Cases Rules

Guidelines for choosing patterns when building ETL/ELT, analytics, ML, and derived-data batch pipelines.

## Core Rules

### 1. Pick ETL vs ELT by where the compute lives

- Use **ETL** when the source is memory/CPU constrained or when the target lacks strong transformation capability — transform in flight before loading.
- Use **ELT** when the target is a modern cloud warehouse (Snowflake, BigQuery, Redshift, DuckDB). Load raw data, transform in the warehouse with SQL. This is the modern default.
- Many ETL jobs and analytical queries now run on the same engine (SparkSQL, Trino, DuckDB) — exploit this to simplify your stack.

### 2. Use a workflow scheduler for any non-trivial pipeline

- Orchestrators (Airflow, Dagster, Flyte, Kubeflow) provide dependency graphs, retries, source/sink operators, and visibility into failures.
- Built-in operators for MySQL, PostgreSQL, Snowflake, Spark, Flink, etc. — use them instead of hand-rolling connectors.
- A failed job that is automatically retried mitigates transient failures; persistently failing jobs surface clearly.

### 3. Make pipelines easy to inspect and rerun

- Persist intermediate inputs/outputs so failed jobs can be inspected (missing fields, malformed rows).
- Batch jobs should be idempotent and rerunnable end-to-end after a fix.

### 4. For analytics, choose the query style deliberately

- **Pre-aggregate** (cubes, marts, Druid, Pinot) for repeated dashboards and reports — schedule via the orchestrator.
- **Ad hoc queries** need fast interactive engines (Trino, Spark SQL, DuckDB) so analysts can iterate.

### 5. For ML: version features, batch large training data

- Treat features as versioned artifacts (feature stores like Tecton or Feast) so training and serving see the same definitions.
- Use batch frameworks (Spark MLlib, FlinkML, Ray, Kubeflow, Flyte) for feature engineering and training over large datasets.
- Use **batch inference** when datasets are large and real-time results aren't needed.
- For graph workloads (recommendations, ranking), use BSP/Pregel-style engines (Giraph, GraphX, Gelly).

### 6. Never write directly from a batch job to a production DB

Three reasons it's a bad idea:

- **Slow**: per-record network requests are orders of magnitude below batch task throughput.
- **DB overload**: parallel batch tasks easily overwhelm the live DB and degrade query performance for production traffic.
- **Breaks all-or-nothing**: external side effects can't be hidden if the job partially fails or restarts; you risk duplicate or partial output.

### 7. For derived data, build atomically and swap

Two recommended patterns:

- **Stream the output**: write to a Kafka topic; downstream systems (Elasticsearch, Pinot, Druid, Venice, ClickHouse) ingest from Kafka. Streaming systems handle sequential writes well, buffer load, allow many consumers, and can sit in a DMZ network.
- **Bulk-import a fresh DB**: build a brand-new database inside the batch job and bulk-load the files (TiDB Lightning, Pinot Hadoop import, RocksDB SST import). Atomic version swaps; very fast.

When all-or-nothing matters with the streaming pattern, send a completion notification — consumers keep ingested data invisible (like read-committed isolation) until notified.

### 8. Don't mutate live indexes in place

- For search indexes (Elasticsearch), build the new index alongside the old, then swap aliases atomically. Don't mutate the live index from a batch job.

## Guidelines

- Use lakehouse table formats (Iceberg) and catalogs (Unity) so multiple engines can read the same data safely.
- Adopt data mesh / data contract / data fabric practices to let product teams own their pipelines safely.
- Use notebooks (Jupyter, Hex) for exploration; promote stable transformations into orchestrated batch jobs.
- For LLM data prep, use purpose-built frameworks (Ray, Kubeflow, Flyte) with native PyTorch/TensorFlow integrations.

## Exceptions

- **Tiny derived datasets**: direct writes to a production DB may be acceptable if volume is low and the job is single-threaded.
- **Hybrid bootstrap + incremental**: when you need both a full rebuild and incremental updates, use hybrid stores like Venice that support both row updates and full swaps.

## Quick Reference

| Rule | Summary |
|------|---------|
| ETL vs ELT | ETL if source-side transform; ELT if warehouse-side (modern default) |
| Scheduler | Always use Airflow/Dagster/Flyte for non-trivial pipelines |
| Inspect & rerun | Persist intermediates; make jobs idempotent |
| Analytics | Pre-aggregate scheduled; ad hoc on fast engine |
| ML features | Version them; use a feature store |
| Direct DB writes | Never from inside batch tasks |
| Derived data | Stream via Kafka or bulk-import fresh DB; swap atomically |
| Search indexes | Build new, alias-swap, don't mutate live |
