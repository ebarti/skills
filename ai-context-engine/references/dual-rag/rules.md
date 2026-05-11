# Dual RAG Rules

Architectural rules for deciding when to adopt dual RAG, how to separate procedural from factual content, and how to design and route queries against the two namespaces.

## Core Rules

### 1. Use Dual RAG When Output Has Both "How" and "What"

If your generator must satisfy **both procedural constraints** (style, structure, format) **and factual grounding** (subject-matter content), separate them into two retrieval channels.

- Single-RAG systems are fine when only one dimension matters
- Dual RAG pays off when blueprints and facts evolve independently
- Required when specialist agents own different retrieval surfaces

### 2. Separate Procedural Content from Factual Content

Classify every piece of source data as either **procedural** (instructions on how to produce output) or **factual** (subject-matter knowledge). Never mix them in the same namespace.

- Procedural → semantic blueprints → `ContextLibrary`
- Factual → text chunks → `KnowledgeStore`
- A piece of content that is genuinely both should be split into two artifacts

### 3. One Index, Two Strictly Separated Namespaces

Use a single Pinecone index divided into two namespaces. Do not query across them and do not allow vectors to leak between them.

- Namespace names: `KnowledgeStore` and `ContextLibrary`
- Each specialist agent is bound to exactly one namespace
- Cross-namespace queries break the independence guarantee

### 4. Embed Intent for Procedural, Embed Chunks for Factual

The two namespaces use **different embedding strategies** because they answer different questions.

- **Procedural**: embed only the blueprint's **intent description**; store the full blueprint in a linked JSON object
- **Factual**: chunk the source text and embed each chunk
- Searches against `ContextLibrary` are matched on intent, not on full blueprint content

### 5. Decompose the User Goal Before Routing

The Orchestrator must split the user goal into **two distinct sub-queries** before any retrieval happens.

- `intent_query` → routed to the Librarian → `ContextLibrary`
- `topic_query` → routed to the Researcher → `KnowledgeStore`
- Never send the raw user goal directly to a specialist agent

### 6. Run the Two Retrievals in Parallel

The Librarian and Researcher have no data dependency on each other. Dispatch both queries concurrently through the MCP messaging layer.

- Sequential dispatch wastes latency
- Parallel dispatch is the architectural default

### 7. Keep Update Cycles Independent

The whole point of two namespaces is decoupling. Updates to one must not require touching the other.

- Adding a new blueprint must not re-ingest the knowledge base
- Updating factual sources must not invalidate existing blueprints
- If an update forces both, the data classification was wrong

## Guidelines

Less strict recommendations:

- Name sub-queries clearly (`intent_query`, `topic_query`) so the routing logic is obvious in logs and traces
- Keep blueprint intent descriptions short and search-optimized — they are the only thing the embedder sees
- Treat the Writer as the only place where blueprint and facts are fused; specialist agents should not pre-merge

## Exceptions

When these rules may be relaxed:

- **Single-channel use case**: If output is purely factual (e.g., a Q&A bot with no styling concerns), a single RAG is sufficient and dual RAG adds unjustified complexity
- **Tightly coupled blueprints and facts**: If blueprints are essentially data-dependent, a single richer index with metadata filtering may be simpler than two namespaces
- **Prototype phase**: Early prototypes can collapse the two namespaces into one to validate the pipeline before committing to the dual architecture

## Quick Reference

| Rule | Summary |
|------|---------|
| When to use | Output needs both *how* (procedural) and *what* (factual) |
| Classification | Every source is procedural OR factual, never both in one vector |
| Index design | One Pinecone index, two namespaces, no cross-queries |
| Embedding | Embed intent for blueprints, embed chunks for facts |
| Query routing | Decompose user goal into `intent_query` + `topic_query` |
| Concurrency | Run Librarian and Researcher retrievals in parallel |
| Independence | Blueprint updates and knowledge updates stay decoupled |
