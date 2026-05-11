# Memory Bottlenecks Knowledge

Core concepts for understanding why finetuning is memory-intensive and how to estimate hardware needs.

## Overview

Foundation models are bottlenecked by GPU memory for both inference and finetuning. Finetuning typically requires far more memory than inference because backpropagation stores gradients and optimizer states for every trainable parameter. Memory footprint depends on (1) parameter count, (2) trainable parameter count, and (3) numerical precision.

## Key Concepts

### Backpropagation

**Definition**: The mechanism used to train neural networks via two phases per training step.

- **Forward pass**: Compute output from input (the only pass at inference).
- **Backward pass**: Compute loss, then gradients (derivative of loss w.r.t. each trainable parameter), then update parameters via the optimizer.

Each trainable parameter requires one gradient value plus 0–2 optimizer state values, which is the root cause of training's memory overhead.

### Trainable vs Frozen Parameters

**Definition**: A *trainable parameter* updates during training; a *frozen parameter* does not.

- Pre-training: all parameters trainable.
- Inference: zero parameters trainable.
- Finetuning: some or all parameters trainable.
- Reducing trainable parameters is the core motivation for PEFT.

### Optimizers and State

| Optimizer | States per trainable param | Notes |
|-----------|----------------------------|-------|
| SGD (vanilla) | 0 | No state |
| SGD + momentum | 1 | One momentum value |
| Adam | 2 | First and second moments — most common for transformers |

### Activations and Gradient Checkpointing

Activations stored from the forward pass are needed to compute gradients. Activation memory grows with sequence length and batch size and can dwarf weight memory in large transformers. *Gradient checkpointing* (a.k.a. *activation recomputation*) trades compute for memory by recomputing activations during the backward pass instead of storing them.

### Numerical Representations

Bit width per value directly drives memory footprint. Each float format splits bits among sign, range (exponent), and precision (mantissa).

| Format | Bits | Bytes | Notes |
|--------|------|-------|-------|
| FP64 | 64 | 8 | Double precision; rare in NN |
| FP32 | 32 | 4 | Single precision; classic NN baseline |
| TF32 | 19 effective | — | NVIDIA GPU format |
| BF16 | 16 | 2 | Google/TPU; same range as FP32, less precision than FP16 |
| FP16 | 16 | 2 | Half precision; less range than BF16, more precision |
| FP8 | 8 | 1 | Minifloat |
| INT8 | 8 | 1 | Integer; common for inference quantization |
| FP4 | 4 | 0.5 | Minifloat |
| INT4 | 4 | 0.5 | QLoRA, edge inference |
| 1.58-bit | ~1.58 | ~0.2 | BitNet b1.58 |

**BF16 vs FP16**: BF16 has wider range, lower precision. FP16 has narrower range, higher precision. Loading a BF16-trained model as FP16 (or vice versa) can severely degrade quality (e.g., the Llama 2 BF16/FP16 confusion).

### Quantization

**Definition**: Converting model values from a higher-bit format to a lower-bit format.

- Strictly: only counts as quantization if target is integer; in practice the term covers any precision reduction.
- **Weight quantization**: more common; stable performance impact.
- **Activation quantization**: less common; harder to do safely.
- **PTQ (post-training quantization)**: most common; quantize after training is done.
- **QAT (quantization-aware training)**: simulate low-precision behavior during training so the model learns to perform well at low precision.

### Mixed Precision

Some operations run in higher precision (e.g., FP32 master weights) while others run in lower precision (e.g., FP16/BF16 forward, gradients). Frameworks expose *automatic mixed precision (AMP)* to handle this.

## Terminology

| Term | Definition |
|------|------------|
| Forward pass | Input → output computation |
| Backward pass | Compute gradients and update weights |
| Gradient | Derivative of loss w.r.t. parameter |
| Optimizer state | Per-parameter values stored by the optimizer (e.g., Adam moments) |
| Activations | Intermediate forward-pass outputs |
| PTQ | Post-training quantization |
| QAT | Quantization-aware training |
| AMP | Automatic mixed precision |
| Minifloat | Floats with very few bits (FP8, FP4) |

## How It Relates To

- **PEFT**: Reduces trainable parameters → reduces gradient/optimizer memory.
- **LoRA / QLoRA**: PEFT + quantization to fit large models on single consumer GPUs.
- **Inference optimization** (Chapter 9): Driven by the same memory math.

## Common Misconceptions

- **Myth**: "FP16 is always better than BF16 because it's more precise."
  **Reality**: BF16 has the same range as FP32, so it avoids overflow on large activations. Most modern LLMs train in BF16.

- **Myth**: "Inference and training memory are similar."
  **Reality**: Training can need 4–6× more memory due to gradients, optimizer states, and stored activations.

- **Myth**: "Quantization is free performance."
  **Reality**: Each precision conversion can change values; compounding changes can degrade quality, especially for activations and at very low bit widths.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Inference memory | ≈ N × M × 1.2 |
| Training memory | weights + activations + gradients + optimizer states |
| Adam overhead | 3 values per trainable param (1 gradient + 2 states) |
| FP32 / FP16 / INT8 / INT4 | 4 / 2 / 1 / 0.5 bytes per value |
| Lower precision | Smaller, faster, sometimes less accurate |
