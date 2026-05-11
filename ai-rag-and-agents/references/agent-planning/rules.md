# Agent Planning Rules

Guidelines for designing planning loops, generating plans, reflecting on outcomes, correcting errors, and selecting tools.

## Core Rules

### 1. Decouple Planning from Execution

Always generate the plan first, validate it, then execute. Never let an agent execute an unvalidated plan end-to-end.

- Reject plans containing actions the agent does not have access to
- Reject plans exceeding a maximum step count (e.g., > N steps)
- Use an AI judge to score plan reasonableness when heuristics are insufficient
- Re-prompt the planner if the plan fails validation

### 2. Add an Intent Classifier

Run an intent step before planning so the agent can route to the right tools and reject out-of-scope queries.

- Reserve an `IRRELEVANT` class for refusable requests
- Use a small classifier or a focused prompt — keep it cheap
- Map each intent to a candidate tool subset

### 3. Implement Reflection at Multiple Points

Reflect after the initial plan, after each execution step, and after the full plan. Skipping reflection costs accuracy.

- After receiving the query: is it feasible?
- After plan generation: does the plan make sense?
- After each step: still on track?
- After execution: was the goal accomplished?

### 4. Inspect Function Call Parameters

Function-calling APIs validate function *names* but rarely validate *parameter values*. Always log and inspect the parameters the model chose.

**Example**:
```python
# Bad - blindly trust the call
result = call_tool(response.tool, **response.params)

# Good - log and validate first
logger.info(f"Tool: {response.tool}, params: {response.params}")
validate_params(response.tool, response.params)
result = call_tool(response.tool, **response.params)
```

### 5. Pick Plan Granularity Deliberately

Choose between exact function names (executable but brittle) and natural language steps (robust but needs a translator).

- Use function-name plans when tool inventory is stable
- Use natural-language plans when tools change often or the planner is reused across apps
- Add a translator (smaller model) to map NL steps to executable calls

### 6. Use Hierarchical Planning for Long Tasks

For multi-step tasks, plan at a high level first, then expand each step. This sidesteps the granularity trade-off.

### 7. Define Human-in-the-Loop Levels per Action

Specify which actions require human approval (e.g., DB writes, code merges, sending money). Default risky actions to manual.

### 8. Curate the Tool Inventory

More tools is not better. Run ablations and trim aggressively.

- Compare agent performance across tool sets
- Remove tools whose absence does not hurt accuracy
- Replace tools the agent consistently misuses
- Plot tool-call distribution to spot dead weight

### 9. Make Tool Descriptions Excellent

The model picks tools from descriptions. Vague descriptions = wrong picks.

- State what the tool does, when to use it, and parameter semantics
- Include parameter types and example values
- Refactor complex tools into smaller, focused ones

### 10. Allow Tool Composition

Track tool transitions. If two tools are frequently used in sequence, expose them as a combined tool. Consider a skill manager (Voyager-style) that saves successful new tools to a reusable library.

## Guidelines

- Generate multiple plans in parallel and pick the best one when latency budget allows
- For reflection, use a separate evaluator model to avoid same-model blind spots
- Use ReAct-style Thought/Act/Observation traces when interpretability matters
- When ReAct/Reflexion costs are too high, batch reflection (every N steps) instead of every step
- Prefer natural-language plans when finetuning a planner you want to reuse
- Evaluate parallel control-flow support when picking a framework — it cuts perceived latency

## Exceptions

- **Trivial single-step tasks**: skip planning; just call the tool
- **Hard real-time loops**: skip per-step reflection; reflect only on failure
- **Cost-sensitive prod**: cap reflection rounds to avoid runaway loops

## Quick Reference

| Rule | Summary |
|------|---------|
| Decouple plan/execute | Validate before running |
| Intent classifier | Route + reject early |
| Reflect often | But cap rounds |
| Inspect params | Log every call |
| Pick granularity | Function names vs NL |
| Hierarchical planning | High-level then expand |
| Human in loop | Per-action approval policy |
| Curate tools | Ablate and trim |
| Great descriptions | Clearer = better selection |
| Compose tools | Track transitions; build skills |
