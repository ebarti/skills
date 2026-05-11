# RAG Ingestion Setup Checklist

Use before running the `RAG_Pipeline.ipynb` ingestion to confirm the environment is ready.

## Before You Start

- [ ] Python environment available (Colab or local)
- [ ] Pinecone account created (free plan is sufficient for the demo)
- [ ] OpenAI account with API access
- [ ] You can read the chapter's `RAG_Pipeline.ipynb`

## Dependencies

- [ ] `tqdm==4.67.1` installed
- [ ] `openai==1.104.2` installed
- [ ] `pinecone==7.0.0` installed
- [ ] `tenacity==8.3.0` installed
- [ ] `tiktoken` available (transitive of `openai` or installed manually)

## Secrets and Environment

- [ ] `OPENAI_API_KEY` available in Colab secrets OR exported as env var
- [ ] `PINECONE_API_KEY` available in Colab secrets OR exported as env var
- [ ] No keys hardcoded in the notebook
- [ ] Env-var fallback path tested if running locally

## Configuration Constants

- [ ] `EMBEDDING_MODEL = "text-embedding-3-small"`
- [ ] `EMBEDDING_DIM = 1536` matches the embedding model
- [ ] `GENERATION_MODEL` set (default `gpt-5`, swap as needed)
- [ ] `INDEX_NAME = 'genai-mas-mcp-ch3'` (or your chosen name)
- [ ] `NAMESPACE_KNOWLEDGE = "KnowledgeStore"` defined
- [ ] `NAMESPACE_CONTEXT = "ContextLibrary"` defined

## Pinecone Index

- [ ] `ServerlessSpec(cloud='aws', region='us-east-1')` (or your chosen region)
- [ ] `pc.list_indexes().names()` checked before creating
- [ ] If creating: `metric='cosine'`, `dimension=EMBEDDING_DIM`
- [ ] Wait loop on `describe_index(INDEX_NAME).status['ready']`
- [ ] Connect with `index = pc.Index(INDEX_NAME)` after readiness

## Namespace Hygiene (Demo Only)

- [ ] Decided whether to clear namespaces (clear in demo, KEEP in production)
- [ ] If clearing: `index.delete(delete_all=True, namespace=ns)` per namespace
- [ ] Poll `describe_index_stats()` until `vector_count == 0` before any new upsert
- [ ] 5-second sleep between polls

## Helpers

- [ ] Tokenizer initialized: `tiktoken.get_encoding("cl100k_base")`
- [ ] `chunk_text(text, chunk_size=400, overlap=50)` defined
- [ ] `get_embeddings_batch(texts, model=EMBEDDING_MODEL)` defined
- [ ] Both wrapped with `@retry(wait=wait_random_exponential(min=1, max=60), stop=stop_after_attempt(6))` where appropriate

## Data

- [ ] `context_blueprints` list defined with `id`, `description`, `blueprint` (JSON string)
- [ ] `knowledge_data_raw` string loaded
- [ ] Stable, deterministic IDs (so re-runs upsert in place)

## Upserts

- [ ] Context: embed `description` only, store `blueprint_json` in metadata
- [ ] Context: `index.upsert(vectors=vectors_context, namespace=NAMESPACE_CONTEXT)`
- [ ] Knowledge: chunk via `chunk_text`, batch size 100
- [ ] Knowledge: `chunk_id = f"knowledge_chunk_{i+j}"`
- [ ] Knowledge: `index.upsert(vectors=batch_vectors, namespace=NAMESPACE_KNOWLEDGE)`
- [ ] Progress shown via `tqdm`

## After Run

- [ ] Console reports `Successfully uploaded N context vectors.`
- [ ] Console reports `Successfully uploaded N knowledge vectors.`
- [ ] `index.describe_index_stats()` shows expected counts in both namespaces

## Red Flags

Stop and fix if you see:

- API key prompts or `KeyError` on secret lookup — secrets not wired up.
- `Dimension mismatch` errors — `EMBEDDING_DIM` doesn't match the embedding model.
- Empty namespace stats after upsert — check you passed the correct `namespace=`.
- Vectors silently disappear shortly after upload — deletion poll skipped or finished after upload started.
- Different chunk count between runs of identical data — non-deterministic chunking; check tokenizer and overlap math.

## Quick Reference

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| Chunk size | 400 tokens | 200-1000 tuned | Character-based |
| Overlap | 50 tokens | 10-20% of chunk | Zero or > chunk size |
| Batch size | 100 | 10-500 | 1 (per-call upsert) |
| Metric | `cosine` | — | `euclidean` for text |
| Secrets | Colab/env | Vault | Hardcoded |
| Index ready check | Poll status | — | Skip and use immediately |
