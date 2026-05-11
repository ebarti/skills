# Finetuning Tactics Knowledge

Core concepts for selecting frameworks, base models, and tuning hyperparameters.

## Overview

Finetuning has three key choices: a base model, a finetuning method, and a framework. Once chosen, success depends on tuning hyperparameters like learning rate, batch size, epochs, and prompt loss weight to balance performance, stability, and cost.

## Key Concepts

### Base Model Selection

**Definition**: The pretrained model from which finetuning starts.

Two common development paths from OpenAI's best practices:

- **Progression path**: Start cheap/fast model to verify code, then middling model to verify data, then strongest model to push performance, then full sweep for price/performance frontier.
- **Distillation path**: Start with strongest model + small dataset to train the best teacher, use it to generate more data, then train a cheaper student model.

### Finetuning Methods

**Definition**: The algorithm used to update model weights (full vs. adapter-based).

- **Full finetuning**: Updates all weights; needs thousands+ examples; serves N full models for N tasks.
- **Adapter-based (LoRA, PEFT)**: Updates a small subset; works with hundreds of examples; one base model serves many adapters.
- Start with LoRA, attempt full finetuning later if needed.

### Finetuning Frameworks

**Definition**: Tooling that orchestrates the training loop, optimization, and distribution.

Three categories:

- **Finetuning APIs** (model providers, cloud providers): easiest, but limited base models and few exposed knobs.
- **Open-source frameworks**: LLaMA-Factory, Unsloth, Hugging Face PEFT, Axolotl, LitGPT — flexible, support many adapter methods.
- **Distributed training frameworks**: DeepSpeed, PyTorch Distributed, ColossalAI — required for multi-machine training.

### Learning Rate

**Definition**: Step size for parameter updates per training step.

- Too small: slow convergence; too big: unstable, may never converge.
- No universal optimum — experiment within `1e-7` to `1e-3`.
- Common practice: take pretraining end LR and multiply by `0.1`–`1.0`.
- A learning rate **schedule** varies LR over training (large early, small late).

### Batch Size

**Definition**: Number of examples processed before each weight update.

- Too small (e.g., < 8) leads to unstable training.
- Larger batch sizes give more stable, reliable gradient signals.
- Limited by GPU memory; trade off cost vs. speed.
- **Gradient accumulation**: accumulate gradients across several small batches and update once — simulates a larger effective batch size when memory is tight.

### Number of Epochs

**Definition**: Number of complete passes over the training dataset.

- Small datasets (thousands) often benefit from 4–10 epochs.
- Large datasets (millions) typically need only 1–2 epochs.
- Use train vs. validation loss to decide:
  - Both still falling: more epochs help.
  - Train falling, validation rising: overfitting — reduce epochs.

### Prompt Loss Weight

**Definition**: Weight applied to prompt tokens (vs. response tokens) when computing loss in instruction finetuning.

- 100% = model learns equally from prompt and response.
- 0% = model learns only from response.
- Default ~10% — model focuses on responses but learns some prompt structure.

## Terminology

| Term | Definition |
|------|------------|
| Base model | Pretrained model used as starting point for finetuning |
| LoRA | Low-Rank Adaptation; an adapter-based PEFT method |
| PEFT | Parameter-Efficient Finetuning |
| Epoch | One full pass over the training data |
| Gradient accumulation | Sum gradients across multiple batches before one weight update |
| LR schedule | Algorithm that varies the learning rate during training |
| Loss curve | Plot of training loss over steps; used to diagnose LR |
| Distillation | Use a strong model to generate data, then train a smaller model |

## How It Relates To

- **PEFT / LoRA**: drives data and compute requirements, narrows framework choice.
- **Memory bottlenecks**: caps batch size and forces gradient accumulation.
- **Data acquisition**: dataset size determines suitable method (full vs. adapter) and epoch count.

## Common Misconceptions

- **Myth**: There is one optimal learning rate for finetuning.
  **Reality**: It is task/model-specific; sweep across `1e-7`–`1e-3`.

- **Myth**: More epochs always means a better model.
  **Reality**: Validation loss rising while training loss falls means overfitting — fewer epochs needed.

- **Myth**: Bigger batches always train better models.
  **Reality**: Bigger batches train faster and more stably, but optimal batch size for performance varies — sweep when compute allows.

- **Myth**: Finetuning APIs are always sufficient.
  **Reality**: They limit base model choice and rarely expose all hyperparameters.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Progression path | Cheap-to-strong sweep mapping price/performance |
| Distillation path | Strong teacher generates data for cheaper student |
| Learning rate | Step size; sweep 1e-7 to 1e-3 |
| Batch size | Examples per update; min 8 for stability |
| Epochs | Passes over data; few for large data, many for small |
| Prompt loss weight | Default ~10% for instruction tuning |
| Gradient accumulation | Simulate large batches when memory-bound |
