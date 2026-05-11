# Pre-Finetuning Checklist

Use before kicking off any finetuning run to avoid wasted compute and lost progress.

## Before You Start

- [ ] Confirmed finetuning is the right tool (vs. prompting or RAG)
- [ ] Decided development path: progression vs. distillation
- [ ] Have a clear evaluation set separate from training data

## Base Model

- [ ] Selected base model fits license, size, and benchmark needs
- [ ] Chose between instruct vs. base variant for the task
- [ ] Strongest affordable model available as benchmark
- [ ] Tokenizer matches model and is loaded correctly

## Method

- [ ] Decided full finetuning vs. LoRA / PEFT
- [ ] If dataset < 1,000 examples, defaulted to LoRA
- [ ] If serving multiple tasks, defaulted to LoRA for adapter swapping
- [ ] If full finetuning, confirmed compute and memory budget

## Framework

- [ ] Chose framework matching customization needs (API vs. open source)
- [ ] Distributed framework configured if multi-machine
- [ ] Framework supports the chosen base model
- [ ] Versions pinned in requirements file

## Data

- [ ] Train/validation/test split exists and is non-overlapping
- [ ] Data format matches framework expectation (alpaca, sharegpt, etc.)
- [ ] Sequence lengths reviewed and `max_seq_len` set
- [ ] Data sanity-checked for label leakage and duplicates

## Hyperparameters

- [ ] Learning rate set within method-appropriate range
  - LoRA: 1e-4 to 5e-4
  - Full FT: 1e-6 to 5e-5
- [ ] LR scheduler chosen (cosine + warmup is a safe default)
- [ ] Per-device batch size and gradient accumulation set
  - Effective batch size >= 16
- [ ] Epochs chosen based on dataset size
  - Millions: 1–2
  - Thousands: 4–10
- [ ] Prompt loss weight set (default ~10% for instruction tuning)

## Compute and Storage

- [ ] GPU memory checked for chosen batch size and method
- [ ] Output / checkpoint directory exists and is writable
- [ ] Checkpoint frequency set (per epoch or every N steps)
- [ ] Disk has room for all checkpoints
- [ ] Logging destination configured (Weights & Biases, MLflow, file)

## Smoke Test

- [ ] Ran end-to-end on tiny dataset (e.g., 50 examples, 10 steps)
- [ ] Verified loss is finite and decreases on overfit-tiny test
- [ ] Verified checkpoint actually saved to disk
- [ ] Verified eval loop runs without error
- [ ] Verified resume-from-checkpoint works

## During the Run

- [ ] Monitor train and validation loss curves
- [ ] Watch for NaN / divergence in first 100 steps
- [ ] Confirm GPU utilization is reasonable (>50%)
- [ ] Confirm checkpoints save on schedule

## Red Flags

Stop and investigate if you see:

- Loss is NaN or rapidly diverging
- Validation loss rises while training loss falls (overfitting)
- Loss curve is flat across thousands of steps
- GPU memory errors after first few steps
- Checkpoint save failing silently
- Per-step time grows without bound (memory leak)

## Quick Reference

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| LR (LoRA) | 2e-4 | 1e-4 to 5e-4 | < 1e-6 or > 1e-3 |
| LR (full FT) | 2e-5 | 1e-6 to 5e-5 | > 1e-4 |
| Effective batch size | 32 | 16–64 | < 8 |
| Epochs (1k examples) | 5 | 4–10 | > 20 |
| Epochs (1M examples) | 1–2 | 1–3 | > 5 |
| Prompt loss weight | 10% | 0–25% | 100% |
| GPU utilization | > 80% | 50–80% | < 30% |
| Smoke test | Runs and saves | Runs | Skipped |
