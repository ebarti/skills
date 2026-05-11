# Data Processing Rules

Guidelines for inspecting, deduplicating, cleaning, filtering, and formatting datasets before training or finetuning.

## Core Rules

### 1. Never Modify Data In Place

Always keep a copy of the original raw data.

- Other teams or applications may need to process it differently
- Bugs in your processing scripts can corrupt data irreversibly
- Write outputs to a new path; version each processing stage

### 2. Trial Run Before Full Run

Validate processing scripts on a small sample before applying to the full dataset.

- Sample 100-1000 examples first
- Inspect output manually
- Check edge cases (empty fields, unusual encodings, very long inputs)

### 3. Order Steps By Compute Cost

Run cheaper-per-example steps first when they reduce volume for downstream steps.

- If cleaning is expensive per example, deduplicate first
- If dedup is more expensive than filtering, filter low-quality first
- Measure on a sample before deciding

### 4. Inspect Manually Before Automating

Spend at least 15 minutes looking at raw examples before writing any processing code.

- Stare at random samples
- Try annotating a few yourself and compare to existing labels
- Look for examples with same query but different responses (and vice versa)
- Plot distributions per source, time, and annotator

### 5. Deduplicate at the Right Granularity

Choose the duplication scope that matches your training objective.

- Document level for whole-doc training
- Paragraph or sentence level for finer-grained tasks
- Decide a similarity threshold (exact / n-gram / 80% overlap / semantic)
- Cover all three scopes: whole-document, intra-document, cross-document

### 6. Use Hashing for Large-Scale Dedup

Pairwise comparison is O(n^2) and infeasible at scale.

- Use MinHash + LSH for near-duplicate text
- Use Bloom filters for exact-match membership
- Reduce dimensionality before pairwise comparison when needed

### 7. Strip Non-Compliant Content Aggressively

Remove anything not allowed by policy before training.

- PII (names, emails, phone numbers, addresses)
- Copyrighted material flagged by source
- Toxic / unsafe content
- Forbidden fields entirely (zip code, gender, etc.)

### 8. Match Inference Format Exactly

The prompt at inference must match the format used during training, character for character.

- Same delimiters (e.g., `-->`, `\n`)
- Same prefixes (e.g., `Item:`)
- Same trailing whitespace
- Same chat template tokens

## Guidelines

### Inspection

- Plot token, input length, and response length distributions
- Plot scores by annotator and check for normality if expected
- Compute inter-annotator disagreement and resolve conflicts
- Look at outliers and decide whether to drop or keep them
- Use creative statistics (e.g., verb-noun pair distributions)

### Deduplication

- Document the duplication definition you chose
- Remove the duplicates AFTER deciding the train/test split strategy
- Track how many examples were removed and why

### Cleaning

- Remove HTML/Markdown unless training a markup-aware model
- Heuristics for low quality: very short, very long, low entropy, suspicious annotator
- Watch for systematic noise like end-of-session annotator fatigue

### Filtering

- Use active learning when you can score example informativeness
- Use importance sampling when you can model the target distribution
- Justify keeping each example when over budget

### Formatting

- Verify the exact chat template on the model card before formatting
- Convert each few-shot exemplar into an individual training row
- Drop task descriptions from instructions when sufficient examples exist

## Exceptions

- **Reproducing baselines**: Match the original processing exactly, even if suboptimal.
- **Markup-aware training**: Keep HTML/Markdown if the downstream task needs them.
- **Audit retention**: Keep PII-bearing rows in a separate, secured pipeline if legally required for audit; never feed them to training.

## Quick Reference

| Rule | Summary |
|------|---------|
| Don't modify in place | Always write to new paths and version stages |
| Trial run first | Validate on samples before full dataset |
| Order by cost | Cheap and volume-reducing steps first |
| Inspect manually | 15 minutes of looking saves hours of debugging |
| Right granularity | Match dedup scope to training objective |
| Use hashing | MinHash/Bloom for large-scale dedup |
| Strip non-compliant | Remove PII, copyrighted, toxic, forbidden fields |
| Match inference format | Train and inference prompts must align exactly |
