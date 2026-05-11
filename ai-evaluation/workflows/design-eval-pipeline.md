# Design Evaluation Pipeline Workflow

The 3-step evaluation pipeline design from "AI Engineering" Chapter 4.

## When to Use

- Building an AI feature for the first time
- Existing AI feature has no evaluation
- Eval scores don't predict production quality (mismatch)
- Adding a new component to an existing AI system

## Prerequisites

- Defined task with input/output
- A small set of representative inputs
- Access to the system's components (or willingness to test e2e)

**Reference**: `references/evaluation-pipeline/rules.md`

---

## Workflow Steps

### Step 1: Evaluate All Components in the System

**Goal**: Decompose the system and evaluate each part separately, not just end-to-end.

- [ ] Draw the system: list every LLM call, retrieval step, tool call, post-processor
- [ ] For each component, identify what could go wrong
- [ ] Pick component-level metrics for each
- [ ] Pick end-to-end metrics that reflect user-visible quality
- [ ] Decide whether evaluation is **turn-based** (each LLM call) or **task-based** (end-to-end)

**Ask**: "If the final output is wrong, can I tell which component caused it?"

**Reference**: `references/evaluation-pipeline/rules.md`, `references/evaluation-pipeline/examples.md`

---

### Step 2: Create an Evaluation Guideline

**Goal**: Write down explicit criteria, rubrics, and business mapping.

#### 2a. Define Evaluation Criteria
- [ ] Pick criteria from `references/evaluation-criteria/rules.md` (domain capability, generation, safety, instruction-following, cost/latency)
- [ ] Limit to 2-4 criteria that matter most for your task
- [ ] For each criterion, define what "pass" means

#### 2b. Create Scoring Rubrics with Examples
- [ ] Prefer classification (3-5 buckets) over numerical scores
- [ ] Provide labeled examples for each bucket
- [ ] Test the rubric: can two different annotators agree?

#### 2c. Tie Evaluation Metrics to Business Metrics
- [ ] For each eval metric, write down the business outcome it predicts
- [ ] If you can't articulate the link, the metric may be vanity

**Reference**: `references/evaluation-pipeline/rules.md`, `references/evaluation-pipeline/examples.md`

---

### Step 3: Define Evaluation Methods and Data

**Goal**: Pick how to score and what to score on.

#### 3a. Select Evaluation Methods
- [ ] Match method to criterion: functional correctness, similarity, AI judge, comparative, human
- [ ] Prefer cheap methods (exact match, classifier) when possible
- [ ] Use AI judge for open-ended outputs (with `temperature=0`, pinned model+prompt)
- [ ] Use multiple eval sets (general, edge cases, regression, slice-by-slice)

**Reference**: `references/exact-evaluation/patterns.md`, `references/ai-as-judge/rules.md`

#### 3b. Annotate Evaluation Data
- [ ] Build an evaluation set with target size (use bootstrap to validate)
- [ ] Write annotation guidelines (= eval guidelines)
- [ ] Annotate with multiple annotators on a sample, measure agreement

#### 3c. Evaluate Your Evaluation Pipeline
- [ ] Verify eval correlates with human judgment on a sample
- [ ] Run eval-the-eval: would the metric reward bad outputs?
- [ ] Check Simpson's paradox: do per-slice trends contradict overall trend?

#### 3d. Iterate
- [ ] Track eval changes over time
- [ ] When eval doesn't predict prod quality, fix the eval first

**Reference**: `references/evaluation-pipeline/checklist.md`

---

## Quick Checklist

```
[ ] Step 1: All components identified and scored
[ ] Step 2a: Criteria defined (2-4)
[ ] Step 2b: Scoring rubric with examples
[ ] Step 2c: Business metric link documented
[ ] Step 3a: Methods chosen
[ ] Step 3b: Eval data annotated
[ ] Step 3c: Eval-the-eval done
[ ] Step 3d: Iteration plan set
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Only e2e evaluation | Can't pinpoint failures | Eval each component too |
| 1-10 numerical AI judge | High variance, low signal | Use 3-5 class classification |
| One eval set | Misses edge cases / regressions | 3+ eval sets (general, edge, regression) |
| Eval metric ≠ business metric | Optimizing wrong thing | Document the link explicitly |
| AI judge with temperature > 0 | Run-to-run variance | temperature=0, pin everything |

---

## Exit Criteria

- [ ] Component decomposition documented
- [ ] Rubrics with examples checked into the repo
- [ ] Evaluation runs reproducibly
- [ ] Eval-prod correlation measured (sample)
- [ ] Iteration cadence set
