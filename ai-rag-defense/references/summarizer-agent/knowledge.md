# Summarizer Agent Knowledge

Core concepts for building a Summarizer agent that performs proactive context reduction inside a glass-box multi-agent context engine.

## Overview

The Summarizer agent is a specialist agent inserted into a glass-box context engine to act as an intelligent gatekeeper: it reduces large bodies of text to objective-driven summaries before that text reaches downstream, more expensive agents. This converts a reactive engine into a strategically efficient one and yields measurable token (and dollar) savings.

## Key Concepts

### Glass-Box System Architecture

**Definition**: A deliberately transparent and controllable AI system, opposite to a black box, where every component is modular and every decision is examinable via a detailed `ExecutionTrace`.

**Key points**:
- Every action is traceable; every decision can be examined.
- Components are plug-and-play modules connected via a registry.
- Prevents technical debt and enables parallel team development.
- Adding capability does NOT require redesigning the engine core.

### Separation of Responsibilities

**Definition**: Each layer of the engine owns one role and is color-coded in the architecture diagram.

| Layer | Color | Role |
|-------|-------|------|
| Engine core | White | Orchestrator / planner / tracer (generic, unchanged) |
| Specialist agents | Green | Workers (Librarian, Researcher, Writer, Summarizer) |
| Agent registry | Purple | Toolkit + capability manual for the Planner |
| Helper functions | Orange | Shared utilities (e.g. `count_tokens`) |
| Execution script | Blue | The user-facing entry point |

### The Summarizer Agent's Role

**Definition**: A specialist agent that takes large text and a `summary_objective`, returns a concise summary tailored to that objective, and is invoked by the Planner whenever context size threatens cost or token limits.

**Key points**:
- Acts as an intelligent gatekeeper before expensive generation steps.
- Output schema: `{"summary": "..."}` wrapped in an MCP message.
- Self-contained: receives all dependencies (`client`, `generation_model`) via dependency injection.
- Logs activation, validates inputs, and wraps the LLM call in `try/except`.

### Foundation: `count_tokens` Utility

**Definition**: A helper in `helpers.py` that uses `tiktoken` to count tokens for a given model, falling back to `cl100k_base` if the model is not in the registry.

**Why it matters**: It is the engine's "fuel gauge" — any component can measure token cost BEFORE sending text to an LLM. Without it, proactive cost management is impossible.

### Integration via Agent Registry

**Definition**: The Summarizer becomes discoverable by adding it to `AgentRegistry.registry`, wiring its dependencies in `get_handler`, and (most critically) describing it in `get_capabilities_description()` — the plain-text manual the Planner reads.

**Key points**:
- Planner learns new capabilities by reading text, not by being recompiled.
- Description must include role, exact input keys, and output schema.
- Decoupled discovery loop is what makes the system scalable.

### Post-Execution Token Analysis

**Definition**: A post-run measurement step that uses `count_tokens` on the original text and the Summarizer's output stored in the trace, then computes a reduction percentage.

**Key points**:
- Provides definitive proof that the agent worked.
- Quantifies the economic value of context reduction.
- One of many measurement points to be decided in architecture workshops.

### Business-Value Framing

**Definition**: The discipline of translating a technical metric (e.g. 56.5% token reduction) into business outcomes: cost, speed, and quality.

**Why it matters**: It separates a developer from a strategic partner. Example: 10,000 reports/day at >50% token reduction can save tens of thousands of dollars per month in API costs, plus faster generation and higher signal-to-noise output.

## Terminology

| Term | Definition |
|------|------------|
| Glass-box | Transparent, modular AI system with traceable decisions |
| MCP message | Standard inter-agent payload format (used by `create_mcp_message`) |
| ExecutionTrace | Engine flight recorder logging every step |
| Dependency injection | Pattern of passing `client`/model into agents as args |
| Capabilities description | Plain-text manual the Planner reads to discover agents |
| Context chaining | Resolving placeholders like `$$STEP_1_OUTPUT$$` between steps |
| Data contract | The expected input/output schema between agents |

## How It Relates To

- **Planner**: Reads `get_capabilities_description()` to decide when to insert a Summarizer step.
- **Writer**: Receives Summarizer output (`{"summary": ...}`) instead of original text — must be made bilingual to accept both `facts` and `summary` keys.
- **`count_tokens`**: Foundational utility that makes Summarizer ROI measurable.
- **Micro-context engineering**: Quality of `summary_objective` determines Summarizer output quality (covered separately).

## Common Misconceptions

- **Myth**: Adding a new agent requires rewriting the orchestrator.
  **Reality**: Glass-box architecture means new agents are plug-and-play — only registry edits are needed.

- **Myth**: A Summarizer is just a "make-it-shorter" tool.
  **Reality**: Without a precise `summary_objective`, output is generic and wastes the API call. The Summarizer is a precision instrument when paired with a strong objective.

- **Myth**: Token counting can be deferred to billing dashboards.
  **Reality**: Proactive measurement (`count_tokens`) before LLM calls is what enables strategic context decisions.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Glass-box | Transparent modular engine, every step traceable |
| Summarizer role | Gatekeeper that reduces context before expensive steps |
| `count_tokens` | Pre-call token measurement using `tiktoken` |
| Registry update | Add agent + handler branch + capabilities entry |
| Post-execution analysis | Compare input vs output tokens to prove ROI |
| Business framing | Translate token % into cost, speed, quality |
