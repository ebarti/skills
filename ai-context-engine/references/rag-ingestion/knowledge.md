# RAG Ingestion Knowledge

Core concepts for building a RAG ingestion pipeline with Pinecone, OpenAI embeddings, and token-aware chunking.

## Overview

The ingestion pipeline prepares two complementary RAG stores: a knowledge base (factual data) and a context library (procedural blueprints). Both are embedded and stored in a single Pinecone index, separated by namespaces, so agents can later retrieve them at runtime.

## Key Concepts

### Pinecone Index

**Definition**: A managed vector store that holds embeddings and metadata. One index can host multiple namespaces.

**Key points**:
- Created with a fixed `dimension` matching the embedding model (1536 for `text-embedding-3-small`).
- Uses `metric='cosine'` for text-embedding similarity.
- Provisioned with a `ServerlessSpec(cloud='aws', region='us-east-1')` for the free plan.
- Must wait until `describe_index(...).status['ready']` is true after creation.

### Namespaces

**Definition**: Logical partitions inside a single Pinecone index that keep different data kinds strictly separated.

- `KnowledgeStore` holds factual chunks (knowledge base).
- `ContextLibrary` holds semantic blueprint vectors (context library).
- Namespaces are addressed at upsert/query time via the `namespace=` argument.

### Serverless Spec

**Definition**: Pinecone's serverless deployment mode (recommended for the free plan).

- Created with `ServerlessSpec(cloud='aws', region='us-east-1')`.
- Plan limits change; consult Pinecone's pricing regularly.

### Tokenizer (`cl100k_base`)

**Definition**: OpenAI's tokenizer for newer models, accessed via `tiktoken.get_encoding("cl100k_base")`.

- Splits words into meaningful sub-units (e.g., `encoding` to `encod` + `ing`).
- Built for speed, optimized for chat-style and embedding workloads.
- Matches the embedding model's training so chunk boundaries align with model expectations.

### Token-aware Chunking

**Definition**: Splitting text by token count rather than character count.

- Default chunk size: 400 tokens; default overlap: 50 tokens.
- Overlap preserves context across chunk boundaries.
- Chunk and overlap sizes must be tuned per data type.

### Embedding Model

**Definition**: OpenAI's `text-embedding-3-small` produces 1536-dim vectors.

- The same model used for ingestion MUST be used for retrieval.
- Configured via `EMBEDDING_MODEL` and `EMBEDDING_DIM` constants.

### Context Library Entry Schema

Each blueprint has three parts:

| Field | Embedded? | Purpose |
|-------|-----------|---------|
| `id` | No | Unique identifier in Pinecone |
| `description` | Yes (vector) | Library card describing intent/style |
| `blueprint` | No (metadata only) | JSON instructions retrieved after match |

### Knowledge Base Entry Schema

Each chunk vector has:

| Field | Value |
|-------|-------|
| `id` | `knowledge_chunk_{n}` |
| `values` | Embedding of the chunk |
| `metadata.text` | Original chunk text |

### Upsert

**Definition**: Pinecone's combined update-or-insert operation.

- Same ID overwrites existing vector; new ID inserts.
- Performed per namespace via `index.upsert(vectors=..., namespace=...)`.
- Knowledge base upserts are batched (batch size 100).

### Retry with Exponential Backoff

**Definition**: Wrapping API calls with Tenacity's `@retry` decorator to survive transient network failures.

- Wait: `wait_random_exponential(min=1, max=60)`.
- Stop: `stop_after_attempt(6)`.

## Terminology

| Term | Definition |
|------|------------|
| RAG | Retrieval-Augmented Generation |
| Knowledge base | Factual RAG store (`KnowledgeStore` namespace) |
| Context library | Procedural RAG store (`ContextLibrary` namespace) |
| Semantic blueprint | JSON instruction set guiding LLM style/structure |
| Upsert | Update existing vector or insert new |
| Cosine similarity | Default distance metric for text embeddings |
| Chunk overlap | Tokens shared between adjacent chunks for context continuity |

## How It Relates To

- **Dual RAG retrieval**: This pipeline produces the data that the Librarian and Researcher agents query.
- **Agent registry**: Blueprints stored here power the procedural side of the multi-agent system.
- **Engine components**: Pinecone client and OpenAI client are reused by downstream retrieval code.

## Common Misconceptions

- **Myth**: Character-based chunking is fine for RAG.
  **Reality**: LLMs operate on tokens; character-based chunks misalign with how the model sees text and degrade retrieval quality.

- **Myth**: You can swap embedding models freely.
  **Reality**: The model used to embed must equal the model used to query. Mixing models breaks semantic search.

- **Myth**: Pinecone deletion is synchronous.
  **Reality**: Namespace deletion can be async; you must poll `describe_index_stats()` until vector count is zero before re-uploading.

- **Myth**: Blueprints should be embedded in full.
  **Reality**: Only the `description` is embedded. The full blueprint JSON is stored as metadata and fetched after a description match.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Index | Single Pinecone container with cosine metric and 1536 dims |
| Namespace | Per-RAG-kind partition inside the index |
| Tokenizer | `cl100k_base` from tiktoken |
| Chunk size | 400 tokens with 50 overlap |
| Embedding model | `text-embedding-3-small` (1536 dims) |
| Generation model | `gpt-5` (model-agnostic switch) |
| Batch size | 100 chunks per upsert batch |
