# Choosing Batch vs Stream Workflow

Decide between batch processing, stream processing, or a unified architecture for a new data pipeline.

## When to Use

- Designing a new data pipeline or analytics system
- Proposing to "make X real-time" — verify the cost is justified
- Migrating an existing batch job toward lower latency
- Evaluating whether a Lambda architecture is worth its operational cost

## Prerequisites

- Clear product/business requirement for the pipeline output
- Rough sense of input data volume and velocity
- Knowledge of which downstream systems consume the result

**References**: `references/batch-foundations/rules.md`, `references/stream-processing/rules.md`, `references/data-integration/rules.md`, `references/end-to-end-correctness/rules.md`

---

## Workflow Steps

### Step 1: Define Result Freshness

**Goal**: Quantify how stale the output is allowed to be — this is the single biggest driver.

- [ ] Identify the consumer's actual freshness need (sub-second, minutes, hourly, daily)
- [ ] Distinguish "nice to have fresh" from "stale data causes harm"
- [ ] Reject vague answers like "real-time" — push for a number

**Ask**: "If this result were 1 hour old, what specifically breaks?"

| Required freshness | Likely architecture |
|--------------------|---------------------|
| Sub-second to seconds | Stream |
| Single-digit minutes | Stream (or micro-batch) |
| Hourly | Either; batch usually simpler |
| Daily / weekly | Batch |

### Step 2: Characterize the Data Shape

**Goal**: Determine whether the input is a bounded snapshot or an unbounded stream.

- [ ] Identify the source: file dump, DB snapshot, CDC stream, event log, queue
- [ ] Determine if the dataset has a natural "end" or grows forever
- [ ] Note partitioning key (often dictates parallelism)

**If bounded snapshot** (daily dump, table export): Batch is the natural fit.
**If unbounded log** (Kafka, CDC, clickstream): Stream is natural; batch becomes "windowed re-read."

**Reference**: `references/batch-foundations/rules.md`

### Step 3: Plan for Replay and Reprocessing

**Goal**: Decide if you need to recompute history when code or schema changes.

- [ ] Will logic evolve? (almost always yes)
- [ ] Is the input retained long enough to replay? (S3 forever; Kafka topic with retention)
- [ ] Is reprocessing acceptable cost? (compute + downstream rebuild time)

**If yes**: source must be a replayable log (Kafka with long retention, immutable S3, event sourcing).
**If no**: any source works, but you're stuck with additive-only schema changes.

**Reference**: `references/data-integration/rules.md` (Rule 6)

### Step 4: Estimate State Size and Complexity

**Goal**: Stream operators with large state are expensive — sometimes batch is cheaper.

- [ ] Identify required windows (tumbling, hopping, sliding, session)
- [ ] Identify required joins (stream-stream, stream-table)
- [ ] Estimate state size: window length x throughput x key cardinality
- [ ] For stream-table joins: can the table fit in operator memory?

**Red flags pushing toward batch**: multi-day join windows, terabyte-scale joined dimensions, complex multi-stage aggregations across long history.

**Reference**: `references/stream-processing/rules.md` (Rules 4, 5, 6)

### Step 5: Assess Operational Tolerance

**Goal**: Stream is harder to operate, debug, and reason about. Honestly assess the team.

- [ ] Does the team have 24/7 on-call? (stream needs it)
- [ ] Comfort with watermarks, exactly-once, fencing tokens?
- [ ] Tooling for replay, state inspection, backfill?
- [ ] Tolerance for retractions and late-arriving corrections?

**If team is new to streaming**: prefer batch + scheduled micro-batch (every 5-15 min) before jumping to true streaming.

### Step 6: Choose the Architecture

**Goal**: Commit to one model — pure batch, pure stream, or unified.

