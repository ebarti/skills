# AI Dataset Engineering Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use**: Find your situation below, then load ONLY the listed files.

---

## By Task

### Curating Training/Eval Data

| What you're doing | Load these files |
|-------------------|------------------|
| Assessing dataset quality | `references/data-curation/rules.md`, `references/data-curation/checklist.md` |
| Ensuring sufficient coverage | `references/data-curation/rules.md`, `references/data-curation/examples.md` |
| Estimating how much data is needed | `references/data-curation/rules.md`, `references/data-curation/examples.md` |
| Acquiring data ethically/legally | `references/data-curation/rules.md`, `references/data-curation/examples.md` |
| Setting up data annotation | `references/data-curation/rules.md`, `references/data-curation/examples.md` |
| Pre-training dataset audit | `references/data-curation/checklist.md` |

### Synthesizing Data

| What you're doing | Load these files |
|-------------------|------------------|
| Deciding if/when to synthesize | `references/data-synthesis/rules.md` |
| Rule-based synthesis | `references/data-synthesis/rules.md`, `references/data-synthesis/examples.md` |
| AI-powered synthesis (Self-Instruct, Evol-Instruct) | `references/data-synthesis/rules.md`, `references/data-synthesis/examples.md` |
| Verifying synthetic data quality | `references/data-synthesis/rules.md`, `references/data-synthesis/examples.md` |
| Distilling a smaller model | `references/data-synthesis/rules.md`, `references/data-synthesis/examples.md` |
| Choosing a synthesis pattern | `references/data-synthesis/patterns.md` |

### Processing Data

| What you're doing | Load these files |
|-------------------|------------------|
| Inspecting a dataset | `references/data-processing/rules.md`, `references/data-processing/examples.md` |
| Deduplicating (exact / near-duplicate) | `references/data-processing/rules.md`, `references/data-processing/examples.md` |
| Cleaning HTML/Markdown/PII | `references/data-processing/rules.md`, `references/data-processing/examples.md` |
| Filtering low-quality records | `references/data-processing/rules.md`, `references/data-processing/examples.md` |
| Formatting for training | `references/data-processing/rules.md`, `references/data-processing/examples.md` |
| End-to-end processing pipeline | `references/data-processing/checklist.md` |

---

## By Symptom/Problem

| If you notice... | Load these files |
|------------------|------------------|
| Model performance plateaus despite more data | `references/data-curation/rules.md` (quality > quantity) |
| Synthetic data degrades model performance | `references/data-synthesis/rules.md` (model collapse, mix real+synthetic) |
| Eval data leaked into training data | `references/data-processing/rules.md` (dedup) |
| Dataset has duplicate examples | `references/data-processing/examples.md` (MinHash, hashing) |
| Inference prompts don't match training format | `references/data-processing/rules.md` (formatting), `references/data-processing/examples.md` |
| Annotators disagree | `references/data-curation/rules.md`, `references/data-processing/examples.md` |
| Too few labeled examples | `references/data-synthesis/rules.md` (synthesis), `references/data-curation/examples.md` (start with 50-100) |
| AI judge biased when filtering data | `references/data-synthesis/rules.md` (order swap) |

---

## By Topic (Direct Index)

### Data Curation
- `references/data-curation/knowledge.md` — Quality, coverage, quantity, acquisition
- `references/data-curation/rules.md` — 25 rules across all aspects
- `references/data-curation/examples.md` — Quality issues, Llama 3 mix table, scaling curve
- `references/data-curation/checklist.md` — Curation checklist

### Data Synthesis
- `references/data-synthesis/knowledge.md` — Augmentation vs synthesis, methods, limitations
- `references/data-synthesis/rules.md` — 8 synthesis rules
- `references/data-synthesis/examples.md` — Self-Instruct, Alpaca, distillation code
- `references/data-synthesis/patterns.md` — 6 reusable pipeline patterns

### Data Processing
- `references/data-processing/knowledge.md` — Inspect, dedup, clean, filter, format
- `references/data-processing/rules.md` — 8 rules
- `references/data-processing/examples.md` — MinHash, Bloom filter, PII redaction
- `references/data-processing/checklist.md` — Processing checklist

---

## Decision Tree

```
What are you doing?
│
├─► Building a new dataset
│   ├─► Plan & curate → data-curation/rules.md + checklist.md
│   ├─► Acquire data → data-curation/rules.md
│   └─► Annotate → data-curation/examples.md
│
├─► Need more data
│   ├─► Synthesize → data-synthesis/rules.md + patterns.md
│   ├─► Augment existing → data-synthesis/examples.md
│   └─► Distill from larger model → data-synthesis/examples.md
│
└─► Have raw data, need to process
    ├─► Inspect/dedup/clean → data-processing/rules.md
    ├─► Format for training → data-processing/examples.md
    └─► Pipeline check → data-processing/checklist.md
```

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| Building first instruction dataset | `data-curation/rules.md` + `data-synthesis/rules.md` + `data-processing/rules.md` |
| Setting up annotation pipeline | `data-curation/rules.md` + `data-curation/examples.md` |
| Distilling Llama into a smaller model | `data-synthesis/examples.md` + `data-synthesis/patterns.md` (distillation) |
| Pre-training data preparation | `data-processing/rules.md` + `data-processing/checklist.md` |
| Building a benchmark from scratch | `data-curation/rules.md` + `data-processing/rules.md` |
