# Agent Registry Rules

Rules for designing, registering, and evolving entries in the Agent Registry so the Planner can reason about the team and the Executor can invoke handlers cleanly.

## Core Rules

### 1. Register every agent in `self.registry`

Every callable agent must have an entry in `AgentRegistry.__init__`. The Planner cannot select an agent that is not registered, and the Executor cannot resolve it.

- Key: human-readable agent name as the Planner will reference it (e.g., `"Librarian"`)
- Value: the agent function itself (not a string, not a class)
- Names must be unique across the registry

**Example**:
```python
# Bad: agent exists but is unregistered, Planner cannot use it
def agent_critic(mcp_message): ...

# Good: registered alongside the rest
self.registry = {
    "Librarian": agents.agent_context_librarian,
    "Researcher": agents.agent_researcher,
    "Writer": agents.agent_writer,
    "Critic": agents.agent_critic,
}
```

### 2. Always use qualified imports in `registry.py`

When the registry lives in its own module, reference agents through the `agents` module, not bare names. Bare names rely on a shared global namespace that does not exist outside notebooks.

- Add `import agents` at the top of `registry.py`
- Reference functions as `agents.agent_context_librarian`

**Example**:
```python
# Bad: NameError outside notebook
self.registry = {"Librarian": agent_context_librarian}

# Good: explicit, modular
import agents
self.registry = {"Librarian": agents.agent_context_librarian}
```

### 3. Inject dependencies in `get_handler`, not inside agents

Agents must remain pure functions of `(mcp_message, **deps)`. The registry is the only place that knows which dependencies each agent needs and binds them via lambdas.

- `get_handler` signature accepts every shared dependency
- Per-agent branches pass only the subset that agent uses
- Returned lambda has signature `lambda mcp_message: handler_func(mcp_message, ...)`

**Example**:
```python
# Bad: agent reaches for globals
def agent_context_librarian(mcp_message):
    result = pinecone_client.query(...)  # global

# Good: dependencies injected via registry lambda
return lambda mcp_message: handler_func(
    mcp_message, client=client, index=index,
    embedding_model=embedding_model,
    namespace_context=namespace_context,
)
```

### 4. Raise on unknown agent names

`get_handler` must raise `ValueError` (and log it) when the agent name is missing. Silent fallbacks hide Planner bugs and create non-deterministic execution.

- Log the error before raising
- Include the missing name in the message

**Example**:
```python
handler_func = self.registry.get(agent_name)
if not handler_func:
    logging.error(f"Agent '{agent_name}' not found in registry.")
    raise ValueError(f"Agent '{agent_name}' not found in registry.")
```

### 5. Make every capability description machine-readable

`get_capabilities_description` is read by the Planner LLM. Use a strict, repeatable structure for every agent so the model can pattern-match.

- Per agent: `AGENT`, `ROLE`, `INPUTS`, `OUTPUT`
- Each input: name in quotes, type in parentheses, plain-language meaning
- Output: type and what it represents
- Use the same input names the Planner is expected to emit in the plan

**Example**:
```text
1. AGENT: Librarian
   ROLE: Retrieves Semantic Blueprints (style/structure instructions).
     INPUTS:
     - "intent_query": (String) A descriptive phrase of the desired style or format.
     OUTPUT: The blueprint structure (JSON string).
```

### 6. Keep capability descriptions specific and complete

Vague descriptions cause the Planner to hallucinate inputs or pick the wrong agent. List every input and explain when each is used.

- State which inputs are required vs. optional
- Explain branching usage (e.g., Writer uses `facts` for new content, `previous_content` for rewrites)
- Reference upstream producers (e.g., "usually from Librarian")

### 7. Instantiate once as a module-level singleton

The registry holds no per-request state and should be created once.

- One canonical instance, e.g., `AGENT_TOOLKIT = AgentRegistry()`
- All components import that singleton

## Naming Conventions

- Registry keys: PascalCase, role-named (`"Librarian"`, `"Researcher"`, `"Writer"`)
- Agent functions: `agent_<role>` snake_case (`agent_context_librarian`)
- Inputs in capability descriptions: snake_case quoted strings (`"intent_query"`, `"topic_query"`, `"blueprint"`)
- The instantiated registry: `AGENT_TOOLKIT`

## When to Add a New Entry

Add a registry entry when, and only when:

- A new specialist function exists with a clear, distinct role from existing agents
- Its inputs and outputs can be described unambiguously to the Planner
- Its dependencies can be resolved through `get_handler` (no hidden globals)

Do not add an entry for:

- Internal helper functions used by other agents
- Variants of an existing agent that differ only by parameters (extend the existing agent instead)

## Guidelines

- Order capability descriptions consistently (alphabetical or workflow order)
- Prefer explicit per-agent branches in `get_handler` over generic kwargs forwarding so dependency wiring stays visible
- When adding an agent, update the capabilities description in the same change as the registry entry

## Exceptions

- **Notebook prototyping**: bare function names without `agents.` prefix are tolerable while everything lives in one notebook; promote to qualified names the moment the registry is extracted to its own module.
- **Trivial agents with no dependencies**: the per-agent branch in `get_handler` may be omitted, and the bare `handler_func` returned via the `else` branch.

## Quick Reference

| Rule | Summary |
|------|---------|
| Register all agents | Every callable must be in `self.registry` |
| Qualified imports | Use `import agents` and `agents.func` in `registry.py` |
| DI in registry | Inject deps via lambda in `get_handler` |
| Raise on missing | `ValueError` for unknown agent names |
| Structured capabilities | `AGENT`/`ROLE`/`INPUTS`/`OUTPUT` per agent |
| Specific descriptions | List every input, explain branching usage |
| Singleton instance | One `AGENT_TOOLKIT` per process |
