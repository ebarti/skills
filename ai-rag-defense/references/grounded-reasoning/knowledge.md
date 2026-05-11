# Grounded Reasoning Knowledge

Core concepts and foundational understanding for validating context engines, preventing hallucination, and maintaining backward compatibility across capability upgrades.

## Overview

A context engine becomes trustworthy only when its components, decisions, and outputs can be inventoried, traced, and validated. Grounded reasoning means the engine reports negative findings rather than fabricating answers, and every capability upgrade preserves prior behavior. Intelligence in such a system emerges from architecture and constrained context flow, not from model guesswork.

## Key Concepts

### Complete Inventory

**Definition**: A structured map of every function in the engine, categorized by location and role.

The inventory is not appendix material; it is the vital map of the system. Each engineer must carry it as a mental mind map.

**Categories** (from Chapter 7 architecture):
- **Main application notebook** - `download_private_github_file()`, `execute_and_display()`
- **Helpers (`helpers.py`)** - `call_llm_robust()`, `get_embedding()`, `create_mcp_message()`, `query_pinecone()`, `count_tokens()`, `helper_sanitize_input()`
- **Specialist agents (`agents.py`)** - `agent_context_librarian()`, `agent_researcher()`, `agent_writer()`, `agent_summarizer()`
- **AgentRegistry (`registry.py`)** - `__init__()`, `get_handler()`, `get_capabilities_description()`
- **Engine core (`engine.py`)** - `ExecutionTrace` lifecycle methods, `planner()`, `resolve_dependencies()`, `context_engine()`

### How the Engine Thinks

**Definition**: The architecture as a complete, interacting system with separated responsibilities.

Five tiers form the "mind" of the engine:

| Tier | Role |
|------|------|
| Main application notebook | Control deck; entry/exit point |
| Engine core | Brain; orchestrator, planner, executor |
| Agent registry | Foreperson/toolkit; dependency injection |
| Specialist agents | Workers; one well-defined job each |
| Helper functions | Foundation; LLM/DB/security utilities |

### Seeing the System in Motion

**Definition**: Two phases drive every task: strategic planning and procedural execution.

**Planning phase (dialogue of contexts)**:
1. Goal context - the user's high-level need
2. Capabilities context - plain-text manual from `get_capabilities_description()`
3. LLM-powered reasoning - Planner produces a JSON plan bridging need and abilities

**Execution phase**:
- Structured communication via MCP messages eliminates ambiguity
- Context chaining via `resolve_dependencies()` injects `$$STEP_N_OUTPUT$$` placeholders with prior outputs

The engine's "magic" is architecture, not telepathy.

### Grounded Reasoning (Hallucination Defense)

**Definition**: The discipline of producing outputs only from retrieved evidence and explicitly reporting absence of information.

When the knowledge base lacks relevant data, a grounded agent must:
- Decline to answer from invention
- Cite exactly which sources were consulted
- Emit a structured negative result the downstream agents can handle
- Allow the Writer to narrate the absence rather than confabulate

This is the canonical hallucination defense: report the negative finding.

### Backward-Compatibility Validation

**Definition**: Confirming that new capabilities have not broken workflows from earlier chapters/versions.

The "trilingual" `agent_writer` is the linchpin: it accepts three data contracts (`facts`, `summary`, `answer_with_sources`) so prior agents continue to function alongside upgraded ones.

**In practice**: Re-run earlier chapter goals on the latest engine; success across Ch5, Ch6, Ch7 cases proves modular soundness.

### ExecutionTrace (Audit)

**Definition**: A flight-recorder that logs goals, plans, per-step inputs/outputs/resolved-context, and finalization status.

Tracing makes "glass box" review possible. Every step (including negative-result steps) is auditable.

## Terminology

| Term | Definition |
|------|------------|
| Glass box | Architecture in which every reasoning step is observable |
| MCP | Model Context Protocol; standardized inter-agent message format |
| Context chaining | Replacing `$$STEP_N_OUTPUT$$` placeholders with prior step output |
| Trilingual writer | Writer agent that accepts `facts`, `summary`, or `answer_with_sources` |
| Negative result | Structured agent output stating that no relevant info was found |
| Sanitization | Inspecting input for prompt injection / data poisoning before LLM use |

## How It Relates To

- **High-fidelity RAG**: Grounded reasoning depends on RAG returning citations and the agent honoring them
- **Multi-agent orchestration**: Negative results must be a recognized data contract, not a failure mode
- **Production readiness**: Inventory + trace + regression suite are prerequisites to deployment

## Common Misconceptions

- **Myth**: A polished response means the system is grounded.
  **Reality**: A polished response can still be hallucinated. Only a citation chain proves grounding.

- **Myth**: New features won't affect old behavior if the new code paths are isolated.
  **Reality**: Shared agents (e.g., Writer) silently regress; backward-compat tests are mandatory.

- **Myth**: An agent that "doesn't know" should stay silent or error out.
  **Reality**: It should emit a structured negative result so the rest of the pipeline can respond gracefully.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Inventory | Every function mapped by tier and role |
| Engine "thinking" | Planning dialogue + chained execution |
| Grounded reasoning | Report negative finding, never invent |
| Backward compat | Old goals still succeed on the new engine |
| Trace | Auditable per-step record of inputs and outputs |
