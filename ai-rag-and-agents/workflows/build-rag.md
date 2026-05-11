# Build RAG System Workflow

End-to-end RAG construction from corpus to production.

## When to Use

- Building RAG for the first time
- Knowledge base too large for a long-context window
- Need to ground LLM in private/proprietary data
- Existing RAG performs poorly and needs a rebuild

## Prerequisites

- A corpus of documents to index
- Decided that RAG is the right approach (vs long-context, vs finetuning)
- An LLM API or model

**Reference**: `references/rag-architecture/rules.md`

---

## Workflow Steps

### Step 1: Confirm RAG Is the Right Choice

**Goal**: Don't build RAG when long-context or finetuning would work better.

- [ ] If knowledge base < 200K tokens AND fits in context: consider long-context first
- [ ] If you need new behavior (not new facts): consider finetuning
- [ ] If you need facts that change frequently: RAG wins
- [ ] If facts are large or proprietary: RAG wins

**Reference**: `references/rag-architecture/rules.md`

---

### Step 2: Design Chunking

**Goal**: Decide how to split documents.

- [ ] Pick chunking strategy: fixed-length, recursive, token-based, or domain-specific (Q&A pairs, code blocks)
- [ ] Pick chunk size (typical 500-2000 chars or 200-500 tokens)
- [ ] Pick overlap (typical 1% or ~20 chars on a 2048-char chunk)
- [ ] If documents have structure (headings, code), respect it

**Reference**: `references/retrieval-optimization/rules.md`, `references/retrieval-optimization/examples.md`

---

### Step 3: Choose Retrieval Algorithm

**Goal**: Pick term-based, embedding-based, or hybrid.

- [ ] Term-based (BM25): identifiers, codes, exact matches
- [ ] Embedding-based: paraphrases, semantic search, multilingual
- [ ] Hybrid: combine BM25 + embeddings via RRF (often the best default)
- [ ] Pick a vector DB based on scale (FAISS for <1M chunks, dedicated DB beyond)
- [ ] Pick an embedding model (e.g., from MTEB leaderboard)

**Reference**: `references/retrieval-algorithms/rules.md`, `references/retrieval-algorithms/patterns.md`

---

### Step 4: Implement Retrieval Optimizations

**Goal**: Add the techniques that move the needle.

- [ ] **Contextual retrieval** (Anthropic style): prepend a 50-100 token context to each chunk before embedding
- [ ] **Reranker** (cross-encoder): retrieve top-K (e.g., 50), rerank to top-N (e.g., 5)
- [ ] **Query rewriting**: for multi-turn, rewrite the user query into a self-contained search query
- [ ] **Question augmentation** (FAQs): index synthetic questions pointing to each answer
- [ ] **Metadata**: preserve entity IDs, dates, source URLs for filtering

**Reference**: `references/retrieval-optimization/patterns.md`, `references/retrieval-optimization/examples.md`

---

### Step 5: Build the Generation Step

**Goal**: Construct the prompt that uses retrieved chunks.

- [ ] Wrap retrieved chunks in delimiters (XML tags or triple-quotes)
- [ ] Restrict the model: "Only use information from the provided context"
- [ ] Cite sources in the answer (chunk IDs)
- [ ] Define behavior when context is insufficient ("I don't have enough information")
- [ ] Configure sampling for grounded answers (low temperature)

**Reference**: `references/rag-architecture/examples.md`

---

### Step 6: Evaluate

**Goal**: Measure retrieval and end-to-end quality separately.

- [ ] Build a retrieval eval set: query → expected document IDs
- [ ] Measure recall@K, precision@K, NDCG, MRR
- [ ] Build an end-to-end eval set: query → expected answer
- [ ] Use AI judge or exact match for end-to-end scoring
- [ ] Slice eval by query type (factual vs reasoning vs multi-hop)

**Reference**: `ai-evaluation/workflows/design-eval-pipeline.md`

---

### Step 7: Add Production Infrastructure

**Goal**: Operate it safely.

- [ ] Add input/output guardrails
- [ ] Add monitoring for retrieval quality (avg score, # of zero-result queries)
- [ ] Add observability (log query, retrieved chunks, final answer)
- [ ] Plan for index updates (incremental vs rebuild)

**Reference**: `ai-production-architecture/references/architecture-patterns/rules.md`

---

## Quick Checklist

```
[ ] Step 1: RAG confirmed as right choice
[ ] Step 2: Chunking strategy chosen
[ ] Step 3: Retrieval algorithm selected
[ ] Step 4: Optimizations added (context/reranker/rewriting)
[ ] Step 5: Generation prompt built with citations
[ ] Step 6: Retrieval + e2e evaluation in place
[ ] Step 7: Production infrastructure in place
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Pure embedding search for code/IDs | Misses exact identifiers | Use hybrid (BM25 + embeddings) |
| No reranker on large indices | Top-K is noisy | Add cross-encoder rerank |
| Ignoring multi-turn queries | Standalone queries miss context | Rewrite query with conversation context |
| No retrieval eval, only e2e | Can't tell if retrieval is the bug | Eval retrieval separately |
| Hard-coded chunk size | Sub-optimal for the corpus | Test 2-3 sizes, measure recall |

---

## Exit Criteria

- [ ] Index built, queryable, and updateable
- [ ] Retrieval recall@5 ≥ target
- [ ] End-to-end quality ≥ target
- [ ] Monitoring + guardrails in production
