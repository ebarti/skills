# Evaluation Pipeline Checklist

Use when designing or auditing an end-to-end evaluation pipeline for an AI application.

## Before You Start

- [ ] Business metric is defined (DAU, automation %, revenue, etc.)
- [ ] Usefulness threshold is defined (below this, app is unusable)
- [ ] Real user queries (or production samples) are available

## Step 1: Component Coverage

- [ ] Every pipeline step has its own evaluation method
- [ ] Each step has ground-truth data for isolated scoring
- [ ] End-to-end score is computed in addition to per-step scores
- [ ] Turn-based scores are computed (per output)
- [ ] Task-based scores are computed (task completion + turn count)
- [ ] Task boundary definition is documented (when applicable)

## Step 2: Guidelines

- [ ] Out-of-scope inputs are defined with handling rules
- [ ] Each criterion is named (avg ~2.3 per app)
- [ ] Each criterion has a scoring scale (binary / 1-5 / -1,0,1 / 0-1)
- [ ] Each score on the scale has a worked example
- [ ] Rubric was validated by 2+ humans (agreement measured)
- [ ] Rubric distinguishes "correct" from "good" responses
- [ ] Eval metrics are mapped to business outcomes (table or function)
- [ ] Usefulness threshold is encoded in the mapping

## Step 3: Methods

- [ ] Each criterion has an appropriate method (classifier / similarity / AI judge / human)
- [ ] Cheap and expensive methods are mixed (cost-aware sampling)
- [ ] Logprobs are captured where the method supports them
- [ ] AI judge temperature is set to 0
- [ ] AI judge prompt is versioned and logged
- [ ] Human-in-the-loop sampling exists (target ~hundreds/day for high-stakes apps)
- [ ] Production evaluation plan exists (no reference data fallback)
- [ ] User feedback collection is wired in (see Ch. 10)

## Step 3: Data

- [ ] Annotation guideline written (decision rules + worked examples)
- [ ] Annotation guideline can be reused for finetuning data
- [ ] Production data is used where possible
- [ ] Multiple eval sets exist:
  - [ ] Production-distribution set
  - [ ] Known-failure set
  - [ ] Common-user-error set (e.g., typos)
  - [ ] Out-of-scope set
  - [ ] Adversarial/safety set (if applicable)
- [ ] Data is sliced (tier, traffic source, length, topic, format)
- [ ] Per-slice metrics are reported (Simpson's paradox guard)
- [ ] Set size justified by bootstrap variance check
- [ ] Set size aligns with target detection level (see table below)

## Step 3: Eval-the-Eval

- [ ] Pipeline produces correct signals (better responses get higher scores)
- [ ] Pipeline is reproducible (low variance across reruns)
- [ ] Metric pairwise correlations are measured
- [ ] Perfectly correlated metrics are pruned
- [ ] Uncorrelated metrics are investigated (insight or untrustworthy)
- [ ] Latency and cost overhead are measured

## Iteration

- [ ] Experiment tracking captures: eval data version, rubric version, judge prompt, sampling config, model version
- [ ] Pipeline is consistent across runs (no silent rubric drift)
- [ ] Iteration cadence is defined (when to revise criteria)

## Red Flags

Stop and address if you find:

- A single end-to-end score with no component scores
- A rubric with no worked examples
- An AI judge with temperature > 0
- Bootstrap variance large enough to flip rank ordering of two systems
- Two metrics with correlation = 1.0 (one is redundant) or = 0 (one is wrong)
- Eval skipped in production "for latency"
- "Correct but unhelpful" responses scoring as good

## Quick Reference: Sample Size for 95% Confidence

| Difference to detect | Samples needed |
|----------------------|----------------|
| 30% | ~10 |
| 10% | ~100 |
| 3% | ~1,000 |
| 1% | ~10,000 |

Rule: every 3x decrease in difference -> 10x more samples.

Inverse Scaling prize floor: 300 examples; preferred 1,000+.
lm-evaluation-harness: median 1,000; mean 2,159.

## Quick Reference: Pipeline Health

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| Component coverage | Score on every step | Score on critical steps | End-to-end only |
| Criteria count | 2-4 | 1 or 5+ (justified) | None defined |
| Rubric clarity | Humans agree >0.8 | Humans agree >0.6 | Disagreement |
| Bootstrap std | Small vs. expected delta | Detectable | Larger than delta |
| AI judge temp | 0 | 0 | > 0 |
| Eval sets | 3+ targeted sets | 2 sets | 1 generic set |
| Tracking | All vars logged | Major vars logged | Nothing logged |
