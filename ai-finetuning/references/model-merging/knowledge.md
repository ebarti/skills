# Model Merging Knowledge

Core concepts for combining multiple models into a single, more capable model.

## Overview

Model merging creates a custom model by combining the parameters of two or more constituent models, in contrast to finetuning, which alters a single model. Merging can run without GPUs, deliver multi-task capability, shrink memory footprint for on-device deployment, and avoid catastrophic forgetting that plagues sequential multi-task finetuning.

## Key Concepts

### Model Merging

**Definition**: Combining the parameters of multiple constituent models into one merged model.

The goal is for the merged model to deliver more value than any constituent alone — better task performance, broader task coverage, or a smaller memory footprint.

**Key points**:
- Can be done without GPUs (attractive for indie developers)
- Optional further finetuning of the merged model often boosts quality
- Especially powerful for adapter-based models (e.g., merging LoRA adapters into one)

### Multi-Task Finetuning Approaches

**Definition**: Strategies for making one model handle multiple tasks.

Three options exist:

1. **Simultaneous finetuning**: One dataset with examples for all tasks. Harder to learn many skills at once; needs more data and training.
2. **Sequential finetuning**: Train on task A, then task B, etc. Risks **catastrophic forgetting** — the model loses earlier-task performance when trained on new tasks.
3. **Parallel finetuning + merging**: Finetune separately per task, then merge. Each task is learned well; no catastrophic forgetting because there is no sequential learning.

### Task Vectors (Delta Parameters)

**Definition**: The difference between a finetuned model and its base model.

Captures the essence of the task that the model was finetuned on. With LoRA, the task vector is the LoRA weights themselves.

**Task arithmetic**:
- **Add** task vectors to combine capabilities
- **Subtract** a task vector to remove a capability (e.g., bias, facial recognition)

### Ensembling vs Merging

| Aspect | Ensembling | Model Merging |
|--------|-----------|---------------|
| What is combined | Model outputs | Model parameters |
| Constituent models | Kept intact | Fused into one |
| Inference cost | High (N forward passes) | Same as one model |
| Output combination | Vote / trainable module | None — single model |

### Three Merging Approaches

**Summing**: Add weight values of constituent models together (linear combination, SLERP).

**Layer stacking** (passthrough / frankenmerging): Take different layers from different models and stack them. Usually requires further finetuning. Can produce unique architectures and parameter counts.

**Concatenation**: Concatenate parameters; for two LoRA adapters of ranks r1 and r2, the merged adapter has rank r1 + r2. Does **not** reduce memory footprint.

You can mix approaches (e.g., sum some layers, stack others).

### Summing Methods

- **Linear combination**: Weighted average of parameters. `Merge(A,B) = (W_A·A + W_B·B) / (W_A + W_B)`. Most effective when models share the same base.
- **SLERP** (Spherical Linear Interpolation): Treats each weight vector as a point on a sphere; the merged vector is along the shortest arc between them. Interpolation factor in [0, 1] controls which constituent dominates. Defined for **only two vectors at a time** — merge more sequentially.
- **Pruning + merge** (TIES, DARE): Reset redundant task-vector parameters to zero before merging. Reduces interference between tasks; benefit grows with the number of merged models.

### Layer Stacking Use Cases

- **Frankenmerging**: e.g., Goliath-120B from two Llama 2-70B finetunes (Xwin + Euryale, 72 of 80 layers each).
- **Sparse upcycling to MoE**: Copy certain layers, add a router, train router + copies — outperforms MoE trained from scratch.
- **Model upscaling / depthwise scaling**: Grow a model to use newly available compute. SOLAR 10.7B was built from a 7B/32-layer model by copying it, summing 16 layers, stacking the rest → 48 layers, then training.

## Terminology

| Term | Definition |
|------|------------|
| Task vector | Finetuned model minus base model; captures task-specific changes |
| Delta parameters | Synonym for task vector |
| Task arithmetic | Adding/subtracting task vectors to combine or remove capabilities |
| Frankenmerging | Layer stacking from different models |
| Passthrough | Synonym for layer stacking |
| Model soup | Averaging entire weights of multiple finetunes of the same base |
| Sparse upcycling | Building MoE from a dense checkpoint via layer stacking + router |
| Depthwise scaling | Layer-stacking technique to upscale model depth |
| Federated learning | Multiple devices train the same model on local data; copies later merged |
| Catastrophic forgetting | Losing earlier-task skill when sequentially trained on new tasks |
| TIES / DARE | Methods that prune redundant task-vector parameters before merging |
| Interpolation factor | SLERP scalar in [0, 1] biasing toward one constituent |

## How It Relates To

- **PEFT / LoRA**: Adapters are the most common merging unit; small task vectors are easy to combine
- **Multi-task finetuning**: Merging is the third (parallel) approach to multi-task learning
- **Federated learning**: Merging is one mechanism for fusing on-device-trained model copies
- **MoE**: Layer stacking + router can produce MoE from dense checkpoints (sparse upcycling)
- **On-device deployment**: One merged multi-task model uses far less memory than N specialized models

## Common Misconceptions

- **Myth**: You need GPUs to merge models.
  **Reality**: Merging itself is parameter arithmetic and runs on CPU. Only optional follow-up finetuning needs GPUs.

- **Myth**: Merging always reduces inference cost vs ensembling.
  **Reality**: Concatenation increases parameter count and memory; only summing/stacking keep size flat.

- **Myth**: SLERP can merge any number of models in one shot.
  **Reality**: SLERP is defined for two vectors. Merge more by chaining (A+B, then with C).

- **Myth**: All finetuned parameters matter equally for merging.
  **Reality**: Most adjustments are redundant. TIES/DARE prune them to reduce interference and boost merged-model quality.

- **Myth**: Merging requires identical architectures and sizes.
  **Reality**: Typical case yes, but you can project layers to a common dimension to merge mismatched models.

## Quick Reference

| Approach | What It Does | Memory Footprint | Needs Re-Finetune? |
|----------|--------------|------------------|--------------------|
| Linear combination | Weighted average of weights | Same as one model | Often no |
| SLERP | Interpolate along sphere arc | Same as one model | Often no |
| TIES / DARE | Prune redundant params, then sum | Same as one model | Often no |
| Layer stacking | Stack layers from different models | Variable | Usually yes |
| Concatenation | Append parameters (e.g., LoRA ranks) | Larger | Optional |
