# Operational vs Analytical Systems Knowledge

Core concepts distinguishing operational (OLTP) from analytical (OLAP) systems and the storage architectures built around them.

## Overview

Modern data architectures split into two system types: operational systems where data is created (OLTP), and analytical systems that hold a read-only copy optimized for analysis (OLAP). This split drives architectural decisions about data warehouses, data lakes, lakehouses, and the flow of data between systems of record and derived data.

## Key Concepts

### Operational Systems (OLTP)

**Definition**: Backend services and data infrastructure where data is created and modified based on user actions. Application code both reads and writes records.

**Key points**:
- Access pattern: point queries (fetch small number of records by key)
- Workload: lots of small queries; create/update/delete individual records
- Data represents: latest state of data (current point in time)
- Dataset size: gigabytes to terabytes
- Queries are fixed/predefined, baked into application code

### Analytical Systems (OLAP)

**Definition**: Read-only copies of operational data optimized for ad-hoc queries that aggregate over many records.

**Key points**:
- Access pattern: scan huge number of records, return aggregates (count/sum/avg)
- Workload: few queries, each complex; bulk import (ETL) or event stream writes
- Data represents: history of events over time
- Dataset size: terabytes to petabytes
- Users freely write arbitrary SQL or use BI/dashboard tools

### Data Warehouse

**Definition**: A separate database holding a read-only copy of data extracted from all OLTP systems, optimized for analytical queries.

**Key points**:
- Uses a relational data model queried through SQL
- Contains transformed, cleaned, analysis-friendly schemas
- Loaded via ETL (extract, transform, load) or ELT (transform after load)
- One enterprise data warehouse aggregates data from many OLTP systems

### Data Lake

**Definition**: Centralized repository holding raw copies of any potentially useful data as files, without imposing a particular file format, model, or schema.

**Key points**:
- Stores files (Avro, Parquet, text, images, video, sensor data, feature vectors, etc.)
- Schema-on-read; consumers transform raw data as needed
- Often built on commodity object storage (cheaper than relational storage)
- Embodies the "sushi principle": raw data is better
- Can serve as intermediate stop between operational systems and the warehouse

### ETL vs ELT

**Definition**: Pipeline patterns for moving data into analytical systems.

- **ETL** (extract–transform–load): Transform happens before loading into the warehouse.
- **ELT** (extract–load–transform): Load raw data first; transform in the warehouse afterwards.

### HTAP (Hybrid Transactional/Analytical Processing)

**Definition**: Systems that aim to serve both OLTP and analytics in one engine, avoiding ETL between systems.

**Key points**:
- Often internally an OLTP system coupled with an analytical system behind one interface
- Does NOT replace data warehouses
- Useful when one app must scan many rows AND read/update single records with low latency (e.g., fraud detection)

### Product / Real-Time Analytics

**Definition**: Analytical systems embedded into user-facing products, ingesting data in real time and optimized for low-latency aggregate queries.

### Systems of Record

**Definition**: Holds the authoritative, canonical version of data — the source of truth. New data is written here first; each fact represented exactly once (typically normalized).

**Key points**:
- If another system disagrees, the system of record is, by definition, correct
- Operational primary databases are typically systems of record

### Derived Data Systems

**Definition**: Data is the result of taking data from another system and transforming/processing it. Re-creatable from the source if lost.

**Key points**:
- Examples: caches, denormalized values, indexes, materialized views, ML models trained on data
- Technically redundant, but essential for read performance
- Multiple derived datasets can be built from one source for different views
- Analytical systems are typically derived data systems

### Reverse ETL

**Definition**: Outputs of analytical systems pushed back into operational systems (e.g., deploying a trained ML model to serve recommendations to end users).

## Terminology

| Term | Definition |
|------|------------|
| OLTP | Online Transaction Processing — interactive operational workload |
| OLAP | Online Analytical Processing — ad-hoc aggregate analytical workload |
| Point query | Fetch small number of records by key |
| ETL | Extract, Transform, Load |
| ELT | Extract, Load, Transform |
| Data silo | Data spread across multiple operational systems, hard to combine |
| Data pipeline | Generalization of ETL processes |
| Sushi principle | "Raw data is better" — keep raw form for flexible downstream use |
| HTAP | Hybrid Transactional/Analytical Processing |
| Reverse ETL | Pushing analytical outputs back to operational systems |
| BI | Business Intelligence — reporting for management decisions |
| Feature engineering | Transforming rows/columns into vectors/matrices for ML |

## How It Relates To

- **Microservices**: Each operational service typically has its own database; many OLTP DBs feed one warehouse.
- **Stream processing**: Streams enable analytical systems to respond in seconds rather than per-batch periods.
- **Data integration**: Pipelines compose multiple data systems to do what one cannot.

## Common Misconceptions

- **Myth**: HTAP eliminates the need for a data warehouse.
  **Reality**: HTAP serves apps needing both workloads at once; warehouses still aggregate across many operational systems.

- **Myth**: A given database is inherently a system of record or derived system.
  **Reality**: Most databases are just tools; the role depends on how the application uses them.

- **Myth**: "Online" in OLAP means real-time queries.
  **Reality**: It indicates interactive/explorative use by analysts (vs. predefined reports).

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| OLTP | Low-latency reads/writes of individual records by user-facing apps |
| OLAP | Ad-hoc aggregate queries scanning many records for analytics |
| Data warehouse | Relational, schema-on-write copy of operational data for SQL analytics |
| Data lake | Raw file repository, schema-on-read, holds any data type |
| ETL/ELT | Pipelines moving and shaping operational data into analytical stores |
| HTAP | Single system attempting both OLTP and OLAP workloads |
| System of record | Authoritative source of truth; data written here first |
| Derived data | Reproducible transformation of source data (cache, index, view, model) |
| Reverse ETL | Sending analytical results back into operational systems |
