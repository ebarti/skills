# Data Processing Checklist

Use this checklist before training or finetuning on any dataset.

## Before You Start

- [ ] Original raw data is preserved at a separate, immutable path
- [ ] Processing pipeline writes to versioned output directories (no in-place edits)
- [ ] Trial run validated on a 100-1000 example sample
- [ ] Compute cost of each step measured on the sample to decide order

## Inspection

- [ ] Plotted distributions of token counts, input length, output length
- [ ] Plotted topic and language distributions and confirmed relevance to task
- [ ] Spent at least 15 minutes manually reading random samples
- [ ] Tried annotating a few examples yourself and compared to existing labels
- [ ] Plotted scores per annotator and checked for bias/normality
- [ ] Computed inter-annotator disagreement and resolved conflicts
- [ ] Identified outliers and decided to drop, fix, or keep each
- [ ] Checked for examples with same query / different response (and vice versa)

## Deduplication

- [ ] Chose duplication granularity (document, paragraph, sentence, token)
- [ ] Chose match definition (exact, n-gram, semantic, % overlap threshold)
- [ ] Handled all three scopes: whole-document, intra-document, cross-document
- [ ] Used hashing (MinHash, Bloom) for large-scale dedup, not pairwise
- [ ] Deduplicated BEFORE train/test split to avoid contamination
- [ ] Logged number of duplicates removed and a sample of removed pairs

## Cleaning

- [ ] Removed HTML and Markdown noise (unless markup-aware task)
- [ ] Stripped or redacted PII (emails, phones, SSNs, addresses, names)
- [ ] Dropped forbidden fields entirely (zip code, gender, etc.)
- [ ] Removed copyrighted or toxic content per policy
- [ ] Applied low-quality heuristics (length, repetition, fatigue patterns)
- [ ] Verified annotator-fatigue patterns (late-session quality drop)

## Filtering

- [ ] Confirmed dataset size fits compute budget
- [ ] Applied active learning or importance sampling if over budget
- [ ] Documented why each filter exists and how many examples it removed

## Formatting

- [ ] Confirmed target model's exact chat template from its model card
- [ ] Converted any prior few-shot exemplars into individual training rows
- [ ] Removed task descriptions from instructions if examples are sufficient
- [ ] Tokenizer matches the target model
- [ ] Verified inference prompt matches training format character-for-character
- [ ] No extra prefixes, missing delimiters, or trailing whitespace

## After Processing

- [ ] Final dataset checksum recorded
- [ ] Manifest documents source, dedup choices, cleaning rules, format version
- [ ] A sample of final examples was reviewed end-to-end
- [ ] Train/val/test splits made AFTER dedup and cleaning

## Red Flags

Stop and address if you find:

- Test examples that match training examples (test contamination)
- PII present in formatted output
- Output rows where input or output is empty
- Inference prompt format does not match training format
- Same model exposed to >0.1% repeated examples
- Single annotator dominates the dataset or shows clear bias

## Quick Reference

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| Manual inspection | Hours of staring | 15+ minutes | Zero |
| Dedup scope | All three (doc/intra/cross) | Document only | None |
| Repeated examples | <0.01% | <0.1% | >0.1% |
| PII residue | Zero detections | Tagged & redacted | Present in plain text |
| Inference/training format match | Identical | Trivial whitespace diff | Different prefix/delimiter |
| Raw data backup | Versioned & immutable | Single backup | Modified in place |
