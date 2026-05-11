# Training Data Rules

Guidelines for choosing, evaluating, and curating training data when selecting or building foundation models.

## Core Rules

### 1. Match Training Data to Target Use Case

A model can only perform tasks that are represented in its training data. Before adopting a model, verify its training data covers your domain, language, and modality.

- Check published training data composition where available
- Run benchmarks in your target language and domain before committing
- Treat absent coverage as a hard limit, not a soft one

### 2. Prefer Quality Over Volume

A smaller model trained on focused, high-quality data often beats a larger model trained on noisy data.

- Do not assume "more tokens" implies "better model"
- Filter heuristics (e.g., upvote thresholds) help but do not replace curation
- For specialized tasks, a curated dataset of millions of tokens can outperform billions of low-quality tokens

### 3. Use Language-Specific Models for Low-Resource Languages

For languages with under ~1% representation in Common Crawl (e.g., Punjabi, Bengali, Urdu, Swahili, Telugu, Marathi), a general-purpose model will typically underperform.

- Choose a dedicated model for the language when one exists (ChatGLM, PhoGPT, Jais, CroissantLLM, etc.)
- If none exists, consider fine-tuning a general model on language-specific data
- Do not rely on translate-to-English-and-back as a default strategy

### 4. Use Domain-Specific Models for Specialized Tasks

If your task requires data that is rare or absent from the public internet (proteins, DNA, medical imaging, factory plans, architectural sketches), a general-purpose model will not perform well no matter how large.

- Look for an existing domain model (AlphaFold, BioNeMo, Med-PaLM2) before building
- Fine-tune a general base if domain data is moderate; train from scratch if data is abundant and divergent
- Privacy and licensing constraints often determine whether domain data is even obtainable

### 5. Account for Tokenization Cost in Non-English Languages

API cost and latency are proportional to token count. The same content can require 3-10x more tokens in under-represented languages than in English.

- Budget cost forecasts using token counts measured in the target language, not English equivalents
- For latency-sensitive applications in Burmese, Hindi, etc., test end-to-end timing in production conditions
- Consider whether a language-specific model with a better tokenizer is worth the switch

### 6. Test Safety and Alignment Per Language

A model's refusal behavior, factuality, and willingness to produce misinformation can differ across languages even with identical prompts.

- Re-run safety evaluations in every production language, not just English
- Do not assume English-evaluated guardrails transfer

## Guidelines

- Prefer existing curated open datasets over raw Common Crawl when available
- Document the training data sources for any model you ship, even at a high level, to support debugging
- When users complain about quality, check whether their use case sits in a known under-represented region of the data distribution
- For multimodal models, remember that domain coverage analysis is harder than for text and benchmark-driven inference may be your only signal

## Exceptions

When these rules may be relaxed:

- **Prototype / exploratory work**: A general-purpose model is acceptable for early validation even in under-served languages or domains; switch before scaling
- **Tasks dominated by reasoning, not knowledge**: If the task is primarily logical manipulation of inputs the user provides, weaker training data coverage matters less
- **Translation as a workaround**: Acceptable when (a) the source language is well enough supported for translation quality and (b) information loss in translation does not affect the task

## Quick Reference

| Rule | Summary |
|------|---------|
| Match data to use case | Capability is bounded by training data coverage |
| Quality over volume | Curated small data beats noisy large data |
| Language-specific models | Use for low-resource languages |
| Domain-specific models | Use when data is absent from public internet |
| Tokenization cost | Budget for 3-10x token inflation in some languages |
| Per-language safety | Re-evaluate alignment in every shipped language |

## Decision Matrix

| Task Profile | Recommended Approach |
|--------------|---------------------|
| English, common domain | General-purpose model |
| Low-resource language | Language-specific model or fine-tune |
| Specialized scientific data | Domain-specific model |
| Niche industry, no model exists | Fine-tune general base on curated data |
| Multilingual production app | Per-language evaluation + tokenization budget review |
