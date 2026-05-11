---
name: ai-finetuning
description: |
  Practical knowledge for finetuning foundation models. Covers when to finetune (vs prompt engineering or RAG), memory bottlenecks (backpropagation, quantization, numerical representations), parameter-efficient finetuning techniques (PEFT, LoRA, adapters), model merging strategies (summing, layer stacking, concatenation), and finetuning tactics (frameworks, hyperparameters).

  Use this skill when:
  - Deciding whether to finetune (vs prompt engineering or RAG)
  - Estimating memory requirements for finetuning
  - Implementing LoRA or other PEFT techniques
  - Merging multiple finetuned models
  - Choosing finetuning hyperparameters or frameworks
  - Quantizing models for inference or training
---

# AI Finetuning

Knowledge from "AI Engineering" by Chip Huyen (Chapter 7). Practical guide to model finetuning with focus on parameter-efficient methods.

## Quick Start

1. Check `guidelines.md` to find which files to load for your task
2. Load only relevant files (each topic has knowledge.md, rules.md, examples.md)
3. Apply guidance to your work

## Contents

### References

| Category | Purpose |
|----------|---------|
| `finetuning-overview` | When to finetune, reasons for/against, finetuning vs RAG |
| `memory-bottlenecks` | Backpropagation memory, numerical representations, quantization |
| `peft-techniques` | Parameter-efficient finetuning, LoRA, adapter methods |
| `model-merging` | Summing, layer stacking, concatenation for multi-task models |
| `finetuning-tactics` | Frameworks, base model selection, hyperparameters |

### Workflows

| Task | Workflow |
|------|----------|
| Decide whether to finetune | `workflows/should-i-finetune.md` |
| Set up a finetuning job (memory → method → params) | `workflows/setup-finetuning.md` |

## Guidelines

See `guidelines.md` for task-based file selection.
