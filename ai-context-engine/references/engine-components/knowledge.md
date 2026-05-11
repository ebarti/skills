# Engine Components Knowledge

Core concepts for the Context Engine: the orchestration loop that makes specialist agents act as one.

## Overview

The Context Engine runs a **plan, execute, reflect** loop that mirrors how people work through complex problems. It is composed of three core components — Planner, Executor, and Execution Tracer — wired together by a `context_engine()` control loop. Together they turn vague human goals into traceable, multi-agent workflows.

## Key Concepts

### The Context Engine

**Definition**: The orchestration layer that makes a team of specialist agents think and act as one.

It runs a simple but powerful loop: the Planner thinks strategically, the Executor carries out the plan and passes context along, and the Tracer records every move so we can later see not just *what* the system did, but *why*.

**Key points**:
- Two-phase process: first plans the work, then works the plan
- Backed by an Agent Registry that catalogs available specialists
- Returns both the final output and a complete execution trace

### Planner

**Definition**: The strategic core of the engine that translates a vague, high-level human goal into a precise, step-by-step, machine-readable JSON plan.

Acts as an expert project manager. Uses the LLM as a reasoning partner, given the user's `goal` and a `capabilities` description from the Agent Registry.

**Key points**:
- Output is a JSON list of step objects
- Each step references an agent and its inputs
- Supports **Context Chaining** via `$$STEP_X_OUTPUT$$` placeholders
- Validates the LLM's output structure; tolerates a list wrapped in `{"plan": [...]}`
- Wrapped in `try...except` to handle malformed JSON

### Executor

**Definition**: The system's on-site foreman that runs each step, calls the right agent, and moves context forward so later steps can build on earlier results.

Before calling an agent, the Executor resolves `$$...$$` placeholders against the current execution state via `resolve_dependencies()`, transforming the static plan into a connected workflow.

**Key points**:
- Dispatches the appropriate agent handler from the registry
- Wraps inputs in an MCP message for transport
- Stores each step's output as `STEP_{n}_OUTPUT` in the state dict (short-term memory)
- Recursively resolves placeholders nested in dicts and lists
- Halts on error and returns the partial trace for debugging

### Execution Tracer

**Definition**: The Context Engine's flight recorder — quietly documents every stage of reasoning from initial goal to final output.

Implemented as the `ExecutionTrace` class. Provides visibility, accountability, and the ability to reconstruct system reasoning at any time.

**Key points**:
- Initialized with the user's `goal` and a start timestamp
- `log_plan()` records the Planner's intended strategy
- `log_step()` captures agent, planned input, resolved context, and output per step
- `finalize()` records final status, output, and duration
- Returned even on failure for post-mortem debugging

### Context Chaining

**Definition**: The mechanism by which a step's input references the output of a prior step using `$$STEP_X_OUTPUT$$` syntax.

Resolved at execution time by walking the input structure (recursively, through dicts and lists) and substituting actual values from the state dictionary.

### Glass-Box Transparency

**Definition**: The property that every internal decision and action of the engine is observable and auditable.

Achieved by the Tracer: it captures the plan, every step's planned vs. resolved input, every output, the final status, and the total duration.

## Component Interaction

```
goal -> [Planner] -> plan
                       |
                       v
              [Executor loop]  <-- state dict (short-term memory)
                       |          ^
                       v          |
                   agent call  -- output stored as STEP_n_OUTPUT
                       |
                       v
                  [Tracer] <-- logs plan, every step, finalize
                       |
                       v
              (final_output, trace)
```

## Terminology

| Term | Definition |
|------|------------|
| Plan | JSON list of step objects produced by the Planner |
| Step | One action: an agent name plus its input parameters |
| State | Dict mapping `STEP_n_OUTPUT` keys to step results |
| Capabilities | Human-readable catalog of agents, inputs, and outputs |
| MCP message | Transport envelope used to call an agent |
| Handler | Callable returned by the registry to invoke an agent |
| Resolved input | Input after `$$...$$` placeholders have been substituted |

## How It Relates To

- **Agent Registry**: Provides the capabilities description the Planner needs and the handlers the Executor dispatches
- **MCP**: The message envelope used by the Executor to call agents
- **LLM**: The Planner's reasoning partner, called with `json_mode=True`

## Common Misconceptions

- **Myth**: The Planner executes anything itself.
  **Reality**: The Planner only produces a JSON plan. All side effects happen in the Executor.

- **Myth**: The Tracer is optional logging.
  **Reality**: It is returned alongside the output (and even on failure), making it the primary debugging surface.

- **Myth**: Placeholders are resolved by the LLM.
  **Reality**: `resolve_dependencies()` substitutes them at execution time from the state dict.

## Quick Reference

| Component | Role | Output |
|-----------|------|--------|
| Planner | Decompose goal into steps | JSON list of steps |
| Executor | Run each step, pass context | Updated state dict |
| Tracer | Record causality and timing | `ExecutionTrace` |
| `context_engine()` | Orchestrate the triad | `(final_output, trace)` |
