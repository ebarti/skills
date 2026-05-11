# Evaluation Pipeline Examples

Concrete examples for scoring rubrics, business-metric tie-in, and annotation guidelines.

## Component Evaluation: Resume Employer Extractor

```python
# Two-step pipeline: PDF -> text -> current employer
def evaluate_pipeline(pdf, gt_text, gt_employer):
    extracted_text = pdf_to_text(pdf)
    extracted_employer = text_to_employer(extracted_text)

    # Score each component independently
    text_score = semantic_similarity(extracted_text, gt_text)         # step 1
    # Use the GROUND-TRUTH text as input to isolate step 2's quality
    employer_score = (text_to_employer(gt_text) == gt_employer)       # step 2
    end_to_end = (extracted_employer == gt_employer)                  # overall

    return {"step1_text": text_score,
            "step2_employer": employer_score,
            "end_to_end": end_to_end}
```

**Why it works**: Without the isolated step-2 score using ground-truth text, you cannot tell whether failures come from PDF parsing or extraction.

## Scoring Rubric: Factual Consistency (Ternary)

```python
# Ternary rubric: -1 contradiction, 0 neutral, 1 entailment
RUBRIC = {
    1: "Entailment: response is fully supported by context.\n"
       "Example context: 'Order #123 shipped on May 1.'\n"
       "Example response: 'Your order shipped on May 1.' -> 1",
    0: "Neutral: response is plausible but context neither confirms nor denies.\n"
       "Example response: 'Your order will arrive soon.' -> 0",
    -1: "Contradiction: response conflicts with context.\n"
        "Example response: 'Your order has not shipped.' -> -1",
}
```

**Why it works**: Each score has a worked example. A human (or AI judge) can apply it without ambiguity.

## Scoring Rubric: Helpfulness (1-5) for Job Assessment

```python
# Job-fit assessment helpfulness rubric
RUBRIC_HELPFULNESS = {
    5: "Identifies fit, names exact gaps, gives a concrete plan to close them.",
    4: "Identifies fit and names gaps but plan is generic.",
    3: "Identifies fit only; mentions gaps without specifics.",
    2: "Verdict only ('You are a terrible fit'). Correct but unhelpful.",
    1: "Wrong verdict OR no actionable content.",
}
# Note: a correct verdict alone scores 2, not 5. Correct != good.
```

**Why it works**: Encodes LinkedIn's lesson that correct-but-unhelpful responses are bad.

## Tying Eval Metrics to Business Metrics

```python
# Map factual-consistency to automation rate (customer support chatbot)
USEFULNESS_THRESHOLD = 0.50   # below this the chatbot is unusable

AUTOMATION_TABLE = [
    (0.98, 0.90),  # 98% factual consistency -> 90% automation
    (0.90, 0.50),  # 90% -> 50%
    (0.80, 0.30),  # 80% -> 30%
]

def expected_automation(factual_consistency):
    if factual_consistency < USEFULNESS_THRESHOLD:
        return 0.0
    for score, automation in AUTOMATION_TABLE:
        if factual_consistency >= score:
            return automation
    return 0.0
```

**Why it works**: Stakeholders can reason about ROI of pushing factual_consistency from 80% to 90% (automation +20pp).

## Annotation Guideline (Excerpt)

```markdown
## Task
Label each (user_query, assistant_response) pair on three axes.

## Criteria & Scales
1. Relevance: 0 (off-topic) | 1 (on-topic)
2. Factual consistency: -1 contradicts context | 0 neutral | 1 entailed
3. Safety: 0 (unsafe/toxic) | 1 (safe)

## Decision rules (apply in order)
- If response is unsafe -> safety=0, others can still be scored.
- Use ONLY the provided context for factual consistency.
- Off-topic responses get relevance=0 even if factually correct.

## Worked examples
Q: "What's your refund policy?"
A: "Refunds within 30 days." (context says 30 days)
-> relevance=1, factual=1, safety=1

Q: "What's your refund policy?"
A: "Vote for candidate X."
-> relevance=0, factual=0 (no support), safety=0 if political content is out of scope.
```

**Why it works**: Decision rules eliminate annotator drift; worked examples calibrate edge cases. This same guideline can be reused for finetuning instruction data.

## Mixing Cheap and Expensive Methods

```python
# Cheap classifier on 100% of traffic, AI judge on a 1% sample
import random

def evaluate(response, context, query):
    cheap = toxicity_classifier(response)           # always run
    record = {"toxicity": cheap}
    if random.random() < 0.01:                      # 1% sample
        record["ai_judge_factuality"] = ai_judge(
            response, context, temperature=0,        # reproducibility
        )
    return record
```

**Why it works**: Bounds cost while keeping a high-quality signal on a representative slice.

## Bootstrap Sizing Check

```python
import numpy as np

def bootstrap_variance(scores, n_bootstraps=1000):
    """Returns std of mean across bootstraps. High std -> grow eval set."""
    n = len(scores)
    means = [
        np.mean(np.random.choice(scores, size=n, replace=True))
        for _ in range(n_bootstraps)
    ]
    return float(np.std(means))

# scores = list of 0/1 correctness for the 100-example eval set
# If std > ~0.05 absolute, grow the set.
```

**Why it works**: Replaces vibes with a numeric reliability signal.

## Slice-Based Evaluation (Avoiding Simpson's Paradox)

```python
def slice_report(records, slice_fn):
    """records: list of {'slice': str, 'score': float}; slice_fn assigns slice."""
    by_slice = {}
    for r in records:
        s = slice_fn(r)
        by_slice.setdefault(s, []).append(r["score"])
    overall = sum(r["score"] for r in records) / len(records)
    per_slice = {s: sum(v) / len(v) for s, v in by_slice.items()}
    return {"overall": overall, **per_slice}

# Always inspect per-slice; aggregate alone can hide reversal (Simpson's paradox).
```

**Why it works**: Catches the case where Model A wins every slice but loses overall (different group sizes).
