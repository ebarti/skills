# AI Context Engine Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use:** Find your situation below, then load ONLY the listed files. For multi-step tasks, use a workflow.

---

## Workflows

| Task | Workflow |
|------|----------|
| Build a full Context Engine end-to-end | `workflows/build-context-engine.md` |
| Set up the Pinecone RAG ingestion pipeline | `workflows/setup-rag-pipeline.md` |
| Harden a notebook prototype for production | `workflows/harden-engine.md` |

---

## By Task

### Architectural Decisions

| What you're doing | Load these files |
|-------------------|------------------|
| Choosing single vs dual RAG | `dual-rag/knowledge.md`, `dual-rag/rules.md` |
| Designing namespace strategy | `dual-rag/rules.md`, `rag-ingestion/rules.md` |
| Reviewing the engine's overall architecture | `engine-reference/knowledge.md`, `engine-components/knowledge.md` |

### Setting Up the RAG Pipeline

| What you're doing | Load these files |
|-------------------|------------------|
| Initial Pinecone setup | `rag-ingestion/examples.md`, `rag-ingestion/checklist.md` |
| Token-aware chunking | `rag-ingestion/knowledge.md`, `rag-ingestion/rules.md` |
| Uploading context library blueprints | `rag-ingestion/examples-upload.md` |
| Uploading knowledge-base documents | `rag-ingestion/examples-upload.md` |

### Building the Engine

| What you're doing | Load these files |
|-------------------|------------------|
| Implementing the Planner | `engine-components/knowledge.md`, `engine-components/examples.md` |
| Implementing the Executor / dependency resolution | `engine-components/rules.md`, `engine-components/examples.md` |
| Implementing the Execution Tracer | `engine-components/examples.md` |
| Assembling all three (context_engine fn) | `engine-components/examples.md` |

### Building / Modifying Specialist Agents

| What you're doing | Load these files |
|-------------------|------------------|
| Implementing the Context Librarian | `specialist-agents/examples-librarian.md`, `specialist-agents/rules.md` |
| Implementing the Researcher | `specialist-agents/examples-researcher.md`, `specialist-agents/rules.md` |
| Implementing the Writer | `specialist-agents/examples-writer.md`, `specialist-agents/rules.md` |
| Adding a fourth specialist | `specialist-agents/rules.md`, `specialist-agents/patterns.md` |

### Agent Registry

| What you're doing | Load these files |
|-------------------|------------------|
| Adding a new agent to the registry | `agent-registry/rules.md`, `agent-registry/examples.md` |
| Writing capability descriptions for the Planner | `agent-registry/knowledge.md`, `agent-registry/rules.md` |
| Migrating from lookup to DI version | `agent-registry/examples.md` (Ch4 → Ch5 diff) |

### Production Hardening

| What you're doing | Load these files |
|-------------------|------------------|
| Adding dependency injection | `hardening/rules.md`, `hardening/examples.md` |
| Adding structured logging | `hardening/examples.md`, `hardening/rules.md` |
| Adding proactive token counting | `hardening/examples.md` (count_tokens) |
| Splitting engine room from control deck | `hardening/knowledge.md`, `hardening/examples.md` |
| Modularizing into commons/ | `hardening/examples.md` |
| Pre-prod review | `hardening/checklist.md` |

### Reference Lookups

| What you're doing | Load these files |
|-------------------|------------------|
| Finding the right commons file | `engine-reference/knowledge.md`, `engine-reference/examples.md` |
| Auditing engine completeness | `engine-reference/checklist.md`, `engine-reference/rules.md` |

---

## By Code Element

| Working with... | Primary | Secondary |
|-----------------|---------|-----------|
| Pinecone index/namespaces | `rag-ingestion/examples.md` | `rag-ingestion/rules.md` |
| Tokenizer + chunking | `rag-ingestion/examples.md` | `rag-ingestion/knowledge.md` |
| Planner LLM prompt | `engine-components/examples.md` | `engine-components/rules.md` |
| ExecutionTrace class | `engine-components/examples.md` | `hardening/examples.md` |
| Specialist agent function | `specialist-agents/examples-{librarian,researcher,writer}.md` | `specialist-agents/rules.md` |
| AgentRegistry class | `agent-registry/examples.md` | `agent-registry/rules.md` |
| call_llm / get_embedding helpers | `hardening/examples.md` | `engine-reference/examples.md` |

