# Set Up the RAG Pipeline Workflow

Pinecone-based ingestion: index → namespaces → chunking → embedding → upsert.

## When to Use

- First-time setup of the engine's RAG layer
- Re-indexing after a knowledge-base refresh
- Adding a new namespace for a different RAG kind

## Prerequisites

- Pinecone account + API key
- OpenAI API key (for embeddings)
- Source data (procedural blueprints + factual documents) ready

**Reference**: `references/rag-ingestion/knowledge.md`, `references/rag-ingestion/checklist.md`

---

## Workflow Steps

### Step 1: Install + configure

**Goal**: Get dependencies and secrets in place.

- [ ] Install `pinecone`, `openai`, `tiktoken` (pinned versions)
- [ ] Load API keys from env (or Colab `userdata`)
- [ ] Initialize OpenAI + Pinecone clients

**Reference**: `references/rag-ingestion/examples.md` (install + clients section)

---

### Step 2: Create the index

**Goal**: One serverless Pinecone index, two namespaces.

- [ ] Choose embedding model (`text-embedding-3-small` recommended, lock dimension)
- [ ] Create index with `cosine` metric, serverless spec
- [ ] Verify index is ready

**Reference**: `references/rag-ingestion/examples.md` (index creation)

---

### Step 3: Define namespaces

**Goal**: One namespace per RAG kind.

- [ ] Create `context-library` namespace for procedural blueprints
- [ ] Create `knowledge-base` namespace for factual documents
- [ ] If re-indexing: clear namespace and wait for delete to complete

**Reference**: `references/rag-ingestion/rules.md` (namespace-per-RAG-kind), `references/dual-rag/knowledge.md`

---

### Step 4: Set up the chunking helper

**Goal**: Token-aware chunking using `tiktoken`.

- [ ] Initialize `cl100k_base` tokenizer
- [ ] Implement `chunk_text(text, chunk_size, overlap)`
- [ ] Test on a sample document

**Reference**: `references/rag-ingestion/examples.md` (tokenizer + chunk_text)

---

### Step 5: Set up the embeddings helper

**Goal**: Batched embedding to keep costs low.

- [ ] Implement `get_embeddings_batch(texts)` using OpenAI batch API
- [ ] Verify dimension matches index

**Reference**: `references/rag-ingestion/examples.md` (get_embeddings_batch)

---

### Step 6: Upload the Context Library

**Goal**: Procedural blueprints in `context-library` namespace.

- [ ] Define blueprints with stable IDs (idempotent re-runs)
- [ ] Embed the INTENT (not the chunks) for procedural retrieval
- [ ] Upsert to `context-library` namespace
- [ ] Verify count matches

**Reference**: `references/rag-ingestion/examples-upload.md` (Context Library section), `references/rag-ingestion/rules.md` (embed-intent-store-payload)

---

### Step 7: Upload the Knowledge Base

**Goal**: Factual chunks in `knowledge-base` namespace.

- [ ] Chunk source documents (token-aware)
- [ ] Batch-embed all chunks
- [ ] Upsert with stable IDs (e.g. `{doc_id}_{chunk_index}`)
- [ ] Verify count matches expected

**Reference**: `references/rag-ingestion/examples-upload.md` (Knowledge Base section)

---

### Step 8: Smoke-test retrieval

**Goal**: Confirm both RAGs return sensible results.

- [ ] Query `context-library` with a procedural intent → should return blueprint
- [ ] Query `knowledge-base` with a factual question → should return relevant chunks
- [ ] Run the checklist

**Reference**: `references/rag-ingestion/checklist.md`

---

## Quick Checklist

```
[ ] Step 1: Install + clients
[ ] Step 2: Index created
[ ] Step 3: Namespaces created
[ ] Step 4: chunk_text helper
[ ] Step 5: get_embeddings_batch helper
[ ] Step 6: Context Library uploaded
[ ] Step 7: Knowledge Base uploaded
[ ] Step 8: Smoke-test retrieval
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Character-based chunking | Token boundaries broken | `tiktoken` token-aware |
| Mixing blueprints + facts in one namespace | Retrieval returns the wrong kind | One namespace per RAG kind |
| Embedding chunks for context library | Procedural retrieval becomes noisy | Embed intent, store payload |
| Random chunk IDs | Re-runs duplicate data | Stable, deterministic IDs |
| Forgetting to wait after `delete` | Upsert into stale state | Wait for deletion to complete |

---

## Exit Criteria

- [ ] Index + both namespaces exist and are populated
- [ ] Counts match expected from source data
- [ ] Procedural query returns blueprint
- [ ] Factual query returns relevant chunks
- [ ] All items in `rag-ingestion/checklist.md` pass
