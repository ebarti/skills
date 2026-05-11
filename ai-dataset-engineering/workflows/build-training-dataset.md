# Build Training Dataset Workflow

Curate, synthesize, and process a dataset for finetuning or evaluation.

## When to Use

- Building a new dataset for finetuning
- Building an eval set for a new task
- Improving an existing dataset that's degrading model performance

## Prerequisites

- Defined task and target output format
- Some seed data (real examples, even if just a handful)
- Tools for annotation if doing it (annotators, AI judges, scripts)

**Reference**: `references/data-curation/rules.md`

---

## Workflow Steps

### Step 1: Define Quality and Coverage Targets

**Goal**: Know what "good" looks like before you build.

- [ ] Define the 6 quality characteristics for your task: relevant, aligned, consistent, formatted, unique, compliant
- [ ] Define coverage: what task types, languages, domains, edge cases?
- [ ] Define quantity target: start with 50-100 examples, plot scaling curve
- [ ] Apply heuristic: **1K curated > 100K noisy** (LIMA, Yi findings)

**Reference**: `references/data-curation/rules.md`, `references/data-curation/examples.md`

---

### Step 2: Acquire Seed Data

**Goal**: Get real examples to anchor the dataset.

- [ ] Source from: production logs (with consent), open datasets, partner data, manual creation
- [ ] Verify license / terms of use for each source
- [ ] Strip PII before using
- [ ] Verify provenance (where each example came from)

**Reference**: `references/data-curation/rules.md`

---

### Step 3: Decide on Synthesis Strategy

**Goal**: Decide whether to augment with synthetic data.

| Need | Method |
|------|--------|
| More volume | AI-powered synthesis (Self-Instruct, Evol-Instruct) |
| More diversity | Topic expansion (UltraChat) |
| More coverage of edge cases | Targeted rule-based generation |
| Privacy | Synthetic generation from schema |
| Distillation | Generate from larger teacher model |

- [ ] Pick a synthesis method (or none)
- [ ] **Mandatory**: verify synthetic data quality before mixing in
- [ ] Mix real + synthetic to avoid model collapse (Shumailov et al.)
- [ ] If distilling: verify license allows it (Llama 700M MAU, output reuse clauses)

**Reference**: `references/data-synthesis/rules.md`, `references/data-synthesis/patterns.md`

---

### Step 4: Annotate

**Goal**: Add labels (if supervised).

- [ ] Write detailed annotation guidelines (= eval guidelines)
- [ ] Train annotators on a sample, measure inter-annotator agreement
- [ ] Re-train guidelines if disagreement is high
- [ ] If using AI judge for annotation: order-swap to avoid position bias (NVIDIA approach)

**Reference**: `references/data-curation/rules.md`, `references/data-curation/examples.md`

---

### Step 5: Inspect

**Goal**: Look at your data manually.

- [ ] Sample 50-100 random examples and read them
- [ ] Check distribution stats (length, label balance, language)
- [ ] Look for obvious junk, near-duplicates, contamination
- [ ] Document what you find

**Reference**: `references/data-processing/rules.md`, `references/data-processing/examples.md`

---

### Step 6: Deduplicate

**Goal**: Remove duplicates that bias the model.

- [ ] Choose granularity: whole-document, intra-document, cross-document
- [ ] At small scale: exact-match hashing
- [ ] At large scale: MinHash + LSH at 0.8 Jaccard for near-duplicates
- [ ] Streaming: Bloom filter for memory efficiency
- [ ] Anthropic finding: 0.1% repeats × 100 can degrade an 800M model to 400M-equivalent

**Reference**: `references/data-processing/rules.md`, `references/data-processing/examples.md`

---

### Step 7: Clean and Filter

**Goal**: Strip junk and low-quality records.

- [ ] Strip HTML/Markdown tags (Databricks: 20% accuracy gain)
- [ ] Redact PII
- [ ] Filter out non-compliant content (terms of use violations)
- [ ] Filter out low-quality records (length < threshold, language mismatch, etc.)
- [ ] Order steps by compute cost (cheap filters first)

**Reference**: `references/data-processing/rules.md`

---

### Step 8: Format

**Goal**: Match training/inference format exactly.

- [ ] Apply the target model's chat template
- [ ] Verify delimiters, special tokens, end-of-turn markers
- [ ] Spot-check 10 formatted examples manually
- [ ] Confirm format matches inference-time format (no trailing spaces, no missing prefixes)

**Reference**: `references/data-processing/examples.md`

---

### Step 9: Split and Validate

**Goal**: Hold out eval data; validate quality.

- [ ] Split: train / val / test (typical 80/10/10 or by date)
- [ ] Verify no leakage: dedup train against test
- [ ] Run final processing checklist

**Reference**: `references/data-processing/checklist.md`

---

## Quick Checklist

```
[ ] Step 1: Quality + coverage + quantity targets defined
[ ] Step 2: Seed data acquired (with provenance)
[ ] Step 3: Synthesis strategy decided
[ ] Step 4: Annotated (with guidelines + agreement measured)
[ ] Step 5: Inspected manually
[ ] Step 6: Deduplicated
[ ] Step 7: Cleaned and filtered
[ ] Step 8: Formatted to match inference
[ ] Step 9: Split, validated, no leakage
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Bigger dataset = better | Quality > quantity (1K > 100K noisy) | Start small, scale on a curve |
| All synthetic, no real | Model collapse | Mix real + synthetic |
| No dedup | Memorization, biased model | MinHash + LSH at 0.8 |
| Inference format ≠ training format | Gibberish at inference | Validate end-to-end |
| Skipping manual inspection | Junk data slips through | Read 50-100 samples |

---

## Exit Criteria

- [ ] Dataset meets quality, coverage, quantity targets
- [ ] No duplicates; no PII; license-clean
- [ ] Format validated end-to-end against inference path
- [ ] Train/val/test splits with no leakage
- [ ] Documentation of provenance and processing
