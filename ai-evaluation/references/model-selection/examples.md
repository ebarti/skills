# Model Selection Examples

Decision frameworks, comparisons, and pitfalls for selecting foundation models.

## Decision Tree: Build vs Buy

```
START: Picking a model for a new feature
│
├── Can data leave your network?
│   ├── No  → Self-host (open weight) or privately-deployed commercial API
│   └── Yes ↓
│
├── Must it run on-device / offline?
│   ├── Yes → Self-host an open weight model (must fit hardware)
│   └── No  ↓
│
├── Need logprobs, full finetuning, or output guardrail customization?
│   ├── Yes → Self-host open weight (or pick an API that exposes these)
│   └── No  ↓
│
├── Is current/projected API cost > expected engineering cost?
│   ├── Yes → Consider self-hosting; revisit when scale stabilizes
│   └── No  ↓
│
├── Need top-tier capability (frontier reasoning, vision, tool use)?
│   ├── Yes → Commercial API (best models stay behind paywalls)
│   └── No  → Either; pick by total cost of ownership and team strengths
```

## Decision Tree: Open Weight vs Open Model

```
Need to retrain from scratch with modifications? ──→ Open model (data required)
Need to audit training data for compliance?       ──→ Open model
Need contractual IP protection?                   ──→ Commercial model with indemnification
Just need to run, finetune, or distill the model? ──→ Open weight is sufficient
```

## Build vs Buy: Side-by-Side

| Axis | API (Buy) | Self-host (Build) |
|------|-----------|-------------------|
| Data privacy | Data leaves your network | Data stays internal |
| Data lineage | Provider may indemnify | You're on the hook for training data IP |
| Best-case performance | Likely the strongest models | Best open lags closed by ~6-12 months |
| Function calling / structured output | Usually supported out of box | DIY or limited |
| Logprobs | Often hidden | Full access |
| Finetuning | Only what provider exposes | Any technique (PEFT, LoRA, full) |
| Cost shape | Per-token | Engineering + GPU |
| Versioning | Provider can change silently | You freeze whatever version you want |
| Edge deployment | Impossible | Possible (with effort) |
| Rate limits | Subject to provider | Your infra, your limits |

## Pitfall: Trusting the Leaderboard Average

```python
# BAD: Pick model with highest HF Open LLM average
candidates = ["model-A", "model-B", "model-C"]
scores = {
    "model-A": {"MMLU": 0.85, "GSM8K": 0.70, "TruthfulQA": 0.45},
    "model-B": {"MMLU": 0.78, "GSM8K": 0.85, "TruthfulQA": 0.60},
    "model-C": {"MMLU": 0.80, "GSM8K": 0.75, "TruthfulQA": 0.80},
}
chosen = max(candidates, key=lambda m: sum(scores[m].values()) / 3)
# Result: model-A "wins" — but if your app is a fact-checking assistant,
# truthfulness matters far more than reasoning. model-C is the right answer.
```

```python
# GOOD: Weight benchmarks by relevance to your application
WEIGHTS = {"MMLU": 0.2, "GSM8K": 0.1, "TruthfulQA": 0.7}  # fact-checking app

def weighted_score(model_scores):
    return sum(model_scores[bench] * WEIGHTS[bench] for bench in WEIGHTS)

chosen = max(candidates, key=lambda m: weighted_score(scores[m]))
# Now model-C wins, matching the application's needs.
```

**Why it matters**: Plain averaging treats an 80% on TruthfulQA the same as 80% on GSM-8K, which is rarely what you want.

## Pitfall: Correlated Benchmarks

The HF leaderboard had MMLU, WinoGrande, and ARC-C all measuring reasoning (Pearson r > 0.85). Including all three triple-counted reasoning capability and underweighted truthfulness, math, and commonsense.

**Fix**: Drop one of each highly correlated pair, or apply weights that compensate:

