# Retrieval Algorithm Examples

Python code showing BM25, embedding similarity search, and hybrid retrieval.

## BM25 Term-Based Retrieval

### Pure BM25 with rank_bm25

```python
from rank_bm25 import BM25Okapi

documents = [
    "AI engineering uses large language models for production systems",
    "Vietnamese pho recipe with beef broth and rice noodles",
    "Transformer architecture revolutionized natural language processing",
    "Easy weeknight pasta dishes for busy home cooks",
]

def tokenize(text: str) -> list[str]:
    return text.lower().split()  # add stop-word/n-gram handling for production

bm25 = BM25Okapi([tokenize(doc) for doc in documents])

query_tokens = tokenize("Vietnamese recipes for home cooking")
top_k = bm25.get_top_n(query_tokens, documents, n=2)
```

**Why it works**:
- BM25Okapi handles TF, IDF, and length normalization for you.
- Tokenization is the only place you need to make decisions (stop words, n-grams).
- O(query_terms * docs_containing_term) via the inverted index — fast.

### BM25 with Elasticsearch (production)

```python
from elasticsearch import Elasticsearch

es = Elasticsearch("http://localhost:9200")
es.indices.create(
    index="docs",
    body={"settings": {"similarity": {"default": {"type": "BM25"}}}},
    ignore=400,
)
es.index(index="docs", id=1, document={"text": "Transformer architecture for NLP"})
es.index(index="docs", id=2, document={"text": "Electric power transformer maintenance"})

result = es.search(
    index="docs",
    query={"match": {"text": "transformer neural network"}},
    size=5,
)
```

**Why it works**:
- Elasticsearch defaults to BM25 since 5.0.
- Inverted index is built and maintained for you; scales to billions of docs.

## Embedding-Based Retrieval

### Embedding similarity search with FAISS

```python
import numpy as np
import faiss
from sentence_transformers import SentenceTransformer

model = SentenceTransformer("all-MiniLM-L6-v2")  # 384-dim, fast

documents = [
    "Transformer architecture revolutionized NLP",
    "Electric transformers step down voltage in power grids",
    "Attention is all you need: a 2017 paper on neural networks",
]

# Index: embed once, store in FAISS
embeddings = model.encode(documents, normalize_embeddings=True).astype("float32")
index = faiss.IndexFlatIP(embeddings.shape[1])  # cosine since normalized
index.add(embeddings)

# Query: must use the SAME model
q_emb = model.encode(["neural network attention mechanism"],
                     normalize_embeddings=True).astype("float32")
scores, ids = index.search(q_emb, k=2)
```

**Why it works**:
- Same model for indexing and querying — non-negotiable.
- `normalize_embeddings=True` + `IndexFlatIP` gives cosine similarity.
- For >100k vectors, swap `IndexFlatIP` for `IndexHNSWFlat` or `IndexIVFPQ`.

### Scaling up: HNSW index for large corpora

```python
index = faiss.IndexHNSWFlat(384, M=32)   # M = connections/node
index.hnsw.efConstruction = 200          # build-time recall vs speed
index.hnsw.efSearch = 64                 # query-time recall vs speed
index.add(embeddings)
scores, ids = index.search(q_emb, k=10)
```

**Why it works**:
- HNSW gives near-exact recall with logarithmic query cost.
- Tune `efSearch` per query without rebuilding the index.

## Hybrid Retrieval

### Sequential: BM25 candidates, then vector rerank

```python
import numpy as np

def hybrid_retrieve(query: str, candidate_k: int = 50, final_k: int = 5):
    # Stage 1: cheap BM25 candidate fetch
    bm25_scores = bm25.get_scores(query.lower().split())
    candidate_ids = np.argsort(bm25_scores)[::-1][:candidate_k]

    # Stage 2: rerank candidates with embeddings
    q_emb = model.encode([query], normalize_embeddings=True)[0]
    sims = doc_embeddings[candidate_ids] @ q_emb
    reranked = candidate_ids[np.argsort(sims)[::-1][:final_k]]
    return [documents[i] for i in reranked]
```

**Why it works**:
- BM25 narrows millions of docs to a few hundred cheaply.
- Embeddings rerank only the candidates — keeps embedding cost bounded.
- Catches both keyword and semantic matches.

### Parallel: BM25 + embeddings fused with RRF

```python
def reciprocal_rank_fusion(rankings: list[list[int]], k: int = 60):
    """Fuse multiple ranked lists of doc IDs into one ranked list."""
    scores: dict[int, float] = {}
    for ranking in rankings:
        for rank, doc_id in enumerate(ranking, start=1):
            scores[doc_id] = scores.get(doc_id, 0.0) + 1.0 / (k + rank)
    return sorted(scores.items(), key=lambda x: x[1], reverse=True)


def hybrid_rrf(query: str, top_n: int = 5):
    bm25_rank = list(np.argsort(bm25.get_scores(query.lower().split()))[::-1][:100])
    q_emb = model.encode([query], normalize_embeddings=True)[0]
    emb_rank = list(np.argsort(doc_embeddings @ q_emb)[::-1][:100])
    fused = reciprocal_rank_fusion([bm25_rank, emb_rank], k=60)
    return [documents[doc_id] for doc_id, _ in fused[:top_n]]
```

**Why it works**:
- RRF needs only ranks, not raw scores — different scorers fuse cleanly.
- `k=60` is the standard constant; raise to flatten, lower to sharpen.
- Add more retrievers by appending to the rankings list.

## Refactoring Walkthrough

### Before: pure embedding search misses exact identifiers

```python
def retrieve(query: str, k: int = 5):
    q_emb = model.encode([query])[0]
    sims = doc_embeddings @ q_emb
    return [documents[i] for i in np.argsort(sims)[::-1][:k]]

# Query: "fix EADDRNOTAVAIL error in Node.js"
# Misses the doc that explains EADDRNOTAVAIL because the embedding
# obscured the exact token.
```

### After: hybrid catches the identifier

```python
def retrieve(query: str, k: int = 5):
    bm25_rank = list(np.argsort(bm25.get_scores(query.lower().split()))[::-1][:50])
    q_emb = model.encode([query], normalize_embeddings=True)[0]
    emb_rank = list(np.argsort(doc_embeddings @ q_emb)[::-1][:50])
    fused = reciprocal_rank_fusion([bm25_rank, emb_rank])
    return [documents[doc_id] for doc_id, _ in fused[:k]]
```

### Changes Made

1. Added a BM25 ranking so exact tokens like `EADDRNOTAVAIL` aren't lost.
2. Used RRF to merge rankings — no need to calibrate scores between retrievers.
3. Capped each retriever at top-50 candidates to keep latency bounded.
