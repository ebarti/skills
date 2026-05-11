# Select Model Workflow

The 4-step model selection workflow from "AI Engineering" Chapter 4.

## When to Use

- Choosing the foundation model for a new project
- Re-evaluating the model behind an existing feature
- Deciding open-source vs API model
- Picking between multiple candidate models

## Prerequisites

- Defined task and basic test cases
- Some sense of latency/cost constraints
- An evaluation metric (or willingness to define one)

**Reference**: `references/model-selection/rules.md`

---

## Workflow Steps

### Step 1: Filter on Hard Attributes

**Goal**: Remove disqualified models before spending evaluation budget.

- [ ] List **hard attributes**: licensing, privacy, max context, modalities, on-device requirement, region availability
- [ ] List **soft attributes** (will be evaluated): quality, latency, cost
- [ ] Disqualify any model that fails a hard attribute
- [ ] Read licenses carefully — flag MAU caps (e.g., Llama 700M MAU), commercial-use clauses, output reuse for distillation

**Reference**: `references/model-selection/rules.md`

---

### Step 2: Use Public Information for Coarse Ranking

**Goal**: Build a candidate shortlist using public benchmarks (cheap signals).

- [ ] Look at relevant public benchmarks (MMLU, HumanEval, etc. — match to your task)
- [ ] Look at public leaderboards (Chatbot Arena, etc.)
- [ ] Cross-check community signals (HF downloads, GitHub stars, popularity)
- [ ] Build a 3-5 model shortlist
- [ ] **DO NOT** make final selection based on benchmarks (contamination risk)

**If benchmark scores look surprisingly high**: check for data contamination via n-gram overlap or perplexity.

**Reference**: `references/model-selection/rules.md`, `references/model-selection/examples.md`

---

### Step 3: Run Your Own Evaluation

**Goal**: Measure each candidate on YOUR task with YOUR data.

- [ ] Use your evaluation pipeline (see `ai-evaluation/workflows/design-eval-pipeline.md`)
- [ ] Run each candidate on your held-out evaluation set
- [ ] Measure quality, latency (TTFT, TPOT), and cost per request
- [ ] Test edge cases and adversarial inputs
- [ ] Score on the 7 build-vs-buy axes if relevant: privacy, lineage, performance, functionality, cost, control, on-device

**Reference**: `references/model-selection/rules.md`, `references/evaluation-pipeline/rules.md`

---

### Step 4: Continually Monitor and Re-evaluate

**Goal**: Treat model selection as ongoing.

- [ ] Set up monitoring on the chosen model in production
- [ ] Re-run the selection workflow when: new models drop, costs change, requirements shift
- [ ] Log model version explicitly (don't use floating aliases like "latest")

**Reference**: `references/model-selection/checklist.md`, `ai-production-architecture/references/monitoring-observability/rules.md`

---

## Quick Checklist

```
[ ] Step 1: Hard attributes filter applied (licenses read)
[ ] Step 2: Public-info shortlist (3-5 models)
[ ] Step 3: Custom evaluation run on each candidate
[ ] Step 4: Monitoring + re-evaluation cadence set
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Picking based on average benchmark | Hides task-specific weakness | Eval on your own task |
| Trusting MMLU = capability | Likely contaminated | Treat benchmarks as coarse filter only |
| Skipping license read | Legal risk on launch | Verify commercial-use, MAU, output-reuse clauses |
| Floating model alias in prod | Silent quality drift | Pin specific version |

---

## Exit Criteria

- [ ] Chosen model documented with rationale
- [ ] Eval scores recorded for chosen model + 1-2 alternatives
- [ ] License compliance verified
- [ ] Monitoring + drift detection in place
