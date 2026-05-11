# Relational vs Document Models Rules

Decision guidance for choosing data models, normalization strategy, and analytics schemas.

## Core Rules

### 1. Use the Document Model for Tree-Structured Data

If the data is a tree of one-to-many relationships and the entire tree is typically loaded together, use a document model.

- Resume / profile (one user → many positions, education entries, contacts)
- Self-contained config or settings blobs
- Entities where shredding into multiple tables would be cumbersome

**Why**: Avoids awkward multi-table joins; locality gives faster reads; matches application object structure.

### 2. Use the Relational Model When Many-to-Many Relationships Dominate

Choose relational when records frequently reference each other in both directions.

- People ↔ organizations (employment history)
- Tags shared across many entities
- Anything requiring direct reference to nested items by ID

**Why**: Joins handle many-to-many cleanly via associative tables; documents force inconsistent two-sided references or app-side joins.

### 3. Use the Relational Model When Schema Enforcement Matters

Prefer schema-on-write when all records share the same structure and you want the database to enforce it.

- Schema acts as documentation
- Catches data errors at write time
- Migrations are explicit (`ALTER TABLE`)

### 4. Use the Document Model for Heterogeneous Data

Prefer schema-on-read when records have varying structure.

- Many object types not practical to put in separate tables
- Structure determined by external systems that may change
- Rapid prototyping where schema is fluid

### 5. Normalize for OLTP, Denormalize for OLAP

- **OLTP** (transactional): Normalized — both reads and writes need to be fast, consistency matters.
- **OLAP** (analytics): Denormalized (star/snowflake/OBT) — bulk updates, read performance dominates, historical data doesn't change.

### 6. Denormalize Only When You Can Afford the Update Cost

Before denormalizing, consider:

- How often does the duplicated field change?
- Can the database guarantee atomic multi-document updates?
- Is the storage cost acceptable?

**Example**: Twitter materialized timelines store post IDs (not text), because likes/usernames change too fast to denormalize.

### 7. Keep Documents Small and Avoid Frequent Small Updates

Documents are usually rewritten in full on update. The locality benefit only applies when you read most of the document at once.

- Don't store huge nested arrays that grow unbounded
- Split out fast-changing or large subfields into separate documents
- A celebrity's comments belong in a separate collection, not embedded

### 8. Star Schema by Default for Analytics

Use star schema unless you have a specific reason to snowflake.

- Star = simpler for analysts
- Snowflake = more normalized but more joins
- OBT (one big table) = consider when query latency is critical and storage is cheap

## Guidelines

### Mix Both Models When Appropriate

Modern relational databases support JSON columns; modern document databases support joins. Hybrid designs are powerful — use relational tables with embedded JSON for fluid sub-structures.

### Prefer IDs over Text Strings for Referenced Entities

Use IDs (normalized) when:
- Spelling/style consistency matters
- Localization needed
- Referenced entity may change name or attributes
- You want to attach extra metadata (logo, description) to the entity

### Use Secondary Indexes for Bidirectional Many-to-Many Queries

Instead of denormalizing the relationship on both sides, store it once and use secondary indexes (on `user_id` and `org_id` in a `positions` table) to query efficiently in either direction.

### Avoid the N+1 Query Problem with ORMs

When listing N items each containing a reference, tell the ORM to fetch related data eagerly — otherwise you'll issue N extra queries.

## Exceptions

- **Genuinely large one-to-many ("one-to-many" vs "one-to-few")**: If the "many" side has thousands of items (celebrity comments), use the relational approach even though the structure is tree-like.
- **Reorderable lists**: Document model handles user-controlled ordering naturally (JSON array); relational requires tricks (fractional indexing, integer sort columns).
- **Reference to nested items**: If you need to point directly at item X within a document, relational is better (document model can only say "the second item in the list").
- **Analytics on historical data**: Denormalization concerns about consistency don't apply because the data doesn't change.

## Quick Reference

| Situation | Recommended |
|-----------|-------------|
| Tree-shaped, loaded as a whole | Document |
| Many-to-many relationships | Relational |
| Heterogeneous records | Document |
| Strict schema needed | Relational |
| OLTP workload | Normalized relational |
| OLAP / data warehouse | Star or snowflake schema |
| Reorderable user lists | Document (JSON array) |
| Reference nested items by ID | Relational |
| Need both | Hybrid (PostgreSQL JSONB / MongoDB joins) |
| Query latency critical, storage cheap | One Big Table (OBT) |
