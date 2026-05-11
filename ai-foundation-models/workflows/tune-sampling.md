# Tune Sampling Parameters Workflow

Configure temperature, top-k, top-p, stopping conditions, and structured output method for an LLM call.

## When to Use

- Setting up a new LLM-powered feature
- Output too random or too repetitive
- Need structured output (JSON, SQL, schema)
- Hallucination is a known issue
- Same input giving different outputs (inconsistency)

## Prerequisites

- The LLM API and model in use
- Clear use case (factual / creative / code / chat)
- A small test set of representative prompts

**Reference**: `references/sampling/rules.md`

---

## Workflow Steps

### Step 1: Classify the Task

**Goal**: Match the task to a sampling pattern.

- [ ] Pick task class: factual Q&A, code/SQL/regex, creative writing, chat (balanced), classification
- [ ] Identify whether the output must be structured (JSON, SQL, etc.)
- [ ] Identify whether reproducibility is required (eval, audit)

**Reference**: `references/sampling/patterns.md`

---

### Step 2: Set Temperature

**Goal**: Pick the right randomness level.

- [ ] Factual / code / classification → `temperature=0` (or near 0)
- [ ] Chat / Q&A → `temperature ~ 0.3-0.7`
- [ ] Creative writing / brainstorming → `temperature ~ 0.7-1.0`
- [ ] Don't stack temperature with top-p/top-k tuning

**If reproducibility matters**: set `temperature=0` AND `seed` (where supported).

**Reference**: `references/sampling/rules.md`

---

### Step 3: Set Top-p / Top-k (if needed)

**Goal**: Adjust diversity beyond temperature.

- [ ] Default: prefer `top_p` over `top_k`
- [ ] If using top-p: typical range `0.9 – 1.0`
- [ ] If using top-k: typical range `40 – 100` for chat
- [ ] Don't stack top-p AND top-k AND temperature simultaneously

**Reference**: `references/sampling/rules.md`

---

### Step 4: Set Stopping Conditions

**Goal**: Prevent runaway generation.

- [ ] Set `max_tokens` to a reasonable upper bound for your task
- [ ] Add `stop` sequences for known terminators (e.g., `</answer>`, `\n\n`)
- [ ] Verify your provider's default max_tokens isn't truncating output

**Reference**: `references/sampling/rules.md`

---

### Step 5: Choose Structured Output Method (if applicable)

**Goal**: Get reliable structured output without hallucinated schemas.

Method ladder (try in order):
1. **Prompting** – cheap, works for simple cases
2. **Post-processing** – validate + retry on parse failure
3. **Constrained sampling** – e.g., `outlines`, `instructor`, JSON mode
4. **Finetuning** – last resort, if structure is critical and the model fails repeatedly

- [ ] Pick lowest method on the ladder that meets your reliability bar
- [ ] Define what to do on parse failure (retry, fallback, user error)

**Reference**: `references/sampling/examples.md`

---

### Step 6: Mitigate Hallucination (if applicable)

**Goal**: Reduce fabrication for factual tasks.

- [ ] Lower temperature
- [ ] Add "I don't know" as an explicit option in the prompt
- [ ] Ground via RAG when facts are needed
- [ ] Add a verification step (self-check or AI judge)
- [ ] For multi-step reasoning: use self-consistency (majority vote across N samples)

**Reference**: `references/sampling/rules.md`, `references/sampling/checklist.md`

---

### Step 7: Validate on Test Set

**Goal**: Confirm the configuration works end to end.

- [ ] Run the chosen config on your test prompts
- [ ] Measure: parse success rate (for structured), task quality, latency
- [ ] Compare against an alternative config
- [ ] Document the chosen settings in code

**Reference**: `references/sampling/checklist.md`

---

## Quick Checklist

```
[ ] Step 1: Task classified
[ ] Step 2: Temperature set
[ ] Step 3: Top-p/top-k set (if needed, no stacking)
[ ] Step 4: max_tokens + stop sequences set
[ ] Step 5: Structured output method chosen
[ ] Step 6: Hallucination mitigations in place
[ ] Step 7: Validated on test set
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Temperature 0.7 for code generation | Bugs from random tokens | Use temperature=0 |
| Stacking temperature + top-p + top-k | Hard to reason about | Pick one knob |
| No max_tokens set | Cost/latency surprises | Always set a sane cap |
| JSON-by-prompting in critical path | Parse failures in prod | Use constrained sampling or post-processing |

---

## Exit Criteria

- [ ] Sampling parameters checked into config or code
- [ ] Test set passes at the chosen quality bar
- [ ] Failure modes (parse error, timeout) handled
