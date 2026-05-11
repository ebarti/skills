# Summarizer Agent Patterns

Reusable patterns for context reduction in glass-box multi-agent systems.

## Pattern: Summarizer-as-Context-Reducer (Gatekeeper)

### Intent

Place a specialist agent between large source text and an expensive downstream agent, so the downstream agent only ever sees an objective-driven, low-volume / high-relevance summary instead of the original high-volume / low-relevance text.

### When to Use

- A user goal embeds factual context that exceeds comfortable token budgets.
- A downstream agent (Writer, planner, generator) is the expensive step in the workflow.
- Cost, latency, or signal-to-noise on the final agent must improve.
- The factual content is already known — no Researcher retrieval is needed.

### Structure

```python
# 1. Specialist agent with injected dependencies
def agent_summarizer(mcp_message, client, generation_model):
    text_to_summarize = mcp_message['content'].get('text_to_summarize')
    summary_objective = mcp_message['content'].get('summary_objective')
    if not text_to_summarize or not summary_objective:
        raise ValueError("...")
    summary = call_llm_robust(system_prompt, user_prompt,
                              client=client, generation_model=generation_model)
    return create_mcp_message("Summarizer", {"summary": summary})

# 2. Register in the agent dictionary
self.registry = {..., "Summarizer": agents.agent_summarizer}

# 3. Wire dependencies in get_handler
elif agent_name == "Summarizer":
    return lambda mcp_message: handler_func(
        mcp_message, client=client, generation_model=generation_model)

# 4. Describe in the Planner-facing capabilities manual
# 3. AGENT: Summarizer
#    ROLE: Reduces large text to a concise summary based on a specific objective...
#    INPUTS: "text_to_summarize", "summary_objective"
#    OUTPUT: {"summary": "..."}
```

### Example

In Chapter 6's demonstration, the Planner correctly chained:

`Summarizer (253 -> 110 tokens) -> Librarian (blueprint) -> Writer (lean facts + style)`

The Writer never received the 253-token article — only the 110-token summary plus the suspense blueprint.

### Benefits

- ~56.5% token reduction on the expensive generation step (chapter result).
- Dynamic Planner discovery — no hardcoding required.
- Decoupled: adding the gatekeeper does not modify the engine core.
- Translates directly into cost, speed, and quality improvements at scale.

### Considerations

- Requires downstream agents to be bilingual (handle both producer schemas — see Writer change accepting `summary` alongside `facts`).
- A weak `summary_objective` collapses the pattern's value to zero. The objective is the lever.
- Tiny inputs may not benefit — the Summarizer's own LLM call has a floor cost.
- Lossy by nature; for entity extraction prefer a structured-output objective (e.g. JSON) over free-form prose.

---

## Pattern: Post-Execution Measurement

### Intent

Prove the value of a context-reduction step by measuring tokens before and after, using the same utility (`count_tokens`) the engine uses internally for proactive decisions.

### When to Use

- After any Summarizer (or other reducer) step completes.
- When validating a new agent's ROI before shipping.
- When building a business case for stakeholders — to convert a technical metric into cost / speed / quality language.
- During architecture-workshop decisions about where in the pipeline to instrument measurement.

### Structure

```python
from helpers import count_tokens

original_text = <input that went into the reducer>
summarized_text = trace.steps[<index>]['output']['summary']

original_tokens = count_tokens(original_text)
summarized_tokens = count_tokens(summarized_text)
reduction_percentage = (1 - (summarized_tokens / original_tokens)) * 100

print(f"Original Text Tokens: {original_tokens}")
print(f"Summarized Text Tokens: {summarized_tokens}")
print(f"Token Reduction: {reduction_percentage:.1f}%")
```

### Example

Chapter 6's run produced:

| Metric | Value |
|--------|-------|
| Original tokens | 253 |
| Summarized tokens | 110 |
| Reduction | 56.5% |

At 10,000 reports/day with >50% reduction on the most expensive generation step, the chapter projects "thousands, or even tens of thousands, of dollars per month in API costs" saved.

### Benefits

- Definitive, trace-anchored proof of agent value.
- Forces the reduction conversation into measurable units.
- Provides the raw input for business-value framing (cost / speed / quality).

### Considerations

- Where to instrument is an architectural decision, not a default — discuss in design workshops.
- Reduction percentages are workload-dependent; measure across realistic samples, not one-off runs.
- Pair with downstream-quality checks — a high reduction with degraded output is a regression, not a win.

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|-------------------|
| Large factual context already embedded in the user goal | Summarizer-as-Context-Reducer |
| Need to prove ROI of a reducer step | Post-Execution Measurement |
| Stakeholder wants a business case for the new agent | Post-Execution Measurement + business framing |
| New producer agent with a different output schema | Update consumers to be bilingual (see Writer rule) |
