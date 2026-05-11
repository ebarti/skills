# Model Architecture Examples

Concrete examples of architectures, model dimensions, scaling laws, and compute calculations.

## Llama Model Dimensions

Sizes for several Llama models, illustrating how dimensions scale with parameter count.

| Model | Transformer Blocks | Model Dim | Feedforward Dim | Vocab Size | Context Length |
|-------|--------------------|-----------|-----------------|------------|----------------|
| Llama 2-7B | 32 | 4,096 | 11,008 | 32K | 4K |
| Llama 2-13B | 40 | 5,120 | 13,824 | 32K | 4K |
| Llama 2-70B | 80 | 8,192 | 22,016 | 32K | 4K |
| Llama 3-7B | 32 | 4,096 | 14,336 | 128K | 128K |
| Llama 3-70B | 80 | 8,192 | 28,672 | 128K | 128K |
| Llama 3-405B | 126 | 16,384 | 53,248 | 128K | 128K |

Note: increasing context length impacts memory footprint but does not change parameter count.

## Multi-Head Attention Splits

For Llama 2-7B with model dimension 4,096 and 32 attention heads:

```python
model_dim = 4096
num_heads = 32
head_dim = model_dim // num_heads  # 128

# Each Q, K, V matrix: 4096 × 4096
# Each Q, K, V vector for one token: shape (4096,)
# Split per head: 32 vectors of dimension 128
```

## Attention Computation

```python
import torch
import torch.nn.functional as F

def attention(Q, K, V):
    """Q, K, V have shape (batch, seq_len, d)"""
    d = Q.size(-1)
    scores = (Q @ K.transpose(-2, -1)) / (d ** 0.5)
    weights = F.softmax(scores, dim=-1)
    return weights @ V
```

## Inference Memory Calculation

```python
def inference_memory_gb(num_params: int, bytes_per_param: int = 2) -> float:
    """Minimum GPU memory to hold model weights."""
    return (num_params * bytes_per_param) / 1e9

# 7B params at FP16 (2 bytes) -> 14 GB
print(inference_memory_gb(7_000_000_000))   # 14.0
# 175B params at FP16 -> 350 GB
print(inference_memory_gb(175_000_000_000)) # 350.0
```

## Chinchilla Scaling Law Applied

```python
def chinchilla_optimal_tokens(num_params: int) -> int:
    """Compute-optimal training token count: ~20 tokens per parameter."""
    return 20 * num_params

examples = [
    ("7B", 7_000_000_000),
    ("13B", 13_000_000_000),
    ("70B", 70_000_000_000),  # Chinchilla itself
    ("175B", 175_000_000_000),
]
for name, p in examples:
    t = chinchilla_optimal_tokens(p)
    print(f"{name}: {t/1e9:.0f}B tokens recommended")
# 7B:    140B tokens
# 13B:   260B tokens
# 70B:  1400B tokens
# 175B: 3500B tokens
```

## Models vs Their Training Tokens

Many large models from 2020–2022 were trained on too few tokens by Chinchilla's standard.

| Model | Parameters | Training Tokens | Tokens / Param |
|-------|-----------|-----------------|----------------|
| LaMDA | 137B | 168B | 1.2 (under-trained) |
| GPT-3 | 175B | 300B | 1.7 (under-trained) |
| Jurassic | 178B | 300B | 1.7 (under-trained) |
| Gopher | 280B | 300B | 1.1 (under-trained) |
| MT-NLG 530B | 530B | 270B | 0.5 (severely under-trained) |
| Chinchilla | 70B | 1.4T | 20 (optimal) |
| Llama 3 | 405B | 15T | 37 (over-trained for inference efficiency) |

## Computing Training Time and Cost

GPT-3-175B training: 3.14 × 10^23 FLOPs total.

```python
# Hardware: NVIDIA H100 NVL
flops_per_second = 6e13  # 60 TeraFLOP/s peak
seconds_per_day = 86400
flops_per_day = flops_per_second * seconds_per_day  # 5.2e18

num_gpus = 256
total_flops = 3.14e23
utilization = 0.7  # 70% is "great"

# At peak utilization
days_at_peak = total_flops / (num_gpus * flops_per_day)
print(f"At 100% utilization: {days_at_peak:.0f} days")  # ~236 days

# Realistic with 70% utilization
days_realistic = days_at_peak / utilization
hours = days_realistic * 24

# Cost at $2/hour per H100
cost_per_h100_hour = 2.0
total_cost = num_gpus * hours * cost_per_h100_hour
print(f"Estimated cost: ${total_cost:,.0f}")  # ~$4.1M
```

## Mixture-of-Experts Cost Calculation

```python
# Mixtral 8x7B
num_experts = 8
params_per_expert = 7_000_000_000
total_params = 46_700_000_000  # less than 8*7B due to shared params

active_experts_per_token = 2
active_params = active_experts_per_token * 7_000_000_000 - shared_overhead := 1_100_000_000
# ~12.9B active parameters per token

# Cost behaves like a 12.9B dense model, even though footprint is ~46.7B
print(f"Memory footprint: ~{total_params/1e9:.1f}B params")
print(f"Inference cost-equivalent: ~{12.9}B dense model")
```

## FLOP/s vs FLOPs Conversion

```python
# 1 FLOP/s-day = sustained 1 FLOP per second for 24 hours
flops_per_second = 1
seconds_in_day = 60 * 60 * 24
flop_per_s_day = flops_per_second * seconds_in_day
print(flop_per_s_day)  # 86400 FLOPs

# Convert: an H100 sustaining 60 TFLOP/s for 1 day
h100_flops_per_day = 6e13 * seconds_in_day
print(f"H100/day = {h100_flops_per_day:.2e} FLOPs")  # 5.18e18 FLOPs
```

## Activation Function Example

```python
def relu(x):
    """ReLU: convert negatives to 0."""
    return max(0, x)
# Used in many transformer MLPs; GPT-2 used GELU instead.
```
