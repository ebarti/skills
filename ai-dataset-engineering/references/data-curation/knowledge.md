# Data Curation Knowledge

Core concepts for curating training datasets for AI model finetuning.

## Overview

Data curation is the process of producing the right data to train a model: enough of it, of high quality, with sufficient coverage of expected use cases. It rests on three pillars - quality, coverage, and quantity - and treats datasets as the primary lever for improving model behavior (the "data-centric" view of AI).

## Key Concepts

### Data-Centric vs Model-Centric AI

**Definition**: Two complementary approaches to improving AI performance.

- **Model-centric**: Improve performance via new architectures, larger models, new training techniques.
- **Data-centric**: Improve performance via better data processing and higher-quality datasets.

Most modern gains (e.g., Llama 3 vs Llama 2) come primarily from data quality and diversity, not architecture changes.

### Data Quality

**Definition**: Data is high-quality if it helps you do your job efficiently and reliably.

Six characteristics define quality data:
- **Relevant** - matches the task domain and time period
- **Aligned with task requirements** - annotations satisfy what the task actually demands (correctness, creativity, conciseness, justifications, etc.)
- **Consistent** - same example annotated similarly across annotators
- **Correctly formatted** - no stray HTML, trailing whitespace, inconsistent casing, or formatting tokens
- **Sufficiently unique** - duplicates introduce bias and contamination
- **Compliant** - obeys laws, regulations, and internal policies (e.g., no PII when prohibited)

### Data Coverage (Diversity)

**Definition**: The training set spans the range of problems and expression patterns the model must handle in production.

Coverage requires diversity along application-specific axes - topic, length, style, language, task type, output format, number of turns. Different applications need different diversity axes.

### Data Quantity

**Definition**: How many examples (or tokens) you need.

Driven by four factors: data quality, data diversity, finetuning technique (full vs PEFT), task complexity, and base model performance. Returns diminish: doubling data typically gives smaller and smaller gains.

### Data Acquisition

**Definition**: Sourcing the dataset from public data, proprietary data, application data, annotation, or synthesis.

The most valuable source is your own application data ("data flywheel"), because it perfectly matches the production distribution.

### Annotation

**Definition**: Producing labels/responses for examples, either manually, with AI assistance, or by domain experts.

The hardest part is rarely the labeling - it's writing clear annotation guidelines that define what "good" means.

### Data Mix

**Definition**: The proportional composition of training data across categories (e.g., 50% general knowledge, 25% math, 17% code).

Different training phases (pre-training, SFT, preference finetuning) use different mixes. Choose by reflecting real usage or by running scaling-law experiments on small models.

### Ossification

**Definition**: A phenomenon where pre-training "freezes" model weights so they don't adapt well to finetuning data.

More severe in smaller models. Argues for training from scratch when you have very large finetuning datasets.

## Terminology

| Term | Definition |
|------|------------|
| Data flywheel | Pipeline that turns user-generated data into continual model improvement |
| Annealing | Training with decreasing learning rate plus increasing high-quality data (math/code) |
| CoT data | Examples that include step-by-step reasoning, not just final answers |
| Single-turn data | One instruction, one response |
| Multi-turn data | Back-and-forth conversation examples |
| PEFT | Parameter-efficient finetuning (e.g., LoRA); needs less data than full finetuning |
| Data contamination | Test/eval examples leaking into training data |
| Preference data | (instruction, winning response, losing response) triples |

## How It Relates To

- **Data Synthesis**: Generation can fill quantity and coverage gaps that curation reveals.
- **Data Processing**: Cleaning and deduplication enforce quality characteristics.
- **Evaluation**: Annotation guidelines are the same artifacts used for eval data; eval examples can seed synthesis.
- **Finetuning**: Quantity needs depend on the technique chosen (full vs PEFT).

## Common Misconceptions

- **Myth**: More data always helps.
  **Reality**: 10K carefully crafted instructions beat hundreds of thousands of noisy ones (Yi); 1K curated examples (LIMA) match GPT-4 in 43% of cases.

- **Myth**: Human annotations are always best.
  **Reality**: Llama 3 found human-generated data more error-prone for nuanced safety; AI-assisted annotation improved quality.

- **Myth**: You should optimize for accuracy.
  **Reality**: You should optimize for *alignment with task requirements* - sometimes the "correct" answer is not what the user wants.

- **Myth**: If small data doesn't help, more data will fix it.
  **Reality**: If 50-100 well-crafted examples produce no improvement, more data rarely does either - check hyperparameters, prompts, and quality first.

- **Myth**: Diversity always helps.
  **Reality**: "The Data Addition Dilemma" shows adding heterogeneous data can hurt performance in some cases.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Quality | Relevant, aligned, consistent, formatted, unique, compliant |
| Coverage | Spans the input distribution along task-relevant axes |
| Quantity | Enough for the technique, task, and base model - usually with diminishing returns |
| Acquisition | Public + proprietary + application + annotated + synthetic, mix-and-match |
| Annotation | Guidelines are harder than labeling - invest there first |
