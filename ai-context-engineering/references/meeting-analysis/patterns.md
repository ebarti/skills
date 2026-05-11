# Meeting Analysis Patterns

Reusable patterns derived from the meeting analysis use case, applicable to any document-analysis pipeline.

## Pattern: Scope → Investigation → Action

### Intent

Decompose a complex analytical task into three layers — extraction, interpretation, and artifact generation — so each LLM call has a single purpose and a clean upstream input.

### When to Use

- Long-form input (transcripts, call recordings, support tickets, design docs, research papers)
- The desired output is a polished artifact (email, report, dashboard row), not raw analysis
- You need to surface both explicit facts and implicit signals (mood, tension, gaps)
- Multiple stakeholders need different views of the same input

### Structure

```
Raw input
    │
    ▼
[Layer 1: Scope]      ── filter signal from noise, identify "what's new"
    │
    ▼
[Layer 2: Investigation] ── infer subtext, synthesize across facts
    │                       (branches: read-between-the-lines, novel synthesis)
    ▼
[Layer 3: Action]     ── schematize into a table, then convert into a delivery artifact
    │
    ▼
Final artifact (email, report, ticket, etc.)
```

### Example (generalized)

```python
# Layer 1: Scope
prompt_extract = f"Extract substantive {DOMAIN_ITEMS} from:\n---\n{raw_input}\n---\nReturn ONLY substantive content."
substantive = call_llm(prompt_extract)

prompt_diff = f"Prior context: {prior_state}\nIdentify ONLY new {DOMAIN_ITEMS}:\n---\n{substantive}\n---"
new_items = call_llm(prompt_diff)

# Layer 2: Investigation (parallel branches)
prompt_subtext = f"Read between the lines of:\n---\n{substantive}\n---\nWhat is unstated?"
subtext = call_llm(prompt_subtext)

prompt_synth = f"Combine fact A ({FACT_A}) and fact B ({FACT_B}) into a novel solution."
novel = call_llm(prompt_synth)

# Layer 3: Action
prompt_table = f"Compile into a markdown table with columns {SCHEMA}:\n{new_items}"
table = call_llm(prompt_table)

prompt_artifact = f"Convert into a {ARTIFACT_TYPE} for {AUDIENCE}:\n---\n{table}\n---"
artifact = call_llm(prompt_artifact)
```

### Benefits

- **Debuggability**: a poor final artifact points to a single failing layer
- **Reusability**: each layer's output can feed multiple downstream artifacts
- **Composability**: branches at Layer 2 produce parallel insights without state coupling
- **Quality**: forced schemas at Layer 3 eliminate vague output

### Considerations

- Each LLM call costs latency and tokens — only chain when sequential dependency is real
- Variables passed between cells are plain text — no validation, so a malformed Layer 1 output silently propagates
- The last layer's prompt should explicitly demand a schema; without it the model drifts back into prose

---

## Pattern: Differential RAG via Prior Summary

### Intent

Narrow analysis to **what changed** by injecting a summary of prior state into the prompt.

### When to Use

- Recurring meetings, status reports, monitoring digests
- You only care about deltas, not absolute state

### Structure

```python
previous_summary = retrieve_prior_state()  # could be from a vector store, doc, or DB
prompt = f"""
Context: prior state was: "{previous_summary}"
Task: Analyze the following and identify ONLY new items since prior state.
---
{current_content}
---
"""
```

### Benefits

- Cheap simulation of RAG without a vector store
- Output is automatically scoped to deltas
- Output stays small even as the underlying input grows

### Considerations

- Quality depends entirely on `previous_summary` accuracy — stale or wrong summaries silently bias the diff

---

## Pattern: Branch-Then-Join

### Intent

Fan out from a single cleaned input to multiple parallel analyses, then optionally join them in a final artifact.

### When to Use

- One source produces multiple distinct artifacts (factual summary, sentiment read, creative idea)
- The branches don't depend on each other

### Structure

```python
clean = clean_step(raw)
# parallel — could use threads or asyncio
facts = facts_step(clean)
mood  = mood_step(clean)
ideas = ideas_step(clean)
# optional join
report = join_step(facts, mood, ideas)
```

### Benefits

- Shorter wall-clock time (parallel calls)
- Each branch can use a different model or temperature
- Independent failure isolation

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|--------------------|
| New document, want polished artifact | Scope → Investigation → Action |
| Recurring input, want only deltas | Differential RAG via Prior Summary |
| One input, multiple consumers | Branch-Then-Join |
| Insights only, no artifact | Stop after Layer 2 |
| Single short input, one question | Skip patterns — single prompt is fine |
