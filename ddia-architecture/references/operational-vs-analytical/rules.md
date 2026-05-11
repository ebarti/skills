# Operational vs Analytical Systems Rules

Decision guidance for choosing between OLTP/OLAP storage, picking warehouse vs lake vs lakehouse, and structuring systems of record vs derived data.

## Core Rules

### 1. Separate Operational and Analytical Systems

Do not run analytics directly against OLTP databases.

- Analytical queries are expensive and degrade OLTP performance for end users
- OLTP schemas are poorly suited for analytical query patterns
- Data of interest is usually spread across multiple OLTP systems (data silos)
- OLTP systems may be on networks restricted by security/compliance

### 2. Choose OLTP When the Workload Is Interactive Per-Record

Use an OLTP database when:

- Requests look up or modify a small number of records by key (point queries)
- Queries are fixed and predefined by the application
- You need low-latency reads and writes for end users
- Dataset is on the order of GB to TB
- You need the latest state of data

### 3. Choose OLAP When the Workload Is Aggregate Over Many Records

Use an analytical system when:

- Queries scan large numbers of records and return aggregates (count, sum, avg)
- Users need ad-hoc, exploratory SQL or BI dashboards
- You need historical data over time, not just current state
- Dataset reaches TB to PB
- Few but complex queries dominate the workload

### 4. Use a Data Warehouse for Relational SQL Analytics

Choose a data warehouse when:

- Business analysts need SQL and BI tools (Tableau, Looker, Power BI)
- Data fits cleanly into a relational, schema-on-write model
- Cross-system queries combining many OLTP sources are required
- Workload is predictable enough to justify upfront schema design

### 5. Use a Data Lake for Heterogeneous or ML-Oriented Data

Choose a data lake when:

- Data scientists need flexibility (Pandas, scikit-learn, R, Spark)
- Data types include text, images, video, sensor data, sparse matrices, feature vectors, genome sequences
- Schemas are unknown at ingest time or vary across consumers
- Cost of relational storage is prohibitive — object storage is cheaper
- You want each consumer to transform raw data themselves (sushi principle)

### 6. Use ETL vs ELT Based on Where Transformation Belongs

- **ETL** (transform before load): When the warehouse has limited transformation capability, or transformations should be standardized centrally.
- **ELT** (load raw, transform after): When the warehouse is powerful enough to transform at scale, or downstream consumers need raw data flexibility.

### 7. Use a Lake as Intermediate Stop in Modern Pipelines

Operational → Data lake (raw) → Data warehouse (modeled) is a common pattern. Each consumer can transform raw data into the form best suited to their needs.

### 8. Consider HTAP Only for Mixed-Workload Single Apps

Use HTAP when:

- A single application must perform both per-row OLTP and aggregate scans simultaneously
- Example: fraud detection scoring per transaction while aggregating history
- Do NOT use HTAP as a substitute for a cross-system enterprise data warehouse

### 9. Identify the System of Record Explicitly

For every dataset, name exactly one system of record:

- Data is written here first
- Stored normalized; each fact represented once
- If any other system disagrees, the system of record is correct by definition

### 10. Treat Caches, Indexes, Views, and Models as Derived Data

Mark these as derived (not authoritative):

- Caches
- Denormalized values
- Search/secondary indexes
- Materialized views
- Transformed/encoded representations
- ML models trained on a dataset

You must always be able to re-create derived data from its source.

### 11. Define Update Pipelines for Derived Data

When data is derived from a system of record:

- Have an explicit process to update the derived copy when the source changes
- Use data pipelines / data integration to propagate updates
- Do not rely on a single database doing this for you — most don't

### 12. Use Reverse ETL to Operationalize Analytical Output

When analytical results must influence end-user experience (e.g., recommendations, risk scores), deploy them into operational systems via dedicated tooling (TFX, Kubeflow, MLflow).

## Guidelines

- Most operational services contain a mix of systems of record AND derived data — be clear which is which.
- Microservice pattern: each operational service owns its own DB; one shared warehouse aggregates them.
- For low-latency analytics on user-facing products, prefer real-time analytical systems over batch warehouses.
- Use specialist data connectors (Fivetran, Singer, Airbyte) for ETL from SaaS APIs you cannot query directly.

## Exceptions

- **Small scale**: General-purpose databases can serve both OLTP and OLAP comfortably at small data volumes.
- **HTAP**: Worth it for fraud-detection-style apps mixing per-record and aggregate workloads in one place.
- **Same-DB analytics**: Acceptable for low-volume reporting, especially in early-stage products before you hit silo or performance issues.

## Quick Reference

| Decision | Pick This | When |
|----------|-----------|------|
| Workload type | OLTP | Point queries, individual record CRUD, low latency |
| Workload type | OLAP | Aggregates over many records, ad-hoc analysis |
| Analytical store | Data warehouse | SQL/BI on relational data, cross-system reporting |
| Analytical store | Data lake | Flexible/raw/mixed data, ML, schema-on-read |
| Analytical store | Real-time (Pinot/Druid/ClickHouse) | User-facing low-latency aggregate queries |
| Pipeline shape | ETL | Standardized pre-load transforms |
| Pipeline shape | ELT | Powerful warehouse, raw kept for flexibility |
| Architecture | HTAP | Single app needs both workloads at once |
| Role labeling | System of record | Authoritative; written first; normalized |
| Role labeling | Derived data | Re-creatable from source; performance-oriented |
