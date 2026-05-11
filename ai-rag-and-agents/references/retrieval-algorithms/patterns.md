# Retrieval Patterns

Reusable retrieval patterns mapped to common RAG use cases.

## Pattern: BM25-Only Retrieval

### Intent

Get a working RAG retriever in days with cheap infrastructure.

### When to Use

- MVP/prototype to validate RAG end-to-end before tuning.
- Small-to-medium corpus (up to a few million docs).
- Keyword-heavy queries (code search, logs, product catalog).
- You can't afford embedding generation or a vector DB.

### Structure

```python
from rank_bm25 import BM25Okapi
bm25 = BM25Okapi([doc.lower().split() for doc in documents])
top_k = bm25.get_top_n(query.lower().split(), documents, n=5)
```

### Benefits / Considerations

- Zero embedding cost; sub-millisecond queries on the inverted index.
- Strong baseline. Misses paraphrases/synonyms.
- Tokenization (n-grams, stop words) drives quality more than the algorithm.

---

## Pattern: Pure Embedding Retrieval

### Intent

Retrieve by meaning when users query in natural language and documents are prose.

### When to Use

- Conversational assistants over docs, FAQs, knowledge bases.
- Cross-lingual search (multilingual embeddings).
- When users don't share vocabulary with the docs.

### Structure

```python
embeddings = model.encode(documents)
faiss_index = faiss.IndexFlatIP(dim)   # or IndexHNSWFlat for scale
faiss_index.add(embeddings)
scores, ids = faiss_index.search(model.encode([query]), k=5)
```

### Benefits / Considerations

- Captures semantic similarity, not surface form; finetunable per-domain.
- Loses exact-token signals (error codes, product names).
- Embedding regen + vector DB cost can rival LLM API spend.

---

## Pattern: Sequential Hybrid (Retrieve then Rerank)

### Intent

Use a cheap retriever to narrow candidates, then a precise (slower) one to rerank.

### When to Use

- Large corpus; can't afford to embed-and-search every doc.
- You have a strong reranker (cross-encoder, LLM judge, embedding similarity).
- Latency budget allows two stages.

### Structure

```python
candidates = bm25.get_top_n(query_tokens, documents, n=100)
q_emb = model.encode([query])[0]
ranked = sorted(zip(candidates, model.encode(candidates) @ q_emb),
                key=lambda x: x[1], reverse=True)[:5]
```

### Benefits / Considerations

- Bounded embedding cost (only candidates are embedded).
- Combines lexical recall with semantic precision.
- If first-stage recall is poor, the reranker can't recover; adds latency.

---

## Pattern: Parallel Hybrid with RRF

### Intent

Run multiple retrievers independently and fuse rankings without calibrating scores.

### When to Use

- BM25 and embedding retrievers each cover blind spots in the other.
- You have multiple specialized retrievers (per-source, per-language).
- Score scales differ between retrievers (RRF needs only ranks).

### Structure

```python
fused = {}
for rank_list in [bm25_rank, emb_rank]:
    for rank, doc_id in enumerate(rank_list, 1):
        fused[doc_id] = fused.get(doc_id, 0.0) + 1 / (60 + rank)
final = sorted(fused.items(), key=lambda x: x[1], reverse=True)[:5]
```

### Benefits

- Robust to score-scale differences between retrievers.
- Adding new retrievers is trivial; `k=60` is a tested default.

### Considerations

- Both retrievers run for every query — higher cost than sequential hybrid.
- Documents missed by all retrievers are still missed.

---

## Pattern: Identifier-Heavy Hybrid

### Intent

Retrieve documents containing exact identifiers (error codes, SKUs, hashes) plus context.

### When to Use

- Code search, log triage, support tickets, product lookup.
- Queries like `"fix EADDRNOTAVAIL error in Node.js"` where one token is decisive.

### Structure

Parallel hybrid, but boost term-based ranking when the query contains all-caps tokens, hex strings, or regex-detected IDs.

```python
import re
has_identifier = bool(re.search(r"\b[A-Z_]{4,}\b|0x[0-9a-f]+", query))
weights = (1.5, 1.0) if has_identifier else (1.0, 1.0)
```

### Benefits / Considerations

- Won't lose docs matching a critical exact token; embeddings still handle semantics.
- Identifier heuristics are app-specific; watch false positives on acronyms.

---

## Pattern: ANN with Periodic Rebuild

### Intent

Serve fast vector search at scale while still incorporating new data.

### When to Use

- Corpus updates daily or weekly, not in real time.
- Latency-sensitive querying (HNSW or IVF needed).

### Structure

```python
# Nightly batch job
index = faiss.IndexHNSWFlat(dim, M=32)
index.hnsw.efConstruction = 200
index.add(all_embeddings)
faiss.write_index(index, "/srv/index.bin")

# Read-only serving
index = faiss.read_index("/srv/index.bin")
index.hnsw.efSearch = 64
```

### Benefits / Considerations

- HNSW: high recall, low query latency, scales horizontally read-only.
- Build is slow and memory-heavy (acceptable as a batch job).
- New docs not searchable until next rebuild — use IVF or an incremental vector DB for streaming updates.

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|--------------------|
| MVP / prototype | BM25-only retrieval |
| Conversational doc search | Pure embedding retrieval |
| Large corpus, latency budget OK | Sequential hybrid |
| Production RAG, mixed queries | Parallel hybrid with RRF |
| Code / log / SKU search | Identifier-heavy hybrid |
| Daily-updated large corpus | ANN with periodic rebuild |
| Static corpus, max recall | HNSW + reranker |
| Tiny corpus (<10k) | Exact k-NN, no ANN needed |
