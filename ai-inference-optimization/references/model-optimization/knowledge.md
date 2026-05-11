# Model Optimization Knowledge

Core concepts for optimizing transformer-based foundation models at the model level.

## Overview

Model-level optimization makes models more efficient by modifying the model itself, which can alter behavior. Three characteristics of transformer models make inference resource-intensive: model size, autoregressive decoding, and the attention mechanism. Each requires different optimization techniques.

## Key Concepts

### Model Compression

**Definition**: Techniques that reduce a model's size; smaller models are typically faster.

**Three main approaches**:
- **Quantization**: Reduce numerical precision (e.g., FP32 -> FP16 -> INT8 -> INT4). Halving precision halves memory footprint. Most popular due to ease of use.
- **Distillation**: Train a small model to mimic the behavior of a large one.
- **Pruning**: Remove nodes (architecture change) OR set least-useful parameters to zero (sparse model).

**Practical reality**: Weight-only quantization dominates production. Pruning is harder to implement, requires architecture knowledge, and not all hardware exploits sparsity.

### Autoregressive Decoding Bottleneck

**Definition**: Tokens generated one at a time, sequentially. A 100-token response at 100ms/token takes 10 seconds.

**Why it's expensive**: Output tokens cost 2-4x input tokens via APIs. One output token can equal 100 input tokens in latency impact.

**Three solution families**:
- **Speculative decoding**: Draft model proposes K tokens, target model verifies in parallel.
- **Inference with reference**: Copy draft tokens directly from input context (no draft model needed).
- **Parallel decoding**: Break sequential dependency, generate multiple tokens simultaneously (Lookahead, Medusa).

### Attention Mechanism Optimization

**Definition**: The attention mechanism's computation grows quadratically with sequence length; KV cache grows linearly but can dominate memory.

**KV cache**: Storage of key/value vectors from previous tokens to avoid recomputation. Used only at inference, not training.

**Three optimization buckets**:
- **Redesign attention**: Local windowed attention, multi-query attention (MQA), grouped-query attention (GQA), cross-layer attention. Applied at training/finetuning time.
- **Optimize KV cache**: PagedAttention (vLLM), KV cache quantization, adaptive compression.
- **Custom kernels**: FlashAttention fuses operations for hardware-specific speedup.

### Kernels and Compilers

**Kernels**: Hardware-specific optimized code for repetitive computations (matmul, attention, convolution). Written in CUDA (NVIDIA), Triton (OpenAI), or ROCm (AMD).

**Compilers**: Tools that "lower" model code to hardware-compatible instructions, swapping in specialized kernels where possible.

**Four core kernel techniques**:
- **Vectorization**: Process multiple contiguous data elements per cycle.
- **Parallelization**: Split work across cores/threads.
- **Loop tiling**: Reorder data access for cache/memory hierarchy (hardware-specific).
- **Operator fusion**: Combine multiple ops into one pass to reduce memory I/O.

## Terminology

| Term | Definition |
|------|------------|
| Quantization | Reducing numerical precision of weights/activations |
| Distillation | Training small model to mimic large model |
| Pruning | Removing/zeroing parameters to reduce size or sparsify |
| Speculative decoding | Draft-then-verify decoding using a faster model |
| KV cache | Cached key/value vectors from previous tokens |
| MQA | Multi-query attention; shares KV across query heads |
| GQA | Grouped-query attention; KV shared per query group |
| PagedAttention | KV cache divided into non-contiguous blocks |
| FlashAttention | Hardware-fused attention kernel |
| Kernel | Hardware-optimized computation routine |
| Lowering | Compiling model code for specific hardware |
| Operator fusion | Combining ops into single pass to cut memory I/O |

## How It Relates To

- **Inference fundamentals**: Decoding bottlenecks dominate latency; KV cache dominates memory.
- **AI accelerators**: Kernels are written specifically for accelerator memory hierarchies.
- **Service optimization**: Model optimization combines with batching and caching at the service layer.

## Common Misconceptions

- **Myth**: Pruning is widely used because research papers show 90%+ parameter reduction.
  **Reality**: Pruning is uncommon in production; harder to apply, smaller speedup than alternatives, and sparsity isn't always hardware-friendly.

- **Myth**: KV cache is a tiny memory cost.
  **Reality**: For a 500B model with batch 512 and 2K context, KV cache totals 3TB - 3x the model weights.

- **Myth**: Speculative decoding sacrifices output quality.
  **Reality**: It's lossless - the target model verifies every accepted token, so quality matches direct generation.

- **Myth**: Custom kernels are needed everywhere.
  **Reality**: Most engineers should use existing kernels (FlashAttention, vLLM); writing custom kernels requires CUDA-level expertise.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Quantization | Easiest, most effective compression; FP16/INT8/INT4 standard |
| Distillation | Train small model to copy big model's behavior |
| Pruning | Remove or zero parameters; rarely used in production |
| Speculative decoding | Draft model proposes, target model verifies in parallel |
| Inference with reference | Copy tokens from input context as draft tokens |
| Parallel decoding | Generate multiple future tokens at once (Medusa, Lookahead) |
| MQA / GQA | Reduce KV cache by sharing keys/values across heads |
| PagedAttention | Block-based KV cache memory management (vLLM) |
| FlashAttention | Fused attention kernel; major throughput boost |
| torch.compile | Compiler that turns PyTorch ops into efficient kernels |
