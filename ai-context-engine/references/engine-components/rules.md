# Engine Components Rules

Rules for building the Planner, Executor, Tracer, and the `context_engine()` assembly that wires them together.

## Core Rules

### 1. Planner Must Receive Goal and Capabilities

The Planner takes exactly two inputs: the user's high-level `goal` and a `capabilities` string from the Agent Registry.

- Pull capabilities via `AgentRegistry.get_capabilities_description()`
- Never hard-code agent lists into the Planner prompt
- The capabilities catalog must include each agent's inputs and outputs

### 2. The Planner Prompt Must Set a Clear Contract

The system prompt does two jobs at once: list available tools and set the rules for how to plan.

Required prompt clauses:
- Plan MUST be a JSON list of objects, each object a "step"
- MUST use Context Chaining via `$$STEP_X_OUTPUT$$` to reference prior results
- Be strategic — break complex goals into distinct steps
- Use the correct input keys for each agent (e.g., `facts` vs `previous_content`)
- Provide at least one worked example plan for each plan shape (single-pass and sequential rewrite)

### 3. Plans Are JSON Lists of Step Objects

Each step object must contain:
- `step` — 1-indexed integer
- `agent` — the agent name as registered
- `input` — a dict of named parameters

Dependencies between steps are expressed only through `$$STEP_X_OUTPUT$$` placeholders inside `input`.

### 4. The Planner Must Validate the LLM Response

After `json.loads`:
- Check the result is a list
- If it's a dict containing a `"plan"` list, unwrap it
- Otherwise raise `ValueError("Planner did not return a valid JSON list structure.")`
- Wrap the whole call in `try...except`; on failure log the raw output and re-raise

Call the LLM with `json_mode=True`.

### 5. The Executor Resolves Dependencies Before Every Agent Call

Use `resolve_dependencies(input_params, state)` for every step.

- Always `copy.deepcopy(input_params)` first — never mutate the original plan
- Recurse into dicts and lists so nested placeholders are caught
- A placeholder is a string that both starts and ends with `$$`
- Strip the `$$` wrapper to get the `ref_key`, then look it up in `state`
- Raise `ValueError` if the reference is not present in state

### 6. The Executor Stores Outputs Under `STEP_{n}_OUTPUT`

Each completed step writes `state[f"STEP_{step_num}_OUTPUT"] = output_data` so subsequent steps can reference it. Use `mcp_output["content"]` as the stored value.

### 7. The Executor Wraps Inputs in MCP Messages

Always call agents through their handler with an MCP-wrapped, *resolved* input:

```python
mcp_resolved_input = create_mcp_message("Engine", resolved_input)
mcp_output = handler(mcp_resolved_input)
```

Never pass raw dicts directly to a handler.

### 8. The Tracer Records Plan, Steps, and Finalization

The `ExecutionTrace` must capture:
- `goal` (constructor)
- `plan` (via `log_plan`)
- `steps` — each entry has `step`, `agent`, `planned_input`, `resolved_context`, `output`
- `status` — `"Initialized"`, then a final value like `"Success"`, `"Failed during Planning"`, or `"Failed at Step N"`
- `final_output`
- `start_time` / `duration`

`log_step` takes `(step_num, agent, planned_input, mcp_output, resolved_input)` and stores `mcp_output['content']` as the output.

### 9. Always Return the Trace — Even on Failure

`context_engine()` returns `(final_output, trace)`. On planning or execution failure, return `(None, trace)` after `trace.finalize("Failed ...")`. Never swallow the trace.

### 10. Assemble in This Order

Inside `context_engine(goal)`:

1. Print the goal banner
2. Construct the `ExecutionTrace`
3. Load the registry (e.g., `AGENT_TOOLKIT`)
4. **Phase 1 — Plan**: get capabilities, call `planner`, `trace.log_plan(plan)`; on exception, `finalize("Failed during Planning")` and return `(None, trace)`
5. **Phase 2 — Execute**: iterate the plan, resolve, dispatch, store output, log step; on exception, `finalize(f"Failed at Step {n}")` and return `(None, trace)`
6. Pull `final_output = state.get(f"STEP_{len(plan)}_OUTPUT")`
7. `trace.finalize("Success", final_output)` and return `(final_output, trace)`

## Guidelines

- Keep the Planner prompt's examples short but representative of the plan shapes you actually need
- Log with a consistent `[Engine: Planner]` / `[Engine: Executor]` prefix for grep-ability
- Treat the state dict as ephemeral short-term memory — it lives for one engine run
- Echo every resolved dependency to logs so reviewers can see context flowing

## Exceptions

- **Single-step plans**: Context Chaining clauses are still required in the prompt — they cost nothing and future-proof the plan
- **Custom output keys**: If an agent returns a non-`content` MCP field, document it explicitly; the default Tracer assumes `mcp_output['content']`

## Quick Reference

| Rule | Summary |
|------|---------|
| Planner inputs | `(goal, capabilities)` only |
| Plan shape | JSON list of `{step, agent, input}` |
| Reference syntax | `$$STEP_X_OUTPUT$$` |
| Pre-call resolve | Always `copy.deepcopy` then recurse |
| State key | `STEP_{n}_OUTPUT` |
| Transport | `create_mcp_message("Engine", resolved_input)` |
| Failure | Return `(None, trace)` after `finalize` |
| Assembly | Plan -> log_plan -> loop(resolve, dispatch, log_step) -> finalize |
