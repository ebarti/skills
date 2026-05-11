# Agent Design Patterns

Reusable patterns for building specialist agents that communicate via MCP.

## Pattern: Specialist Agent

### Intent

Encapsulate one focused job as a Python function whose behavior is defined by a system prompt and whose I/O is uniform MCP messages.

### When to Use

- You are adding a new step to a multi-agent workflow.
- The new step has a distinct role, tone, or output format from existing agents.
- You want the orchestrator to chain the step's output into another agent without translation.

### Structure

```python
def <role>_agent(mcp_input):
    """One-line description of this agent's single job."""
    print("\n[<Role> Agent Activated]")

    # 1. Extract input from the MCP envelope
    payload = mcp_input['content']

    # 2. Optional: domain-specific preparation (lookup, parsing, validation)
    prepared = prepare(payload)

    # 3. Define the agent's identity via a system prompt
    system_prompt = "You are a <role>. Your task is to <action> with <constraints>."

    # 4. Delegate the LLM call to the shared helper
    output = call_llm(system_prompt, prepared)
    print("<Role> work complete.")

    # 5. Wrap the result in a new MCP message
    return create_mcp_message(
        sender="<Role>Agent",
        content=output,
        metadata={"<key>": "<per-agent context>"},
    )
```

### Example

The Researcher is the canonical instance: extract topic → lookup in `simulated_database` → call `call_llm` with an analyst persona → return an MCP message tagged with the data source. The Writer is the same shape with a different prompt and `word_count` metadata.

### Benefits

- Predictable shape across every agent makes the workflow easy to read.
- Adding a new agent is a copy-paste-and-edit-the-prompt operation.
- Single responsibility keeps prompts short and outputs reliable.
- Uniform MCP I/O lets the orchestrator chain agents without glue code.

### Considerations

- Resist the urge to add branching inside an agent — split it instead.
- Keep metadata meaningful but small; this is not the place for large payloads.
- Activation logs are part of the pattern; do not skip them in production code.

---

## Pattern: Helper Function (`call_llm`)

### Intent

Centralize every LLM API call so agents stay small and behavior changes (model swaps, retries, logging) happen in one place.

### When to Use

- Any time more than one agent calls the LLM.
- When you want consistent error handling across the system.
- When you anticipate model upgrades or provider swaps.

### Structure

```python
def call_llm(system_prompt, user_content):
    """Wrap every LLM API call behind a single, consistent interface."""
    try:
        response = client.chat.completions.create(
            model="<model-id>",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_content},
            ],
        )
        return response.choices[0].message.content
    except Exception:
        # Centralized error handling: log, retry, or return a sentinel
        ...
```

### Example

```python
def call_llm(system_prompt, user_content):
    """A helper function to call the OpenAI API using the new client syntax."""
    try:
        response = client.chat.completions.create(
            model="gpt-5",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_content}
            ]
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"LLM call failed: {e}")
        return ""
```

### Benefits

- One place to change model IDs, headers, retries, or telemetry.
- Agents become small, declarative, and easy to test.
- Error handling is uniform — no agent forgets a `try`/`except`.

### Considerations

- Keep the helper generic; do not bake one agent's prompt or defaults into it.
- If you need agent-specific parameters (temperature, max tokens), pass them as optional arguments rather than creating per-agent helpers.
- For more advanced features (streaming, tool calls), extend this single helper instead of forking it.

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|--------------------|
| Adding a new step (research, write, edit, fact-check) to a workflow | Specialist Agent |
| Multiple agents need to call the LLM consistently | Helper Function |
| Agent needs to behave differently based on input type | Split into two Specialist Agents |
| You want to swap models or add retries everywhere | Modify the Helper Function |
