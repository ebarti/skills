# AI RAG and Agents Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use**: Find your situation below, then load ONLY the listed files.

---

## By Task

### Building a RAG System

| What you're doing | Load these files |
|-------------------|------------------|
| Deciding if RAG is right for your problem | `references/rag-architecture/rules.md`, `references/rag-architecture/examples.md` |
| Designing RAG architecture | `references/rag-architecture/knowledge.md`, `references/rag-architecture/rules.md` |
| Choosing retrieval algorithm (BM25/embedding/hybrid) | `references/retrieval-algorithms/rules.md`, `references/retrieval-algorithms/patterns.md` |
| Configuring chunking strategy | `references/retrieval-optimization/rules.md`, `references/retrieval-optimization/examples.md` |
| Adding a reranker | `references/retrieval-optimization/rules.md`, `references/retrieval-optimization/patterns.md` |
| Implementing query rewriting | `references/retrieval-optimization/rules.md`, `references/retrieval-optimization/examples.md` |
| Implementing contextual retrieval (Anthropic) | `references/retrieval-optimization/examples.md` |
| Building multimodal RAG | `references/retrieval-optimization/rules.md`, `references/retrieval-optimization/examples.md` |
| Building text-to-SQL / tabular RAG | `references/retrieval-optimization/examples.md` |

### Building an Agent

| What you're doing | Load these files |
|-------------------|------------------|
| Deciding whether to use an agent | `references/agent-overview/rules.md` |
| Designing an agent's tool inventory | `references/agent-overview/rules.md`, `references/agent-overview/examples.md` |
| Adding write actions safely | `references/agent-overview/rules.md`, `references/agent-overview/examples.md` |
| Implementing planning | `references/agent-planning/rules.md`, `references/agent-planning/patterns.md` |
| Implementing ReAct | `references/agent-planning/patterns.md`, `references/agent-planning/examples.md` |
| Adding reflection / error correction | `references/agent-planning/rules.md`, `references/agent-planning/patterns.md` |
| Implementing tool selection | `references/agent-planning/rules.md`, `references/agent-planning/examples.md` |
| Adding memory to an agent | `references/agent-memory/rules.md`, `references/agent-memory/examples.md` |

### Debugging and Evaluating

| What you're doing | Load these files |
|-------------------|------------------|
| Diagnosing agent failures | `references/agent-failures/rules.md`, `references/agent-failures/smells.md` |
| Evaluating an agent | `references/agent-failures/rules.md`, `references/agent-failures/examples.md` |
| Improving agent efficiency | `references/agent-failures/rules.md` |

---

## By Symptom/Problem

| If you notice... | Load these files |
|------------------|------------------|
| RAG retrieves wrong chunks | `references/retrieval-optimization/rules.md` (chunking), `references/retrieval-algorithms/rules.md` |
| Embedding search misses keyword matches | `references/retrieval-algorithms/rules.md` (hybrid), `references/retrieval-algorithms/examples.md` |
| Multi-turn queries produce bad retrieval | `references/retrieval-optimization/rules.md` (query rewriting) |
| Agent calls wrong tool | `references/agent-failures/rules.md`, `references/agent-failures/smells.md` |
| Agent passes wrong parameters | `references/agent-failures/rules.md`, `references/agent-failures/examples.md` |
| Agent doesn't recover from errors | `references/agent-planning/rules.md` (reflection) |
| Agent runs forever / inefficient | `references/agent-failures/rules.md` (efficiency) |
| Conversation loses context | `references/agent-memory/rules.md`, `references/agent-memory/examples.md` |
| Agent does dangerous write actions | `references/agent-overview/rules.md` (approval gates) |

---

## By Topic (Direct Index)

### RAG Architecture
- `references/rag-architecture/knowledge.md` — RAG, retriever, generator
- `references/rag-architecture/rules.md` — When to use RAG, structure
- `references/rag-architecture/examples.md` — Architecture diagrams, basic implementation

### Retrieval Algorithms
- `references/retrieval-algorithms/knowledge.md` — BM25, embeddings, hybrid, ANN
- `references/retrieval-algorithms/rules.md` — Algorithm selection
- `references/retrieval-algorithms/examples.md` — BM25, FAISS, hybrid code
- `references/retrieval-algorithms/patterns.md` — 6 retrieval patterns

### Retrieval Optimization
- `references/retrieval-optimization/knowledge.md` — Chunking, reranking, rewriting, contextual
- `references/retrieval-optimization/rules.md` — Optimization rules
- `references/retrieval-optimization/examples.md` — Code for each technique + multimodal/tabular
- `references/retrieval-optimization/patterns.md` — 8 optimization patterns

### Agent Overview
- `references/agent-overview/knowledge.md` — Agents, tools, environment
- `references/agent-overview/rules.md` — Agent design rules
- `references/agent-overview/examples.md` — Tool implementations (knowledge/capability/write)

### Agent Planning
- `references/agent-planning/knowledge.md` — Planning, ReAct, reflection
- `references/agent-planning/rules.md` — 10 planning rules
- `references/agent-planning/examples.md` — Planning prompts, ReAct trace
- `references/agent-planning/patterns.md` — 7 patterns (ReAct, Reflexion, Hierarchical, etc.)

### Agent Failures
- `references/agent-failures/knowledge.md` — Failure modes (planning, tool, efficiency)
- `references/agent-failures/rules.md` — Detection and prevention
- `references/agent-failures/examples.md` — Failure examples + fixes
- `references/agent-failures/smells.md` — 8 anti-patterns

### Agent Memory
- `references/agent-memory/knowledge.md` — Memory mechanisms (internal/short/long)
- `references/agent-memory/rules.md` — When/how to add memory
- `references/agent-memory/examples.md` — Memory implementations

---

## Decision Tree

```
What are you building?
│
├─► RAG system
│   ├─► Architecture → rag-architecture/rules.md
│   ├─► Retrieval algorithm → retrieval-algorithms/rules.md
│   └─► Optimization → retrieval-optimization/rules.md
│
├─► Agent
│   ├─► Tools → agent-overview/rules.md
│   ├─► Planning → agent-planning/rules.md
│   ├─► Memory → agent-memory/rules.md
│   └─► Debug failures → agent-failures/rules.md
│
└─► Both (agentic RAG)
    └─► Start with agent-overview + retrieval-algorithms
```

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| First RAG MVP | `rag-architecture/rules.md` + `retrieval-algorithms/rules.md` |
| Production-grade RAG | `retrieval-algorithms/patterns.md` + `retrieval-optimization/patterns.md` |
| First agent | `agent-overview/rules.md` + `agent-planning/rules.md` |
| Production agent | `agent-overview/rules.md` + `agent-planning/patterns.md` + `agent-failures/rules.md` |
| Conversational agent with memory | `agent-overview/rules.md` + `agent-memory/rules.md` + `agent-planning/rules.md` |
| Document Q&A | `rag-architecture/rules.md` + `retrieval-optimization/examples.md` (chunking) |
