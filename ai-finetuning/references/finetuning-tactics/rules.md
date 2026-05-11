# Finetuning Tactics Rules

Practical rules for choosing frameworks, base models, and setting hyperparameters.

## Core Rules

### 1. Start with the Strongest Affordable Base Model

Use the most capable model you can afford for early feasibility checks. If the strongest model fails, weaker ones will too.

- Use the strong model as a benchmark before exploring smaller ones.
- For instruction-following tasks, prefer instruct/chat variants; for raw next-token learning on novel data, base variants are valid.

### 2. Pick the Development Path that Matches Your Goal

- **Progression path** when you need to map the price/performance frontier.
- **Distillation path** when you have very little labeled data but a strong teacher.

### 3. Start with LoRA, Move to Full Finetuning Later

Adapter-based methods (LoRA, PEFT) are cheaper, work with smaller datasets, and serve many tasks from one base model.

- For datasets < ~1,000 examples, LoRA usually matches or beats full finetuning.
- Full finetuning typically needs thousands of examples to outperform LoRA.

### 4. Match Framework to Customization Needs

- **Finetuning API** when you want speed and don't care about exotic knobs.
- **Open-source framework** (Axolotl, Unsloth, LLaMA-Factory, PEFT, LitGPT) when you need flexibility, custom methods, or unsupported base models.
- **Distributed framework** (DeepSpeed, PyTorch Distributed, ColossalAI) only when training spans multiple machines.

### 5. Sweep Learning Rate; Never Hardcode

Learning rate is the most consequential hyperparameter and varies by model and method.

- Sweep within `1e-7` to `1e-3`.
- Heuristic: `pretraining_end_lr * c`, where `c ∈ [0.1, 1.0]`.
- For LoRA, common range is `1e-4` to `5e-4` (much higher than full finetuning).
- For full finetuning of large LLMs, common range is `1e-6` to `5e-5`.

### 6. Read the Loss Curve Before Re-tuning

- Loss fluctuates wildly → learning rate too high.
- Loss flat or barely decreasing → learning rate too low.
- Increase LR until just before instability appears.

### 7. Keep Batch Size >= 8

Tiny batches make training unstable. Use gradient accumulation when memory cannot fit a real batch of that size.

- Effective batch size = `per_device_batch_size * grad_accum_steps * num_devices`.
- Aim for an effective batch size of at least 16–32 for stable instruction tuning.

### 8. Pick Epochs Based on Dataset Size

| Dataset size | Typical epochs |
|--------------|---------------|
| Millions | 1–2 |
| Tens of thousands | 2–4 |
| Thousands | 4–10 |

- Stop early when validation loss starts rising.
- Continue when both train and validation losses still decrease.

### 9. Set Prompt Loss Weight to ~10% for Instruction Tuning

Default of 10% balances learning prompt structure without diluting response quality.

- Set to 0% if your prompts are short or fixed templates.
- Avoid 100% — it overweights inputs the model never has to generate.

### 10. Always Smoke-Test Before Long Training Runs

Run a tiny end-to-end pass first (small data, few steps, cheapest model) to verify code, paths, and checkpointing.

- Save a checkpoint to confirm the output folder exists and is writable.
- Verify metrics are logged correctly before scaling up.

## Guidelines

- Use a learning rate **schedule** (linear warmup + cosine decay is a safe default).
- For multi-task serving, prefer LoRA so you can hot-swap adapters on a single base model.
- Mid-tier GPU is fine for adapter-based finetuning; full finetuning of large models requires multi-GPU.
- When using a finetuning API, accept the limited knobs — don't fight the API.

## Exceptions

- **Domain-shift tasks**: full finetuning may outperform LoRA even with smaller data when the new domain diverges sharply from pretraining.
- **One-off research runs**: epoch limits and LR sweeps may be relaxed when cost is irrelevant.
- **Very large datasets**: skip LoRA — full finetuning with 1 epoch is often more effective and serving cost is the same.

## Quick Reference

| Rule | Summary |
|------|---------|
| Base model | Start strong, then explore smaller |
| Method | LoRA first, full finetuning later |
| LR (LoRA) | 1e-4 to 5e-4 |
| LR (full FT) | 1e-6 to 5e-5 |
| Batch size | Min 8; use grad accumulation |
| Epochs (small data) | 4–10 |
| Epochs (large data) | 1–2 |
| Prompt loss weight | ~10% for instruction tuning |
| Smoke test | Always run before long training |