```python
import numpy as np

# Compute correlations from your benchmark data
correlation_matrix = np.array([
    # ARC-C HellaSwag MMLU TruthQA WinoG GSM8K
    [1.00, 0.48, 0.87, 0.48, 0.89, 0.74],
    [0.48, 1.00, 0.61, 0.42, 0.48, 0.35],
    [0.87, 0.61, 1.00, 0.55, 0.90, 0.79],
    [0.48, 0.42, 0.55, 1.00, 0.45, 0.50],
    [0.89, 0.48, 0.90, 0.45, 1.00, 0.80],
    [0.74, 0.35, 0.79, 0.50, 0.80, 1.00],
])

# Drop benchmarks where every correlation > 0.85 with another already-kept one
threshold = 0.85
keep = [0]  # always keep first
for i in range(1, len(correlation_matrix)):
    if all(correlation_matrix[i][j] < threshold for j in keep):
        keep.append(i)
# Result: ARC-C, HellaSwag, TruthfulQA, GSM8K — drops MMLU and WinoGrande
```

## Pitfall: Contamination Inflates Scores

A model scoring 95% on MMLU may have memorized 40% of MMLU during pretraining (as OpenAI found with GPT-3 on 13 benchmarks). The "real" capability score on the clean subset can be substantially lower.

```python
# Simple n-gram overlap detection (13-token rule)
def is_dirty(eval_sample: str, training_corpus_ngrams: set, n: int = 13) -> bool:
    tokens = eval_sample.split()
    for i in range(len(tokens) - n + 1):
        ngram = tuple(tokens[i:i + n])
        if ngram in training_corpus_ngrams:
            return True
    return False

# Report both numbers
clean_samples = [s for s in eval_set if not is_dirty(s, train_ngrams)]
print(f"Full benchmark: {evaluate(model, eval_set):.3f}")
print(f"Clean subset:   {evaluate(model, clean_samples):.3f}")
print(f"Contaminated:   {1 - len(clean_samples)/len(eval_set):.1%}")
```

## License Pitfall: Llama and Distillation

```python
# WARNING: This violates the Llama 3 Community License (as of writing)
# You CANNOT use Llama outputs to train another model.

teacher = load_model("meta-llama/Llama-3-70B")
synthetic_data = teacher.generate(prompts)        # OK to view
student = train_new_model(data=synthetic_data)    # NOT ALLOWED by license

# OK alternatives:
# - Use Mistral (license now allows output reuse)
# - Use Apache 2.0 models (Gemma, Mistral-7B)
# - Use a model whose license explicitly permits distillation
```

**Always verify the current license — terms change.** Mistral originally banned output reuse and later permitted it.

## License Pitfall: MAU Threshold

```python
# Llama 2/3 require a special license from Meta if your application has
# more than 700M monthly active users.

# This decision is upstream of model selection:
projected_mau = forecast_mau(years=2)
if projected_mau > 700_000_000 and not has_meta_license():
    candidates.remove("llama")  # filter at the hard-attribute step
```

## Workflow Walkthrough

### Step 1: Filter (Hard Attributes)

```python
all_models = ["gpt-4o", "claude-3-7", "llama-3-70b", "mistral-large", "gemma-2-27b"]

constraints = {
    "data_can_leave_network": False,        # privacy: must self-host
    "needs_commercial_use": True,
    "projected_mau": 1_200_000_000,         # > 700M
}

def passes_filter(model):
    if not constraints["data_can_leave_network"] and is_api_only(model):
        return False
    if model.startswith("llama") and constraints["projected_mau"] > 700_000_000:
        return False
    return True

shortlist = [m for m in all_models if passes_filter(m)]
# Result: ["mistral-large", "gemma-2-27b"]  (open weight + license-clean)
```

### Step 2: Public Benchmarks (Shortlist Further)

Pick benchmarks that match your task (e.g., HumanEval/MBPP for code, GSM8K/MATH for math, IFEval for instruction following). Drop models with poor relevant scores.

### Step 3: Private Evaluation

Run your own evaluation pipeline (see `evaluation-pipeline/`) on the remaining 2-3 candidates with your data, your metrics, your prompts.

### Step 4: Monitor

Once deployed, log latency, errors, user feedback. Re-run step 3 quarterly or when major releases land.
