# Dual RAG Knowledge

Core concepts and foundational understanding for the dual RAG multi-agent system architecture.

## Overview

A dual RAG MAS uses **two separate retrieval indexes**, one for procedural knowledge (how to write) and one for factual knowledge (what to write about). The architecture splits work into two phases: a one-time **data preparation** phase that builds both indexes, and a **runtime execution** phase where specialist agents query each index in parallel and a generator merges the results.

## Key Concepts

### Dual RAG

**Definition**: A retrieval architecture in which two independent vector namespaces are queried for two different kinds of context — procedural and factual — and the results are merged at generation time.

**Key points**:
- One vector index (Pinecone) split into two strictly separated namespaces
- Each namespace is queried by a different specialist agent
- Procedural and factual context are kept on independent update cycles

### Procedural RAG (Context Library)

**Definition**: The retrieval channel that returns **semantic blueprints** — structured instructions describing *how* the output should be styled or structured.

**Key points**:
- Stored in the `ContextLibrary` namespace
- Only the blueprint's **intent description** is embedded; the full blueprint payload lives in a JSON object linked to that description
- Searches are matched on intent (e.g., "suspenseful story") rather than full content

### Factual RAG (Knowledge Store)

**Definition**: The retrieval channel that returns **factual chunks** — the raw subject-matter content the system should know about.

**Key points**:
- Stored in the `KnowledgeStore` namespace
- Source documents are split into chunks and each chunk is embedded
- Returns concise factual findings the generator can ground its output in

### Phase 1: Data Preparation

**Definition**: The offline pipeline that ingests both knowledge data and context data, embeds them with the embedding model, and writes them into the two Pinecone namespaces.

Implementation lives in `rag-ingestion`. At an architectural level, Phase 1 produces two populated namespaces ready for Phase 2 to query.

### Phase 2: Runtime Execution

**Definition**: The online flow where the Orchestrator decomposes a user goal into two queries, dispatches them to the Librarian and Researcher agents, and hands the merged results to the Writer.

**Key points**:
- Orchestrator splits the user goal into `intent_query` (procedural) and `topic_query` (factual)
- Librarian queries `ContextLibrary`; Researcher queries `KnowledgeStore`
- Both retrievals run in parallel through the engine's MCP messaging layer
- Writer combines blueprint (instructions) with facts (content) to produce the final output

### Why Two RAGs Instead of One

**Definition**: The architectural rationale for separating procedural and factual retrieval into independent indexes.

**Key points**:
- **Independent update cycles**: knowledge base can change without touching blueprints, and vice versa
- **Cleaner semantic search**: queries for "how to write" don't compete with queries for "what to know"
- **Specialist agents**: each agent owns one retrieval surface, simplifying its prompt and tools
- **Dynamic adaptation**: at runtime, agents pick context based on the user goal rather than relying on a fixed pipeline

## Terminology

| Term | Definition |
|------|------------|
| Dual RAG | Two-namespace retrieval architecture for procedural + factual context |
| Context Library | Namespace storing procedural blueprint embeddings |
| Knowledge Store | Namespace storing factual content embeddings |
| Semantic Blueprint | Structured instruction object describing output style/structure |
| Knowledge Data | Factual source information the system should know |
| Context Data | Procedural blueprints / semantic instructions |
| Intent Query | Sub-query targeting the procedural index (style/structure) |
| Topic Query | Sub-query targeting the factual index (subject matter) |
| Orchestrator | Central coordinator that splits the user goal into two queries |
| Librarian | Specialist agent that retrieves blueprints from `ContextLibrary` |
| Researcher | Specialist agent that retrieves facts from `KnowledgeStore` |
| Writer | Generation agent that fuses blueprint + facts into final output |

## How It Relates To

- **rag-ingestion**: Implements Phase 1 — chunking, embedding, and writing to the two namespaces
- **specialist-agents**: Defines the Librarian, Researcher, and Writer that consume the dual RAG at runtime
- **engine-components**: Provides the MCP messaging layer the Orchestrator uses to dispatch queries
- **agent-registry**: Tracks the specialist agents bound to each namespace

## Common Misconceptions

- **Myth**: Dual RAG means two separate vector databases.
  **Reality**: It's one Pinecone index split into two strictly separated namespaces.

- **Myth**: The full blueprint is embedded for procedural retrieval.
  **Reality**: Only the blueprint's intent description is embedded; the full payload is stored in a linked JSON object.

- **Myth**: The Orchestrator answers the user goal directly.
  **Reality**: The Orchestrator only decomposes the goal and delegates; the Writer generates the final output.

- **Myth**: A single RAG with good chunking would do the same job.
  **Reality**: Mixing procedural and factual vectors degrades retrieval relevance and couples update cycles for two unrelated kinds of content.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Dual RAG | Two namespaces, two specialist agents, one merged generation |
| Context Library | Procedural index — blueprints describing *how* to produce output |
| Knowledge Store | Factual index — chunks describing *what* the output is about |
| Phase 1 | Offline data prep that populates both namespaces |
| Phase 2 | Runtime flow: decompose goal → parallel retrieve → fuse → write |
| Independence | Knowledge and blueprints evolve on separate update cycles |
