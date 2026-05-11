# Data Processing Knowledge

Core concepts and foundational understanding for processing datasets before training or finetuning AI models.

## Overview

Data processing transforms a raw dataset into one ready for training. The four main steps are inspection, deduplication, cleaning/filtering, and formatting. Each can take hours or days on large datasets, so order them to minimize total compute time and always preserve a copy of the original data.

## Key Concepts

### Inspect Data

**Definition**: The act of getting to know your dataset through statistics, distributions, and manual inspection.

You compute distributions (tokens, input lengths, response lengths, topics, languages), plot them by source/time/annotator, and stare at the data manually. The goal is to understand quality, spot outliers, identify biases per annotator, and verify that examples make sense.

**Key points**:
- Manual inspection has the highest value-to-prestige ratio in ML (Greg Brockman)
- 15 minutes of staring at data often saves hours of headaches
- Compute inter-annotator disagreement when multiple annotations exist
- Analyze creative statistics: e.g., (verb, direct object, noun) pair distribution

### Deduplicate Data

**Definition**: Removing repeated examples that would otherwise skew distribution, bias the model, or contaminate test splits.

Duplications cause the model to overweight repeated patterns, can leak training data into the test set during splitting, and waste compute. Anthropic showed that repeating 0.1% of data 100 times can degrade an 800M model to 400M-equivalent performance.

**Key points**:
- Three duplication scopes: whole-document, intra-document, cross-document
- Granularity matters: document, paragraph, sentence, or token level
- Match definition matters: exact, n-gram overlap, fuzzy (e.g., 80% overlap), semantic
- Same techniques as similarity measurement and identity resolution

### Clean and Filter Data

**Definition**: Removing extraneous tokens, non-compliant content, and low-quality examples to make models performant and safe.

Cleaning removes HTML/Markdown noise from scraped data, strips PII and copyrighted/toxic content, and drops low-quality examples. Filtering further reduces the dataset to fit compute budgets, often by selecting the most informative examples.

**Key points**:
- Removing extraneous Markdown/HTML can improve accuracy by 20% and cut tokens by 60% (Databricks)
- Strip disallowed fields (zip code, name, gender) per policy
- Annotator boredom degrades quality in the second half of sessions (Kern et al., 2024)
- Use active learning or importance sampling to keep only the most useful examples

### Format Data

**Definition**: Converting cleaned data into the exact tokenizer and chat template the target model expects.

Each model has a specific tokenizer and chat template. Wrong formatting causes strange bugs. For supervised finetuning, data is usually `(instruction, response)` where instructions decompose into `(system_prompt, user_prompt)`. Finetuning instructions can omit task descriptions and few-shot examples that prompts need.

**Key points**:
- Few-shot prompt examples become individual training rows
- Inference prompts must match training format exactly (delimiters, spacing, prefixes)
- Wrong chat template causes silent quality regressions

## Terminology

| Term | Definition |
|------|------------|
| Pairwise comparison | Compute similarity for every example pair; expensive on large data |
| MinHash | Hash-based technique for fast near-duplicate detection |
| Bloom filter | Probabilistic membership data structure for dedup buckets |
| n-gram match | Overlap measured by shared n-token sequences |
| Active learning | Select examples whose labels would most help the model |
| Importance sampling | Pick examples most relevant to the target task distribution |
| Chat template | Model-specific structure wrapping system/user/assistant turns |
| Inter-annotator agreement | Consistency across human labelers on the same examples |

## How It Relates To

- **Data Curation**: Processing is what you do after curating the raw collection.
- **Evaluation Methodology (Ch. 3)**: Same similarity techniques drive deduplication.
- **Prompt Engineering (Ch. 5)**: Chat templates from prompting carry over to formatting.
- **AI Safety (Ch. 4)**: PII/toxicity detection techniques are reused in cleaning.

## Common Misconceptions

- **Myth**: Deduplication is optional if you have lots of data.
  **Reality**: Even small fractions of duplicates can sharply degrade model quality.

- **Myth**: You only need to remove exact duplicates.
  **Reality**: Near-duplicates (paragraphs, popular quotes, reordered lists) also hurt.

- **Myth**: Tools replace manual inspection.
  **Reality**: Manual review surfaces patterns no exploration tool finds automatically.

- **Myth**: Order of processing steps doesn't matter.
  **Reality**: Order should minimize compute (e.g., dedup first if cleaning is per-example expensive).

- **Myth**: Finetuning prompts should look like the few-shot prompts you used before.
  **Reality**: Finetuning examples typically drop task descriptions and exemplars.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Inspect | Plot distributions and stare at the data manually |
| Deduplicate | Remove repeats that bias or contaminate splits |
| Clean | Strip noise, PII, low-quality content |
| Filter | Subset to highest-value examples within budget |
| Format | Match the model's exact tokenizer and chat template |
