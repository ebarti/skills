# Specialized Indexes Examples

Concrete systems and small illustrations for multidimensional, full-text, and vector indexes.

## Geospatial Systems

### PostGIS (PostgreSQL)

```sql
CREATE EXTENSION postgis;
CREATE INDEX restaurants_geom_gix ON restaurants USING GIST (geom);
SELECT id FROM restaurants
WHERE geom && ST_MakeEnvelope(:minlon, :minlat, :maxlon, :maxlat, 4326);
```

**Why it works**: GIST is R-tree-style; rectangular intersection avoids a full scan.

### MongoDB 2dsphere

```javascript
db.restaurants.createIndex({ location: "2dsphere" });
db.restaurants.find({
  location: { $geoWithin: { $box: [[minLon, minLat], [maxLon, maxLat]] } }
});
```

### Bad: Concatenated Index for Geo

```sql
CREATE INDEX restaurants_lat_lon ON restaurants (latitude, longitude);
SELECT * FROM restaurants
 WHERE latitude  BETWEEN 37.70 AND 37.80
   AND longitude BETWEEN -122.50 AND -122.40;
```

**Problem**: The index narrows by `latitude` only; `longitude` filter degenerates to a row scan over that band.

## Full-Text Search Engines

### Lucene-Based (Elasticsearch, OpenSearch, Solr, Tantivy)

```json
PUT /docs/_doc/1   { "title": "Red apples are sweet" }

GET /docs/_search
{ "query": { "match": { "title": "red apples" } } }
```

**Why it works**: Lucene maintains an inverted index in SSTable-like sorted files merged log-structurally; multi-term queries reduce to bitmap intersection over postings lists.

### PostgreSQL GIN

```sql
CREATE INDEX docs_fts ON docs USING GIN (to_tsvector('english', body));

SELECT id FROM docs
WHERE to_tsvector('english', body) @@ plainto_tsquery('red apples');

-- GIN also indexes JSON document fields
CREATE INDEX events_payload_gin ON events USING GIN (payload jsonb_path_ops);
```

**Why it works**: GIN stores postings lists per term, supporting natural-language search and JSON key/value lookups.

### ASCII Illustration: Inverted Index

Documents:

```
doc 1: "red apples are sweet"
doc 2: "green apples"
doc 3: "red wine"
```

Inverted index (term -> postings list):

```
   term     | postings
   ---------+----------
   apples   | [1, 2]
   green    | [2]
   red      | [1, 3]
   sweet    | [1]
   wine     | [3]
```

Query "red apples" -> intersect postings:

```
   red    -> [1, 3]
   apples -> [1, 2]
   AND    -> [1]
```

As bitmaps (one bit per doc):

```
   red     | 1 0 1
   apples  | 1 1 0
   AND     | 1 0 0   --> doc 1 matches
```

### Substring / Regex via Trigrams

```
Term:        hello
Trigrams:    hel, ell, llo

An inverted index on trigrams supports:
  - LIKE '%ell%'   (substring search)
  - regex /h.l+o/  (decompose into trigram set + verify)
```

**Trade-off**: trigram indexes are substantially larger than word indexes.

## Vector Databases and Libraries

### Faiss (Facebook)

```python
import faiss
# IVF: cluster into 100 centroids, probe 10 at query time
quantizer = faiss.IndexFlatL2(d)
ivf = faiss.IndexIVFFlat(quantizer, d, 100); ivf.train(xb); ivf.add(xb)
ivf.nprobe = 10

# HNSW: graph with M=32 neighbors per node
hnsw = faiss.IndexHNSWFlat(d, 32); hnsw.add(xb)
D, I = hnsw.search(xq, k=5)
```

**Why it works**: Faiss exposes multiple IVF and HNSW variants; choose by recall/latency/memory budget.

### pgvector (PostgreSQL)

```sql
CREATE EXTENSION vector;
CREATE TABLE docs (id bigserial PRIMARY KEY, body text, emb vector(1536));

CREATE INDEX docs_emb_hnsw ON docs USING hnsw   (emb vector_cosine_ops);
CREATE INDEX docs_emb_ivf  ON docs USING ivfflat(emb vector_cosine_ops) WITH (lists = 100);

SELECT id FROM docs ORDER BY emb <=> :query_vec LIMIT 5;
```

**Why it works**: pgvector implements both IVF and HNSW so existing PostgreSQL deployments can serve semantic search.

### Other Vector Databases

| System | Notes |
|--------|-------|
| Pinecone | Managed vector DB, HNSW-style |
| Weaviate | Open-source, HNSW |
| Qdrant | Open-source, HNSW |
| Milvus | Open-source, multiple ANN backends (IVF, HNSW) |
| Faiss | Library, embed in your own service |

### Embedding Models Mentioned in Source

| Model | Modality |
|-------|----------|
| Word2Vec | Text |
| BERT | Text |
| GPT | Text |
| Multimodal models | Text + image (and beyond) |

## Refactoring Walkthrough

### Before

```sql
CREATE INDEX r_latlon ON restaurants (latitude, longitude);

SELECT * FROM restaurants
 WHERE latitude  BETWEEN 37.70 AND 37.80
   AND longitude BETWEEN -122.50 AND -122.40;
```

### After

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
ALTER TABLE restaurants
  ADD COLUMN geom geography(Point, 4326)
  GENERATED ALWAYS AS (ST_MakePoint(longitude, latitude)::geography) STORED;
CREATE INDEX restaurants_geom_gix ON restaurants USING GIST (geom);

SELECT * FROM restaurants
WHERE geom && ST_MakeEnvelope(-122.50, 37.70, -122.40, 37.80, 4326);
```

### Changes Made

1. Replaced the concatenated B-tree with a spatial GIST (R-tree) — only structure that narrows on lat AND lon simultaneously.
2. Added a derived `geom` column so PostGIS operators can be used directly.
3. Switched the WHERE clause to bounding-box intersection, answered efficiently by the spatial index.