**Decision Tree**:
```
freshness >= hourly AND data bounded?
  -> Pure batch (Spark/Flink + Airflow/Dagster)

freshness < minutes AND data unbounded?
  -> Pure stream (Flink, Kafka Streams, Materialize)

freshness mixed (some queries fresh, some historical)?
  -> Unified (Beam, Flink) running same code on both modes
  -> NEVER Lambda (two codebases for the same logic)

stream needed but team not ready?
  -> Micro-batch every N minutes as a stepping stone
```

**Reference**: `references/data-integration/rules.md` (Rule 7)

### Step 7: Pick Tooling

**Goal**: Match the engine and orchestrator to the chosen mode.

| Need | Tool |
|------|------|
| Batch SQL on warehouse | dbt + Snowflake/BigQuery/Trino |
| Batch dataflow at scale | Spark, Flink (batch mode) |
| Multi-step batch DAG | Airflow, Dagster, Prefect, Argo |
| Stream with rich state | Flink, Kafka Streams |
| Stream as SQL | ksqlDB, Flink SQL, Materialize |
| Unified batch + stream | Apache Beam (on Flink/Dataflow) |
| Lightweight stream-table joins | Materialize, RisingWave |

### Step 8: Plan the Correctness Model

**Goal**: Batch is naturally idempotent; stream needs an end-to-end argument.

**For batch**:
- [ ] Write to fresh path then atomic swap (or Iceberg/Delta commit)
- [ ] No external side effects from inside tasks; verify rerun produces same output

**For stream**:
- [ ] Replayable log-based source (Kafka, not RabbitMQ)
- [ ] Checkpoint operator state (Flink) or microbatch atomicity (Spark)
- [ ] Idempotent or transactional sink (tag writes with input offset)
- [ ] Fencing tokens for failover scenarios
- [ ] Define straggler policy (drop+alert vs publish corrections)

**Reference**: `references/stream-processing/rules.md` (Rules 8-10), `references/end-to-end-correctness/rules.md`

### Step 9: Document the Architecture

**Goal**: Make the dataflow explicit so future engineers don't reinvent it.

- [ ] Diagram source -> processor -> sinks with arrows labeled by latency SLA
- [ ] Mark which system is the source of truth
- [ ] List replay procedure and retention windows
- [ ] Document straggler/late-event policy
- [ ] Note operational runbook (failover, backfill, schema evolution)

---

## Quick Checklist

```
[ ] Step 1: Freshness requirement quantified (in seconds/minutes/hours)
[ ] Step 2: Data shape identified (bounded vs unbounded)
[ ] Step 3: Replay strategy decided (replayable log or not)
[ ] Step 4: State size and join complexity estimated
[ ] Step 5: Operational readiness honestly assessed
[ ] Step 6: Architecture chosen (batch / stream / unified)
[ ] Step 7: Engine and orchestrator picked
[ ] Step 8: Correctness model designed end-to-end
[ ] Step 9: Architecture documented
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Building Lambda architecture | Two codebases for same logic; bugs diverge | Use Beam/Flink unified API (Kappa-style) |
| Choosing stream when batch suffices | 10x operational cost for no business gain | Quantify freshness need first; default to batch |
| "Real-time" with no number attached | Drives over-engineering | Force a numeric SLA before designing |
| Per-event remote DB lookups in joins | Slow, overloads source DB | Local state + CDC changelog |
| Mixing event time and processing time | Fake spikes after redeploys/backlogs | Pick one; event time for correctness |
| No replay strategy | Cannot fix historical data or evolve schema | Use replayable log (Kafka + retention, S3) |
| Stream with no fencing tokens | Split-brain on failover corrupts state | Design fencing into failover from day one |
| Skipping straggler policy | Late events silently dropped or counted twice | Decide drop+alert vs corrections up front |

---

## Exit Criteria

Task is complete when:
- [ ] Freshness SLA is documented in seconds/minutes/hours, not adjectives
- [ ] One architecture chosen (not Lambda); rationale recorded
- [ ] Source of truth and derivation graph are diagrammed
- [ ] Correctness mechanism (idempotence/transactions/checkpoints) is explicit
- [ ] Replay procedure is written down and tested
- [ ] Team agrees the operational cost matches the business value
