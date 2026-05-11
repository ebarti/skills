---
name: ai-rag-and-agents
description: |
  Practical knowledge for building RAG (Retrieval-Augmented Generation) systems and AI agents. Covers RAG architecture and retrieval algorithms (term-based, embedding-based, hybrid), retrieval optimization (chunking, reranking, query rewriting), multimodal RAG, agent design with tools and planning, agent failure modes, and memory systems.

  Use this skill when:
  - Building a RAG system from scratch or improving an existing one
  - Choosing retrieval algorithms (BM25, dense vectors, hybrid)
  - Optimizing retrieval (chunking strategy, reranker selection)
  - Designing an AI agent (tools, planning, error correction)
  - Debugging agent failures
  - Implementing memory for conversational systems
---

# AI RAG and Agents

Knowledge from "AI Engineering" by Chip Huyen (Chapter 6). Practical guidance for building retrieval-augmented and agentic systems.

## Quick Start

1. Check `guidelines.md` to find which files to load for your task
2. Load only relevant files (each topic has knowledge.md, rules.md, examples.md)
3. Apply guidance to your work

## Contents

### References

| Category | Purpose |
|----------|---------|
| `rag-architecture` | RAG overview, architecture, when to use RAG |
| `retrieval-algorithms` | Term-based (BM25, TF-IDF), embedding-based, hybrid retrieval |
| `retrieval-optimization` | Chunking strategies, reranking, query rewriting, contextual retrieval |
| `rag-beyond-text` | Multimodal RAG, RAG with tabular data |
| `agent-overview` | Agent definition, tools (knowledge augmentation, capability extension, write actions) |
| `agent-planning` | Plan generation, reflection, error correction, tool selection |
| `agent-failures` | Planning failures, tool failures, efficiency issues, evaluation |
| `agent-memory` | Memory systems for agents and conversations |

### Workflows

| Task | Workflow |
|------|----------|
| Build a RAG system end-to-end | `workflows/build-rag.md` |
| Build an agent end-to-end | `workflows/build-agent.md` |
| Diagnose and fix agent failures | `workflows/debug-agent.md` |

## Guidelines

See `guidelines.md` for task-based file selection.
