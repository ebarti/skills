# Choosing a Database Type Workflow

Decide between relational, document, graph, columnar, or hybrid storage — and pick a specific product — based on workload, data shape, relationships, and schema needs.

## When to Use

- Greenfield service needing a primary datastore
- Migrating off a database that no longer fits the workload
- Adding a secondary store for a new access pattern (search, analytics, graph)
- Validating a teammate's database proposal against the actual workload

## Prerequisites

- A rough sketch of the dominant entities and how they relate
- Read/write ratio estimate, target QPS, and latency budget
- List of the top 3-5 query patterns the system must serve
- Knowledge of operational constraints (cloud vs on-prem, team familiarity)

**Reference**: `references/relational-document-models/rules.md`, `references/graph-models/rules.md`, `references/oltp-storage/rules.md`, `references/olap-storage/rules.md`

---

## Workflow Steps

### Step 1: Characterize the Workload

**Goal**: Classify the workload as OLTP, OLAP, or hybrid before anything else.

- [ ] Is this transactional (OLTP) — many small reads/writes by user-facing requests?
- [ ] Is this analytical (OLAP) — few large scans aggregating millions of rows?
- [ ] Estimate read/write ratio (e.g. 95/5 read-heavy, 30/70 write-heavy)
- [ ] List the top 3-5 query patterns (point lookup, range scan, aggregation, traversal)
- [ ] Capture latency budget (p99) and throughput target

**Ask**: "If I describe the dominant query out loud, does it sound like 'fetch this user' (OLTP) or 'sum revenue by region for last quarter' (OLAP)?"

**Reference**: `references/oltp-storage/rules.md`, `references/olap-storage/rules.md`

---

### Step 2: Characterize the Data Shape

**Goal**: Determine the structural archetype of the data.

- [ ] Mostly tabular rows with a fixed schema? → relational candidate
- [ ] Self-contained tree-shaped aggregates loaded as a unit? → document candidate
- [ ] Highly connected entities where the *connections* are the value? → graph candidate
- [ ] Wide rows scanned in column-oriented aggregates? → columnar candidate
- [ ] Heterogeneous records with no shared schema? → document candidate

**Reference**: `references/relational-document-models/rules.md` (rules 1, 4), `references/graph-models/rules.md` (rule 1)

---

### Step 3: Assess Relationships

**Goal**: Map the relationship cardinality — this is the most decisive signal.

- [ ] One-to-many, single-parent, loaded together → document
- [ ] Many-to-many requiring bidirectional reference → relational
- [ ] Deeply connected, recursive, variable-depth traversals → graph
- [ ] Mostly isolated records, occasional join → relational or document

**If only an occasional transitive query is needed in an existing SQL shop**:
- [ ] Use `WITH RECURSIVE` instead of adopting a graph DB

**Reference**: `references/relational-document-models/rules.md` (rule 2), `references/graph-models/rules.md` (rules 2, 3)

---

### Step 4: Consider Schema Evolution Needs

**Goal**: Decide between schema-on-write (rigid) and schema-on-read (fluid).

- [ ] All records share a stable structure, integrity matters → schema-on-write (relational)
- [ ] Records vary or schema changes frequently → schema-on-read (document)
- [ ] Need both? → hybrid (Postgres + JSONB columns, or Mongo with validators)

**Ask**: "Will the database catch a malformed record at write time, or will my application discover it weeks later in production?"

**Reference**: `references/relational-document-models/rules.md` (rules 3, 4)

---

### Step 5: Match to a Model

**Goal**: Combine signals from steps 1-4 into one model recommendation.

- [ ] Pick from: relational | document | graph | columnar | hybrid
- [ ] Use the decision tree below
- [ ] Document why competing models were rejected

**Decision tree (data shape → model)**:

```
Workload?
├── OLAP (analytics, large scans)
│   └── Columnar (Parquet, Snowflake, ClickHouse, DuckDB)
└── OLTP / mixed
    ├── Highly connected, recursive traversals?
    │   └── Graph (property graph or triple store)
    ├── Tree-shaped, loaded as a whole, heterogeneous?
    │   └── Document
    ├── Many-to-many, stable schema, integrity matters?
    │   └── Relational
    └── Mix of fluid sub-structure + relational integrity?
        └── Hybrid (Postgres + JSONB)
```

**Reference**: `references/relational-document-models/rules.md` Quick Reference table

---

### Step 6: Pick a Specific Product

