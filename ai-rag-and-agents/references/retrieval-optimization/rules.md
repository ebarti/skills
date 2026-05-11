# Retrieval Optimization Rules

Guidelines for tuning chunking, reranking, query rewriting, contextual retrieval, and extending RAG to non-text data.

## Core Rules

### 1. Match Chunk Size to Both Context Limits

Chunk size must not exceed:
- The **generative model's** maximum context length
- The **embedding model's** context limit (for embedding-based retrieval)

If you halve chunk size, you double the number of embeddings, vector storage, and search space — query speed drops.

### 2. Always Use Overlap When Chunking

Without overlap, key info can be split across boundaries (e.g., "I left my wife" / "a note"). Overlap ensures critical boundary content appears in at least one chunk.

**Heuristic**: ~1% overlap is reasonable (e.g., 20 chars on 2,048-char chunks). Tune empirically.

### 3. Prefer Recursive Splitting Over Pure Fixed-Length

Recursive splitting (section → paragraph → sentence) reduces arbitrary breaks compared to a hard character/word limit. Reserve fixed-length when document structure is flat.

### 4. Use Domain-Aware Chunkers When Available

- **Code**: use language-specific splitters (e.g., tree-sitter)
- **Q&A**: one chunk per question/answer pair
- **Non-English**: use language-appropriate sentence/paragraph rules

### 5. Add a Reranker When Retrieved Candidates Exceed What You Need

Add a reranker if:
- You retrieve more candidates than fit in the LLM's context
- You want to reduce input tokens (cost)
- You combine multiple retrievers (hybrid search)

The standard pattern is: cheap recall-oriented retriever → expensive precision-oriented reranker.

### 6. Weight by Time for Time-Sensitive Domains

For news, email, stock, or any freshness-critical domain, rerank candidates with a time decay so recent results win ties.

### 7. Rewrite Queries in Multi-Turn Conversations

Any follow-up like "How about X?" or "his wife" must be rewritten into a self-contained query before retrieval. Use an LLM with a rewrite prompt or heuristics.

**Refuse, don't hallucinate**: if the rewriter lacks information needed (e.g., who "his wife" is), it must say so rather than invent an answer.

### 8. Augment Chunks with Context Before Indexing (Anthropic's Technique)

For each chunk, generate a short 50-100 token context that explains the chunk's place in the parent document, then prepend it before indexing. This dramatically improves recall for chunks that lose meaning when isolated.

### 9. Add Anticipated Questions to Knowledge-Base Articles

For customer support / FAQ content, augment each article with multiple paraphrases of the questions it answers ("How to reset password?", "I forgot my password", "I can't log in"). This bridges vocabulary gaps between users and docs.

### 10. Preserve Searchable Entities in Metadata

If a chunk contains identifiers like error codes (`EADDRNOTAVAIL (99)`), product SKUs, or proper nouns, extract them into metadata. Embeddings often blur these literals.

### 11. For Multimodal RAG, Pick Metadata or Joint Embeddings

- **Metadata path**: retrieve images via captions/tags — cheap, works without multimodal models
- **Content path**: use a model like CLIP to embed images and queries in the same space — works when no metadata exists

### 12. For Tabular RAG, Use Text-to-SQL with Schema in Context

Workflow: text-to-SQL → execute → generate response from results.

If schemas don't all fit in the model context, add a **table selection** step before generating SQL.

## Guidelines

- Document order in context still matters (beginning/end positions are processed best) — but inclusion matters more than rank in RAG vs search
- If you use token-based chunking, plan for reindexing whenever you switch tokenizers
- Experiment: there is no universal best chunk size, overlap size, or reranker
- Token-based chunking aligns chunks with the generator's tokenizer, which simplifies downstream prompt assembly

## Exceptions

- **Single-turn, well-formed queries**: skip query rewriting
- **Few documents that all fit context**: skip reranking
- **Homogeneous, well-structured docs**: simple fixed-length chunking can be enough
- **Closed vocabulary corpora**: keyword retrieval may need no embeddings or rerankers

## Quick Reference

| Rule | Summary |
|------|---------|
| Context limits | Chunk size ≤ embedding & generator context |
| Overlap | Always overlap chunks (~1% size) |
| Recursive split | Prefer over fixed-length when possible |
| Domain chunkers | Use code/Q&A/language-aware splitters |
| Add reranker | When candidates > context budget |
| Time decay | Apply for freshness-sensitive domains |
| Rewrite queries | Required for multi-turn / ambiguous queries |
| Refuse on missing info | Rewriter must not hallucinate identities |
| Contextualize chunks | Anthropic 50-100 token chunk-context prepend |
| Question augmentation | Add paraphrased queries to FAQ articles |
| Entity metadata | Preserve codes/SKUs/names as metadata |
| Multimodal | Metadata or CLIP-style joint embeddings |
| Tabular | Text-to-SQL → execute → generate |
