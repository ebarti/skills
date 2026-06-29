# Batch Processing Foundations Knowledge

Core concepts for batch processing — from Unix pipelines to distributed dataflow engines.

## Overview

Batch processing reads a large, bounded dataset, performs computation, and writes a derived output. Jobs are throughput-oriented (not latency-oriented), often run on a schedule, and regenerate output from scratch every run. Modern systems scale this model from a single machine of Unix tools to clusters of thousands of nodes via distributed filesystems, object stores, and dataflow engines.

## Key Concepts

### Batch Processing

**Definition**: Reads a fixed-size (bounded) input dataset and produces an output dataset; runs to completion, then exits.

- Throughput-oriented: optimize records/second, not per-record latency
- Idempotent: rerunning a job with the same input produces the same output
- Inputs are immutable during the run; outputs are written atomically at the end

### Unix Philosophy

**Definition**: Compose small single-purpose tools via stdin/stdout pipes to build larger pipelines.

- Tools (`awk`, `sort`, `uniq`, `grep`, `head`, `xargs`) read text from stdin, write to stdout
- Pipes connect output of one process to input of next via small in-memory buffers (with backpressure)
- GNU `sort` spills to disk and parallelizes across cores — handles datasets larger than memory
- Limitation: runs on a single machine

### Distributed Filesystem (DFS)

**Definition**: A filesystem whose blocks are spread across many machines (shared-nothing), accessed via a network protocol.

- HDFS (Hadoop), GlusterFS, JuiceFS, DeepSeek 3FS
- Large blocks (HDFS = 128 MB; vs ext4 = 4 KB) reduce metadata overhead
- DataNodes hold blocks; NameNode holds metadata (file -> block -> node mapping)
- Replication or erasure coding (Reed-Solomon) for fault tolerance
- Allows compute-on-data-locality: schedule task on a node that has the input block

### Object Store

**Definition**: A flat, immutable, key-addressed blob store with a `get`/`put` API exposed over HTTP.

- Amazon S3, GCS, Azure Blob, OpenStack Swift, MinIO, R2, B2
- Objects are immutable; updates rewrite entire object (limited append support in S3 Express, Azure)
- "Directories" are a convention — slashes are part of the key; prefix-list ~ recursive `ls -R`
- No atomic rename, no hard/symbolic links, no file locks
- Decouples storage from compute: scale independently; data flows over fast datacenter network

### Shared-Nothing Architecture

**Definition**: Each node has its own private CPU, memory, and disk; nodes coordinate over a conventional network only.

- Contrast with shared-disk (NAS, SAN with Fibre Channel) — no special hardware
- Built on commodity hardware; tolerates higher per-node failure via replication

### MapReduce

**Definition**: A two-stage batch model: a **mapper** emits key-value pairs from input records; a **reducer** receives all values for one key (after sort/shuffle) and emits output.

- Mapper is stateless across records; many run in parallel on input shards
- Framework sorts mapper output by key (the implicit shuffle), then routes each key to one reducer
- Intermediate data is written to the DFS between jobs — robust but slow
- Multi-step pipelines = chained MapReduce jobs

### Shuffle

**Definition**: Distributed sort that brings all key-value pairs with the same key to the same reducer.

- Each mapper writes one local sorted file per reducer (hash-of-key picks the file)
- Each reducer fetches its file from every mapper and merge-sorts them
- Foundational primitive: powers joins and group-by
- Despite the name, output is sorted (not random)

### Dataflow Engine

**Definition**: An execution engine that models a whole workflow as a single DAG of operators (not separate jobs).

- Spark, Flink, Tez, Daft, Dryad, Nephele
- Operators (map, filter, join, group-by) are flexibly composed — no forced map/reduce alternation
- Intermediate state stays in memory (spill to local disk if needed); only final output to DFS
- Pipelining: downstream operators start as soon as input is ready
- Locality-aware scheduling: place consumer on producer's node
- Spark recomputes lost partitions from lineage; Flink uses periodic checkpoints

### Joins (Distributed)

| Join | When | How |
|------|------|-----|
| **Sort-merge** | Both sides are large | Shuffle both by join key; reducer merges sorted streams |
| **Broadcast hash** | One side small enough to fit in memory | Ship small side to every node; build hash table; stream large side |
| **Partitioned hash** | Both sides already sharded by join key | Each node joins its local partitions only — no shuffle |

### Job Orchestrator

**Definition**: A cluster-level system that schedules tasks, allocates resources, and tracks task liveness across a fleet.

- YARN (Hadoop), Kubernetes, Mesos
- **Task executors** (NodeManager / kubelet): run tasks, send heartbeats, enforce isolation via cgroups
- **Resource manager**: tracks node state in coordination service (ZooKeeper / etcd)
- **Scheduler**: assigns tasks to nodes; balances fairness vs efficiency (NP-hard, uses heuristics like FIFO, DRF, bin-packing)

### Workflow Scheduler

**Definition**: A system that orchestrates DAGs of multi-step batch jobs with dependencies and triggers.

- Airflow, Dagster, Prefect, Argo Workflows
- Waits until all upstream jobs succeed before starting downstream
- Manages scheduling, retries, alerting, lineage across 50-100+ job pipelines
- Distinct from per-job schedulers (YARN, Spark scheduler) — orchestrates between jobs

## Terminology

| Term | Definition |
|------|------------|
| Bounded data | A fixed, finite input dataset (vs unbounded streams) |
| Working set | Memory needed for the job's random-access state |
| Backpressure | Slowing producer when consumer's buffer is full |
| Spot/preemptible instance | Cheap VM the cloud may kill at any time |
| Gang scheduling | Wait until all N tasks for a job can start together |
| Erasure coding | Reed-Solomon-style redundancy with less storage than full replication |
| Secondary sort | Reducer receives values for a key in a controlled order |
| Lineage | Recipe of how a dataset was computed (used to recompute on failure) |

## How It Relates To

- **Stream processing**: batch handles bounded data; stream handles unbounded
- **Cloud data warehouses** (BigQuery, Snowflake): converged with batch — both use SQL, columnar storage, distributed shuffle
- **Functional programming**: MapReduce's stateless mapper/reducer enables free parallel retries

## Common Misconceptions

- **Myth**: MapReduce shuffle randomizes data.
  **Reality**: It produces a sorted order keyed by the mapper's output key.

- **Myth**: Object stores are just cheap distributed filesystems.
  **Reality**: They lack atomic rename, locks, and links; objects are immutable.

- **Myth**: You should always write raw MapReduce for big jobs.
  **Reality**: Use Spark, Flink, or SQL on top — raw MapReduce is slow and laborious.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Unix pipes | Compose stateless tools via stdin/stdout |
| HDFS | Block-based DFS with NameNode metadata + DataNode blocks |
| S3 / object store | Immutable key-addressed blobs, flat namespace |
| MapReduce | map -> sort -> reduce, intermediates to DFS |
| Dataflow engine | DAG of operators, intermediates in memory |
| Shuffle | Distributed sort that routes each key to one reducer |
| Sort-merge join | Shuffle both sides, merge sorted streams in reducer |
| Broadcast join | Ship small side everywhere, hash-join locally |
| Workflow scheduler | Airflow/Dagster orchestrate DAGs of jobs |
