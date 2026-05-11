# PEFT Techniques Rules

Guidelines for choosing PEFT vs full finetuning, configuring LoRA, and using QLoRA.

## Core Rules

### 1. Default to PEFT (LoRA) over full finetuning

Use PEFT when memory, data, or budget are constrained, which is most real-world cases.

- A 7B model needs ~56 GB for full FT (FP16 + Adam) but fits LoRA on a single consumer GPU
- LoRA is also sample-efficient: works with thousands (not millions) of examples
- Only choose full FT if you have abundant compute AND need the last few percentage points of quality

### 2. Use LoRA as the default PEFT method

LoRA dominates PEFT usage and has the best tooling.

- Mergeable into base weights -> zero inference latency
- Strong support in Hugging Face PEFT, Axolotl, unsloth, LitGPT
- Reuse community-published adapters from Hugging Face / AdapterHub

### 3. Apply LoRA to attention matrices first

For transformer models, prioritize the attention projections.

- LoRA targets: Wq, Wk, Wv, Wo
- If budget forces just two: pick **Wq and Wv** (best two-matrix combo per LoRA paper)
- All four matrices at low rank often beats two matrices at higher rank
- Apply LoRA uniformly to all matrices of a given type across layers

### 4. Start with rank r in [4, 64]

A small rank usually suffices.

- Common defaults: r = 8 or r = 16
- Increasing r beyond a point yields no quality gain and may overfit
- Some tasks need higher r (Raschka observed r = 256 on certain tasks); test if quality plateaus too early

### 5. Set alpha relative to rank

The scaling factor alpha controls LoRA's contribution: W' = W + (alpha/r) * W_AB.

- Keep alpha:r ratio between 1:8 and 8:1
- Common starting point: alpha = 2 * r (e.g., r = 8, alpha = 16) or alpha = r
- If r is small, prefer larger alpha; if r is large, prefer smaller alpha
- Always verify empirically per task

### 6. Use QLoRA when memory is the bottleneck

QLoRA quantizes the base model to 4-bit NF4, dequantizing during compute.

- Use when the base model alone won't fit (e.g., 65B on a single 48 GB GPU)
- Accept slower training in exchange for fitting bigger models
- Pair with paged optimizers for long context lengths

### 7. Choose serving strategy by adapter count

Two options: merge weights pre-serving, or keep adapters separate at runtime.

- **One model only**: merge LoRA into W -> no extra latency, no extra storage logic
- **Multi-tenant / multi-task**: keep adapters separate -> small per-adapter storage, fast task switching, accept small inference overhead

## Guidelines

- Try feedforward-layer LoRA in addition to attention; Databricks reported the biggest boost from FFN layers
- Quantize base model + LoRA when targeting on-device deployment (Apple did this on iPhone)
- Prefer existing PEFT framework (Hugging Face PEFT, Axolotl, unsloth) over hand-rolling LoRA
- Do an alpha/r grid sweep early; the optimum is task-dependent
- Track trainable-parameter count explicitly (frameworks usually print it on setup)

## Exceptions

When these rules may be relaxed:

- **Highest-quality requirement**: full FT may be worth it if you have the compute and the last 1-2% matters
- **Very small base models**: full FT is cheap enough that PEFT adds little value
- **Unsupported architecture**: PEFT frameworks ship great support for popular models; obscure architectures may require hand-implementing LoRA layers
- **Pretraining**: low-rank pretraining (ReLoRA, GaLore) only works at small/medium scale; do NOT use LoRA for pretraining a large model from scratch

## Quick Reference

| Rule | Summary |
|------|---------|
| Default method | LoRA via Hugging Face PEFT or unsloth |
| Where to apply LoRA | All attention matrices (Wq, Wk, Wv, Wo); add FFN if budget allows |
| Two-matrix budget | Wq and Wv |
| Starting rank | r = 8 or 16; sweep [4, 64] |
| Alpha | Often 2*r; keep alpha:r in [1:8, 8:1] |
| When to QLoRA | Base model doesn't fit in GPU memory |
| Serving (one model) | Merge adapter into base |
| Serving (many tasks) | Keep adapters separate (multi-LoRA) |
