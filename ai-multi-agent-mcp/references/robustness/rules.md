# Robustness Rules

Rules for hardening a multi-agent system: validating MCP messages, guarding LLM calls, controlling agent specialization, and designing the validation loop.

## Core Rules

### 1. Wrap Every LLM Call in Retry Logic

Never call the LLM with a single naked request. Use a robust caller that retries transient failures.

- Wrap the API call in `try/except` inside a `for` loop.
- Pause between attempts with `time.sleep(delay)`.
- Default to `retries=3, delay=5`; tune per workload.
- Return `None` after all retries fail so the Orchestrator can decide how to recover.
- Log every failed attempt and the final "All retries failed" event.

**Example**:
```python
# Bad
def call_llm(system_prompt, user_content):
    response = client.chat.completions.create(...)  # one shot, no recovery
    return response.choices[0].message.content

# Good
def call_llm_robust(system_prompt, user_content, retries=3, delay=5):
    for i in range(retries):
        try:
            ...
            return response.choices[0].message.content
        except Exception as e:
            print(f"API call failed on attempt {i+1}/{retries}. Error: {e}")
            if i < retries - 1:
                time.sleep(delay)
            else:
                return None
```

### 2. Validate Every MCP Message Before Use

The Orchestrator must call `validate_mcp_message` immediately after every agent returns.

- Reject anything that is not a `dict`.
- Require all four keys: `protocol_version`, `sender`, `content`, `metadata`.
- Always pair structural validation with an empty-content check (`not message['content']`) to catch `None` returns from `call_llm_robust`.
- On validation failure, log the reason and abort the current step or loop iteration.

**Example**:
```python
# Bad
mcp_from_writer = writer_agent(mcp_to_writer)
draft_post = mcp_from_writer['content']  # KeyError or None lurking

# Good
mcp_from_writer = writer_agent(mcp_to_writer)
if not validate_mcp_message(mcp_from_writer) or not mcp_from_writer['content']:
    print("Aborting revision loop due to invalid message from Writer.")
    break
draft_post = mcp_from_writer['content']
```

### 3. Upgrade Existing Specialists to the Robust Caller

When you introduce `call_llm_robust`, swap it into every agent that talks to the LLM.

- Replace `call_llm(...)` with `call_llm_robust(...)` in Researcher, Writer, and any new specialist.
- Do not leave a single naked `call_llm` in the codebase.

### 4. Add a Validator Agent When Output Quality Matters

Introduce a Validator (Agent 3) whenever a downstream agent's output must be trusted as final.

- Validator's sole job is fact-checking; it has no other responsibilities.
- It takes two inputs from the Orchestrator: the source summary and the draft.
- It must return a deterministic token (`pass`) or a structured failure (`fail` + explanation).
- The system prompt must constrain the response format to make the Orchestrator's decision logic trivial.

### 5. Design the Validation Loop With Explicit Exit Conditions

A validation loop must always terminate. Encode every exit condition.

- **Cap iterations**: use `max_revisions` (e.g., `2`). Never loop unbounded.
- **Pass exit**: `if "pass" in validation_result.lower(): final_output = draft_post; break`.
- **Structural-failure exit**: `break` on invalid MCP message from Writer or Validator.
- **Exhaustion exit**: when `i == max_revisions - 1`, log "Max revisions reached. Workflow failed." and let the loop end.
- **Default output**: initialize `final_output = "Could not produce a validated article."` so the system has a safe fallback.

### 6. Pass Validator Feedback Back to the Writer

When validation fails, the next Writer call must include the Validator's feedback.

- On revisions (`i > 0`), append: `f"\n\nPlease revise the previous draft based on this feedback: {validation_result}"`.
- This is what makes the loop self-correcting rather than just repetitive.

### 7. Validate Before Stopping the Workflow Early

Step 1 (Research) must validate immediately and stop the workflow on failure.

- Check `validate_mcp_message(mcp_from_researcher)` and `mcp_from_researcher['content']`.
- If either fails, print the reason and `return` from the Orchestrator. Do not enter the writing loop with bad context.

## Guidelines

- Make decision points case-insensitive (`"pass" in validation_result.lower()`) to absorb LLM formatting drift.
- Package multi-input messages as a dict in `content` (e.g., `{"summary": ..., "draft": ...}`) so the Validator can extract by key.
- Log generously at every step: agent activations, validations, revision attempts, decision outcomes.
- Keep `max_revisions` small (1-3) until you have observability; high values hide systemic prompt issues.

## Exceptions

- **Throwaway prototype**: A single `call_llm` is acceptable in scratch notebooks; promote to `call_llm_robust` before any shared use.
- **Strictly deterministic agents**: If an agent does no LLM call (pure code), it doesn't need retry logic but its output still needs MCP validation.

## Quick Reference

| Rule | Summary |
|------|---------|
| 1 | Retry every LLM call; return `None` on exhaustion. |
| 2 | Validate every MCP message + empty-content check. |
| 3 | Replace all `call_llm` with `call_llm_robust`. |
| 4 | Add a Validator agent for trusted output. |
| 5 | Cap loops with `max_revisions`; encode every exit. |
| 6 | Feed Validator feedback into the next Writer call. |
| 7 | Validate Researcher output before entering the loop. |
