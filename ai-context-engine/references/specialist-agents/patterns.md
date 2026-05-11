# Specialist Agents Patterns

Reusable patterns for building MCP-based specialist agents in a multi-agent system.

## Pattern: Specialist Agent Template

### Intent

Provide a uniform skeleton so every specialist behaves predictably: validates input, retrieves/processes, returns a structured MCP message.

### When to Use

- Building any new agent that participates in the MCP message bus
- Refactoring a prototype agent for production
- Adding a 4th+ specialist (e.g., Critic, Validator)

### Structure

```python
def agent_<role>(
    mcp_message,
    client,                 # LLM/API client
    index,                  # vector index (if retrieval-based)
    <model_args>,           # embedding_model, generation_model, etc.
    <namespace>,            # namespace if retrieval-based
):
    """One-line role description."""
    logging.info("[<Role>] Activated. <action>...")
    try:
        # 1. Validate required MCP input fields
        required = mcp_message['content'].get('<required_key>')
        if not required:
            raise ValueError("<Role> requires '<required_key>' in the input content.")

        # 2. Do the work (retrieve, synthesize, generate, etc.)
        result = ...

        # 3. Return MCP message with structured dict content
        return create_mcp_message("<Role>", {"<output_key>": result})
    except Exception as e:
        logging.error(f"[<Role>] An error occurred: {e}")
        raise e
```

### Example

The Librarian, Researcher, and Writer all instantiate this template — see `examples.md`.

### Benefits

- Predictable shape for the Executor to invoke
- Easy to add new agents — copy the skeleton, swap the role + keys
- Logging tags make multi-agent traces filterable
- Failures surface explicitly at the right boundary

### Considerations

- Terminal agents (like Writer) may return a raw string instead of a dict, since nothing consumes their output as a structured field
- If the agent has no retrieval need, drop `index`/`namespace`/`embedding_model` from the signature

## Pattern: Dependency Injection for Agents

### Intent

Eliminate global state from agent functions so they become self-contained, testable units.

### When to Use

- Moving from prototype notebook code to a library module
- Writing tests that need to mock the LLM client or vector store
- Supporting multiple environments (staging vs prod indices, different models)

### Structure

```python
# Anti-pattern: globals leak in
client = OpenAI(...)
index = pinecone.Index(...)

def agent_x(mcp_message):
    return query_pinecone(..., index=index, client=client)  # implicit deps

# Pattern: explicit injection
def agent_x(mcp_message, client, index, embedding_model, namespace):
    return query_pinecone(
        query_text=...,
        namespace=namespace,
        index=index,
        client=client,
        embedding_model=embedding_model
    )
```

### Example

The hardened Librarian signature shows the full pattern:

```python
def agent_context_librarian(
    mcp_message, client, index, embedding_model, namespace_context
):
    ...
```

The Executor (or test harness) is responsible for constructing the dependencies once and passing them in on each call.

### Benefits

- **Testability**: mock any dependency in unit tests
- **Reusability**: same agent function can target different namespaces, models, or environments
- **Clarity**: the signature documents exactly what the agent needs
- **Concurrency-safe**: no shared mutable state

### Considerations

- Function signatures grow longer — consider grouping deps into a single `AgentContext` dataclass if the count exceeds 5–6
- Requires the orchestration layer (Executor) to know how to wire all deps — a one-time setup cost

## Pattern: Data Contract via Wrapped Dict Output

### Intent

Force agents to communicate through a stable, named-key contract rather than raw strings.

### When to Use

- Any time one agent's output feeds another agent's input
- When a downstream agent could legitimately consume multiple input flavors

### Structure

```python
# Anti-pattern: raw string output
return create_mcp_message("Researcher", findings)  # consumer must guess

# Pattern: dict-wrapped with stable key
return create_mcp_message("Researcher", {"facts": findings})
```

### Benefits

- Downstream agents can use a deterministic `.get("facts")` lookup
- Adding new fields later is non-breaking (additive)
- Ambiguity ("is this a blueprint or facts?") becomes impossible

### Considerations

- Consumers should defensively handle both dict and raw-string shapes during transition (see Writer's `isinstance` check)
- Document the keys per-agent in one place (a registry or this skill's `rules.md` table)

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|---------------------|
| Building any new specialist | Specialist Agent Template |
| Moving prototype → library | Dependency Injection for Agents |
| Two agents need to exchange data | Data Contract via Wrapped Dict Output |
| Adding 4th+ specialist | Combine all three |
