# AI Evaluation Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use**: Find your situation below, then load ONLY the listed files.

---

## By Task

### Setting Up Evaluation for an AI System

| What you're doing | Load these files |
|-------------------|------------------|
| Designing a full eval pipeline from scratch | `references/evaluation-pipeline/rules.md`, `references/evaluation-pipeline/patterns.md`, `references/evaluation-pipeline/checklist.md` |
| Defining evaluation criteria | `references/evaluation-criteria/rules.md`, `references/evaluation-criteria/checklist.md` |
| Writing scoring rubrics | `references/evaluation-pipeline/examples.md` |
| Tying eval to business metrics | `references/evaluation-pipeline/rules.md`, `references/evaluation-pipeline/examples.md` |

### Choosing Evaluation Methods

| What you're doing | Load these files |
|-------------------|------------------|
| Picking an evaluation method by task type | `references/exact-evaluation/patterns.md` |
| Using perplexity / BPB / cross-entropy | `references/language-modeling-metrics/rules.md`, `references/language-modeling-metrics/examples.md` |
| Setting up exact match / similarity | `references/exact-evaluation/rules.md`, `references/exact-evaluation/examples.md` |
| Setting up AI-as-judge | `references/ai-as-judge/rules.md`, `references/ai-as-judge/examples.md` |
| Comparative evaluation (Bradley-Terry, Elo) | `references/comparative-evaluation/rules.md`, `references/comparative-evaluation/examples.md` |

### Selecting a Model

| What you're doing | Load these files |
|-------------------|------------------|
| Build vs buy decision | `references/model-selection/rules.md`, `references/model-selection/examples.md` |
| Open source vs API tradeoffs | `references/model-selection/rules.md`, `references/model-selection/checklist.md` |
| Evaluating against benchmarks | `references/model-selection/rules.md`, `references/model-selection/examples.md` |
| Detecting data contamination | `references/model-selection/rules.md`, `references/model-selection/examples.md` |
| Final selection checklist | `references/model-selection/checklist.md` |

### Evaluating Specific Capabilities

| What you're doing | Load these files |
|-------------------|------------------|
| Domain-specific capability eval | `references/evaluation-criteria/rules.md`, `references/evaluation-criteria/examples.md` |
| Factual consistency eval | `references/evaluation-criteria/rules.md`, `references/evaluation-criteria/examples.md` |
| Safety eval | `references/evaluation-criteria/rules.md`, `references/evaluation-criteria/examples.md` |
| Instruction-following eval | `references/evaluation-criteria/rules.md`, `references/evaluation-criteria/examples.md` |
| Cost/latency eval | `references/evaluation-criteria/rules.md` |

---

## By Symptom/Problem

| If you notice... | Load these files |
|------------------|------------------|
| Eval scores don't match production quality | `references/evaluation-pipeline/rules.md`, `references/evaluation-pipeline/patterns.md` |
| AI judge results vary run-to-run | `references/ai-as-judge/rules.md`, `references/ai-as-judge/smells.md` |
| Public benchmark scores look suspiciously high | `references/model-selection/rules.md` (contamination) |
| BLEU/ROUGE scores high but output bad | `references/exact-evaluation/rules.md` |
| Model passes eval but fails on edge cases | `references/evaluation-pipeline/rules.md` (slicing, multiple eval sets) |
| AI judge biased toward longer outputs | `references/ai-as-judge/smells.md` |

---

## By Topic (Direct Index)

### Language Modeling Metrics
- `references/language-modeling-metrics/knowledge.md` — Entropy, cross-entropy, perplexity, BPB
- `references/language-modeling-metrics/rules.md` — When to use perplexity, interpretation rules
- `references/language-modeling-metrics/examples.md` — Numerical examples, GPT-2 reference table

### Exact Evaluation
- `references/exact-evaluation/knowledge.md` — Functional correctness, similarity, embeddings
- `references/exact-evaluation/rules.md` — Method selection rules
- `references/exact-evaluation/examples.md` — Code: pass@k, BLEU, ROUGE, cosine similarity
- `references/exact-evaluation/patterns.md` — Method selection by task type

### AI as Judge
- `references/ai-as-judge/knowledge.md` — Judge as system, eval modes
- `references/ai-as-judge/rules.md` — Pin model+prompt+params, prefer classification
- `references/ai-as-judge/examples.md` — Good/bad judge prompts, bias examples
- `references/ai-as-judge/smells.md` — 8 anti-patterns

### Comparative Evaluation
- `references/comparative-evaluation/knowledge.md` — Pairwise, Bradley-Terry, Elo
- `references/comparative-evaluation/rules.md` — When comparative is appropriate
- `references/comparative-evaluation/examples.md` — Implementation examples

### Evaluation Criteria
- `references/evaluation-criteria/knowledge.md` — Domain, generation, instruction, cost criteria
- `references/evaluation-criteria/rules.md` — How to evaluate each
- `references/evaluation-criteria/examples.md` — Code: factuality, safety, instruction-following
- `references/evaluation-criteria/checklist.md` — Pre-deployment checklist

### Model Selection
- `references/model-selection/knowledge.md` — Hard/soft attributes, OS vs API, benchmarks, contamination
- `references/model-selection/rules.md` — 8 selection rules, license considerations
- `references/model-selection/examples.md` — Decision trees, pitfalls
- `references/model-selection/checklist.md` — Workflow checklist

### Evaluation Pipeline
- `references/evaluation-pipeline/knowledge.md` — Component vs e2e eval, rubrics, business mapping
- `references/evaluation-pipeline/rules.md` — 18 rules across 3 steps
- `references/evaluation-pipeline/examples.md` — Rubrics, decomposition, business mapping
- `references/evaluation-pipeline/patterns.md` — 6 reusable patterns
- `references/evaluation-pipeline/checklist.md` — End-to-end audit checklist

---

## Decision Tree

```
What are you doing?
│
├─► Setting up evaluation for a new system
│   ├─► Define criteria → evaluation-criteria/rules.md
│   ├─► Design pipeline → evaluation-pipeline/rules.md + patterns.md
│   └─► Pre-deployment check → evaluation-criteria/checklist.md
│
├─► Picking a model
│   ├─► Workflow → model-selection/rules.md + checklist.md
│   ├─► Build vs buy → model-selection/examples.md
│   └─► Benchmark trust → model-selection/rules.md
│
├─► Computing scores
│   ├─► Code/SQL/math (functional) → exact-evaluation/rules.md
│   ├─► Open-ended text → ai-as-judge/rules.md
│   ├─► Comparing models → comparative-evaluation/rules.md
│   └─► Base model quality → language-modeling-metrics/rules.md
│
└─► Diagnosing eval problems
    ├─► Judge inconsistency → ai-as-judge/smells.md
    └─► Eval-prod mismatch → evaluation-pipeline/rules.md
```

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| New AI system, end-to-end eval | `evaluation-criteria/rules.md` + `evaluation-pipeline/rules.md` + `evaluation-pipeline/patterns.md` |
| Setting up AI judge | `ai-as-judge/rules.md` + `ai-as-judge/examples.md` + `ai-as-judge/smells.md` |
| Picking between Claude/GPT/Llama | `model-selection/rules.md` + `model-selection/checklist.md` |
| Evaluating a code-gen system | `exact-evaluation/rules.md` + `evaluation-criteria/rules.md` |
| Evaluating a chatbot | `evaluation-criteria/rules.md` + `ai-as-judge/rules.md` |
