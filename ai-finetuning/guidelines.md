# AI Finetuning Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use**: Find your situation below, then load ONLY the listed files.

---

## By Task

### Should I Finetune?

| What you're doing | Load these files |
|-------------------|------------------|
| Deciding if finetuning is the right approach | `references/finetuning-overview/rules.md`, `references/finetuning-overview/checklist.md` |
| Comparing finetuning vs RAG vs prompt engineering | `references/finetuning-overview/knowledge.md`, `references/finetuning-overview/rules.md` |
| Pre-finetuning go/no-go decision | `references/finetuning-overview/checklist.md` |
| Understanding when finetuning fails | `references/finetuning-overview/examples.md` |

### Sizing Memory and Compute

| What you're doing | Load these files |
|-------------------|------------------|
| Estimating memory for inference | `references/memory-bottlenecks/rules.md`, `references/memory-bottlenecks/examples.md` |
| Estimating memory for training | `references/memory-bottlenecks/rules.md`, `references/memory-bottlenecks/examples.md` |
| Choosing precision (FP16, BF16, INT8, etc.) | `references/memory-bottlenecks/rules.md`, `references/memory-bottlenecks/patterns.md` |
| Quantizing a model | `references/memory-bottlenecks/rules.md`, `references/memory-bottlenecks/examples.md` |
| Fitting model in limited GPU | `references/memory-bottlenecks/patterns.md` |

### Implementing PEFT

| What you're doing | Load these files |
|-------------------|------------------|
| Choosing PEFT vs full finetuning | `references/peft-techniques/rules.md` |
| Setting up LoRA | `references/peft-techniques/rules.md`, `references/peft-techniques/examples.md` |
| Choosing LoRA rank and alpha | `references/peft-techniques/rules.md`, `references/peft-techniques/patterns.md` |
| Setting up QLoRA | `references/peft-techniques/examples.md`, `references/peft-techniques/patterns.md` |
| Multi-LoRA serving | `references/peft-techniques/patterns.md`, `references/peft-techniques/examples.md` |

### Combining Multiple Models

| What you're doing | Load these files |
|-------------------|------------------|
| Choosing model merging vs multi-task FT | `references/model-merging/rules.md`, `references/model-merging/examples.md` |
| Implementing summing-based merge | `references/model-merging/examples.md`, `references/model-merging/patterns.md` |
| Layer stacking / frankenmerging | `references/model-merging/examples.md`, `references/model-merging/patterns.md` |
| Adapter concatenation | `references/model-merging/examples.md` |
| Sparse upcycling to MoE | `references/model-merging/patterns.md` |

### Picking Hyperparameters and Tools

| What you're doing | Load these files |
|-------------------|------------------|
| Selecting a finetuning framework | `references/finetuning-tactics/rules.md`, `references/finetuning-tactics/examples.md` |
| Selecting a base model | `references/finetuning-tactics/rules.md`, `references/finetuning-tactics/examples.md` |
| Choosing learning rate, batch size, epochs | `references/finetuning-tactics/rules.md`, `references/finetuning-tactics/examples.md` |
| Pre-finetuning checklist | `references/finetuning-tactics/checklist.md` |

---

## By Symptom/Problem

| If you notice... | Load these files |
|------------------|------------------|
| OOM error during training | `references/memory-bottlenecks/rules.md`, `references/memory-bottlenecks/patterns.md` |
| Loss plateaus / doesn't decrease | `references/finetuning-tactics/examples.md` (loss diagnosis) |
| Model overfits quickly | `references/finetuning-tactics/rules.md` (epochs) |
| Catastrophic forgetting | `references/peft-techniques/rules.md` |
| Need to serve many specialized models | `references/peft-techniques/patterns.md` (multi-LoRA) |
| Finetuned but doesn't improve over base | `references/finetuning-overview/rules.md` (RAG-first), `references/finetuning-overview/examples.md` |
| BloombergGPT-style: built but couldn't beat GPT-4 | `references/finetuning-overview/examples.md` (cautionary tale) |

---

## By Topic (Direct Index)

### Finetuning Overview
- `references/finetuning-overview/knowledge.md` — Finetuning types, prompting/RAG/FT comparison
- `references/finetuning-overview/rules.md` — 9 decision rules ("form vs facts")
- `references/finetuning-overview/examples.md` — 11 decision cases including BloombergGPT
- `references/finetuning-overview/checklist.md` — Should-I-finetune checklist

### Memory Bottlenecks
- `references/memory-bottlenecks/knowledge.md` — Backprop, formats, quantization
- `references/memory-bottlenecks/rules.md` — Memory formulas (NxMx1.2)
- `references/memory-bottlenecks/examples.md` — 7B/13B/70B calculations
- `references/memory-bottlenecks/patterns.md` — 6 memory patterns

### PEFT Techniques
- `references/peft-techniques/knowledge.md` — PEFT, adapters, LoRA, QLoRA
- `references/peft-techniques/rules.md` — LoRA rank/alpha, when to use
- `references/peft-techniques/examples.md` — HuggingFace PEFT code
- `references/peft-techniques/patterns.md` — 5 PEFT patterns

### Model Merging
- `references/model-merging/knowledge.md` — Merging vs ensembling, summing/stacking/concat
- `references/model-merging/rules.md` — 8 merging rules
- `references/model-merging/examples.md` — 6 Python recipes
- `references/model-merging/patterns.md` — 6 merging patterns

### Finetuning Tactics
- `references/finetuning-tactics/knowledge.md` — Frameworks, base models, hyperparams
- `references/finetuning-tactics/rules.md` — 10 rules with LR ranges
- `references/finetuning-tactics/examples.md` — Hyperparameter tables, framework configs
- `references/finetuning-tactics/checklist.md` — Pre-finetuning checklist

---

## Decision Tree

```
What are you doing?
│
├─► Deciding whether to finetune
│   ├─► First go/no-go → finetuning-overview/checklist.md
│   ├─► Compare to alternatives → finetuning-overview/rules.md
│   └─► See past failures → finetuning-overview/examples.md
│
├─► Already decided to finetune
│   ├─► Memory budget → memory-bottlenecks/rules.md
│   ├─► Method (PEFT/LoRA?) → peft-techniques/rules.md
│   ├─► Framework → finetuning-tactics/rules.md
│   ├─► Hyperparameters → finetuning-tactics/rules.md
│   └─► Pre-flight check → finetuning-tactics/checklist.md
│
├─► Combining models
│   └─► Merging strategy → model-merging/rules.md
│
└─► OOM problems
    └─► Memory patterns → memory-bottlenecks/patterns.md
```

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| First-time finetuning decision | `finetuning-overview/checklist.md` + `finetuning-overview/rules.md` |
| Setting up LoRA on a 7B model | `peft-techniques/rules.md` + `peft-techniques/examples.md` + `memory-bottlenecks/examples.md` |
| Setting up QLoRA on a 65B model | `peft-techniques/examples.md` + `memory-bottlenecks/patterns.md` + `finetuning-tactics/rules.md` |
| Building a multi-task model | `model-merging/rules.md` + `model-merging/patterns.md` |
| Pre-launch sanity check | `finetuning-tactics/checklist.md` |
