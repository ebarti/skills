# PEFT Techniques Knowledge

Core concepts for parameter-efficient finetuning (PEFT), with focus on LoRA and QLoRA.

## Overview

PEFT methods finetune large models with a tiny fraction of trainable parameters (often <1%) while approaching full-finetuning performance. They make finetuning accessible on consumer-grade hardware and require less data. LoRA dominates the field, with QLoRA extending it via quantization.

## Key Concepts

### Full Finetuning

**Definition**: Updating every parameter in the model, identical to training but starting from pretrained weights.

A 7B model in FP16 needs ~14 GB just for weights, plus ~42 GB for gradients and Adam optimizer states (3x weights at 2 bytes), totaling 56 GB before activations. This exceeds most consumer GPUs (12-48 GB).

### Partial Finetuning

**Definition**: Freezing most layers and updating only a subset (e.g., last layer only).

Reduces memory but is parameter-inefficient: BERT large needs ~25% of parameters updated to match full-finetuning quality on GLUE.

### PEFT (Parameter-Efficient Finetuning)

**Definition**: Family of techniques achieving near-full-finetuning performance with several orders of magnitude fewer trainable parameters.

**Key points**:
- Introduced by Houlsby et al. (2019) with adapter modules
- Original adapter method: 0.4% performance gap from full FT, 3% trainable params on GLUE
- Also sample-efficient: thousands of examples vs. millions for full FT
- Two main buckets: adapter-based (additive) and soft prompt-based

### Adapter-Based Methods

**Definition**: Add small trainable modules to model architecture; freeze original weights.

Examples: original Houlsby adapters, BitFit, IA3, LoRA, LongLoRA. Original adapters add inference latency due to extra layers.

### Soft Prompt-Based Methods

**Definition**: Inject continuous, trainable token vectors alongside input tokens.

Differ from hard prompts: continuous (not discrete tokens), trainable via backprop, not human-readable. Variants: prefix tuning (every transformer layer), prompt tuning (only embedded input), P-Tuning.

### LoRA (Low-Rank Adaptation)

**Definition**: Decomposes weight updates into the product of two low-rank matrices A and B that can be merged back into the original weights.

**Key points**:
- Hu et al. (2021) - dominant PEFT method today
- No inference latency when merged (unlike original adapters)
- For GPT-3, achieves comparable performance with ~4.7M trainable params (0.0027% of full FT)
- Built on low-rank factorization (lossy approximation)

### LoRA Math

For weight matrix W of dimension n x m:
1. Choose rank r; construct A (n x r) and B (r x m), so W_AB = A @ B has same shape as W
2. New weight: W' = W + (alpha / r) * W_AB
3. During finetuning, only A and B are updated; W stays frozen

### Why LoRA Works

LLMs have low **intrinsic dimension** despite many parameters. Pre-training implicitly compresses intrinsic dimension; larger/better-pretrained models need fewer trainable parameters during finetuning.

### QLoRA (Quantized LoRA)

**Definition**: LoRA variant that stores base model weights in 4-bit (NF4 format) and dequantizes to BF16 during forward/backward passes.

**Key points**:
- Dettmers et al. (2023)
- Uses NF4 (NormalFloat-4): exploits normal distribution of pretrained weights
- Paged optimizers offload between CPU/GPU on memory pressure
- Enables finetuning a 65B model on a single 48 GB GPU
- Tradeoff: slower training due to (de)quantization overhead

### Multi-LoRA Serving

**Definition**: Serving many LoRA adapters that share one base model.

Enables one adapter per task/customer with minimal storage overhead vs. storing full merged models.

## Terminology

| Term | Definition |
|------|------------|
| Rank (r) | Dimension of LoRA's low-rank factorization |
| Alpha (alpha) | Scaling factor controlling LoRA contribution: W' = W + (alpha/r) * W_AB |
| Adapter | Small trainable module inserted into a frozen base model |
| Soft prompt | Trainable continuous token vector prepended to input |
| Hard prompt | Standard discrete-token textual prompt |
| Intrinsic dimension | Effective dimensionality of a model's parameter space |
| NF4 | NormalFloat-4: 4-bit format optimized for normally-distributed weights |
| Wq, Wk, Wv, Wo | Attention's query, key, value, and output projection matrices |
| Multi-LoRA serving | Serving many LoRA adapters atop a single base model |

## How It Relates To

- **Full finetuning**: PEFT trades a small accuracy gap for massive memory/data savings
- **Quantization**: Composes with PEFT (QLoRA) to further cut memory
- **Prompt engineering**: Soft prompts are a learned generalization of hard prompts
- **Model merging**: LoRA adapters are easy to share, swap, and combine

## Common Misconceptions

- **Myth**: PEFT matches full finetuning in all cases.
  **Reality**: LoRA usually slightly underperforms full FT; choose based on budget and acceptable gap.

- **Myth**: Higher LoRA rank always helps.
  **Reality**: Beyond a small r (typically 4-64), quality plateaus; high r risks overfitting.

- **Myth**: All adapter methods add inference latency.
  **Reality**: LoRA can be merged into base weights, adding zero inference latency.

- **Myth**: QLoRA is always faster than LoRA.
  **Reality**: QLoRA uses less memory but is slower per step due to (de)quantization.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| PEFT | Finetune <1% of parameters, near full-FT quality |
| Adapter methods | Add small trainable modules to frozen base |
| Soft prompts | Trainable continuous tokens prepended to input |
| LoRA | Low-rank update W' = W + (alpha/r)(A @ B), mergeable, no inference cost |
| QLoRA | LoRA + 4-bit NF4 base weights + paged optimizers |
| Multi-LoRA serving | Many task adapters on one shared base model |
