# Setup Finetuning Workflow

Memory → method → params → run. Concrete steps to set up a finetuning job.

## When to Use

- Decided to finetune (passed `should-i-finetune.md`)
- Have training data (or plan to generate it)
- Have compute access (GPU/cloud)

## Prerequisites

- Training dataset (curated, deduplicated, formatted)
- Eval set held out from training
- GPU(s) with sufficient memory
- Chosen method (full FT, LoRA, QLoRA)

**Reference**: `references/finetuning-tactics/rules.md`

---

## Workflow Steps

### Step 1: Estimate Memory Requirements

**Goal**: Confirm your hardware can run the job before starting.

- [ ] Look up base model size (params)
- [ ] Calculate inference memory: `N_params × bytes_per_param × 1.2`
- [ ] Calculate training memory: weights + gradients + optimizer states + activations
- [ ] If using Adam: optimizer states add ~3x trainable param size
- [ ] Compare to available GPU memory; if tight, plan for QLoRA / sharded training

**Reference**: `references/memory-bottlenecks/rules.md`, `references/memory-bottlenecks/examples.md`

---

### Step 2: Choose Method and Precision

**Goal**: Pick the leanest method that fits your hardware.

| Hardware | Method |
|----------|--------|
| Plenty of GPU memory | Full FT (or LoRA for speed) |
| Tight GPU memory | LoRA |
| Very tight (1 GPU, 65B model) | QLoRA |
| Multi-node distributed | FSDP / DeepSpeed ZeRO |

- [ ] Pick precision: BF16 (preferred over FP16), FP32 master weights with mixed precision
- [ ] If quantizing for inference later: pick INT8 or INT4 (NF4 with QLoRA)
- [ ] If full finetuning: enable gradient checkpointing for memory savings

**Reference**: `references/memory-bottlenecks/patterns.md`

---

### Step 3: Choose Framework and Base Model

**Goal**: Pick tooling that matches your scale.

| Need | Framework |
|------|-----------|
| Single-node, fast iteration | Hugging Face Transformers + PEFT |
| Single-node, opinionated configs | Axolotl (YAML) |
| Single-node, fastest LoRA | Unsloth |
| Multi-node distributed | FSDP / DeepSpeed |
| Hosted | OpenAI / Together / Replicate FT API |

- [ ] Pick a base model: prefer instruct variant if FT-ing for chat; base if FT for raw completion
- [ ] Pin the base model version
- [ ] Verify license allows your use case

**Reference**: `references/finetuning-tactics/rules.md`, `references/finetuning-tactics/examples.md`

---

### Step 4: Configure LoRA (if PEFT)

**Goal**: Pick rank, alpha, and target modules.

- [ ] Target modules: at minimum Wq + Wv; preferably all 4 attention matrices; FFN if budget allows
- [ ] Rank: start with 8 (range 4-64)
- [ ] Alpha: typical alpha = 2 × rank (e.g., r=8, alpha=16); ratio in [1:8, 8:1]
- [ ] Dropout: 0.05-0.1
- [ ] Save adapter separately from base model for multi-LoRA serving

**Reference**: `references/peft-techniques/rules.md`, `references/peft-techniques/examples.md`

---

### Step 5: Set Hyperparameters

**Goal**: Pick learning rate, batch size, epochs.

| Method | LR Range |
|--------|----------|
| LoRA | 1e-4 to 5e-4 |
| Full FT | 1e-6 to 5e-5 |

- [ ] Effective batch size: `per_device × grad_accum × num_devices`
- [ ] Minimum effective batch size: 8 (per book guidance)
- [ ] Epochs: small dataset (~1K) → 3-5 epochs; medium (~10K) → 1-3; large (>100K) → 1
- [ ] Prompt loss weight: typical 10% (don't fully train on the prompt)
- [ ] Warmup: 5-10% of total steps

**Reference**: `references/finetuning-tactics/rules.md`

---

### Step 6: Format Training Data

**Goal**: Match training format to inference format exactly.

- [ ] Apply the model's chat template (HuggingFace `tokenizer.apply_chat_template`)
- [ ] Verify delimiters match what the model expects
- [ ] Verify no trailing spaces / extra prefixes
- [ ] Spot-check 5-10 formatted examples manually

**Reference**: `ai-dataset-engineering/references/data-processing/examples.md`

---

### Step 7: Smoke Test

**Goal**: Run a tiny training pass to catch bugs before committing budget.

- [ ] Run for 10-50 steps on a small subset
- [ ] Verify loss decreases (or at least doesn't NaN)
- [ ] Verify no OOM errors
- [ ] Verify checkpointing works (save and reload)
- [ ] Generate a sample from the partially-trained model — sanity check

**Reference**: `references/finetuning-tactics/checklist.md`

---

### Step 8: Full Training Run

**Goal**: Train and monitor.

- [ ] Launch the full run with logging (wandb, tensorboard)
- [ ] Monitor train loss and eval loss
- [ ] Watch for: loss spikes, eval loss diverging from train loss (overfit), NaN
- [ ] Save checkpoints periodically

**Reference**: `references/finetuning-tactics/examples.md` (loss diagnosis table)

---

### Step 9: Evaluate the Finetuned Model

**Goal**: Verify it actually improved over the base model.

- [ ] Run the eval set on the finetuned model
- [ ] Compare to base model on the same eval set
- [ ] Compare to base model + prompting / + RAG (was finetuning worth it?)
- [ ] Check for catastrophic forgetting on out-of-distribution tasks

**Reference**: `ai-evaluation/workflows/design-eval-pipeline.md`

---

## Quick Checklist

```
[ ] Step 1: Memory estimated, fits hardware
[ ] Step 2: Method + precision chosen
[ ] Step 3: Framework + base model picked
[ ] Step 4: LoRA configured (if PEFT)
[ ] Step 5: Hyperparameters set
[ ] Step 6: Training data formatted
[ ] Step 7: Smoke test passes
[ ] Step 8: Full training run completes
[ ] Step 9: Evaluation shows improvement
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Skipping smoke test | Day-long runs OOM | Run 10-50 steps first |
| LoRA on Wq only | Underperforms | Target Wq + Wv minimum |
| Inference format ≠ training format | Gibberish at inference | Use same chat template |
| Too many epochs on small data | Overfit | 3-5 epochs max for ~1K |
| Skipping eval-vs-base comparison | "We finetuned" but no improvement | Always compare |

---

## Exit Criteria

- [ ] Trained model passes eval at target quality
- [ ] Adapter / weights saved and version-tagged
- [ ] Inference path tested
- [ ] Results documented (config, metrics, baseline comparison)
