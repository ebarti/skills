# Evaluation Pipeline Patterns

Reusable patterns for building and operating an evaluation pipeline.

## Pattern: Per-Component Decomposition

### Intent

Localize failures in multi-step pipelines.

### When to Use

- Pipeline has 2+ stages (RAG, extract+classify, plan+act).
- End-to-end metric is moving and you cannot tell which step is responsible.

### Structure

```python
scores = {}
intermediate = step1(input)
scores["step1"] = score_step1(intermediate, gt_intermediate)
final = step2(intermediate)
scores["step2_isolated"] = score_step2(step2(gt_intermediate), gt_final)
scores["end_to_end"] = score_step2(final, gt_final)
```

### Benefits

- Pinpoints regressions to specific component.
- Lets teams own and improve their step independently.

### Considerations

- Requires ground truth at each intermediate stage; collect during annotation.

---

## Pattern: Layered Cheap + Expensive Scoring

### Intent

High coverage with bounded cost.

### When to Use

- Evaluating production traffic at scale.
- Expensive methods (AI judge, human) cannot run on 100% of traffic.

### Structure

```python
def score(record):
    out = {"cheap": cheap_classifier(record)}    # 100% of traffic
    if sample_for_expensive(record):             # 1-5% of traffic
        out["expensive"] = expensive_judge(record, temperature=0)
    return out
```

### Benefits

- Cheap signals catch obvious regressions immediately.
- Expensive signals calibrate cheap signals on a sampled slice.

### Considerations

- Sampling must be stratified to ensure all slices are represented.

---

## Pattern: Multiple Evaluation Sets

### Intent

One number cannot capture all behaviors; partition the space.

### When to Use

- Production application with diverse inputs.
- Distinct risk surfaces (out-of-scope, adversarial, edge cases).

### Structure

```python
EVAL_SETS = {
    "production_dist": load("prod_sample.jsonl"),    # mirrors prod traffic
    "known_failures":  load("known_bugs.jsonl"),     # regression suite
    "user_typos":      load("typo_inputs.jsonl"),    # robustness
    "out_of_scope":    load("oos.jsonl"),            # refusal behavior
    "adversarial":     load("jailbreak.jsonl"),      # safety
}
report = {name: evaluate(model, ds) for name, ds in EVAL_SETS.items()}
```

### Benefits

- Each set targets a specific concern; deltas are interpretable.
- Out-of-scope set guards against scope creep.

### Considerations

- Maintenance overhead; reserve sets that you genuinely act on.

---

## Pattern: Eval-the-Eval Loop

### Intent

Ensure the pipeline itself is reliable before trusting its verdicts.

### When to Use

- Before adopting a new metric.
- Periodically (quarterly) on existing pipeline.

### Structure

```python
checks = {
    "right_signal":   correlate(eval_score, business_outcome),
    "reproducible":   variance_across_repeated_runs(eval_pipeline),
    "metric_corr":    pairwise_correlation(metrics),
    "cost_latency":   measure_eval_overhead(),
}
```

### Benefits

- Catches a broken judge before it ships bad model decisions.
- Surfaces redundant metrics (drop perfectly-correlated ones).

### Considerations

- AI judge temperature MUST be 0 for reproducibility checks to be meaningful.

---

## Pattern: Bootstrap-Sized Eval Set

### Intent

Pick the smallest reliable eval set.

### When to Use

- Choosing N for a new eval set.
- Justifying a regression-vs-noise call.

### Structure

```python
n = 100
while bootstrap_std(model_scores_on_n_examples) > tolerance:
    n *= 2  # or follow the OpenAI table for target detection level
```

Reference: 10% delta -> ~100 samples; 3% -> ~1,000; 1% -> ~10,000.

### Benefits

- Quantitative justification for eval set size.
- Avoids both undersizing (noise) and oversizing (cost).

---

## Pattern: Production Feedback Substitution

### Intent

Run evaluation in production where reference data is missing.

### When to Use

- Live system with no reference labels available.

### Structure

```python
auto = lightweight_metrics(response)             # always
if sample_for_human():
    human = expert_review(response)              # LinkedIn: 500/day
user_signal = await collect_user_feedback(response)  # Ch. 10
```

### Benefits

- Detects drift and unusual usage patterns; builds future reference data.

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|-------------------|
| Multi-step pipeline regressions | Per-Component Decomposition |
| Need full coverage on a budget | Layered Cheap + Expensive |
| Diverse production traffic | Multiple Evaluation Sets |
| New metric or judge | Eval-the-Eval Loop |
| Sizing a new eval set | Bootstrap-Sized Eval Set |
| Live system, no reference data | Production Feedback Substitution |
