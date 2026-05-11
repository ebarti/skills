# Retrieval Optimization Knowledge

Core concepts for improving retrieval quality in RAG systems.

## Overview

Retrieval optimization improves the chance that relevant documents are fetched for a query. Four primary tactics: chunking strategy, reranking, query rewriting, and contextual retrieval. Beyond text, RAG can also be extended to multimodal data (images, video, audio) and tabular data via text-to-SQL.

## Key Concepts

### Chunking Strategy

**Definition**: How documents are split into manageable pieces before indexing.

The chunking strategy significantly impacts retrieval performance. Indexing depends on intended retrieval — chunks must fit the embedding model's context limit and (later) the generative model's context.

**Common strategies**:
- **Fixed-length by unit**: characters (e.g., 2,048), words (e.g., 512), sentences (e.g., 20), or paragraphs
- **Recursive splitting**: split by section → paragraph → sentence until chunk fits max size; reduces arbitrary breaks
- **Domain-specific**: code splitters (tree-sitter), Q&A pair chunks, language-specific (Chinese vs English)
- **Token-based**: chunk by generative model's tokenizer; downside is reindexing if tokenizer changes
- **Overlapping**: include boundary characters in adjacent chunks to preserve context (e.g., 20-char overlap on 2,048-char chunks)

**Trade-offs of chunk size**:
- Smaller chunks → more diversity, more chunks fit in context, but risk losing important info and increase compute/storage
- Larger chunks → preserve context, fewer embeddings, but less diversity
- No universal best — must experiment

### Reranking

**Definition**: A second-pass scoring of retrieved candidates to improve ranking accuracy.

Useful when reducing the number of retrieved documents to fit into model context or to lower input tokens. Common pattern: cheap retriever fetches candidates → expensive reranker reorders them.

**Variants**:
- **Score-based reranking**: more precise model rescores candidates
- **Time-based reranking**: weight recent data higher (news, emails, stocks)
- **Context reranking** vs **search reranking**: in RAG, exact rank matters less than inclusion; documents at beginning/end of context are processed best

### Query Rewriting

**Definition**: Reformulating the user's query so it makes sense on its own and retrieves better results.

Also called query reformulation, query normalization, or query expansion. Critical for multi-turn conversations where the latest query relies on prior context.

**Techniques**:
- **Heuristics** (traditional search engines)
- **AI-based rewriting** with prompts like "Given the following conversation, rewrite the last user input to reflect what the user is actually asking"
- **Identity resolution**: resolve references like "his wife" by querying a database first
- **Refuse-on-unknown**: rewriter should refuse instead of hallucinating when info is missing

### Contextual Retrieval

**Definition**: Augmenting each chunk with extra context so it's easier to retrieve and understand in isolation.

**Augmentation sources**:
- **Metadata**: tags, keywords, descriptions, captions, reviews
- **Extracted entities**: error codes (e.g., `EADDRNOTAVAIL (99)`), product IDs, named entities
- **Anticipated questions**: each article paired with related queries it can answer
- **Document context**: title, summary, or short AI-generated context (50-100 tokens) explaining the chunk's place in the parent document — Anthropic's technique

### Multimodal RAG

**Definition**: RAG where the retriever returns texts and other modalities (images, video, audio).

**Two retrieval paths**:
1. **Metadata-based**: retrieve image by its title/tag/caption
2. **Content-based**: use a multimodal embedding model (e.g., CLIP) so text queries and image content live in the same vector space

### RAG with Tabular Data

**Definition**: RAG over structured tables, typically via text-to-SQL.

The workflow differs from text RAG. The system must generate and execute a query (usually SQL), then synthesize a response from the result.

**Three steps**:
1. **Text-to-SQL**: convert user query + table schema into SQL (a form of semantic parsing)
2. **SQL execution**: run the query
3. **Generation**: build a response from SQL results + original query

If schemas don't fit in context, add an intermediate **table selection** step.

## Terminology

| Term | Definition |
|------|------------|
| Chunk | A piece of a document that is indexed and retrieved as a unit |
| Overlap | Bytes/tokens shared between adjacent chunks to preserve boundary context |
| Reranking | Second-pass scoring/reordering of retrieved candidates |
| Query rewriting | Reformulating a user query to be self-contained and retrievable |
| Contextual retrieval | Adding context (metadata, summary) to chunks before indexing |
| CLIP | Multimodal embedding model that maps images and text to a shared space |
| Text-to-SQL | Generating SQL from natural-language queries |
| Identity resolution | Resolving references (e.g., "his wife") to concrete entities |

## How It Relates To

- **Retrieval algorithms**: optimization tactics layer on top of term-based or embedding-based retrievers
- **Context length**: chunk size and reranking affect how many chunks fit and which positions matter
- **Hybrid search**: reranking is the standard way to combine multiple retrievers

## Common Misconceptions

- **Myth**: Smaller chunks always retrieve better.
  **Reality**: Small chunks lose document-level context and increase compute/storage costs.

- **Myth**: Reranking is just sorting.
  **Reality**: It's typically a second model call (precise but expensive) over candidates from a cheap retriever.

- **Myth**: Query rewriting is only for conversational RAG.
  **Reality**: It also normalizes ambiguous, terse, or jargon-heavy single-turn queries.

- **Myth**: You always need a vector database for multimodal RAG.
  **Reality**: Metadata (captions, tags) often retrieves images well without multimodal embeddings.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Chunking | Split docs into units that fit retrieval and generation contexts |
| Overlap | Share boundary content across chunks to avoid splitting key info |
| Reranking | Cheap retriever → precise reranker reorders candidates |
| Query rewriting | Make the query self-contained before retrieval |
| Contextual retrieval | Augment each chunk with summary/metadata for better recall |
| Multimodal RAG | Use CLIP-style models or metadata to retrieve images/audio/video |
| Tabular RAG | Text-to-SQL → execute → generate |
