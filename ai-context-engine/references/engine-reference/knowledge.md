# Context Engine Reference Knowledge

Theoretical foundations and high-level architecture of the Context Engine — the multi-agent system that turns prompt-response cycles into directed creation.

## Overview

The Context Engine is a glass-box, multi-agent system orchestrated by a Planner and Executor that communicate via the Model Context Protocol (MCP). It operationalizes Semantic Role Labeling (SRL) through dynamically retrieved semantic blueprints and is suitable for enterprise deployment.

## Theoretical Foundations

### Linguistic Roots

- **Lucien Tesnière (dependency grammar)** — sentences are hierarchical stemmas centered on a main verb.
- **Charles J. Fillmore (Case for Case → SRL)** — deconstructs a sentence to answer "Who did what to whom, when, where, and why?".
- The engine treats sentences as multidimensional structures of meaning, not linear word sequences.

### Semantic Blueprint

**Definition**: A structured, unambiguous JSON plan supplied to the LLM that defines the goal, style guide, structure, and roles of participants.

- Stored in a vector DB (the Context Library).
- Retrieved dynamically by the Context Librarian agent based on user intent.
- Consumed by the Writer agent to enforce structure and style.
- Transforms the creative act into a reliable engineering process.

### Glass-Box vs Black-Box

| Trait | Black-Box | Glass-Box (this engine) |
|-------|-----------|--------------------------|
| Visibility | Opaque API consumer | Full execution trace |
| Debugging | Trial-and-error prompts | Step-by-step inspection |
| Control | Limited | Customizable agents, library, safeguards |
| Procedural RAG | No | Yes (via Librarian) |
| Policy layer | Implicit | Explicit meta-controller |

## System Architecture

The system runs in two stages: **Phase 0 (data ingestion, preparatory)** and **Context Engine workflow (runtime)**.

### Phase 0: Data Ingestion Pipeline

1. **Source docs** — raw documents collected (e.g., legal files, papers).
2. **Data ingestion** (`Data_Ingestion.ipynb`) — chunks text and adds source metadata.
3. **Pinecone knowledge base** — chunks (with embeddings + metadata) upserted for semantic retrieval.

See `references/rag-ingestion/` for full ingestion details.

### Context Engine Workflow (runtime)

Managed by `context_engine()`:

1. **User goal** — high-level objective submitted.
2. **Pre-flight moderation** — `helper_moderate_content` vets the goal; halts if flagged.
3. **Planner + Executor** — Planner reads `AgentRegistry` capabilities and emits a plan; Executor runs it.
4. **Agent workflow** — agents called sequentially. Researcher pattern: Retrieve → Sanitize → Synthesize → Context-chain.
5. **Post-flight moderation** — final output vetted; redacted if flagged.
6. **Final output** — delivered to user.

## Commons Library Structure

| Module | Responsibility |
|--------|----------------|
| `helpers.py` | External-API utilities, formatting, security primitives |
| `agents.py` | Specialist agents (Librarian, Researcher, Writer, Summarizer) |
| `registry.py` | `AgentRegistry` — directory + factory for agents |
| `engine.py` | `ExecutionTrace`, `planner()`, `resolve_dependencies()`, `context_engine()` |
| `utils.py` | Environment setup (dependency install, client init) |

See `references/engine-components/` and `references/specialist-agents/` for code-level detail.

## Execution Model

### Engine Room

- `execute_and_display(goal, config, client, pc, moderation_active=False)`
- Wraps `context_engine` with pre/post moderation, output rendering, and trace display.

### Control Deck

- Interactive notebook cell (e.g., `Legal_assistant_Explorer.ipynb`).
- Steps: Define goal → Define config → Execute (optionally with moderation).

### Workflow Templates

| Template | Use Case | Typical Chain |
|----------|----------|---------------|
| 1. High-fidelity RAG | Verifiable research with citations | Librarian → Researcher → Writer |
| 2. Context reduction | Large documents | Summarizer → Writer |
| 3. Grounded reasoning | Hallucination-absence validation | Researcher → Writer (no hits) |

## Production Safeguards

| Layer | Mechanism | Trigger |
|-------|-----------|---------|
| Input sanitization | `helper_sanitize_input()` inside `agent_researcher()` | Every retrieved chunk |
| Pre-flight moderation | `helper_moderate_content()` on goal | Before planning |
| Post-flight moderation | `helper_moderate_content()` on output | Before delivery |
| Policy (meta-controller) | External higher-level app | Above core engine |

See `references/hardening/` for safeguard implementations.

## Operational Realities

- **Latency** — sequential API calls (planning, embedding, retrieval, synthesis, generation) take time. This is deliberate, not error.
- **Stochasticity** — LLM remains probabilistic. Blueprints + chaining constrain output but don't eliminate variance between runs.

## Terminology

| Term | Definition |
|------|------------|
| MCP | Model Context Protocol — standardized inter-agent dict format |
| Semantic blueprint | JSON plan defining goal, style, structure, roles |
| Glass-box | Architecture exposing full reasoning trace |
| Context chaining | Passing step output into later step inputs via `$$STEP_N_OUTPUT$$` |
| Meta-controller | External policy layer above the engine |
| Engine room | The `execute_and_display` wrapper |
| Control deck | Notebook cell defining goal + config |

## How It Relates To

- **`rag-ingestion`** — Phase 0 detail.
- **`engine-components`** — `engine.py` internals (Planner, Executor, Tracer).
- **`specialist-agents`** — full agent implementations.
- **`agent-registry`** — `AgentRegistry` deep dive.
- **`hardening`** — moderation, sanitization, policy patterns.
- **`dual-rag`** — knowledge vs context library distinction.
