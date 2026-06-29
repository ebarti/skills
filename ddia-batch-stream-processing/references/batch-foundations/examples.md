# Batch Processing Examples

Concrete examples of batch tooling, architectures, and join strategies.

## 1. Unix Pipeline: Top 5 URLs from Access Log

```bash
cat access.log \
  | awk '{print $7}' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -n 5
```

Output:
```
4189 /favicon.ico
3631 /2016/02/08/how-to-do-distributed-locking.html
2124 /2020/11/18/distributed-systems-and-elliptic-curves.html
1369 /
 915 /css/typography.css
```

**Why it works**:
- `awk '{print $7}'` extracts the URL field
- `sort` groups identical URLs adjacent (so `uniq -c` can count them)
- `sort -rn` sorts numerically descending; `head -n 5` keeps top 5
- GNU `sort` spills to disk and parallelizes — handles GB log files in seconds

## 2. HDFS Architecture

```
                  +-------------------+
                  |     NameNode      |   <- file -> block -> node mapping
                  | (metadata service)|      (single point of metadata)
                  +---------+---------+
                            |
        +-------------------+-------------------+
        |                   |                   |
   +----+----+         +----+----+         +----+----+
   | DataNode|         | DataNode|         | DataNode|
   | blk_001 |         | blk_001 |         | blk_002 |
   | blk_002 |         | blk_003 |         | blk_003 |
   +---------+         +---------+         +---------+

  - Each block (default 128 MB) is replicated 3x across DataNodes.
  - Schedulers place tasks on a node that holds a replica of the input block
    -> data locality; no network read required.
```

## 3. MapReduce Word Count

```python
# Mapper: emit (word, 1) for every word in every line
def mapper(key, line):
    for word in line.split():
        emit(word, 1)

# Reducer: framework groups all 1s for each word together
def reducer(word, counts):
    emit(word, sum(counts))
```

**Flow**:
1. Framework reads input shards from HDFS, calls `mapper` per record.
2. Each mapper writes one local sorted file per reducer (hash of word picks the file).
3. Each reducer pulls its file from every mapper, merge-sorts, then calls `reducer` once per unique word.
4. Reducer outputs are written back to HDFS as the job's result.

## 4. Spark DataFrame Example

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count, desc

spark = SparkSession.builder.appName("top-urls").getOrCreate()

# Read access log (one row per request)
events = spark.read.parquet("s3://logs/access/")

top5 = (
    events
    .filter(col("status") == 200)
    .groupBy("url")
    .agg(count("*").alias("hits"))
    .orderBy(desc("hits"))
    .limit(5)
)

top5.write.mode("overwrite").parquet("s3://reports/top-urls/")
```

**Why it works**:
- DataFrame API translates to a query plan -> Catalyst optimizer rewrites it -> runs on Spark's dataflow engine.
- Reads only the columns needed (Parquet projection pushdown).
- Filter pushed before groupBy (predicate pushdown).
- Output is written atomically as a Parquet directory.

## 5. Real Systems Map

| System | Type | Use For |
|--------|------|---------|
| **Hadoop MapReduce** | Batch engine (legacy) | Avoid for new work; foundational reference |
| **Apache Spark** | Dataflow engine | General batch, ML, SQL, streaming |
| **Apache Flink** | Dataflow engine | Stream-first; also strong batch |
| **Apache Beam** | Unified batch+stream API | Portable pipelines (runs on Spark, Flink, Dataflow) |
| **Trino / Presto** | Distributed SQL engine | Interactive analytical queries on lakes |
| **dbt** | SQL transformation framework | Modeling layer on top of Snowflake/BigQuery/Spark |
| **HDFS** | Distributed FS | On-prem clusters, data locality |
| **Amazon S3 / GCS / Azure Blob** | Object store | Cloud storage for data lakes |
| **YARN / Kubernetes** | Resource manager | Cluster scheduling for batch jobs |
| **Airflow / Dagster / Prefect / Argo** | Workflow orchestrator | DAGs of multi-step pipelines |

## 6. Joins: Broadcast vs Partitioned Hash

### Broadcast Hash Join (small + large)

```
   small_table (10 MB)              large_table (10 TB, sharded)
        |                                  |
        | broadcast to every executor      | (already sharded)
        v                                  v
   +-----------+                    +------------+
   | executor 1|                    | shard 1    | -- hash join with broadcast --> output
   | hash_tbl  |                    +------------+
   +-----------+                    +------------+
   +-----------+                    | shard 2    | -- hash join with broadcast --> output
   | executor 2|<-- copy on every --+------------+
   | hash_tbl  |    executor        +------------+
   +-----------+                    | shard 3    | -- hash join with broadcast --> output
                                    +------------+

   No shuffle of the large side.
```

### Partitioned Hash Join (both pre-sharded by join key)

```
   left_table (sharded by user_id)       right_table (sharded by user_id)
   +----------+ +----------+ +----------+ +----------+ +----------+ +----------+
   | shard 0  | | shard 1  | | shard 2  | | shard 0  | | shard 1  | | shard 2  |
   |  uid % 3 | |  uid % 3 | |  uid % 3 | |  uid % 3 | |  uid % 3 | |  uid % 3 |
   |   == 0   | |   == 1   | |   == 2   | |   == 0   | |   == 1   | |   == 2   |
   +----+-----+ +----+-----+ +----+-----+ +----+-----+ +----+-----+ +----+-----+
        |            |            |            |            |            |
        +-----+------+            |            +-----+------+            |
              |    +--------------+                  |    +--------------+
              v                                      v
        +-----------+                          +-----------+
        | join @ 0  |   no network shuffle --> | join @ 1  |   etc.
        +-----------+                          +-----------+

   Each node joins its own partitions only; no cross-network data movement.
```

### Sort-Merge Join (both sides large, neither pre-sharded)

```
   mappers shuffle both sides by join key
                |
                v
   reducer receives sorted run from each side
                |
                v
   merge two sorted streams; emit matches
```

## 6. Object Store URL Anatomy

```
s3://my-photo-bucket/2025/04/01/birthday.png
    \---------------/\------------------------/
       bucket name             object key
    (globally unique)   (slashes = convention only)
```

- `list` with prefix `2025/04/` returns ALL objects under that prefix (no directory concept)
- Renaming `2025/04/` to `2025/05/` requires copying every object and deleting the original
- Empty "directories" are simulated with a zero-byte placeholder object
