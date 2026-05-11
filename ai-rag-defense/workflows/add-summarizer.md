# Add a Summarizer Agent Workflow

Integrate the Summarizer agent into the Context Engine for proactive context reduction.

## When to Use

- Token costs are spiking due to large retrieved documents
- Writer prompts hit context-window limits
- Need to summarize one step's output before passing to the next

## Prerequisites

- Working Context Engine (from `ai-context-engine/workflows/build-context-engine.md`)
- Hardened engine recommended (from `ai-context-engine/workflows/harden-engine.md`)
- `count_tokens` helper already in place

**Reference**: `references/summarizer-agent/knowledge.md`

---

## Workflow Steps

### Step 1: Add count_tokens (if not already)

**Goal**: Foundation for proactive context reduction — must measure before reducing.

- [ ] Verify `count_tokens(text, model)` helper exists in `commons/helpers.py`
- [ ] If not: add it (see `ai-context-engine/references/hardening/examples.md`)

**Reference**: `references/summarizer-agent/examples.md` (count_tokens)

---

### Step 2: Build the Summarizer agent

**Goal**: A new specialist agent that takes long text + an objective, returns short text.

- [ ] Define inputs: `text_to_summarize`, `summary_objective`
- [ ] Write the agent's system prompt (use micro-context engineering — see Step 5)
- [ ] Wrap as a function following the specialist agent template
- [ ] Use DI for the LLM client

**Reference**: `references/summarizer-agent/examples.md` (agent_summarizer)

---

### Step 3: Update the Agent Registry

**Goal**: Make the Planner aware of the new agent.

- [ ] Add `summarizer` to the registry dict
- [ ] Update `get_handler` to inject deps for the Summarizer
- [ ] Update the capability description so the Planner picks it for reduction tasks

**Reference**: `references/summarizer-agent/examples.md` (registry update — three places), `references/summarizer-agent/rules.md` (three-place rule)

---

### Step 4: Reinforce the Writer agent (optional but recommended)

**Goal**: Ensure the Writer can consume summarized text just as well as raw.

- [ ] Update Writer's system prompt to handle both raw and summarized inputs
- [ ] Show before/after examples in the prompt

**Reference**: `references/micro-context-engineering/examples.md` (Writer before/after)

---

### Step 5: Apply micro-context engineering to the Summarizer's prompt

**Goal**: Strong, specific objective beats generic "summarize this".

- [ ] Define the macro role (you are a Summarizer)
- [ ] Define the micro objective (preserve X, drop Y)
- [ ] Set output constraints (length, structure)
- [ ] Compare poor vs strong objectives in the source

**Reference**: `references/micro-context-engineering/examples.md` (Summarizer prompts), `references/micro-context-engineering/rules.md`

---

### Step 6: Measure reduction

**Goal**: Quantify the value with token counts before/after.

- [ ] After execution, retrieve `text_to_summarize` from the trace
- [ ] Retrieve the Summarizer's output from the trace
- [ ] `count_tokens` both, compute reduction %
- [ ] Log/display the metric

**Reference**: `references/summarizer-agent/examples.md` (post-execution analysis)

---

### Step 7: End-to-end run

**Goal**: Verify Planner picks Summarizer when appropriate.

- [ ] Run a goal that produces a large intermediate (e.g. summarize a 5K-token doc, then act on it)
- [ ] Inspect the plan — does it include a Summarizer step?
- [ ] Verify Writer receives reduced text
- [ ] Check the reduction metric

---

## Quick Checklist

```
[ ] Step 1: count_tokens helper
[ ] Step 2: Summarizer agent function
[ ] Step 3: Registry updated (3 places)
[ ] Step 4: Writer reinforced (optional)
[ ] Step 5: Strong micro-context objective
[ ] Step 6: Reduction measurement
[ ] Step 7: End-to-end run
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Updating registry in only one place | Planner won't pick it | Update dict + get_handler + capabilities |
| Generic "summarize this" prompt | Generic, low-fidelity output | Micro-context engineering |
| No before/after measurement | Can't justify the cost saving | Always count tokens |
| Writer expects raw input only | Crashes on summarized input | Reinforce Writer to handle both |
| Skipping Summarizer for small text | Adds latency for no gain | Threshold: only invoke if over N tokens |

---

## Exit Criteria

- [ ] Summarizer agent exists and is registered
- [ ] Planner picks it for context-reduction goals
- [ ] Writer accepts summarized output
- [ ] Reduction % measured + logged
- [ ] Token costs reduced on representative goals
