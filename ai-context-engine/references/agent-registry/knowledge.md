# Agent Registry Knowledge

Core concepts and foundational understanding for the Agent Registry component of the context engine.

## Overview

The Agent Registry is a central directory that turns a collection of specialist agents into a coordinated team. It decouples the Planner from concrete agent implementations by exposing a name-to-function map and a structured capabilities description that the Planner LLM uses to reason about which agents to invoke. In its hardened form, it also acts as a dependency injector, wiring each agent with the runtime dependencies it requires.

## Key Concepts

### Agent Registry

**Definition**: A class (`AgentRegistry`) that maintains a dictionary mapping human-readable agent names (e.g., `"Librarian"`) to their corresponding Python functions (e.g., `agent_context_librarian`).

The registry is the single source of truth for what agents exist in the system. All other components (Planner, Executor) talk to the registry rather than importing agent functions directly.

**Key points**:
- One central directory of all available agents
- Adding a new agent (e.g., "Critic", "Editor") requires only a registry entry
- No other component needs to change when agents are added
- Instantiated once as a module-level singleton (e.g., `AGENT_TOOLKIT = AgentRegistry()`)

### Decoupling the Planner

**Definition**: The Planner never references agent functions directly. It only knows agents by name and capability description.

This means the Planner LLM reasons about an abstract roster, not Python imports. Swapping or upgrading an agent never requires Planner changes.

**Key points**:
- Planner reads `get_capabilities_description()` to learn the team
- Planner outputs steps referencing agent names like `"Librarian"`
- Executor uses `get_handler(name)` to resolve a name to a callable

### `get_handler` Pattern

**Definition**: A method that, given an agent name, returns the callable function the Executor invokes for a plan step.

In the initial Chapter 4 form it is a simple lookup. In the hardened Chapter 5 form, `get_handler` becomes a dependency injector: it accepts shared runtime dependencies (`client`, `index`, `generation_model`, `embedding_model`, `namespace_context`, `namespace_knowledge`) and returns a lambda that closes over only the dependencies relevant to that specific agent.

**Key points**:
- Returns a callable, not a result
- Raises `ValueError` if the agent name is not found
- Hardened form returns a `lambda mcp_message: ...` so the Executor only ever passes the MCP message

### Capabilities Description

**Definition**: A structured, human-readable string returned by `get_capabilities_description()` that lists each agent's role, required inputs (with names and types), and outputs.

This text is injected into the Planner LLM's prompt. It is the only way the Planner discovers what is possible. Its clarity directly determines plan quality: vague descriptions lead to broken plans; detailed descriptions enable logical, executable workflows.

**Key points**:
- Format per agent: `AGENT`, `ROLE`, `INPUTS` (named, typed), `OUTPUT`
- Inputs are named the same way the Planner will reference them
- Outputs explain what downstream agents can consume

### Dependency Injection (Hardened)

**Definition**: The hardened `get_handler` accepts shared infrastructure (Pinecone client, model handles, namespaces) and binds only the subset each agent needs via lambdas.

This avoids agents reaching for globals or constructing their own clients, making each agent testable and the registry the single seam where dependencies flow into agents.

**Key points**:
- Per-agent branches inject only relevant dependencies
- Agents stay pure functions of `(mcp_message, **deps)`
- Centralized injection means one place to change wiring

### Modular Self-Containment

**Definition**: When the registry is moved into its own `registry.py`, it must `import agents` and reference functions as `agents.agent_context_librarian` rather than relying on a shared global namespace.

The notebook version worked because everything lived in one global scope. Splitting into modules exposed the implicit dependency and caused `NameError`. The fix: explicit imports, qualified names.

**Key points**:
- Each file is its own environment
- Always import the `agents` module explicitly
- Reference functions with the `agents.` prefix

## Terminology

| Term | Definition |
|------|------------|
| Registry | The dictionary mapping agent names to functions |
| Handler | The callable returned by `get_handler` for a given agent |
| Capabilities description | LLM-facing text describing each agent's role, inputs, outputs |
| AGENT_TOOLKIT | Module-level singleton instance of `AgentRegistry` |
| MCP message | The standardized message passed between Executor and agent handlers |

## How It Relates To

- **Planner**: Reads `get_capabilities_description()` to know what agents exist and how to invoke them
- **Executor**: Calls `get_handler(name, ...)` for each plan step to obtain the callable to run
- **Specialist Agents**: Functions registered in the registry (Librarian, Researcher, Writer)
- **Dual RAG**: Provides the `client`, `index`, and namespaces injected into agents through the registry

## Common Misconceptions

- **Myth**: The Planner imports agent functions directly.
  **Reality**: The Planner only sees names and capability descriptions; resolution happens in the registry.

- **Myth**: Adding a new agent requires changes across the codebase.
  **Reality**: A new entry in `self.registry` plus an entry in the capabilities description is enough.

- **Myth**: The capabilities description is documentation for humans.
  **Reality**: It is prompt context for the Planner LLM; its precision drives plan correctness.

- **Myth**: `get_handler` runs the agent.
  **Reality**: It returns a callable; the Executor invokes it.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Agent Registry | Central directory mapping names to agent functions |
| `get_handler` | Returns a ready-to-call (dependency-injected) handler for a named agent |
| Capabilities description | LLM prompt text listing roles, inputs, outputs |
| AGENT_TOOLKIT | The single instantiated registry used across the engine |
| Modular fix | Use `import agents` and `agents.func` qualified names |
