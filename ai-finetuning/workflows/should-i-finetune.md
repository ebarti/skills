# Should I Finetune Workflow

Pre-finetuning decision workflow. Apply the "form vs facts" heuristic and exhaust cheaper alternatives first.

## When to Use

- Considering finetuning for a use case
- Stakeholders ask "shouldn't we just finetune our own model?"
- Existing model fails at the task and you're tempted to finetune
- Pre-investment go/no-go on a finetuning project

## Prerequisites

- Defined task with input/output
- Honest assessment of base model performance
- Resources estimate (compute, data, eng time)

**Reference**: `references/finetuning-overview/rules.md`

---

## Workflow Steps

### Step 1: Diagnose the Failure

**Goal**: Distinguish "model lacks information" from "model lacks behavior."

- [ ] Run the task on the best base model with a good prompt
- [ ] Categorize the failure:
  - **Information failure**: model doesn't know facts → RAG (don't finetune)
  - **Behavior failure**: model knows facts but outputs in wrong form → consider finetuning
- [ ] Apply heuristic: **Finetuning is for form, RAG is for facts**

**Reference**: `references/finetuning-overview/rules.md`

---

### Step 2: Exhaust Prompting

**Goal**: Squeeze out gains from prompt engineering before finetuning.

- [ ] Apply best practices: clear instructions, persona, examples, output format
- [ ] Try chain-of-thought / decomposition
- [ ] Iterate 3-5 times with different approaches
- [ ] Measure on your eval set
- [ ] If prompting is sufficient: STOP. Don't finetune.

**Reference**: `ai-prompt-engineering/workflows/build-prompt.md`

---

### Step 3: Try RAG (if information gap)

**Goal**: Solve information failures with retrieval.

- [ ] If failure is "lacks knowledge": build a small RAG prototype
- [ ] Measure on your eval set
- [ ] If RAG is sufficient: STOP. Don't finetune.
- [ ] If RAG helps but doesn't fully solve: consider RAG + finetuning later

**Reference**: `ai-rag-and-agents/workflows/build-rag.md`

---

### Step 4: Estimate Finetuning Resources

**Goal**: Make sure the cost is realistic.

- [ ] Estimate training data needed (start ~1K examples for SFT, scale up)
- [ ] Estimate annotation effort (often the bottleneck)
- [ ] Estimate compute: use `references/memory-bottlenecks/examples.md`
- [ ] Estimate ongoing maintenance: re-finetune on model updates, drift, etc.

**Reference**: `references/memory-bottlenecks/rules.md`, `references/memory-bottlenecks/examples.md`

---

### Step 5: Verify Justification

**Goal**: Confirm there's a real reason that prompting + RAG can't fix.

Valid reasons to finetune:
- [ ] Custom output format / DSL the model can't reliably produce via prompting
- [ ] Bias mitigation that requires retraining behavior
- [ ] Safety-critical or regulated deployment requiring on-prem control
- [ ] Need to make a smaller model match a larger model (distillation)
- [ ] Need consistency across thousands of similar requests (form learning)

Invalid reasons (these don't justify finetuning):
- [ ] "We have proprietary data" → use RAG
- [ ] "We want better quality" → exhaust prompting first
- [ ] "We need privacy" → use a private model API or self-host
- [ ] "It's cool" → no

**Reference**: `references/finetuning-overview/examples.md` (BloombergGPT cautionary tale)

---

### Step 6: Plan the Finetuning Approach

**Goal**: Pick the cheapest method that meets the bar.

- [ ] Default to PEFT (LoRA / QLoRA) over full finetuning
- [ ] Pick the smallest base model that can plausibly meet the bar
- [ ] Decide on SFT only, vs SFT + DPO, vs SFT + RLHF
- [ ] Plan a small experiment first (~50-200 examples) to measure scaling

**Reference**: `references/peft-techniques/rules.md`, `ai-foundation-models/references/post-training/patterns.md`

---

### Step 7: Walk the Pre-Finetuning Checklist

**Goal**: Final go/no-go.

- [ ] Walk every item in `references/finetuning-overview/checklist.md`
- [ ] Document the answer to each question
- [ ] Get sign-off from technical lead

**Reference**: `references/finetuning-overview/checklist.md`

---

## Quick Checklist

```
[ ] Step 1: Failure diagnosed (form vs facts)
[ ] Step 2: Prompting exhausted
[ ] Step 3: RAG tried (if info gap)
[ ] Step 4: Resources estimated
[ ] Step 5: Justification verified (valid reason)
[ ] Step 6: Approach planned (method, base model)
[ ] Step 7: Pre-finetuning checklist passed
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Finetuning for facts | Model still hallucinates | Use RAG |
| Skipping prompt engineering | Wastes compute on solvable problems | Exhaust prompting first |
| Picking too-large base model | Excessive cost | Start with smallest plausible |
| No data/maintenance plan | Project dies in production | Pre-commit to maintenance |
| Building custom model when API works | BloombergGPT outcome | Try APIs first, especially for general tasks |

---

## Exit Criteria

- [ ] Documented decision: finetune, defer, or don't finetune
- [ ] If finetuning: chosen method, base model, data plan, maintenance plan
- [ ] If not finetuning: documented why (RAG sufficient? prompting works?)
