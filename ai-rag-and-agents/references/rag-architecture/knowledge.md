# RAG Architecture Knowledge

Core concepts for retrieval-augmented generation (RAG) systems.

## Overview

RAG enhances a model's generation by retrieving relevant information from external memory sources (databases, prior chats, the internet) and feeding only the most relevant pieces into the model. It exists to construct query-specific context, overcome context-length limits, reduce hallucinations, and make better use of model attention than dumping everything into the prompt.

## Key Concepts

### RAG (Retrieval-Augmented Generation)

**Definition**: A technique that augments a generative model by retrieving relevant information from external memory sources and including it in the prompt.

**Key points**:
- Retrieves only the information most relevant to the current query.
- Allows query-specific context instead of one fixed context for all queries.
- Reduces hallucinations and produces more detailed responses (Lewis et al., 2020).
- External memory can be: internal database, user chat history, or the open internet.

### Retriever

**Definition**: The component that locates and returns the most relevant documents/chunks for a given query.

**Two main functions**:
- **Indexing**: Processing data so it can be quickly retrieved later.
- **Querying**: Sending a query and ranking documents by relevance to it.

The success of a RAG system depends primarily on the retriever's quality. How you index data depends on how you intend to retrieve it.

### Generator

**Definition**: The model (typically an LLM) that produces the final answer using both the user's prompt and the retrieved documents.

In modern systems the retriever and generator are usually trained separately and built from off-the-shelf parts; end-to-end finetuning can still significantly improve performance.

### Document and Chunk

**Definition**: A "document" is any retrievable unit of text. A "chunk" is a sub-piece of a larger document.

In this knowledge base (following classical IR convention), "document" refers to both whole documents and chunks. Documents are split into chunks because retrieving entire documents can blow up context length.

### Context Construction

**Definition**: Assembling the per-query information the model needs to answer well.

For foundation models, context construction is the equivalent of feature engineering for classical ML. RAG is one pattern for it; agents (tools) are the other.

## Terminology

| Term | Definition |
|------|------------|
| RAG | Retrieval-augmented generation |
| Retriever | Component that fetches relevant docs for a query |
| Generator | Model that produces the response from query + retrieved docs |
| Indexing | Pre-processing data so it can be retrieved quickly |
| Querying | Ranking and returning docs for a given query |
| Chunk | A manageable sub-piece of a document |
| External memory | Data source outside the model's weights (DB, chat logs, web) |
| Retrieval | Ranking documents by relevance to a query |

## How It Relates To

- **Long context windows**: RAG complements long context, not replaces it. Even with huge context, retrieval reduces cost, latency, and "lost in the middle" problems.
- **Agents**: Both are context-construction patterns. RAG retrieves from passive memory; agents actively call tools.
- **Finetuning**: Finetuning bakes knowledge into weights; RAG keeps knowledge external and updatable.
- **Information retrieval (IR)**: RAG retrievers reuse decades-old IR algorithms (search engines, recommender systems).

## Common Misconceptions

- **Myth**: Long context windows will make RAG obsolete.
  **Reality**: Data grows faster than context windows, longer contexts are used less effectively, and every extra token costs money and latency.

- **Myth**: RAG is only for working around context limits.
  **Reality**: RAG also enables per-user data scoping, freshness, source attribution, and cost control.

- **Myth**: A retriever returns "the answer."
  **Reality**: It returns ranked documents; the generator still has to read and synthesize them.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| RAG | Retrieve relevant external info, then generate with it |
| Retriever | Indexes data and ranks it by query relevance |
| Generator | LLM that produces the answer from query + retrieved docs |
| Chunking | Splitting docs into smaller retrievable units |
| Context construction | Feature engineering for foundation models |