**Goal**: Translate the model choice into a concrete product based on operational fit.

- [ ] Filter by team familiarity, ops maturity, hosted vs self-managed
- [ ] Verify product handles the storage engine needs (writes-heavy → LSM; predictable reads → B-tree)
- [ ] Confirm replication/HA model matches your durability target
- [ ] Confirm cost-per-GB and licensing fit the budget

**Model → product (sane defaults)**:

| Model | Typical product | When |
|-------|----------------|------|
| Relational | PostgreSQL | Default OLTP; JSONB gives hybrid for free |
| Relational (managed scale) | Aurora, Spanner, CockroachDB | Multi-region, horizontal scale needed |
| Document | MongoDB, DynamoDB | Tree aggregates, flexible schema |
| Property graph | Neo4j, Memgraph, KùzuDB | Cypher app traversals |
| Triple store | Datomic, AllegroGraph | RDF/Linked Data, time-travel queries |
| Columnar (warehouse) | Snowflake, BigQuery, Redshift | Cloud DW for BI |
| Columnar (embedded/OLAP) | DuckDB, ClickHouse | Single-node or low-latency analytics |
| In-memory | Redis, Memcached | Cache, session, leaderboard |
| Hybrid | Postgres + JSONB | Most "I need both" cases |

**Reference**: `references/oltp-storage/rules.md`, `references/olap-storage/rules.md`

---

### Step 7: Document the Choice and Tradeoffs

**Goal**: Record the decision so future maintainers understand it.

- [ ] Write an ADR (Architecture Decision Record) capturing: workload, data shape, chosen model, chosen product, rejected alternatives, known tradeoffs
- [ ] List the operational risks accepted (e.g. "Mongo means we own multi-document atomicity in the app")
- [ ] Note the trigger that would force re-evaluation (e.g. "if traversals exceed 5% of QPS, revisit graph DB")

---

## Quick Checklist

```
[ ] Step 1: Workload classified (OLTP/OLAP, R/W ratio, query patterns)
[ ] Step 2: Data shape identified (tabular/tree/graph/wide)
[ ] Step 3: Relationship cardinality mapped
[ ] Step 4: Schema evolution policy decided
[ ] Step 5: Model selected via decision tree
[ ] Step 6: Specific product chosen for operational fit
[ ] Step 7: Decision and tradeoffs documented
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Picking a graph DB for tabular data | Adds operational complexity with no payback | Use relational; reach for `WITH RECURSIVE` for occasional traversals |
| Going schemaless when integrity matters | Bad data found weeks later in production | Use schema-on-write or add validators (Mongo `$jsonSchema`, Postgres + JSONB + check constraints) |
| Choosing a database "because we use GraphQL" | GraphQL is an API contract, not a storage engine | Pick the DB for the data; resolve GraphQL on top of it |
| Using OLTP row-store for analytics | Aggregations scan unused columns; slow and expensive | Replicate to a columnar store (Snowflake, ClickHouse, DuckDB) |
| Embedding unbounded arrays in documents | Documents rewritten in full on every update; locality lost | Split fast-growing subfields into a separate collection |
| Denormalizing fields that change often | Update storms across many copies | Store a reference (ID); join at read time, or use materialized views with explicit refresh |
| Adding indexes "just in case" | Each index slows every write; wastes space | Add per measured query pattern; drop unused indexes |
| Picking a write-heavy LSM engine for range-scan workloads | LSM range scans must merge across segments | Use B-tree or pick leveled compaction with care |
| Building event sourcing for a CRUD app | Massive complexity for no audit/replay benefit | Use a normal relational store; revisit if audit/temporal queries become core |

---

## Exit Criteria

Task is complete when:
- [ ] One model is selected with explicit justification tied to workload + data shape
- [ ] One specific product is selected with operational fit confirmed
- [ ] Rejected alternatives are documented with the reason for rejection
- [ ] A re-evaluation trigger is recorded (what would invalidate this choice)
- [ ] Decision is captured in an ADR or equivalent durable doc

---

## Cross-References

- `references/relational-document-models/rules.md` — relational vs document tradeoffs, normalization, hybrid designs
- `references/graph-models/rules.md` — when graphs win, property graph vs triple store, query language choice
- `references/event-sourcing-cqrs/rules.md` — when event sourcing is worth the complexity
- `references/oltp-storage/rules.md` — LSM vs B-tree, secondary indexes, durability
- `references/olap-storage/rules.md` — columnar storage, star schema, warehouse choice
