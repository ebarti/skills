# AI Engineering Overview Knowledge

Core concepts and terminology for understanding foundation models and the AI engineering discipline.

## Overview

AI engineering is the process of building applications on top of readily available foundation models. It emerged from the evolution: language models → large language models (LLMs) → foundation models. Unlike traditional ML engineering which involves developing models, AI engineering leverages existing ones.

## Key Concepts

### Language Model

**Definition**: A model that encodes statistical information about one or more languages, predicting how likely a token is to appear in a given context.

**Key points**:
- Operates on tokens (characters, words, or sub-word units like `-tion`)
- The set of tokens a model knows is its **vocabulary**
- Outputs are open-ended (generative)
- Acts as a "completion machine" — given a prompt, it predicts what comes next

**Two types**:
- **Masked language model** (e.g., BERT): predicts missing tokens using context from both before and after; used for non-generative tasks like sentiment analysis and classification
- **Autoregressive language model**: predicts the next token using only preceding tokens; the default choice for text generation

### Self-Supervision

**Definition**: A training approach where the model infers labels from input data itself, rather than requiring explicit human-provided labels.

**Why it matters**: Eliminates the data labeling bottleneck. Language modeling is naturally self-supervised — each input sequence provides both the labels (next tokens) and the context. This is what enabled scaling language models to LLM size.

**Distinct from unsupervised learning**: self-supervision still uses labels, they're just inferred from the data; unsupervised learning uses no labels.

### Large Language Model (LLM)

**Definition**: A language model with a large number of parameters, trained on massive text corpora via self-supervision.

**Key points**:
- "Large" is not scientifically defined; the threshold moves as models grow
- Size measured by parameter count (variables updated during training)
- Larger models need more training data to maximize performance
- More parameters = greater capacity to learn (generally)

### Foundation Model

**Definition**: A large model (LLM or large multimodal model) that serves as a base which can be adapted for many downstream tasks.

**Key points**:
- "Foundation" signals both importance and that they can be built upon
- Multimodal: can process text, images, video, audio, 3D, protein structures, etc.
- General-purpose, not task-specific — one model can do sentiment analysis AND translation
- Trained at a scale only feasible for big corporations, governments, and well-funded startups

### Large Multimodal Model (LMM)

**Definition**: A generative foundation model that works with more than one data modality (e.g., text + images).

Generates next tokens conditioned on multiple modalities. Examples: GPT-4V, Claude 3, Gemini.

### Embedding Model

**Definition**: A model trained to produce vector representations (embeddings) that capture the meaning of input data.

Not generative. Example: CLIP produces joint embeddings of text and images. Embedding models often serve as backbones for generative multimodal models (Flamingo, LLaVA, Gemini).

### AI Engineering

**Definition**: The process of building applications on top of foundation models.

**Three enabling factors**:
1. **General-purpose AI capabilities** — one model handles many tasks
2. **Increased AI investment** — capital flooding into the space
3. **Low entrance barrier** — model-as-a-service APIs, plus AI that writes code and accepts plain English

**Three core adaptation techniques**:
- **Prompt engineering** — crafting instructions and examples
- **Retrieval-augmented generation (RAG)** — supplementing prompts with database content
- **Finetuning** — further training the model on domain data

## Terminology

| Term | Definition |
|------|------------|
| Token | Basic unit of a language model (character, word, or word part) |
| Tokenization | Process of breaking text into tokens |
| Vocabulary | Set of all tokens a model can work with |
| Parameter | A variable in an ML model updated through training |
| Generative AI | Models that produce open-ended outputs |
| Self-supervision | Training where labels are inferred from input data |
| Natural language supervision | Self-supervision variant using co-occurring (image, text) pairs |
| Multimodal | Working with more than one data modality |
| Model as a service | Models exposed via APIs by their developers |
| Agent | An AI that can plan and use external tools |
| BOS / EOS | Beginning-of-sequence / end-of-sequence markers |

## How It Relates To

- **ML Engineering**: AI engineering is a subset focused on adapting foundation models rather than building models from scratch. ML engineering encompasses both.
- **MLOps / LLMOps / AIOps**: Adjacent terms; the book uses "AI engineering" because it emphasizes engineering (tweaking) over operations.
- **NLP / Computer Vision**: Foundation models break the historical division of AI by data modality — one model can span both.

## Common Misconceptions

- **Myth**: An LLM and a foundation model are the same thing.
  **Reality**: Foundation models include LLMs but also large multimodal models. The book uses "foundation model" to refer to both.

- **Myth**: A language model that completes text can answer questions.
  **Reality**: Completion is not conversation. A pure completion model may extend a question with another question. Post-training (instruction tuning, RLHF) is what makes it respond appropriately.

- **Myth**: Self-supervised = unsupervised.
  **Reality**: Self-supervised uses labels inferred from input; unsupervised uses no labels.

- **Myth**: Bigger model is always better.
  **Reality**: Larger models need proportionally more data. Training a large model on a small dataset wastes compute — a smaller model might match or beat it.

- **Myth**: Foundation models replace task-specific models.
  **Reality**: Task-specific models can still be smaller, faster, and cheaper. Buy-vs-build remains a real decision.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Language model | Predicts likely next tokens given context |
| Self-supervision | Labels inferred from the data itself |
| LLM | Language model scaled up via self-supervision |
| Foundation model | LLM + multimodal capability, adaptable to many tasks |
| AI engineering | Building applications on top of foundation models |
| Prompt engineering | Adapting via instructions |
| RAG | Adapting via retrieved context |
| Finetuning | Adapting via further training |
