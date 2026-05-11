---
name: ai-evaluation
description: |
  Practical knowledge for evaluating AI/LLM systems. Covers language modeling metrics (perplexity, cross-entropy), exact evaluation methods (functional correctness, similarity), AI-as-judge patterns, comparative evaluation, evaluation criteria for production systems, model selection workflows, and designing end-to-end evaluation pipelines.

  Use this skill when:
  - Designing an evaluation strategy for an LLM application
  - Choosing between models or providers (build vs buy)
  - Selecting evaluation metrics (perplexity, BLEU, semantic similarity)
  - Setting up AI-as-judge evaluation
  - Interpreting public benchmarks (MMLU, HumanEval, etc.)
  - Building an evaluation pipeline with scoring rubrics
---

# AI Evaluation

Knowledge from "AI Engineering" by Chip Huyen (Chapters 3-4). Practical methods for evaluating foundation models and AI systems built on top of them.

## Quick Start

1. Check `guidelines.md` to find which files to load for your task
2. Load only relevant files (each topic has knowledge.md, rules.md, examples.md)
3. Apply guidance to your work

## Contents

### References

| Category | Purpose |
|----------|---------|
| `language-modeling-metrics` | Entropy, cross-entropy, perplexity, bits-per-character |
| `exact-evaluation` | Functional correctness, exact match, lexical/semantic similarity, embeddings |
| `ai-as-judge` | When to use AI judges, how to prompt them, limitations and biases |
| `comparative-evaluation` | Ranking models with pairwise comparisons, Bradley-Terry, scalability challenges |
| `evaluation-criteria` | Domain capability, generation (factual, safety), instruction-following, cost/latency |
| `model-selection` | Selection workflow, open source vs API, navigating public benchmarks |
| `evaluation-pipeline` | End-to-end pipeline design, scoring rubrics, evaluation methods |

### Workflows

| Task | Workflow |
|------|----------|
| Choose a model (build vs buy, OS vs API) | `workflows/select-model.md` |
| Design an end-to-end evaluation pipeline | `workflows/design-eval-pipeline.md` |

## Guidelines

See `guidelines.md` for task-based file selection.
