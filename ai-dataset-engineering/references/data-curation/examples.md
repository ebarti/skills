# Data Curation Examples

Concrete examples of quality issues, coverage analysis, quantity estimation, and annotation processes.

## Quality Issues to Look For
### Relevance Mismatch

```python
# BAD: Modern legal QA model trained on 19th-century case law
training_examples = load_dataset("19th_century_legal_cases")
# Statutes/terminology have changed - model produces confidently wrong answers.

# GOOD: Filter by date and jurisdiction
training_examples = [
    ex for ex in load_dataset("legal_qa")
    if ex["jurisdiction"] == "US" and ex["year"] >= 2010
]
```

### Misalignment with Task Requirements

```python
# BAD: Task requires "score + justification" but data has scores only
example = {"essay": "...", "score": 4}

# GOOD: Include all required fields
example = {"essay": "...", "score": 4,
           "justification": "Clear thesis but weak evidence in paragraph 3."}
```

### Formatting Noise

```python
import re
# BAD: Scraped HTML and stray whitespace left in
raw = {"text": "  <p>This is <b>great</b>!</p>\n\n\n", "label": "positive"}

# GOOD: Clean at ingestion
def clean(t: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", t)).strip()
example = {"text": clean(raw["text"]), "label": "positive"}
```

### Inconsistent Annotations

```python
# BAD: Two annotators differ wildly - no clear guideline
annotations = [{"annotator": "A", "essay_id": 42, "score": 2},
               {"annotator": "B", "essay_id": 42, "score": 5}]

# GOOD: Guideline-driven, with inter-annotator agreement gate
def kappa_above(annotations, threshold=0.7) -> bool: ...
assert kappa_above(annotations, 0.7), "Re-train annotators or revise guideline"
```

### Duplication / Eval Contamination

```python
import hashlib
def hashes(rows): return {hashlib.md5(r["text"].encode()).hexdigest() for r in rows}

# Detect contamination
overlap = hashes(train) & hashes(eval_set)
print(f"Contaminated examples: {len(overlap)}")

# Deduplicate and remove eval overlap
seen, eval_h, train_clean = set(), hashes(eval_set), []
for ex in train:
    h = hashlib.md5(ex["text"].encode()).hexdigest()
    if h not in seen and h not in eval_h:
        seen.add(h); train_clean.append(ex)
```

### PII / Compliance Violation

```python
import re
# BAD: emails, phones, SSNs left in when policy forbids
# GOOD: Scrub before training
def redact_pii(t: str) -> str:
    t = re.sub(r"\b[\w.+-]+@[\w-]+\.[\w.-]+\b", "[EMAIL]", t)
    t = re.sub(r"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b", "[PHONE]", t)
    return re.sub(r"\b\d{3}-\d{2}-\d{4}\b", "[SSN]", t)
```

## Coverage Analysis

### Diversity Audit

```python
from collections import Counter

def length_bucket(t: str) -> str:
    return "short" if len(t) < 200 else "medium" if len(t) < 1000 else "long"

def audit_coverage(dataset: list[dict]) -> dict:
    return {
        "topics": Counter(ex["topic"] for ex in dataset),
        "languages": Counter(ex["language"] for ex in dataset),
        "lengths": Counter(length_bucket(ex["text"]) for ex in dataset),
        "turn_counts": Counter(ex.get("num_turns", 1) for ex in dataset),
    }

# Flag under-represented buckets (<5%)
for axis, counts in audit_coverage(my_dataset).items():
    total = sum(counts.values())
    rare = {k: v for k, v in counts.items() if v / total < 0.05}
    if rare: print(f"{axis} under-represented: {rare}")
```

### Llama 3 Data Mix (reference)

| Domain | Pre-training | SFT | Preference |
|--------|--------------|-----|------------|
| General knowledge (English) | 50% | 52.66% | 81.99% |
| Math and reasoning | 25% | 21.19% | 5.89% |
| Coding | 17% | 14.89% | 6.93% |
| Multilingual | 8% | 3.01% | 5.19% |
| Exam-like | - | 8.14% | - |
| Long context | - | 0.11% | - |

Math + code dominate pre-training/SFT (~42%), far above their internet share - boosts reasoning.

## Quantity Estimates by Task Type

| Task Type | Technique | Approx Examples | Reasoning |
|-----------|-----------|-----------------|-----------|
| Sentiment classification (binary) | PEFT | 100-1,000 | Simple, narrow output |
| Domain QA (e.g., financial filings) | Full FT | 10K-100K+ | Reasoning + domain depth |
| Instruction following (general) | PEFT/Full | 1K-100K | LIMA showed 1K curated works |
| Chain-of-thought | Full FT | 10K-100K | Step-by-step is scarce |
| Tool use / agentic | Mixed | 10K-100K | Often synthetic + simulated |
| Pre-training (from scratch) | Full | Trillions of tokens | Llama 2: 2T, Llama 3: 16T |
| Sanity check | Any | 50-100 | Should already show lift |

### Scaling Curve Experiment

```python
import matplotlib.pyplot as plt

def scaling_experiment(data, fractions=(0.25, 0.5, 1.0)):
    return [(int(len(data) * f),
             evaluate(finetune(base_model, data[:int(len(data) * f)]), eval_set))
            for f in fractions]

pts = scaling_experiment(my_dataset)
plt.plot([n for n, _ in pts], [s for _, s in pts], marker="o")
```

Steep slope at 100% -> doubling data will pay off. Plateau by 50% -> stop, invest elsewhere.

## Annotation Processes

### Realistic Iterative Pipeline

```python
# 1. Public dataset
raw = load_dataset("instructions_v1")                                       # 10,000
# 2. Filter low-quality instructions
filtered = [e for e in raw if quality_check(e["instruction"]) > 0.7]        # 9,000
# 3. Separate low-quality responses
low_q  = [e for e in filtered if quality_check(e["response"]) < 0.7]        # 3,000
high_q = [e for e in filtered if e not in low_q]                            # 6,000
# 4. Manually rewrite responses
dataset = high_q + manual_annotate(low_q)                                   # 9,000
# 5. Coverage gap -> synthetic
synthetic = ai_synthesize(manual_create_templates(topic="X", n=100), total=2000)
# 6. Annotate synthetic
dataset = dataset + manual_annotate(synthetic)                              # 11,000
# Hidden: re-annotation cycles, fact-checking, guideline updates
```

### Annotation Guideline Sketch (rating task)

```markdown
1: Factually wrong, harmful, or off-topic.
2: On-topic but missing key info OR contains a notable error.
3: Correct and on-topic. May lack polish.
4: Correct, complete, well-structured. No unsolicited additions.
5: Score 4 plus exemplary clarity, helpfulness, or insight.

Edge cases:
- Correct but unhelpful: max score 2.
- Unsolicited rewrites/suggestions: subtract 1.
- Appropriate refusal on unsafe prompt: score the refusal quality.
```

### Bootstrapping Pattern: Cheaper -> Real Data

```python
# Self-supervised -> supervised
m = self_supervised_finetune(base_model, legal_documents)
final = supervised_finetune(m, legal_qa_pairs)
# Less-relevant -> in-domain
m = supervised_finetune(base_model, tweet_sentiment_data)
final = supervised_finetune(m, product_review_sentiment_data)
# Synthetic -> real (caution: easy to waste compute)
m = supervised_finetune(base_model, ai_synthesized_medical_reports)
final = supervised_finetune(m, real_medical_reports)
```
