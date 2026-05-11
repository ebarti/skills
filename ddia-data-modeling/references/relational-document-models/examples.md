# Relational vs Document Models Examples

Concrete schemas, query examples, and real databases illustrating relational and document model trade-offs.

## Example 1: LinkedIn Resume — One-to-Many

A user profile has one name, but many positions, education entries, and contacts.

### Relational Representation (shredding)

```sql
users (user_id PK, first_name, last_name, region_id FK)
positions (id PK, user_id FK, organization, role, start, end)
education (id PK, user_id FK, school_name, degree, year)
contact_info (id PK, user_id FK, type, value)
regions (region_id PK, name)
```

To fetch a profile: multiple queries by `user_id` or a multi-way join.

### Document Representation (JSON)

```json
{
  "user_id": 251,
  "first_name": "Barack",
  "last_name": "Obama",
  "region_id": 18,
  "positions": [
    {"organization": "U.S. Senate", "role": "Senator"},
    {"organization": "White House", "role": "President"}
  ],
  "education": [
    {"school_name": "Columbia", "degree": "BA"},
    {"school_name": "Harvard Law", "degree": "JD"}
  ],
  "contact_info": [
    {"type": "twitter", "value": "@barackobama"}
  ]
}
```

**Why document works here**: One-to-many tree, entire profile loaded together, better locality, fewer queries.

## Example 2: Many-to-Many — People and Organizations

When organizations become entities (with logos, descriptions), employment becomes many-to-many.

### Relational (associative table)

```sql
users (user_id PK, ...)
organizations (org_id PK, name, logo_url, description)
positions (id PK, user_id FK, org_id FK, role, start, end)
```

Index on both `user_id` and `org_id` enables bidirectional queries (people at an org, orgs of a person).

### Document with References

```json
{
  "user_id": 251,
  "positions": [
    {"org_id": "white_house", "role": "President"},
    {"org_id": "us_senate", "role": "Senator"}
  ]
}
```

The `org_id` references a separate `organizations` document. Bidirectional queries require either:
- Storing IDs on both sides (denormalized, risks inconsistency), or
- Secondary index on `positions.org_id` inside documents.

## Example 3: Normalization — IDs vs Strings

```json
// Denormalized (copies logo_url everywhere)
{"organization": "Acme", "logo_url": "https://.../acme-v1.png"}

// Normalized (reference by ID)
{"org_id": "acme"}
// organizations table holds {id: "acme", name: "Acme", logo_url: "..."}
```

Updating the logo: trivial in normalized form (one row); requires finding all occurrences in denormalized form.

## Example 4: Join Resolution

```sql
-- SQL join
SELECT users.*, regions.name FROM users
JOIN regions ON users.region_id = regions.region_id
WHERE users.user_id = 251;
```

```javascript
// MongoDB $lookup join
db.users.aggregate([
  { $match: { user_id: 251 } },
  { $lookup: { from: "regions", localField: "region_id",
               foreignField: "region_id", as: "region" }}
]);
```

## Example 5: Star Schema for Analytics

Grocery retailer warehouse:

```
fact_sales (
  date_key FK,
  product_sk FK,
  store_sk FK,
  customer_sk FK,
  promotion_sk FK,
  quantity, net_price, discount, cost
)

dim_product (product_sk PK, sku, description, brand, category, package_size)
dim_store   (store_sk PK, name, city, state, square_footage, has_bakery)
dim_date    (date_key PK, day, month, year, day_of_week, is_holiday)
dim_customer(customer_sk PK, name, segment, loyalty_tier)
dim_promotion(promotion_sk PK, name, discount_pct, ad_type)
```

- **Fact table**: One row per purchase event (potentially billions of rows, hundreds of columns).
- **Dimension tables**: Wide; describe the who/what/where/when/why.
- **Even date is a dimension**: Lets queries differentiate holidays vs weekdays.

### Snowflake Variant

```
dim_product (product_sk, sku, description, brand_id FK, category_id FK)
dim_brand   (brand_id PK, brand_name, parent_company)
dim_category(category_id PK, category_name, department_id FK)
```

More normalized but more joins — analysts often prefer the simpler star.

## Example 6: Schema Migration — Schema-on-Write vs Schema-on-Read

### Schema-on-Read (document) — handle in app code

```javascript
if (user.name && !user.first_name) {
  // Old format: split full name on read
  [user.first_name, user.last_name] = user.name.split(' ', 2);
}
```

### Schema-on-Write (relational) — explicit migration

```sql
ALTER TABLE users ADD COLUMN first_name TEXT;
UPDATE users SET first_name = split_part(name, ' ', 1);
-- UPDATE on a large table is slow; tools exist for online migrations.
```

## Example 7: Aggregation Query — Sharks per Month

```sql
-- PostgreSQL
SELECT date_trunc('month', observation_timestamp) AS month,
       sum(num_animals) AS total
FROM observations WHERE family = 'Sharks' GROUP BY month;
```

```javascript
// MongoDB aggregation pipeline
db.observations.aggregate([
  { $match: { family: "Sharks" } },
  { $group: { _id: { $dateToString: { format: "%Y-%m",
              date: "$observationTimestamp" }},
              totalAnimals: { $sum: "$numAnimals" }}}
]);
```

Same expressiveness, different syntax (English-like SQL vs JSON pipeline).

## Real Databases Mentioned

| Database | Type | Notes |
|----------|------|-------|
| PostgreSQL | Relational | Strong JSON/JSONB support, indexing inside documents |
| MySQL | Relational | JSON support added |
| Oracle | Relational | Multi-table index cluster tables for locality |
| Google Spanner | Relational | Interleaved tables (rows nested in parent) for locality |
| MongoDB | Document | Added `$lookup` joins, secondary indexes |
| Couchbase | Document | Added joins and declarative queries |
| RethinkDB | Document | Added joins and declarative queries |
| Google Bigtable | Wide-column | Column families for locality |
| HBase, Accumulo | Wide-column | Bigtable-style locality |

## ORM Frameworks Cited

- **ActiveRecord** (Ruby on Rails)
- **Hibernate** (Java)

Both reduce object-relational boilerplate but can mask N+1 query problems and produce awkward auto-generated schemas.
