# Specialist Agents Knowledge

Core concepts for the three specialist agents that power the Context Engine: Context Librarian, Researcher, and Writer.

## Overview

The Context Engine's multi-agent system is composed of three specialized agents — Librarian, Researcher, and Writer — each serving a distinct purpose. All agents communicate via MCP messages, which act as a universal "shipping container" for information, enabling **context chaining**: each agent receives an MCP message and returns another, allowing the Executor to pass data downstream without translation.

## Key Concepts

### Context Librarian Agent

**Definition**: `agent_context_librarian` identifies the user's intent and fetches the appropriate semantic blueprint from the context vector store.

The blueprint provides instructions to the Writer on **how** to structure and style the content. The Librarian extracts an `intent_query` from the MCP message, performs semantic search against `NAMESPACE_CONTEXT`, and returns either a matched blueprint or a generic default.

**Key points**:
- Reads from the **context library** (a library of "recipes" — structural/stylistic blueprints)
- Translates broad concepts ("suspense") into actionable search queries
- Always returns a valid MCP message — defaults to a neutral instruction if no match
- Returns the blueprint wrapped under the key `"blueprint_json"` (hardened version)

### Researcher Agent

**Definition**: `agent_researcher` queries the knowledge vector store, retrieves the most relevant facts for a topic, and synthesizes them into a concise factual summary.

Acts as the system's "investigative journalist." Performs a two-step **retrieve-and-synthesize** process: pulls `top_k=3` chunks from `NAMESPACE_KNOWLEDGE`, then uses an LLM with a strict synthesis prompt that forbids outside information.

**Key points**:
- Reads from the **knowledge base** (factual, verifiable content)
- Retrieves multiple sources for a more nuanced summary
- The synthesis system prompt enforces "Focus strictly on the facts provided. Do not add outside information." — a critical hallucination mitigation
- Returns the findings wrapped under the key `"facts"` (hardened version)

### Writer Agent

**Definition**: `agent_writer` is the final specialist — the master craftsman that combines the Librarian's blueprint with the Researcher's findings (or previous content) to produce the final text.

It separates **how to write** (blueprint → system prompt) from **what to write about** (facts/previous_content → user prompt). It supports both new generation and rewriting modes via an `if/elif/else` block on its inputs.

**Key points**:
- Requires a `blueprint`; raises `ValueError` if missing
- Accepts EITHER `facts` (new generation) OR `previous_content` (rewriting)
- Hardened version intelligently unpacks structured dicts OR raw strings (backward compatible)
- This dual-mode design enables iterative self-refinement workflows

### Evolution: Initial → Hardened

The Ch4 versions were prototypes using global variables and `print()`. The Ch5 versions are the production-ready forms residing in `agents.py`.

**Three upgrades applied to all three agents**:
1. **Dependency injection**: function signatures explicitly require `client`, `index`, `embedding_model`, etc. — no more globals
2. **Structured logging**: `print()` replaced with `logging.info`/`logging.warning`
3. **Robust error handling**: entire logic wrapped in `try...except`

**Critical bug found during hardening**: Librarian and Researcher originally returned raw strings. The Writer expected specific keys. The fix wrapped outputs in dictionaries (`{"blueprint_json": ...}` and `{"facts": ...}`) — establishing a stable **data contract** between agents.

## Terminology

| Term | Definition |
|------|------------|
| MCP message | Standardized message envelope (Model Context Protocol) for inter-agent comms |
| Context chaining | Passing MCP messages agent-to-agent without translation |
| Semantic blueprint | A "recipe" describing structure, style, and constraints |
| `NAMESPACE_CONTEXT` | Pinecone namespace storing blueprints (Librarian's domain) |
| `NAMESPACE_KNOWLEDGE` | Pinecone namespace storing facts (Researcher's domain) |
| Data contract | The agreed-upon dict keys agents use to exchange data |
| Dependency injection | Passing clients/configs as args instead of using globals |

## How It Relates To

- **Dual-RAG architecture**: Librarian queries context library; Researcher queries knowledge base — same retrieval primitive, different namespaces
- **Engine components**: `query_pinecone`, `call_llm_robust`, and `create_mcp_message` are the shared helpers each agent depends on
- **Executor**: orchestrates the agents in sequence, passing MCP messages between them

## Common Misconceptions

- **Myth**: The Writer can synthesize without a blueprint (use sane defaults).
  **Reality**: The Writer raises `ValueError` if no blueprint is supplied. The Librarian guarantees a default blueprint, so this should never happen in normal flow.

- **Myth**: The Researcher just dumps retrieved chunks.
  **Reality**: It explicitly synthesizes via an LLM with strict guardrails — the synthesis step is the value, not the retrieval.

- **Myth**: Returning a raw string is fine since it's "just text."
  **Reality**: Without a consistent dict key contract, downstream agents break. The wrapping dict is the integration contract.

## Quick Reference

| Agent | Reads From | Input Key | Output Key | Role |
|-------|-----------|-----------|------------|------|
| Librarian | `NAMESPACE_CONTEXT` | `intent_query` | `blueprint_json` | How to write |
| Researcher | `NAMESPACE_KNOWLEDGE` | `topic_query` | `facts` | What to know |
| Writer | (no retrieval) | `blueprint` + (`facts` OR `previous_content`) | (raw string output) | Final synthesis |
