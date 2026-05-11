# Specialist Agents Rules

Rules and conventions for designing, implementing, and integrating the three specialist agents in the Context Engine.

## Core Rules

### 1. Use Dependency Injection — No Globals

Every agent's signature must explicitly list its dependencies (client, index, embedding/generation models, namespaces). Never reach into module-level globals.

- Makes each agent a self-contained, testable unit
- Enables swapping clients, models, or namespaces per call

```python
# Bad
def agent_context_librarian(mcp_message):
    results = query_pinecone(...)  # uses globals

# Good
def agent_context_librarian(
    mcp_message, client, index, embedding_model, namespace_context
):
    ...
```

### 2. Always Return a Structured MCP Message

Every agent must wrap its output as a dict with a stable, documented key — not a raw string. This is the **data contract** between agents.

| Agent | Output Content |
|-------|----------------|
| Librarian | `{"blueprint_json": "<json string>"}` |
| Researcher | `{"facts": "<synthesized text>"}` |
| Writer | `<final text string>` (terminal — no downstream consumer needs a key) |

### 3. Validate Required MCP Inputs Up Front

If a required input field is missing, raise `ValueError` immediately. Do not produce silent garbage.

- Librarian requires `intent_query`
- Researcher requires `topic_query`
- Writer requires `blueprint` AND one of (`facts`, `previous_content`)

```python
if not requested_intent:
    raise ValueError("Librarian requires 'intent_query' in the input content.")
```

### 4. Wrap All Logic in `try...except`

Every hardened agent body lives inside a `try` block. Log the error, then re-raise so the Executor can react.

```python
try:
    # agent logic
except Exception as e:
    logging.error(f"[Writer] An error occurred: {e}")
    raise e
```

### 5. Use Structured Logging — Not `print()`

Replace all `print()` with `logging.info`, `logging.warning`, or `logging.error`. Tag log messages with `[AgentName]` for filterability.

```python
logging.info("[Librarian] Activated. Analyzing intent...")
logging.warning("[Researcher] No relevant information found.")
```

### 6. Pass Namespaces Explicitly (Librarian + Researcher)

Both retrieval-based agents must accept the namespace as an argument — never hardcode `NAMESPACE_CONTEXT` or `NAMESPACE_KNOWLEDGE` inside the agent body.

- Librarian: `namespace_context`
- Researcher: `namespace_knowledge`

This lets you point the same agent at staging vs production indices.

### 7. Use Keyword Arguments for Helper Calls

When invoking `query_pinecone` or `call_llm_robust`, pass arguments by name. Improves readability and avoids positional-argument bugs.

```python
results = query_pinecone(
    query_text=requested_intent,
    namespace=namespace_context,
    top_k=1,
    index=index,
    client=client,
    embedding_model=embedding_model
)
```

### 8. Separate "How" from "What" in Writer Prompts

The Writer constructs **two** prompts:
- **System prompt**: contains the blueprint (HOW to write — style, structure, constraints)
- **User prompt**: contains the source material (WHAT to write about)

Never collapse them into a single prompt — the LLM benefits from the role separation.

### 9. Researcher Must Forbid Outside Information

The Researcher's synthesis system prompt MUST contain a guardrail like "Focus strictly on the facts provided in the sources. Do not add outside information." This is the primary hallucination defense.

### 10. Writer Must Handle Both Dict and Raw String Inputs

For backward compatibility, the Writer's input unpacking checks `isinstance(blueprint_data, dict)` before calling `.get()`. This makes it robust to legacy callers that still pass raw strings.

## Guidelines

- **Default gracefully**: If retrieval returns nothing, return a valid message with a sensible default rather than failing
- **Tag log lines** with `[AgentName]` so multi-agent traces are filterable
- **Keep agents stateless**: all context flows through MCP messages, never via instance variables

## When to Add a 4th Specialist

Add a new specialist agent when:
- A new retrieval domain is needed (e.g., a "Critic" agent reading from a `NAMESPACE_FEEDBACK`)
- A distinct cognitive role emerges that doesn't fit Librarian/Researcher/Writer (e.g., a "Validator" that fact-checks output)
- The role can be cleanly defined by: (1) what MCP fields it consumes, (2) what dict key it returns, (3) what dependencies it needs injected

Do **not** add a specialist just to split a long prompt — refactor the prompt instead.

## Exceptions

- **Librarian default content**: returns `json.dumps({"instruction": "Generate the content neutrally."})` rather than raising — the engine must always have a blueprint
- **Writer terminal output**: returns a raw string (no dict wrapping) because nothing downstream consumes it as a structured field

## Quick Reference

| Rule | Summary |
|------|---------|
| Dependency injection | Pass client/index/models as args |
| Structured output | Wrap in `{"key": value}` dict |
| Validate inputs | Raise `ValueError` on missing fields |
| `try/except` | Wrap whole body, log + re-raise |
| Structured logging | `logging.*` not `print()` |
| Pass namespaces | Never hardcode |
| Kwargs for helpers | Improves clarity |
| Two-prompt Writer | System=how, User=what |
| Forbid outside info | Researcher guardrail |
| Robust unpacking | Writer handles dict OR str |
