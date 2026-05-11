# Retrieval Algorithms Knowledge

Core concepts for choosing and combining retrieval algorithms in RAG systems.

## Overview

A RAG retriever ranks documents in a knowledge base by relevance to a query. The two foundational families are **term-based** (lexical, keyword matching) and **embedding-based** (semantic, vector similarity). Production systems usually combine both via **hybrid search**.

## Key Concepts

### Term-Based Retrieval (Lexical Retrieval)

**Definition**: Ranks documents by how often query terms appear in them, weighted by term importance.

Operates at the lexical level (surface form), not the semantic level. Two documents using different words for the same concept will not match.

**Key components**:
- **TF (Term Frequency)**: How many times a term appears in a document. Higher TF means more relevant.
- **IDF (Inverse Document Frequency)**: `log(N / C(t))` where N = total docs, C(t) = docs containing term t. Common terms ("the", "for") get low IDF; rare terms get high IDF.
- **TF-IDF score**: Sum over query terms of `IDF(t) * TF(t, D)`.
- **Inverted index**: Dictionary mapping term -> list of (document_id, term_frequency). Enables fast lookup.

### BM25 (Okapi BM25)

**Definition**: A TF-IDF variant that normalizes term frequency by document length so longer docs don't dominate.

Industry standard term-based scorer. Variants: BM25+, BM25F. Used as the baseline that more sophisticated retrievers must beat.

### Embedding-Based Retrieval (Semantic Retrieval)

**Definition**: Ranks documents by the closeness of their embedding vectors to the query embedding.

Captures meaning rather than surface form. "Transformer architecture" can match "attention-based neural networks" even with no shared keywords.

**Workflow**:
1. **Indexing**: Embedding model converts each chunk into a vector; stored in a vector database.
2. **Query embedding**: Same model embeds the query.
3. **Vector search**: Retriever returns top-k vectors closest to the query (e.g., by cosine similarity).

### Vector Database

**Definition**: A datastore optimized for storing vectors and performing fast nearest-neighbor search.

Storage is easy; the hard part is fast vector search. Many traditional databases now offer vector extensions (pgvector, Elasticsearch dense vectors, etc.).

### Approximate Nearest Neighbor (ANN)

**Definition**: Algorithms that trade exactness for speed when finding the k vectors closest to a query.

Exact k-NN scans every vector; impractical above a few thousand items. ANN organizes vectors into buckets, trees, or graphs to skip most comparisons.

**Major ANN algorithms**:

| Algorithm | Structure | Notes |
|-----------|-----------|-------|
| LSH | Hash buckets | Hashes similar vectors into same bucket. Implemented in FAISS, Annoy. |
| HNSW | Multi-layer graph | High accuracy, fast queries; expensive to build. In FAISS, Milvus, hnswlib. |
| Product Quantization | Compressed subvectors | Reduces dimensionality for speed. Backbone of FAISS. |
| IVF | K-means clusters | Searches only nearest centroids' clusters. Backbone of FAISS. |
| Annoy | Random binary trees | Spotify's library. Tree-based partitioning. |

### Hybrid Search

**Definition**: Combining term-based and embedding-based retrieval to leverage both lexical exactness and semantic understanding.

Two combination strategies:
- **Sequential (reranking)**: Cheap retriever fetches candidates, expensive retriever reranks them.
- **Parallel (ensemble)**: Multiple retrievers run independently; rankings fused with an algorithm like RRF.

### Reciprocal Rank Fusion (RRF)

**Definition**: Algorithm for merging rankings from multiple retrievers.

Formula: `Score(D) = Σ 1 / (k + r_i(D))` where `r_i(D)` is the rank of D by retriever i, and k is a constant (typically 60) that dampens the influence of low-ranked items.

## Terminology

| Term | Definition |
|------|------------|
| TF | Term frequency in a document |
| IDF | Inverse document frequency across the corpus |
| Inverted index | Term -> documents mapping for fast lookup |
| Tokenization | Splitting text into terms (words, n-grams) |
| n-gram | Contiguous sequence of n tokens (e.g., "hot dog") |
| Embedding | Dense vector preserving semantic properties |
| Vector search | Finding vectors closest to a query vector |
| ANN | Approximate Nearest Neighbor (fast, inexact) |
| k-NN | Exact k Nearest Neighbors (precise, slow) |
| Reranking | Re-ordering candidates with a more expensive scorer |
| RRF | Reciprocal Rank Fusion |
| Context precision | % of retrieved docs that are relevant |
| Context recall | % of relevant docs that were retrieved |

## Common Misconceptions

- **Myth**: Embedding-based retrieval always beats BM25.
  **Reality**: BM25 is a strong baseline. Embedding wins only with good models, often after finetuning.

- **Myth**: Vector databases are required for RAG.
  **Reality**: Any storage that supports vector search works. Many SQL/NoSQL DBs added vector extensions.

- **Myth**: Embeddings handle exact identifiers (error codes, SKUs) well.
  **Reality**: Embeddings can obscure exact tokens like `EADDRNOTAVAIL`; use hybrid search for these cases.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| TF-IDF | Score = TF * IDF; rewards rare matched terms |
| BM25 | TF-IDF with document-length normalization |
| Inverted index | Term-to-documents lookup table |
| Vector DB | Stores embeddings; runs ANN search |
| ANN | Trades exactness for query-time speed |
| Hybrid search | Term-based + embedding-based combined |
| Reranker | Second-pass scorer on top-N candidates |
| RRF | Rank-based fusion of multiple retrievers |
