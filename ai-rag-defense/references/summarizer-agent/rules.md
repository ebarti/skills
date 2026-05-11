# Summarizer Agent Rules

Rules for designing, integrating, and measuring a Summarizer agent inside a glass-box multi-agent context engine.

## Core Rules

### 1. Invoke the Summarizer Before Expensive Generation Steps

Insert a Summarizer step whenever a downstream agent (typically the Writer or any LLM-heavy agent) would otherwise receive a large block of text.

- The Planner — not the developer — should choose the step, based on the capabilities description.
- Trigger conditions: factual context already provided in the goal, large source text, explicit "summarize" instruction, or anticipated token limit pressure.
- Do NOT default to the Researcher when the factual content is already embedded in the user goal.

### 2. Always Pair `text_to_summarize` With a Specific `summary_objective`

Both inputs are required. The agent raises `ValueError` if either is missing.

- A vague objective ("Summarize this text.") forces the LLM to guess and produces generic output.
- A strong objective is a miniature semantic blueprint: specific, constrained, and defines desired output structure.
- Treat `summary_objective` as the lever that turns a generic tool into a precision instrument.

### 3. Follow the Established Agent Patterns

Every new agent — including Summarizer — must:

- Accept `mcp_message` plus its dependencies (`client`, `generation_model`) as function args (dependency injection).
- Log activation with `logging.info("[Summarizer] Activated. ...")`.
- Validate inputs and `raise ValueError` on missing keys.
- Wrap the LLM call in `try/except` and re-raise on failure.
- Return output via `create_mcp_message("Summarizer", {"summary": summary})`.

### 4. Update the Registry in Three Coordinated Places

Adding the Summarizer to `registry.py` requires:

1. Add `"Summarizer": agents.agent_summarizer` to `self.registry` in `__init__`.
2. Add an `elif agent_name == "Summarizer":` branch in `get_handler` that injects `client` and `generation_model`.
3. Add a Summarizer entry to `get_capabilities_description()` listing role, exact input key names, and output schema `{"summary": "..."}`.

Skipping step 3 makes the agent invisible to the Planner — it will never be used.

### 5. Use Exact Input Key Names in the Capabilities Description

The capabilities docstring contains the line: "CRITICAL: You MUST use the exact input key names provided for each agent."

- Required inputs: `text_to_summarize`, `summary_objective`.
- Output: `{"summary": "..."}` — exact key.
- Mismatched keys cause silent data contract violations downstream (e.g. Writer receiving `{'summary': ...}` when it only knew `{'facts': ...}`).

### 6. Make Downstream Consumers Bilingual

When a new producer agent is added, its consumers must be updated to handle the new schema.

- Writer must check for `facts` first, then fall back to `summary`.
- Use `isinstance(facts_data, dict)` then `.get('facts')` then `.get('summary')`.
- Without this, the Planner's correct decision still fails at execution time.

### 7. Measure Reduction With `count_tokens` Before and After

After every Summarizer run, quantify the reduction:

- Call `count_tokens(original_text)` and `count_tokens(summarized_text)`.
- Compute `reduction_percentage = (1 - (summarized_tokens / original_tokens)) * 100`.
- Pull `summarized_text` from `trace.steps[0]['output']['summary']`.
- Where in the engine you place this measurement is an architecture-workshop decision.

### 8. Translate Reduction Into Business Value

Do not ship a token-percentage metric without a business-value framing.

- Multiply per-call savings by realistic workload (e.g. 10,000 reports/day).
- Discuss cost (API spend), speed (lower computational load), and quality (higher signal-to-noise) — all three.
- Example threshold: >50% reduction at enterprise volume = tens of thousands of dollars/month.

## Guidelines

- Validate the agent in isolation before relying on the Planner to use it.
- Keep the Summarizer's prompts inside the function — `system_prompt` and `user_prompt` use `f`-strings with clear `--- OBJECTIVE ---` and `--- TEXT TO SUMMARIZE ---` delimiters.
- Run a backward-compatibility test after registry changes — confirm simpler plans still work.
- Prefer summarized context as `facts` input even when the original would fit, if cost savings are meaningful.

## Exceptions

- **Tiny inputs**: Skip the Summarizer if `count_tokens(text) < downstream_threshold` — the LLM call itself costs more than it saves.
- **Lossy-summary risks**: For legal/financial extraction, prefer a structured-extraction objective (JSON output) instead of free-form summary.

## Quick Reference

| Rule | Summary |
|------|---------|
| When to invoke | Before expensive generation steps with large input text |
| Required inputs | `text_to_summarize` + `summary_objective` (both validated) |
| Output schema | MCP message with `{"summary": "..."}` |
| Registry edits | Dictionary entry + handler branch + capabilities description |
| Downstream impact | Update consumers to handle `summary` key alongside `facts` |
| Measurement | `count_tokens` before and after, compute % reduction |
| Reporting | Frame as cost / speed / quality business value |
