# Model Architecture Patterns

Reusable patterns for choosing and sizing foundation models based on resources and use case.

## Pattern: Compute-Budget-First Sizing

### Intent

Pick model size and training tokens given a fixed compute (FLOPs) budget.

### When to Use

- You have a hard cap on training compute (cost or hardware)
- Building a new pretrained model from scratch
- Optimizing for model quality given budget constraints

### Structure

```python
def compute_optimal_split(flop_budget: float):
    """
    Chinchilla rule: tokens = 20 * params, training FLOPs ~ 6 * params * tokens.
    Solve for params and tokens given FLOP budget.
    """
    # 6 * P * (20*P) = budget  ->  P = sqrt(budget / 120)
    params = (flop_budget / 120) ** 0.5
    tokens = 20 * params
    return int(params), int(tokens)
```

### Example

```python
# 1e22 FLOP budget (similar to a small Chinchilla-class run)
p, t = compute_optimal_split(1e22)
print(f"Optimal: ~{p/1e9:.1f}B params, ~{t/1e9:.0f}B tokens")
```

### Benefits

- Predicts loss curves before committing compute
- Avoids over-sizing (under-trained) or under-sizing (under-utilized) models

### Considerations

- Assumes data is plentiful and cheap relative to compute
- Derived for dense models on human-generated data — adjust for MoE/synthetic data

---

## Pattern: Inference-Aware Sizing (Llama Strategy)

### Intent

Pick a smaller-than-Chinchilla model trained for longer, to lower inference cost over the model's lifetime.

### When to Use

- Model will be served at high QPS or for long periods
- Inference cost dominates total cost of ownership
- Deployment hardware has limited memory (single-GPU constraints)

### Structure

```python
def inference_aware_sizing(flop_budget, expected_inference_tokens):
    """
    Trade off training cost vs lifetime inference cost.
    More inference -> smaller model + more training tokens.
    See Sardana et al. (2023) for the formal Modified Chinchilla rule.
    """
    # Heuristic: use less than the compute-optimal model size
    p_optimal, _ = compute_optimal_split(flop_budget)
    if expected_inference_tokens > 1e12:  # > 1T inference tokens
        p_target = p_optimal * 0.5  # smaller model
    else:
        p_target = p_optimal
    tokens = (flop_budget / (6 * p_target))
    return int(p_target), int(tokens)
```

### Example

Llama 3-8B was trained on 15T tokens — far above Chinchilla's recommendation (160B) — because Meta wanted a small model that performs well in high-volume inference.

### Benefits

- Lower per-query latency and cost
- Easier to fit on commodity GPUs
- Wider community adoption

### Considerations

- Higher up-front training cost
- Eventually hits diminishing returns from over-training

---

## Pattern: Memory-First Architecture Choice

### Intent

Pick architecture and quantization based on available GPU memory.

### When to Use

- Deploying on fixed hardware (single GPU, edge device)
- Choosing between dense, MoE, and alternative architectures

### Structure

```python
def fits_on_gpu(num_params, bytes_per_param, gpu_memory_gb, overhead_factor=1.4):
    """Check if model fits with KV cache and activation overhead."""
    weight_gb = (num_params * bytes_per_param) / 1e9
    return weight_gb * overhead_factor <= gpu_memory_gb
```

### Example

```python
gpu_memory = 80  # H100 80GB

# Dense 70B FP16: 140 GB * 1.4 = 196 GB -> won't fit
print(fits_on_gpu(70e9, 2, gpu_memory))  # False

# Dense 70B INT4: 35 GB * 1.4 = 49 GB -> fits
print(fits_on_gpu(70e9, 0.5, gpu_memory))  # True

# Jamba MoE: 52B total but designed to fit in 80 GB
```

### Benefits

- Avoids out-of-memory failures
- Forces explicit quantization/sparsity decisions

### Considerations

- KV cache scales with batch size and context length — overhead factor may need bumping for long contexts

---

## Pattern: Long-Context-First Architecture

### Intent

Choose an architecture suited to long sequences when transformer quadratic scaling becomes prohibitive.

### When to Use

- Typical sequence length > 100K tokens
- Memory-constrained environments serving long contexts
- Streaming or document-scale inputs

### Structure

| Sequence Length | Recommended Architecture |
|-----------------|--------------------------|
| < 8K | Transformer |
| 8K – 128K | Transformer with FlashAttention / KV-cache optimizations |
| 128K – 1M | Transformer + extensions, or Jamba (transformer + Mamba hybrid) |
| > 1M | Mamba or other SSM |

### Benefits

- Mamba scales linearly in sequence length vs quadratic for transformer
- Hybrids like Jamba combine attention quality with SSM efficiency

### Considerations

- Smaller ecosystem and tooling outside transformer
- Long-range performance still benchmark-dependent

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|---------------------|
| Building a new pretrained model from scratch | Compute-Budget-First Sizing |
| High-volume production serving | Inference-Aware Sizing |
| Fixed-hardware deployment | Memory-First Architecture Choice |
| Document/long-context workloads | Long-Context-First Architecture |
| Hard cap on parameters but flexible compute | Train longer than Chinchilla suggests |
| Training data is the bottleneck, compute cheap | Use larger model, accept under-training |
