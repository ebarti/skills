# RAG Architecture Rules

Guidelines for deciding when to use RAG and how to structure a RAG system.

## Core Rules

### 1. Use RAG when knowledge is too large or too dynamic for the prompt

If the knowledge base exceeds what fits comfortably in context, or changes frequently, retrieve instead of stuffing.

- Knowledge base larger than your model's effective context window.
- Per-user / per-tenant data that must be scoped to specific queries.
- Frequently-updated sources (docs, tickets, chat history).
- Need for source attribution / citations.

**Anthropic guidance for Claude**: if your knowledge base is under ~200,000 tokens (~500 pages), you can skip RAG and put it all in the prompt.

### 2. Prefer RAG over finetuning for factual knowledge

Finetuning is for behavior, style, and skills. RAG is for facts that may change.

- Facts change → RAG (re-index, no retraining).
- Behavior/format/persona is fixed → finetuning is fine.
- Use both when you need a tuned model that also reads fresh sources.

### 3. Prefer RAG over long context for cost, latency, and accuracy

Even when everything fits, retrieving the relevant subset usually wins.

- Every extra token adds cost and latency.
- Models often focus on the wrong part of a long context.
- Retrieval lets you pick salient pieces and feed only those.

### 4. A RAG system has exactly two components: retriever + generator

Keep this separation explicit when you design the system.

- **Retriever**: indexing pipeline + query pipeline.
- **Generator**: the LLM that answers using retrieved docs.
- Off-the-shelf retrievers + off-the-shelf models are a fine starting point.
- End-to-end finetuning of both can significantly improve quality if you need it.

### 5. Index the way you intend to query

How you preprocess and store data must match how you'll search for it later.

- Term-based queries → term-based indexing (e.g., BM25).
- Semantic queries → embedding-based indexing (vector DB).
- Hybrid queries → maintain both indexes.

### 6. Chunk documents before indexing

Whole-document retrieval blows up context length unpredictably.

- Split each document into manageable chunks.
- Index at the chunk level, retrieve at the chunk level.
- Treat a chunk as a "document" in the IR sense.

### 7. Post-process before sending to the generator

Don't just concatenate raw chunks and call it done.

- Join retrieved chunks with the user prompt cleanly.
- Add separators / source markers so the model can cite or distinguish sources.
- Trim or rerank to fit the generator's context budget.

## Guidelines

- Treat retriever quality as the #1 lever for RAG quality.
- Start simple (off-the-shelf retriever + LLM); add complexity only when metrics demand it.
- Plan for the data to grow — retrieval scales better than context length.
- Log which chunks were retrieved per query; you cannot debug RAG without this.

## Exceptions

When these rules may be relaxed:

- **Small static knowledge base (<200K tokens for Claude)**: skip RAG, put it all in the prompt.
- **Pure style/persona use case**: a finetuned model with no retrieval may suffice.
- **Realtime tool use needed (web search, APIs)**: prefer the agent pattern over plain RAG.

## Quick Reference

| Situation | Use |
|-----------|-----|
| Knowledge fits in prompt and is static | Long context, no RAG |
| Knowledge is large or changing | RAG |
| Need to teach the model behavior/style | Finetuning |
| Need fresh facts and stable behavior | RAG + finetuned model |
| Need to call live tools (search, APIs) | Agents |
| Per-user scoped data | RAG (filter by user at query time) |

| Decision | Rule of Thumb |
|----------|---------------|
| Index format | Match it to the query format you plan to use |
| Chunk vs whole doc | Always chunk |
| Build from scratch vs off-the-shelf | Off-the-shelf retriever + LLM first |
| Finetune end-to-end | Only after off-the-shelf RAG is measurably the bottleneck |
