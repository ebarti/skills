# Batch Use Cases Examples

Concrete examples for ETL/ELT, ML pipelines, search index rebuilds, and serving derived data.

## Bad Examples

### Direct writes to production DB from a batch task

```python
# In a Spark task running on hundreds of executors
def write_partition(rows):
    conn = psycopg2.connect("host=prod-db ...")
    cur = conn.cursor()
    for row in rows:
        cur.execute("INSERT INTO recs VALUES (%s, %s)", (row.user, row.recs))
    conn.commit()

df.foreachPartition(write_partition)
```

**Problems**:
- One network roundtrip per row — orders of magnitude below batch throughput.
- Hundreds of parallel tasks hammer prod DB and degrade live query latency.
- Task retries cause duplicate inserts; partial job failure leaves the DB in an inconsistent state — breaks all-or-nothing.

### Mutating a live Elasticsearch index in a batch job

```python
for doc in spark_df.toLocalIterator():
    es.index(index="products", id=doc.id, body=doc.asDict())  # mutates live
```

**Problems**:
- Live queries see partial / inconsistent state during the rebuild.
- A failed midway run leaves a corrupted live index with no clean rollback.

## Good Examples

### ELT with dbt on a cloud warehouse

```sql
-- models/staging/stg_orders.sql (raw -> cleaned, runs in Snowflake)
SELECT
  order_id,
  customer_id,
  CAST(amount AS NUMERIC(10,2)) AS amount,
  CAST(created_at AS TIMESTAMP) AS created_at
FROM {{ source('raw', 'orders') }}
WHERE amount IS NOT NULL

-- models/marts/fct_daily_revenue.sql (mart, scheduled)
SELECT
  DATE_TRUNC('day', created_at) AS day,
  SUM(amount) AS revenue
FROM {{ ref('stg_orders') }}
GROUP BY 1
```

**Why it works**:
- Raw data is loaded; transforms run as SQL in the warehouse (ELT).
- dbt builds a DAG of models; lineage and tests are first-class.
- Orchestrated by Airflow/Dagster on a schedule.

### Airflow ETL: operational DB to warehouse

```python
from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.snowflake.transfers.s3_to_snowflake import S3ToSnowflakeOperator

with DAG("orders_etl", schedule="@hourly", catchup=False) as dag:
    extract = PostgresOperator(
        task_id="extract_to_s3",
        postgres_conn_id="prod_pg",
        sql="COPY (SELECT * FROM orders WHERE updated_at > '{{ prev_execution_date }}') TO 's3://...';",
    )
    load = S3ToSnowflakeOperator(
        task_id="load_to_snowflake",
        stage="orders_stage",
        table="raw.orders",
        file_format="(TYPE = 'CSV')",
    )
    extract >> load
```

**Why it works**:
- Scheduler manages dependencies, retries, and operators for both source and sink.
- Source DB sees one efficient bulk read per run.

### ML training pipeline (Airflow + Spark + SageMaker)

```python
with DAG("rec_model_daily", schedule="0 2 * * *") as dag:
    features = SparkSubmitOperator(
        task_id="feature_engineering",
        application="s3://jobs/build_features.py",  # Spark MLlib transforms
    )
    train = SageMakerTrainingOperator(
        task_id="train_model",
        config={"AlgorithmSpecification": {...}, "InputDataConfig": [...]},
    )
    register = PythonOperator(
        task_id="register_model",
        python_callable=lambda: mlflow.register_model("s3://.../model", "rec_model"),
    )
    features >> train >> register
```

**Why it works**:
- Features built once per day in Spark, reused across jobs.
- Model artifact versioned in MLflow.
- Each step is idempotent and rerunnable.

### Serving derived data via Kafka (Pinot / Druid / Elasticsearch sink)

```python
# Spark job writes to Kafka; Pinot ingests from Kafka
df.selectExpr("CAST(user_id AS STRING) AS key",
              "to_json(struct(*)) AS value") \
  .write.format("kafka") \
  .option("kafka.bootstrap.servers", "kafka:9092") \
  .option("topic", "user_recs_v3") \
  .save()

# Then notify downstream when complete
notify_completion(topic="user_recs_v3", run_id="2026-05-11-02")
```

**Why it works**:
- Kafka is optimized for sequential bulk writes.
- Multiple downstream systems (Pinot, Elasticsearch, Druid) consume the same topic.
- Consumers hold data invisible until the completion notification arrives — preserves all-or-nothing.
- Kafka can sit in a DMZ between batch and prod networks.

### Search index rebuild with alias swap (Elasticsearch reindex pattern)

```python
new_index = f"products_{datetime.utcnow():%Y%m%d_%H%M}"
es.indices.create(index=new_index, body=mapping)

# Bulk-load from batch output
helpers.bulk(es, ((doc | {"_index": new_index}) for doc in spark_output_iter()))

# Atomic alias swap
es.indices.update_aliases(body={"actions": [
    {"remove": {"alias": "products", "index": "products_*"}},
    {"add":    {"alias": "products", "index": new_index}},
]})
```

**Why it works**:
- New index built side-by-side; live queries unaffected.
- Atomic alias swap = atomic version switch.
- Old index can be deleted later or kept for instant rollback.

### Bulk-import pattern (TiDB Lightning / RocksDB SST / Pinot)

```bash
# Spark job emits SST/Parquet files to s3://exports/recs/run=2026-05-11/
# TiDB Lightning bulk-loads directly into TiDB
tidb-lightning -config tidb-lightning.toml \
  -d s3://exports/recs/run=2026-05-11/

# Or for Pinot (Hadoop import job)
pinot-admin LaunchDataIngestionJob -jobSpecFile ingestion-spec.yaml
```

**Why it works**:
- Files built inside the batch job; database loads them in bulk (no per-row writes).
- Atomic version swap; very fast.
- Pair with hybrid stores (Venice) when incremental updates are also needed.

## Real Tools by Category

| Category | Tools |
|----------|-------|
| ELT modeling | dbt, SQLMesh |
| Orchestration | Airflow, Dagster, Prefect, Flyte |
| Batch engines | Spark, Flink (batch mode), DuckDB, Trino |
| Warehouses | Snowflake, BigQuery, Redshift, ClickHouse |
| Lakehouse formats | Apache Iceberg, Delta Lake, Apache Hudi |
| ML training | SageMaker, Vertex AI, Kubeflow, Ray, Flyte |
| Feature stores | Tecton, Feast |
| Model registry | MLflow |
| Real-time OLAP sinks | Apache Druid, Apache Pinot, ClickHouse |
| Derived stores | Venice (hybrid), Elasticsearch, RocksDB |
| Bulk import tools | TiDB Lightning, Pinot Hadoop import, RocksDB SST API |
| BI / visualization | Tableau, Power BI, Looker, Apache Superset |
| Notebooks | Jupyter, Hex |
