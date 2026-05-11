# RAG Ingestion Rules

Rules for building a reliable Pinecone + OpenAI ingestion pipeline.

## Core Rules

### 1. Chunk by Tokens, Not Characters

Use the same tokenizer the embedding model was trained with (`cl100k_base` for OpenAI's newer models).

- Default to chunk size 400 with 50-token overlap.
- Overlap must be strictly less than chunk size.
- Tune per data type (long technical docs may need bigger chunks).

**Example**:
```python
# Bad: character-based, misaligned with model
chunks = [text[i:i+2000] for i in range(0, len(text), 1800)]

# Good: token-aware with overlap
tokens = tokenizer.encode(text)
for i in range(0, len(tokens), chunk_size - overlap):
    chunk = tokenizer.decode(tokens[i:i + chunk_size])
```

### 2. One Namespace per RAG Kind

Keep factual and procedural data strictly separated.

- `NAMESPACE_KNOWLEDGE = "KnowledgeStore"` for facts.
- `NAMESPACE_CONTEXT = "ContextLibrary"` for blueprints.
- Always pass `namespace=...` to upsert and query calls. Never mix.

### 3. Lock the Embedding Model

The model used at ingestion MUST match the model used at retrieval.

- Pin `EMBEDDING_MODEL = "text-embedding-3-small"` in a constants block.
- Pin `EMBEDDING_DIM = 1536` and use it when creating the index.
- Never change the model without re-embedding everything.

### 4. Use Cosine Similarity for Text

Create indexes with `metric='cosine'` for text embeddings.

- Cosine is the standard for OpenAI text embeddings.
- Mismatched metrics produce nonsense rankings.

### 5. Batch Upserts

Group vectors into batches of ~100 before upserting to Pinecone.

- Reduces request overhead and avoids per-call rate-limit pressure.
- Wrap each batch's embedding call in `@retry` (Tenacity) with exponential backoff.
- Show progress with `tqdm`.

### 6. Wait for Index and Deletions

Pinecone operations can be asynchronous; poll until ready.

- After `pc.create_index(...)`, loop until `describe_index(INDEX_NAME).status['ready']`.
- After `index.delete(delete_all=True, namespace=...)`, poll `describe_index_stats()` until the namespace's `vector_count == 0` (sleep 5s between polls).

**Example**:
```python
# Bad: assume deletion is instant
index.delete(delete_all=True, namespace=ns)
index.upsert(vectors=new_vectors, namespace=ns)  # may be wiped!

# Good: wait for vector count to hit zero
while True:
    stats = index.describe_index_stats()
    if ns not in stats.namespaces or stats.namespaces[ns].vector_count == 0:
        break
    time.sleep(5)
```

### 7. Embed Intent, Store Payload as Metadata

For procedural RAG, embed only the `description` and keep the full blueprint JSON in metadata.

- Description acts like a library card; blueprint is the book.
- `blueprint_json` lives under `metadata`, not in `values`.

### 8. Pin Library Versions

Freeze versions to avoid dependency drift.

```
!pip install tqdm==4.67.1 --upgrade
!pip install openai==1.104.2
!pip install pinecone==7.0.0 tqdm==4.67.1 tenacity==8.3.0
```

### 9. Handle Secrets Safely

Never hardcode API keys.

- In Colab: read from `google.colab.userdata`.
- Locally: fall back to environment variables (`os.environ`).
- Required keys: `OPENAI_API_KEY`, `PINECONE_API_KEY`.

### 10. Make Ingestion Idempotent

Upsert is intentionally idempotent — same `id` overwrites.

- Use stable IDs (`blueprint_suspense_narrative`, `knowledge_chunk_{i+j}`) so re-runs replace, not duplicate.
- Decide explicitly per environment whether to clear namespaces before re-ingesting.

## Guidelines

- Replace `\n` with spaces before sending text to OpenAI embeddings.
- Skip empty chunks after stripping whitespace.
- Use `tqdm` to surface long-running batch progress.
- Log the count of vectors uploaded to each namespace.

## Exceptions

- **Production environments**: Do NOT clear namespaces on every run. The book uses `delete_all=True` only for the learning notebook; production systems should preserve stored knowledge.
- **Large corpora**: Increase `batch_size` above 100 only after measuring API limits.
- **Non-OpenAI embeddings**: Swap the tokenizer to match the chosen model's training.

## When to Re-Index

Re-embed and re-upsert when:

- The embedding model changes (e.g., upgrade to a newer text-embedding model).
- The chunking strategy changes (chunk size, overlap, or tokenizer).
- Source documents are updated; use stable IDs to overwrite via upsert.

Do NOT re-index for:

- Generation model swaps (e.g., `gpt-5` to Claude). The retrieval layer is model-agnostic.
- Adding new blueprints — append with new IDs.

## Quick Reference

| Rule | Summary |
|------|---------|
| Token chunking | 400/50 with `cl100k_base` |
| Namespaces | One per RAG kind |
| Embedding model | Pin and reuse for retrieval |
| Metric | `cosine` for text |
| Batches | 100 vectors per upsert |
| Async waits | Poll until ready / count == 0 |
| Secrets | Colab userdata or env vars |
| IDs | Stable to enable idempotent upsert |