---

## By Problem / Symptom

| If you notice... | Load these files |
|------------------|------------------|
| Planner picks wrong agent | `agent-registry/rules.md` (capability descriptions) |
| Context retrieval returns mixed procedural+factual | `dual-rag/rules.md` (separate namespaces) |
| Agents share global state | `hardening/rules.md` (DI), `specialist-agents/rules.md` |
| Hard to debug what step did what | `engine-components/rules.md` (Tracer), `hardening/rules.md` (logging) |
| Token counts blow up | `hardening/examples.md` (count_tokens) — also see `ai-rag-defense/summarizer-agent` |
| Notebook is unmaintainable | `hardening/examples.md` (engine room vs control deck), `hardening/checklist.md` |

---

## File Index

### dual-rag
| File | Purpose |
|------|---------|
| `knowledge.md` | Procedural vs factual RAG, Phase 1/2 |
| `rules.md` | When to use, namespace design, query routing |
| `examples.md` | ASCII diagrams + decomposition example |

### rag-ingestion
| File | Purpose |
|------|---------|
| `knowledge.md` | Pinecone, tokenizer, chunking, embedding |
| `rules.md` | 10 rules covering chunking, namespaces, embeddings, idempotency |
| `examples.md` | Setup, clients, helpers, tokenizer, chunk_text, batch_embeddings |
| `examples-upload.md` | Context library + knowledge base upload code |
| `checklist.md` | Setup gates + red flags |

### engine-components
| File | Purpose |
|------|---------|
| `knowledge.md` | Planner/Executor/Tracer triad, glass-box |
| `rules.md` | 10 rules covering planning, dependencies, MCP, tracing |
| `examples.md` | Verbatim Planner prompt + Executor + Tracer + assembly |

### specialist-agents
| File | Purpose |
|------|---------|
| `knowledge.md` | Roles, evolution, terminology |
| `rules.md` | 10 rules covering DI, output structure, logging |
| `examples.md` | Index across the 3 agents |
| `examples-librarian.md` | Verbatim Ch4 + Ch5 Librarian code |
| `examples-researcher.md` | Verbatim Ch4 + Ch5 Researcher code |
| `examples-writer.md` | Verbatim Ch4 + Ch5 Writer code (incl. data-contract fix) |
| `patterns.md` | Specialist Template, DI, Data Contract via Wrapped Dict |

### agent-registry
| File | Purpose |
|------|---------|
| `knowledge.md` | Registry role, get_handler, capability descriptions |
| `rules.md` | Registration rules, DI lambdas, naming |
| `examples.md` | Both Ch4 (initial) and Ch5 (hardened) versions |

### hardening
| File | Purpose |
|------|---------|
| `knowledge.md` | 4 phases, 4 hardening pillars |
| `rules.md` | 8 rules: DI / logging / errors / tokens / setup / modules |
| `examples.md` | Verbatim hardened helpers, engine room, control deck |
| `checklist.md` | Production-readiness gates |

### engine-reference
| File | Purpose |
|------|---------|
| `knowledge.md` | Theoretical foundations, commons table, safeguards |
| `rules.md` | 10 rules covering ordering, sanitize-always, MCP chaining |
| `examples.md` | Per-file snippets w/ cross-refs |
| `checklist.md` | Engine completeness audit |

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| Build the engine from scratch | `dual-rag/knowledge.md` + `engine-components/examples.md` + `specialist-agents/examples.md` + `agent-registry/examples.md` |
| Set up ingestion the first time | `rag-ingestion/checklist.md` + `rag-ingestion/examples.md` + `rag-ingestion/examples-upload.md` |
| Harden a working prototype | `hardening/knowledge.md` + `hardening/examples.md` + `hardening/checklist.md` |
| Audit an existing engine | `engine-reference/checklist.md` + `engine-reference/knowledge.md` |
| Add a new specialist agent | `specialist-agents/patterns.md` + `agent-registry/rules.md` + `specialist-agents/rules.md` |
