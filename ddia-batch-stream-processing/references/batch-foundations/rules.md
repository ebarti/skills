# Batch Processing Rules

Decision rules for picking batch tooling, storage, and join strategies.

## Core Rules

### 1. Use Unix tools for ad-hoc, single-machine analysis

For one-off log analysis, debugging, or data shapes you can hold on a laptop, reach for `awk`, `sort`, `uniq`, `grep`, `head` first.

- GNU `sort` spills to disk and parallelizes across cores — handles multi-GB files fine
- Pipelines are easier to iterate on than a Python script
- The bottleneck is usually disk read speed, not CPU

**Use when**: dataset fits one machine, exploration is interactive, no orchestration needed.
**Stop when**: data won't fit on local disk, or the job needs to run on a schedule with retries.

### 2. Use distributed batch (Spark / Flink) for large datasets

Once data exceeds a single machine, switch to a distributed engine.

- Spark and Flink are the defaults
- They handle sharding, shuffle, fault tolerance, and locality for you
- Both run on YARN, Kubernetes, or standalone

### 3. Avoid raw MapReduce — use a dataflow engine or SQL on top

Writing low-level MapReduce in Java is laborious, slow, and forces you to reimplement joins.

- Prefer Spark / Flink dataflow APIs
- Or write SQL via Hive, Trino, Spark SQL, BigQuery, Snowflake
- Use DataFrames (Spark, Daft, Snowpark) for programmatic style with optimizer benefits

### 4. Pick join strategy by data size

| Both sides large | Sort-merge join (shuffle both, merge in reducer) |
| One side small (< node memory) | Broadcast hash join (ship small side everywhere) |
| Both already sharded by join key | Partitioned hash join (no shuffle) |

A modern query optimizer (Spark Catalyst, Trino, Flink) will pick the right one if you give it stats — let it.

### 5. Use object store (S3) over HDFS in the cloud

For new cloud workloads, prefer S3 / GCS / Azure Blob over HDFS.

- 11 nines durability without operating NameNodes / DataNodes
- Storage and compute scale independently
- Modern datacenter networks make compute-storage separation cheap
- HDFS still wins for on-prem or extreme data-locality needs

**Caveats**: no atomic rename (use a commit protocol like Iceberg, Delta), eventual consistency on listings (mostly resolved on S3), metadata operations are slow at scale.

### 6. Use a workflow orchestrator for multi-step pipelines

If your data pipeline has more than 2-3 stages, run it under Airflow, Dagster, Prefect, or Argo.

- Per-job schedulers (YARN, Spark) only schedule one job — they don't model dependencies between jobs
- Orchestrators give you retries, alerting, backfills, and lineage
- Makes it tractable to maintain 50-100 job DAGs

### 7. Use spot / preemptible instances for batch

Batch jobs are not latency-sensitive and frameworks already handle task retries.

- Cheap (often 60-90% off on-demand)
- Preemptions are more frequent than hardware failures, but the framework restarts killed tasks
- Avoid spot for the driver / coordinator; run those on regular instances

### 8. Make jobs idempotent and rerunnable

A batch job should be safe to rerun on the same input and produce the same output.

- Write to a fresh output path, then atomically swap (or use Iceberg/Delta commits)
- Don't make external side-effects (RPC, email) from inside mappers/reducers
- Treat the workflow as: input -> transform -> output. No mutation.

## Guidelines

- Default to Parquet (columnar) for analytical batch outputs; Avro (row-based) for record streams
- Push filtering and aggregation into SQL; reach for UDFs only when SQL can't express it
- Set reducer/partition count to (cluster cores) x 2-4 for balanced load
- For Spark: keep intermediate data in memory; only write final output to DFS
- Watch for skew — one hot key can stall a whole job; salting or two-stage aggregation fixes it

## Exceptions

- **ML / iterative jobs**: SQL is awkward for iterative algorithms (PageRank, gradient descent). Use Spark/Flink dataflow APIs or a dedicated framework.
- **Multimodal data** (images, video, audio): often poor fit for SQL. Use Spark, Ray, or a custom framework.
- **Tiny datasets**: don't pay the distributed-system tax — Pandas / DuckDB on one node beats a cluster.
- **HDFS over S3**: keep HDFS when you need true atomic rename, file locks, or extreme data locality.

## Quick Reference

| Decision | Rule |
|----------|------|
| Dataset fits on laptop | Unix tools or Pandas/DuckDB |
| Dataset > 1 machine | Spark or Flink |
| Writing pipelines | Use SQL or DataFrames; never raw MapReduce |
| Cloud storage | S3 / GCS / Azure Blob over HDFS |
| Multi-step workflow | Airflow / Dagster / Prefect / Argo |
| Both join sides large | Sort-merge join |
| One join side small | Broadcast hash join |
| Both pre-partitioned | Partitioned hash join |
| Cost reduction | Spot / preemptible for tasks (not driver) |
| Output format | Parquet for analytics, Avro for records |
