# Retrieval Algorithm Rules

Guidelines for choosing retrieval approaches, vector databases, and embedding models for RAG.

## Core Rules

### 1. Start with BM25 as the baseline

Term-based retrieval is fast, cheap, and works well out of the box. Beat it before adding embedding complexity.

- Indexing and querying are much cheaper than embedding-based retrieval.
- Excellent default when keywords and exact terms matter (logs, code, product IDs).
- Use it as the floor any new retriever must outperform.

### 2. Use embedding-based retrieval when semantics matter more than tokens

Choose embeddings when users phrase queries differently from how documents are written, or when synonyms and paraphrases are common.

- Best when queries are natural-language and documents are prose.
- Allows finetuning the embedding model to your domain over time.
- Avoid when exact identifiers (`EADDRNOTAVAIL`, SKUs, error codes) must match.

### 3. Use hybrid search in production

Production retrieval systems typically combine both. Embedding catches paraphrases; term-based catches exact tokens embeddings obscure.

- Sequential (term-based then vector rerank) when one retriever is much cheaper.
- Parallel + RRF (`k=60` is a typical default) when retrievers have comparable cost.
- Always evaluate hybrid against each individual retriever; it doesn't always win.

### 4. Pick ANN over exact k-NN above ~10k vectors

Exact k-NN scans every vector and is O(N * d). Use it only for tiny datasets or evaluation ground truth.

- For production retrieval at scale, always use an ANN index.
- Use exact k-NN only to compute recall numbers for your ANN choice.

### 5. Match ANN algorithm to your update pattern

Different indexes trade build time, memory, query speed, and recall.

- **HNSW**: high accuracy, fast queries, slow/memory-heavy to build. Use when index updates are infrequent.
- **IVF + PQ**: balanced speed/memory, scales to billions. Backbone of FAISS for large corpora.
- **LSH**: fast/cheap to build, lower accuracy. Use when index changes constantly.
- **Annoy**: tree-based, easy to use, read-only after build. Good for static corpora (Spotify uses it).

### 6. Evaluate retrieval with precision, recall, and ranking metrics

- **Context precision**: of retrieved docs, how many are relevant. Cheap to compute (AI judge can label per-query).
- **Context recall**: of all relevant docs, how many retrieved. Requires labeling all docs in DB; expensive.
- **NDCG / MAP / MRR**: when ranking order matters (more relevant docs should be first).
- Always evaluate end-to-end RAG output too — a "good" retriever that hurts answers isn't good.

### 7. Tokenization matters for term-based retrieval

The way you split text into terms determines what BM25 can match.

- Lowercase everything; strip punctuation; remove stop words.
- Treat common n-grams ("hot dog", "machine learning") as single terms.
- Use NLTK, spaCy, or CoreNLP if your search engine doesn't tokenize for you.

## Guidelines

### Vector database selection

- Need cheap, simple, already-on-Postgres: pgvector.
- Need scale + managed: Pinecone, Weaviate, Qdrant Cloud, Milvus.
- Need full-text + vector in one engine: Elasticsearch, OpenSearch.
- Need to embed search in app code: FAISS, hnswlib, Annoy (libraries, not databases).
- Frequently updated data: prefer indexes with low build cost (LSH, IVF) over HNSW.

### Embedding model selection

- Check the **MTEB benchmark** for your task type (retrieval, classification, clustering).
- Match model dimension to vector DB cost — 1536-dim costs ~2x storage of 768-dim.
- Prefer multilingual models if queries cross languages.
- If embedding cost dominates your bill (>20% of model API spend), consider smaller open-source models.
- Whatever you pick, use the **same model** for indexing and querying.

### Cost and latency

- Generating embeddings costs money — budget regen if data changes daily.
- Vector DB spend can be 1/5 to 1/2 of model API spend; measure before scaling.
- Query embedding + vector search is usually small vs. LLM generation latency, but still measurable.
- Cache query embeddings for repeat queries.

## Exceptions

- **Tiny corpus (< few thousand docs)**: skip ANN, use exact k-NN. The complexity isn't worth it.
- **Exact-match queries dominate**: skip embeddings, BM25 is enough.
- **Highly multilingual or paraphrased queries**: skip pure BM25, embeddings carry their weight.
- **Your data never changes**: build a heavy HNSW once, query forever.

## Quick Reference

| Rule | Summary |
|------|---------|
| Start with BM25 | Cheap, strong baseline |
| Embeddings for semantics | Use when paraphrasing matters |
| Hybrid in production | Combine for best results |
| ANN above 10k vectors | Exact k-NN doesn't scale |
| Match index to update rate | HNSW for static, LSH/IVF for dynamic |
| Evaluate precision + recall | And NDCG/MAP/MRR for ranking |
| Same model both ends | Index and query use the same embedder |
| MTEB for model picks | Benchmark before you commit |
