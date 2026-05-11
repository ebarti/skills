# Specialized Indexes Rules

Guidelines for choosing among multidimensional, full-text, and vector indexes.

## Core Rules

### 1. Use a Multidimensional Index for Simultaneous Range Queries on Multiple Columns

Reach for an R-tree (or Bkd-tree, or space-filling-curve B-tree) when queries constrain two or more columns at once.

- Geospatial map-area queries (lat AND lon)
- Color-range search (red AND green AND blue)
- Time-series with secondary attribute (date AND temperature)
- Avoid relying on a concatenated index in these cases — it can only narrow on a single prefix dimension

**Example**:
```sql
-- Bad: concatenated index on (latitude, longitude) cannot narrow both ranges
SELECT * FROM restaurants
 WHERE latitude  BETWEEN ? AND ?
   AND longitude BETWEEN ? AND ?;

-- Good: declare a spatial (R-tree / GIST) index
CREATE INDEX restaurants_geo ON restaurants USING GIST (location);
```

### 2. Use a Concatenated Index Only for Prefix Lookups

A concatenated `(a, b)` index serves queries on `a` alone, or `a + b` together — never on `b` alone.

- Pick column order to match the most common query
- If multiple non-prefix queries exist, add separate indexes or move to a multidimensional structure

### 3. Use an Inverted Index for Keyword / Full-Text Search

When users search documents by words that may appear anywhere in the text, build an inverted index (term -> postings list).

- Postings as sorted lists or sparse bitmaps
- Multi-term AND queries become bitwise AND of bitmaps
- Lucene-backed engines (Elasticsearch, Solr) and PostgreSQL GIN are mature defaults

### 4. Use an N-gram (Trigram) Index for Substring or Regex Search

When queries need arbitrary substring or regular-expression match, index n-grams instead of words.

- Pick `n = 3` (trigrams) as a common default
- Accept that the index is significantly larger than a word index
- Use only when substring/regex queries are required; otherwise prefer word-level inverted indexes

### 5. Use Edit-Distance Search for Typo Tolerance

For misspelling tolerance, configure the search engine to allow edit distance >= 1 (Lucene supports this via Levenshtein automata).

- Edit distance of 1 = one insertion/deletion/substitution
- Use sparingly — wider edit distances inflate result sets and cost

### 6. Use a Vector Index for Semantic Search and RAG

When the goal is "documents that mean the same thing" rather than "documents containing this word," use vector embeddings + a vector index.

- Required for retrieval-augmented generation feeding LLM context
- Required for cross-modal search (text query -> image, etc.)
- Pick a distance function (cosine similarity for direction; Euclidean for absolute distance)

### 7. Pick the Right ANN Algorithm

| Goal | Choice |
|------|--------|
| Exact results, small dataset | Flat index (linear scan) |
| Memory-constrained, willing to tune accuracy via probes | IVF |
| High recall, fast queries, willing to spend memory on graph | HNSW |

- Flat: accurate but O(N) per query
- IVF: faster, partition-based; tune `nprobes` for accuracy/latency
- HNSW: graph-based; generally best recall/latency trade-off

### 8. Do Not Use R-trees for High-Dimensional Vectors

R-trees degrade rapidly as dimensions increase and are unsuitable for the >100-dimensional embeddings produced by typical models. Use IVF or HNSW instead.

## Guidelines

- Default geo storage: PostGIS / MongoDB 2dsphere with R-tree-style spatial indexes.
- Default text search: a Lucene-backed engine (Elasticsearch / OpenSearch) or PostgreSQL GIN for in-database needs.
- Default vector store: a vector database or pgvector if data already lives in PostgreSQL.
- Generate embeddings with a model matching your modality (text, image, multimodal).
- Treat IVF and HNSW results as approximate; verify recall on representative queries.

## Exceptions

- **Tiny dataset**: A flat (exact) vector scan may be simpler and fast enough; skip ANN tuning.
- **Single-dimension geo lookups**: A regular B-tree on a geohash/space-filling-curve key can be enough for coarse queries.
- **Pure prefix text search**: A B-tree on the column may suffice; you don't need an inverted index for `LIKE 'foo%'`.

## Quick Reference

| Need | Index |
|------|-------|
| Range on multiple columns at once | R-tree / Bkd-tree / multidim |
| Geographic area lookup | R-tree (PostGIS, 2dsphere) |
| Keyword search in documents | Inverted index (Lucene/GIN) |
| Substring or regex search | N-gram (trigram) inverted index |
| Typo-tolerant search | Lucene edit-distance / Levenshtein |
| Semantic / meaning-based search | Vector index (embeddings) |
| Highest recall ANN | HNSW |
| Memory-saving ANN | IVF |
| Exact ANN baseline | Flat index |
