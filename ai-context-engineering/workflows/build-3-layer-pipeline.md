# Build a 3-Layer Analysis Pipeline Workflow

End-to-end build of a layered (scope → investigation → action) document/meeting analysis pipeline using semantic blueprints + chained prompts.

## When to Use

- Building a new meeting / interview / document summarization system
- The single-prompt approach produces generic or off-target output
- The task naturally decomposes into "what / how / what-next"

## Prerequisites

- An LLM client (OpenAI or compatible)
- A source document or transcript to analyze
- Familiarity with semantic blueprints (Level 5 context)

**Reference**: `references/semantic-blueprint/knowledge.md`, `references/meeting-analysis/knowledge.md`

---

## Workflow Steps

### Step 1: Choose the right context level

**Goal**: Confirm a layered approach is the right fit.

- [ ] Try the task at Level 1-3 first (basic / linear / goal-oriented prompt)
- [ ] If output is generic or misses key details, escalate
- [ ] If the task has 3+ distinct cognitive sub-steps, use the 3-layer pattern

**Reference**: `references/semantic-blueprint/rules.md` (when to upgrade levels)

---

### Step 2: Design Layer 1 — Scope (the "what")

**Goal**: Establish what the analysis is about, who's involved, and the high-level shape.

- [ ] Write a system prompt that ONLY extracts scope (no analysis yet)
- [ ] Define output schema (e.g. `{topic, participants, scope_summary}`)
- [ ] Test with a short input

**Ask**: "Does Layer 1 output give me everything I need to start investigating?"

**Reference**: `references/meeting-analysis/rules.md`, `references/meeting-analysis/examples-layer1.md`

---

### Step 3: Design Layer 2 — Investigation (the "how")

**Goal**: Use Layer 1's output as context to investigate the specifics.

- [ ] Pipe Layer 1 output verbatim into Layer 2's prompt
- [ ] Define investigation roles (decisions, blockers, key claims, etc.)
- [ ] Output structured findings (don't summarize yet)

**If the task involves retrieval**:
- [ ] Use Layer 1 scope to constrain retrieval queries

**Reference**: `references/meeting-analysis/examples-layer2.md`, `references/meeting-analysis/patterns.md` (Differential RAG)

---

### Step 4: Design Layer 3 — Action (the "what next")

**Goal**: Convert findings into structured next steps.

- [ ] Pipe Layer 2 findings + Layer 1 scope verbatim into Layer 3
- [ ] Output a structured summary (g6) and follow-up actions (g7)
- [ ] Include explicit ownership / deadlines if applicable

**Reference**: `references/meeting-analysis/examples-layer3.md`

---

### Step 5: Wire the pipeline

**Goal**: Chain the 3 layers into a single callable pipeline.

- [ ] Build a function `analyze(input) -> {scope, findings, summary, actions}`
- [ ] Use one-purpose-per-prompt — never combine layers
- [ ] Pipe outputs verbatim (no paraphrasing)
- [ ] Log each layer's output for debugging

**Reference**: `references/meeting-analysis/rules.md` (rule: pipe outputs verbatim)

---

### Step 6: Validate end-to-end

**Goal**: Confirm the pipeline produces useful output on real inputs.

- [ ] Run on 3 distinct sample inputs
- [ ] Verify Layer 3's summary captures Layer 2's key findings
- [ ] Verify Layer 2's findings are grounded in Layer 1's scope
- [ ] Verify no fabrication (every claim traceable)

---

## Quick Checklist

```
[ ] Step 1: Confirmed layered approach is right
[ ] Step 2: Layer 1 (scope) prompt + schema
[ ] Step 3: Layer 2 (investigation) prompt + schema
[ ] Step 4: Layer 3 (action) prompt + schema
[ ] Step 5: Chained pipeline
[ ] Step 6: End-to-end validation
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Combining 2 layers in one prompt | Mixes responsibilities, drift | One purpose per prompt |
| Paraphrasing layer outputs | Loses fidelity, introduces noise | Pipe verbatim |
| Skipping Layer 1 if scope "obvious" | Investigation lacks anchor | Always do scope first |
| Hard-coding output schema in prompt | Schema drift across layers | Define schemas separately |

---

## Exit Criteria

- [ ] Pipeline runs end-to-end on 3 sample inputs
- [ ] Each layer's output is structured and traceable
- [ ] No claim in Layer 3 lacks support from Layer 2
- [ ] Pipeline is reusable for new domains by swapping prompts only
