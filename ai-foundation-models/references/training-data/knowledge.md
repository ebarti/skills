# Training Data Knowledge

Core concepts about training data for foundation models, including multilingual and domain-specific training.

## Overview

A foundation model's capabilities and limitations are primarily determined by its training data: a model cannot perform a task it never saw examples of during training. Model developers face trade-offs between using available large-scale data (often low-quality) and curating focused datasets for specific languages or domains.

## Key Concepts

### Training Data

**Definition**: The corpus of text, images, or other inputs used to teach a foundation model patterns and capabilities during pre-training.

A model's performance on any given task is bounded by the presence and quality of related examples in its training data. If Vietnamese is absent from the training corpus, the model cannot translate to Vietnamese. If only animals appear in an image classifier's training set, plant photos will fail.

**Key points**:
- Data availability often dictates training data choices, not data ideality
- Quality matters more than raw volume for many tasks
- Distribution of data across languages, domains, and topics shapes downstream behavior

### Common Crawl

**Definition**: A nonprofit-maintained corpus of approximately 2-3 billion web pages crawled monthly from the public internet.

The dominant source of pre-training data for most disclosed foundation models (e.g., GPT-3, Gemini). Quality is uneven and includes misinformation, clickbait, and offensive content.

**Key points**:
- C4 (Colossal Clean Crawled Corpus) is Google's filtered subset
- Heuristic filters (e.g., minimum upvotes on Reddit links) help but do not guarantee quality
- Likely used by undisclosed models as well

### Multilingual Models

**Definition**: Foundation models trained with intentional support for multiple languages, often emphasizing non-English data to compensate for English's dominance in web corpora.

English makes up ~46% of Common Crawl despite representing ~18% of world population. Many widely-spoken languages (Punjabi, Bengali, Urdu, Swahili) are severely under-represented, leading to poorer model performance in those languages.

**Key points**:
- Low-resource languages: typically those with under 1% representation in Common Crawl
- Under-representation causes accuracy gaps, but language structure and cultural context also contribute
- Examples: ChatGLM, Llama-Chinese (Chinese); CroissantLLM (French); PhoGPT (Vietnamese); Jais (Arabic)

### Domain-Specific Models

**Definition**: Foundation models trained or fine-tuned on data from a narrow field (medicine, biology, law, engineering) to outperform general-purpose models on specialized tasks.

General-purpose models cover many domains broadly but fail on specialized tasks involving data not present on the public internet (proteins, X-rays, fMRI scans, factory plans).

**Key points**:
- Common in biomedicine due to private/regulated data sources
- Examples: AlphaFold (protein structures), BioNeMo (drug discovery), Med-PaLM2 (medical Q&A)
- Can be trained from scratch or fine-tuned on top of a general-purpose base

### Tokenization Efficiency

**Definition**: How compactly a tokenizer encodes text in a given language, directly affecting inference latency and API cost.

Tokenizers trained primarily on English split non-English text into many more tokens. Median tokens to express the same content: English ~7, Hindi ~32, Burmese ~72.

**Key points**:
- Inference cost and latency scale roughly linearly with token count
- A non-English query can cost 10x more than its English equivalent
- Affects both API pricing and self-hosted throughput planning

## Terminology

| Term | Definition |
|------|------------|
| Foundation model (FM) | Large pre-trained model adaptable to many downstream tasks |
| Common Crawl | Web-scrape corpus used in most disclosed FM training data |
| C4 | Cleaned subset of Common Crawl maintained by Google |
| Low-resource language | Language with under ~1% representation in Common Crawl |
| Pre-training | Initial training on broad corpora to build general capability |
| Fine-tuning | Additional training on focused data, often atop a general model |
| Domain-specific model | Model trained for a narrow field with specialized data |

## How It Relates To

- **Model architecture**: Architecture determines capacity to absorb training data, but data sets the ceiling on what the model can learn
- **Post-training**: Pre-training on raw data produces capability; post-training aligns it for safe, useful interaction
- **Sampling**: Sampling strategy at inference shapes which trained behaviors surface, but cannot create knowledge missing from training data

## Common Misconceptions

- **Myth**: More training data always produces a better model.
  **Reality**: A smaller model trained on high-quality focused data can beat much larger models. A 1.3B-parameter model trained on 7B tokens of high-quality coding data outperformed much larger models on coding benchmarks.

- **Myth**: A general-purpose LLM can handle any language by translating to English internally.
  **Reality**: Translation requires sufficient understanding of the source language and causes information loss (e.g., Vietnamese pronouns encoding speaker relationships collapse to "I"/"you").

- **Myth**: Model behavior is consistent across languages.
  **Reality**: Safety alignment, hallucination rates, and willingness to produce misinformation can vary substantially by language even within the same model.

- **Myth**: General-purpose models can be tuned for any domain with prompting alone.
  **Reality**: Tasks requiring data absent from public web sources (protein structures, medical imaging) need domain-specific training data, not just clever prompts.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Training data | Bounds what a model can ever do |
| Common Crawl | Default but noisy web corpus underpinning most FMs |
| Multilingual model | Trained with deliberate non-English coverage |
| Low-resource language | Under-represented in web data, poor general-model performance |
| Domain-specific model | Trained on specialized data the open web lacks |
| Tokenization efficiency | Why non-English calls cost more and run slower |
