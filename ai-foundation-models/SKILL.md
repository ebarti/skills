---
name: ai-foundation-models
description: |
  Practical knowledge for understanding and working with foundation models (FMs) in AI engineering. Covers the AI engineering stack, planning AI applications, transformer architecture, training data, model size and scaling laws, post-training (SFT, RLHF), and sampling strategies (temperature, top-k, top-p, structured outputs).

  Use this skill when:
  - Planning a new AI application using foundation models
  - Choosing between models (size, architecture, capabilities)
  - Configuring sampling parameters (temperature, top-k, top-p)
  - Understanding why a model behaves a certain way (hallucination, inconsistency)
  - Designing structured outputs from LLMs
  - Comparing AI engineering vs ML engineering responsibilities
---

# AI Foundation Models

Knowledge from "AI Engineering" by Chip Huyen (Chapters 1-2). Focuses on understanding what foundation models are, how they're built, and how to make sound architectural decisions when integrating them.

## Quick Start

1. Check `guidelines.md` to find which files to load for your task
2. Load only relevant files (each topic has knowledge.md, rules.md, examples.md)
3. Apply guidance to your work

## Contents

### References

| Category | Purpose |
|----------|---------|
| `ai-engineering-overview` | Rise of AI engineering, language model basics, FM use cases |
| `planning-applications` | Use case evaluation, defensibility, AI stack layers, AI vs ML eng |
| `training-data` | Multilingual models, domain-specific models, data quality |
| `model-architecture` | Transformer architecture, model size, scaling laws |
| `post-training` | Supervised finetuning (SFT), preference finetuning (RLHF), reward models |
| `sampling` | Temperature, top-k, top-p, structured outputs, hallucination, inconsistency |

### Workflows

| Task | Workflow |
|------|----------|
| Decide if/how to use FMs for a use case | `workflows/evaluate-use-case.md` |
| Configure sampling (temperature, top-k/p, structured output) | `workflows/tune-sampling.md` |

## Guidelines

See `guidelines.md` for task-based file selection.
