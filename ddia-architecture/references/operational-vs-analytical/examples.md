# Operational vs Analytical Systems Examples

Concrete tools, scenarios, and architectures from the book illustrating operational vs analytical system choices.

## OLTP Workload Examples

### End-user web/mobile application

- Checking if an action is authorized
- Inserting/updating/deleting individual records based on user input
- Looking up a single user, order, or product by key (point query)
- Customer-facing website, point-of-sale (checkout) systems, inventory tracking, vehicle route planning, supplier management, employee administration

### Characteristics in practice

- Lots of small queries
- Predefined queries baked into application code
- Latest state of data
- GB to TB scale

## OLAP Workload Examples

### Supermarket chain BI questions

- "What was the total revenue of each of our stores in January?"
- "How many more bananas than usual did we sell during our latest promotion?"
- "Which brand of baby food is most often purchased together with brand X diapers?"

### Other analytical use cases

- Detecting fraud/abuse patterns
- Predictive analytics (risk scoring, spam filtering)
- Ranking of search results
- "People who bought X also bought Y" recommendations
- ML/AI feature engineering and model training

### Characteristics in practice

- Few queries, each complex
- Arbitrary, ad-hoc exploration
- History of events over time
- TB to PB scale

## Real-World Tools by Category

### Operational (OLTP) databases

- The book emphasizes the *pattern* over specific tools — examples mentioned in surrounding context include traditional relational engines used for transactional workloads (the chapter focuses on patterns rather than a vendor list here).

### Analytical (OLAP) — real-time / product analytics

- Pinot
- Druid
- ClickHouse

These ingest in real time and target low-latency aggregate queries embedded in user-facing products.

### BI / dashboard tools (front-ends to analytical systems)

- Tableau
- Looker
- Microsoft Power BI

### Data science / analytics frameworks (typical lake consumers)

- Pandas (Python)
- scikit-learn (Python)
- R (statistical analysis)
- Apache Spark (distributed analytics)

### File formats common in data lakes

- Avro
- Parquet
- Plus arbitrary content: text, images, videos, sensor readings, sparse matrices, feature vectors, genome sequences

### ETL / data connector services for SaaS sources

- Fivetran
- Singer
- Airbyte

Used when source systems (CRM, email marketing, credit card processing) are accessible only via SaaS APIs.

### ML model deployment to operational systems (reverse ETL)

- TFX
- Kubeflow
- MLflow

## OLTP vs OLAP Comparison Table

Reproduced from the book (Table 1-1):

| Property | Operational systems (OLTP) | Analytical systems (OLAP) |
| --- | --- | --- |
| Main read pattern | Point queries (fetch individual records by key) | Aggregate over large number of records |
| Main write pattern | Create, update, delete individual records | Bulk import (ETL) or event stream |
| Human user example | End user of web/mobile application | Internal analyst, for decision support |
| Machine use example | Checking if an action is authorized | Detecting fraud/abuse patterns |
| Type of queries | Fixed, predefined by application | Arbitrary, ad-hoc exploration by analysts |
| Query volume | Lots of small queries | Few queries, each is complex |
| Data represents | Latest state of data (current point in time) | History of events that happened over time |
| Dataset size | Gigabytes to terabytes | Terabytes to petabytes |

## Architecture Scenarios

### Enterprise with many OLTP systems → one warehouse

A large enterprise may run dozens or hundreds of OLTP systems (website, point-of-sale, inventory, vehicle routing, supplier management, employee administration). Each system runs independently with its own team. Data from all systems is extracted, transformed, and loaded into a single data warehouse so analysts can combine them in one query.

### Lake as intermediate stop

```
Operational systems  →  Data lake (raw files)  →  Data warehouse (modeled)
                              ↓
                       ML / data science
                              ↓
                     Operational systems (reverse ETL)
```

Each consumer transforms raw lake data into the form best for their needs (sushi principle).

### Reverse ETL deployment

An ML model trained on data in an analytical system is deployed back into production using TFX/Kubeflow/MLflow so it can generate end-user recommendations like "people who bought X also bought Y."

### HTAP use case

Fraud detection: a single application needs to score individual transactions in real time (per-record OLTP read/write) while simultaneously aggregating across history (OLAP scan).

## Schema References

The book mentions analytical schemas in this section, with deeper coverage in Chapter 3:

- **"Stars and Snowflakes: Schemas for Analytics"** — analytical fact/dimension schemas live in the data warehouse, not in OLTP
- The OLTP schema and the analytical schema differ; the analytical schema is generally cleaner and more denormalized for query performance

Specific star/snowflake schema details and fact/dimension table examples are not enumerated in this section — they belong to Chapter 3 coverage.

## Systems of Record vs Derived Data Examples

### Systems of record (authoritative)

- Primary application database where user input is first written
- Source of truth; normalized; each fact represented once

### Derived data (re-creatable)

- Caches (e.g., Redis fronting a primary DB)
- Denormalized representations
- Search/secondary indexes
- Materialized views
- Transformed data encodings
- ML models trained on a dataset
- Analytical systems (warehouse, lake) — they consume data created elsewhere

### Mixed example: an operational service

An operational service typically contains BOTH:
- Systems of record (the primary database where data is first written)
- Derived data (indexes and caches that speed up reads, especially for queries the system of record cannot answer efficiently)
