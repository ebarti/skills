# Relational vs Document Models Knowledge

Core concepts for choosing between relational (SQL) and document (JSON) data models.

## Overview

The relational model (Codd, 1970) organizes data as relations (tables) of tuples (rows) and dominated since the 1980s. The document model, popularized by NoSQL databases in the 2010s, represents data as JSON trees. Both models have converged: relational databases now support JSON, and document databases support joins.

## Key Concepts

### Relational Model

**Definition**: Data organized into relations (tables) of unordered tuples (rows), with relationships expressed via foreign keys and resolved at query time using joins.

**Key points**:
- Schema enforced at write time (schema-on-write)
- Strong support for many-to-one and many-to-many relationships
- Joins resolve foreign key references in queries

### Document Model

**Definition**: Data represented as self-contained documents (typically JSON), where related one-to-many data is nested inside a single document.

**Key points**:
- Schema not enforced (schema-on-read)
- Tree-structured data fits naturally
- Better locality: entire document fetched as one continuous string

### Object-Relational Mismatch (Impedance Mismatch)

**Definition**: The disconnect between in-memory object representations in OO code and the relational database model of tables/rows/columns, requiring an awkward translation layer.

The term is borrowed from electronics where mismatched circuit impedances cause signal reflection.

### Object-Relational Mapping (ORM)

**Definition**: Frameworks (e.g., ActiveRecord, Hibernate) that reduce boilerplate when translating between objects and relational rows.

**Key tradeoffs**: Cannot fully hide model differences; can mask inefficient queries (N+1 query problem); typically OLTP-only.

### Normalization

**Definition**: Storing each piece of human-meaningful information in exactly one place and referencing it elsewhere by ID.

The ID has no human meaning, so it never needs to change even if the referenced data does.

### Denormalization

**Definition**: Duplicating human-meaningful information across multiple records to avoid lookups, trading write cost and consistency risk for read speed.

Can be viewed as a form of derived data requiring an update process for redundant copies.

### Foreign Key / Document Reference

**Definition**: A foreign key (relational) or document reference (document) is an ID that points to a record stored elsewhere; resolved via join (relational) or application-side lookup / `$lookup` (document).

### Schema-on-Write vs Schema-on-Read

**Definition**:
- **Schema-on-write**: Schema explicit; database enforces it on insert (relational default). Analogous to static typing.
- **Schema-on-read**: Structure implicit; interpreted at read time (document default). Analogous to dynamic typing.

### One-to-Many, Many-to-One, Many-to-Many

**Definition**:
- **One-to-many** (one-to-few): One parent has several related items (resume → positions). Tree-shaped; fits documents.
- **Many-to-one**: Many records reference the same entity (many people → one region). Fits normalization.
- **Many-to-many**: Both sides reference many of the other (people ↔ organizations). Modeled with associative/join tables in SQL.

### Star Schema and Snowflake Schema

**Definition**: Analytics warehouse conventions where a central **fact table** (one row per event) holds foreign keys to surrounding **dimension tables** (who/what/where/when/how/why).

- **Star**: Dimensions stored as flat tables (preferred for analyst simplicity).
- **Snowflake**: Dimensions further normalized into subdimensions (more normalized, more complex).
- **One Big Table (OBT)**: Dimensions folded into the fact table; maximum denormalization.

### Data Locality

**Definition**: The performance benefit of storing related data physically close together so a single read retrieves it all without multiple index lookups or disk seeks.

Achieved by documents (JSON blob), Spanner interleaved tables, Oracle index cluster tables, and Bigtable column families.

### Convergence

**Definition**: The trend where relational and document databases adopt each other's features.

- Relational (PostgreSQL, MySQL): added JSON types, query operators, JSON indexing.
- Document (MongoDB, Couchbase, RethinkDB): added joins, secondary indexes, declarative query languages.

Codd's original relational model already allowed *nonsimple domains* (nested relations as values), foreshadowing JSON support 30+ years later.

## Terminology

| Term | Definition |
|------|------------|
| Relation / Table | Unordered collection of tuples |
| Tuple / Row | A single record in a relation |
| Document | A self-contained JSON tree |
| Shredding | Splitting a document-like structure into multiple relational tables |
| Hydrating | Application-side join: looking up referenced IDs to get human-readable data |
| N+1 query problem | Fetching N records then issuing one extra query per record (instead of joining once) |
| Associative / Join Table | Relational table mapping many-to-many relationships |
| Fact Table | Central event table in star schema |
| Dimension Table | Surrounding metadata tables referenced by fact table |
| Nonsimple Domains | Codd's original allowance for nested relations as values |

## Common Misconceptions

- **Myth**: Document databases are schemaless.
  **Reality**: They are schema-on-read; an implicit schema exists in the reading code.

- **Myth**: Joins prevent scalability.
  **Reality**: Hydrating IDs parallelizes well; cost doesn't depend on follower counts (Twitter timelines still join).

- **Myth**: NoSQL replaced relational databases.
  **Reality**: SQL absorbed JSON/XML/graph support; NoSQL/NewSQL terms have faded as ideas merged.

## How It Relates To

- **Graph models**: When many-to-many relationships dominate, neither relational nor document fits well; graph models become natural.
- **OLTP vs OLAP**: Normalization fits OLTP (fast reads/writes); denormalization (star/snowflake/OBT) fits OLAP analytics.
- **Encoding (Ch 5)**: JSON and other document formats raise schema evolution questions handled there.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Relational | Tables + joins + enforced schema |
| Document | Nested JSON tree + schema-on-read |
| Normalization | Store info once, reference by ID |
| Denormalization | Duplicate for read speed |
| Star schema | Fact table + dimension tables for analytics |
| Convergence | Both models now support each other's core features |
