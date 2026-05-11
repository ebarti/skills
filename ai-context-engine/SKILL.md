---
name: ai-context-engine
description: |
  The full Context Engine architecture: dual RAG (procedural + factual), Pinecone-based ingestion, the Planner / Executor / Tracer triad, specialist agents (Context Librarian, Researcher, Writer), the Agent Registry, production hardening (dependency injection, logging, modularization), plus an appendix-style reference guide.

  Use this skill when:
  - Building a context engine from scratch
  - Choosing between procedural RAG (blueprints) and factual RAG (evidence)
  - Setting up Pinecone ingestion (chunking, embedding, namespaces)
  - Designing a Planner-driven execution flow with traceability
  - Adding or refactoring specialist agents
  - Building or extending an Agent Registry
  - Hardening a notebook prototype for production (DI, logging, modularization)
  - Looking up the engine's commons library reference (helpers/agents/registry/engine/utils)
---

# AI Context Engine

Knowledge from "Context Engineering for Multi-Agent Systems" (Chapters 3-5 + Appendix A). The full architecture and hardening of the glass-box Context Engine.

## Quick Start

1. Check `guidelines.md` to find which files to load
2. Load only relevant files (each topic has knowledge.md, rules.md, examples.md)
3. Apply guidance to your work

## Contents

### References

| Category | Purpose |
|----------|---------|
| `dual-rag` | Procedural vs factual RAG, context library vs knowledge base |
| `rag-ingestion` | Pinecone setup, token-aware chunking, embeddings, upsert |
| `engine-components` | Planner, Executor, Execution Tracer (the engine triad) |
| `specialist-agents` | Context Librarian, Researcher, Writer (initial + hardened) |
| `agent-registry` | Capability descriptions, get_handler, dependency injection |
| `hardening` | DI, structured logging, proactive context mgmt, modularization |
| `engine-reference` | Appendix-style reference guide for the commons library |

### Workflows

| Workflow | Purpose |
|----------|---------|
| `workflows/build-context-engine.md` | Full engine build (dual RAG → triad → agents → registry → run) |
| `workflows/setup-rag-pipeline.md` | Pinecone ingestion (chunk → embed → upsert) |
| `workflows/harden-engine.md` | Take prototype to production (DI, logging, modularization) |

## Guidelines

See `guidelines.md` for task-based file selection.
