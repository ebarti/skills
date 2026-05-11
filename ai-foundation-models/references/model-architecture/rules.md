# Model Architecture Rules

Guidelines for choosing and sizing foundation models.

## Core Rules

### 1. Default to Transformer Architecture

For language-based foundation models, transformer is the dominant and best-supported choice as of writing.

- Heavily optimized hardware/software stack since 2017
- Massive ecosystem (kernels, inference frameworks, fine-tuning libraries)
- Only consider alternatives when their advantage materially matters for your use case

### 2. Pick Architecture Based on the Bottleneck You Care About

Different architectures address different limitations.

- **Long context (>128K tokens)**: consider SSMs (Mamba) or hybrids (Jamba)
- **Memory-efficient long sequences**: Mamba scales linearly with sequence length; transformers scale quadratically
- **No context limit in theory**: RWKV (RNN-based, parallelizable for training)
- **Standard NLP at scale on common hardware**: stick with transformer

### 3. Use the Chinchilla Ratio (≈20 Tokens per Parameter)

For compute-optimal training of dense language models on human-generated data:

- Training tokens ≈ 20 × parameter count
- 7B model → 140B training tokens
- 13B model → 260B training tokens
- 70B model → 1.4T training tokens (matches Chinchilla)
- Doubling model size requires doubling training tokens

**Example**:
```python
# Compute-optimal token budget for a target model size
def chinchilla_tokens(num_params: int) -> int:
    return 20 * num_params

# 3B-param model needs ~60B tokens
target_tokens = chinchilla_tokens(3_000_000_000)  # 60_000_000_000
```

### 4. Estimate Inference Memory From Parameter Count

Quick rule: GPU memory ≥ params × bytes-per-param.

- FP16/BF16 (2 bytes): 7B model needs ≥14 GB just to hold weights
- INT8 (1 byte): 7B model needs ≥7 GB
- INT4 (~0.5 bytes): 7B model needs ≥3.5 GB
- Add overhead for KV cache, activations, framework

### 5. For MoE/Sparse Models, Use Active Parameters for Cost

The total parameter count overstates the inference cost.

- Mixtral 8x7B: 46.7B total, ~12.9B active per token → costs ≈ a 12.9B dense model
- Use active params for latency/throughput estimates
- Use total params for memory footprint estimates

### 6. Optimize Prefill and Decode Separately

Transformer inference has two distinct phases with different characteristics.

- **Prefill** (parallel): compute-bound; optimize via batching, FlashAttention
- **Decode** (sequential): memory-bandwidth-bound; optimize via KV cache, speculative decoding, smaller models

### 7. Pick Smaller Models for Production Usability

Compute-optimal does not equal production-optimal.

- Llama deliberately uses smaller models than Chinchilla suggests because smaller = easier to deploy, cheaper to serve
- For long-running services, factor inference cost over the model's lifetime, not just training cost
- See Sardana et al. (2023) for inference-aware scaling laws

## Guidelines

- Newer-generation small models often beat older-generation large ones — always benchmark against the latest models of the size you can afford
- The cost of reaching a fixed performance level halves roughly every couple of years; defer training/buying until you actually need it
- Improving from 90% to 95% accuracy can cost 10x more than 85% to 90% — avoid over-targeting metrics
- Treat parameter count as a proxy for capacity, not a guarantee of capability

## Exceptions

When core rules may be relaxed:

- **Inference-heavy workloads**: train smaller, longer than Chinchilla suggests (Llama strategy) to cut serving cost
- **Synthetic-data-heavy training**: Chinchilla ratio was derived for human-generated data; sparse models and synthetic data may require different ratios (active research)
- **Specialized long-context applications**: justify Mamba/Jamba over transformer when sequence length exceeds 128K and quadratic attention cost dominates

## Scaling Bottlenecks: When to Worry

Two visible ceilings to indefinite scaling:

- **Training data**: high-quality public internet data is being exhausted; growth in dataset size outpaces new content. Proprietary data is becoming a competitive moat.
- **Electricity**: data centers already consume 1–2% of global electricity, projected up to 4–20% by 2030. Power supply caps further scaling at roughly 50× current usage.

If your plan depends on a future 10× larger model existing, account for these bottlenecks.

## Quick Reference

| Rule | Summary |
|------|---------|
| Default architecture | Use transformer for language models |
| Chinchilla ratio | 20 training tokens per parameter |
| Memory estimate | bytes_per_param × params (FP16 = 2) |
| MoE cost | Use active params, not total |
| Production sizing | Trade compute-optimal for inference-optimal |
| Prefill vs decode | Optimize as separate workloads |
| Generation matters | Newer small > older large |
