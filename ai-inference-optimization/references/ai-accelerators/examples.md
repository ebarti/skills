# AI Accelerator Examples

Concrete spec comparisons and sizing examples for common accelerators and model sizes.

## NVIDIA H100 SXM Compute Throughput

From the H100 datasheet (with 2:4 sparsity):

| Numerical precision | teraFLOP/s with sparsity |
|---------------------|--------------------------|
| TF32 Tensor Core (19-bit) | 989 |
| BFLOAT16 Tensor Core | 1,979 |
| FP16 Tensor Core | 1,979 |
| FP8 Tensor Core | 3,958 |

Without sparsity, halve each number. Note that lower precision gives near-linear FLOP/s scaling (FP16 -> FP8 doubles throughput).

## A100 vs H100 vs Google TPU v4

| Spec | NVIDIA A100 80 GB SXM | NVIDIA H100 80 GB SXM | Google TPU v4 |
|------|-----------------------|-----------------------|---------------|
| Transistors | 54 B | 80 B | n/a (chiplet) |
| HBM capacity | 80 GB HBM2e | 80 GB HBM3 | 32 GB HBM |
| HBM bandwidth | ~2.0 TB/s | ~3.35 TB/s | ~1.2 TB/s |
| Peak FP16/BF16 (with sparsity) | 624 TFLOP/s | 1,979 TFLOP/s | 275 TFLOP/s (BF16) |
| Peak FP8 (with sparsity) | n/a (no FP8) | 3,958 TFLOP/s | n/a |
| TDP | 400 W | 700 W | 192 W (per chip) |
| Primary use | Training + inference | Training + inference; LLM serving | Training + inference (Google Cloud) |

Takeaways:
- H100 roughly 3x A100 on FP16 FLOP/s and 1.7x on HBM bandwidth.
- H100 introduces FP8 tensor cores, doubling throughput vs. FP16 again.
- TPU v4 has lower per-chip headline numbers but is designed to be deployed in large pods (4,096 chips).

## Memory Sizing for Common Model Sizes

Rough working set in HBM at FP16 (2 bytes per parameter, weights only):

| Model size | FP16 weights | INT8 weights | INT4 weights | Smallest single GPU |
|------------|--------------|--------------|--------------|---------------------|
| 7 B | 14 GB | 7 GB | 3.5 GB | RTX 4090 24 GB |
| 13 B | 26 GB | 13 GB | 6.5 GB | A100 40 GB |
| 34 B | 68 GB | 34 GB | 17 GB | A100 80 GB |
| 70 B | 140 GB | 70 GB | 35 GB | 2x A100/H100 80 GB or 1x MI300X 192 GB |
| 175 B (GPT-3) | 350 GB | 175 GB | 87 GB | 4x H100 80 GB or 2x H200 141 GB |
| 405 B | 810 GB | 405 GB | 202 GB | 8x H100 80 GB minimum |

Reserve 20-40% additional HBM for KV cache and activations during inference.

## KV Cache Size Example

KV cache per request (FP16):
`2 (K and V) x num_layers x hidden_dim x seq_len x 2 bytes`

Llama-2 70B with seq_len = 4,096:
- num_layers = 80, hidden_dim = 8,192
- KV per request = 2 x 80 x 8,192 x 4,096 x 2 bytes ~ 10.7 GB per request

Implication: serving 8 concurrent requests needs ~85 GB of KV cache alone, on top of 140 GB of FP16 weights. Quantizing weights to INT4 (~35 GB) makes room.

## Bandwidth-Bound Decoding Example (Python sketch)

```python
# Estimate decode latency from HBM bandwidth, not FLOP/s.
def decode_latency_per_token(model_bytes: float, hbm_bandwidth_bytes_per_s: float) -> float:
    """Return seconds per token assuming weights are loaded once per token."""
    return model_bytes / hbm_bandwidth_bytes_per_s

# Llama-2 70B, FP16 -> 140 GB
model_bytes = 140 * 1024**3

a100_bw = 2.0 * 1024**3 * 1024  # 2.0 TB/s
h100_bw = 3.35 * 1024**3 * 1024  # 3.35 TB/s

a100_latency = decode_latency_per_token(model_bytes, a100_bw)
h100_latency = decode_latency_per_token(model_bytes, h100_bw)

print(f"A100 lower bound: {1/a100_latency:.1f} tok/s")
print(f"H100 lower bound: {1/h100_latency:.1f} tok/s")
# Speedup roughly tracks HBM bandwidth ratio (~1.7x), not FLOP/s ratio (~3x).
```

## Compute-Bound Prefill Example (Python sketch)

```python
# Prefill throughput is gated by FLOP/s, not bandwidth.
def prefill_time(num_tokens: int, model_params: int, peak_flops: float) -> float:
    """Approximate prefill time using ~2 FLOPs per parameter per token."""
    flops_required = 2 * model_params * num_tokens
    return flops_required / peak_flops

params_70b = 70e9
prompt_tokens = 4096

a100_fp16 = 624e12   # 624 TFLOP/s with sparsity
h100_fp16 = 1979e12  # 1,979 TFLOP/s with sparsity
h100_fp8 = 3958e12   # 3,958 TFLOP/s with sparsity

print(f"A100 FP16 prefill: {prefill_time(prompt_tokens, params_70b, a100_fp16):.2f}s")
print(f"H100 FP16 prefill: {prefill_time(prompt_tokens, params_70b, h100_fp16):.2f}s")
print(f"H100 FP8  prefill: {prefill_time(prompt_tokens, params_70b, h100_fp8):.2f}s")
# Here FLOP/s ratio matters: H100 ~ 3x A100; FP8 doubles again.
```

## Inference-Specialized Chips

| Chip | Role | Notable Trait |
|------|------|---------------|
| AWS Inferentia2 | Datacenter inference | Lower $/inference vs. GPUs for many transformer models |
| Google TPU v5e | Datacenter inference | Optimized for cost-per-inference |
| Groq LPU | Datacenter inference | Deterministic latency, very high tokens/sec |
| MTIA (Meta) | Internal inference | Custom for Meta's recommendation/LLM stack |
| Apple Neural Engine | On-device inference | INT8/FP16 on iPhone/Mac silicon |
| Google Edge TPU | Edge inference | INT8 only, very low TDP (~2 W) |
| NVIDIA Jetson Xavier | Edge inference | GPU + ARM CPU on a power-constrained module |

## Power and Energy Example

H100 running at peak (700 W TDP, max draw ~ 1.1-1.5x TDP -> ~770-1,050 W) for a year:

```python
peak_power_w = 700  # use TDP as conservative baseline
hours_per_year = 24 * 365
annual_kwh = peak_power_w * hours_per_year / 1000
print(f"H100 annual energy at TDP: {annual_kwh:.0f} kWh")  # ~6,132 kWh
# Book quotes ~7,000 kWh at peak; the gap is real-world max draw > TDP.
# Compare with average US household: 10,000 kWh/year.
```

## Decision Walkthrough: 70B LLM Serving

Scenario: serve a 70B parameter model with low latency for chat.

**Step 1: Memory check.**
- FP16 weights = 140 GB. Single 80 GB GPU is insufficient.
- Options: 2x A100/H100 80 GB with tensor parallelism, or 1x MI300X 192 GB, or quantize.

**Step 2: Bandwidth check (decoding is memory-bound).**
- A100: 2.0 TB/s -> ~14 tok/s lower bound per stream.
- H100: 3.35 TB/s -> ~24 tok/s lower bound per stream.
- INT4 quantization (~35 GB) drops working set ~4x, lifting the bandwidth ceiling proportionally.

**Step 3: FLOP/s check (only matters for prefill / large batches).**
- Long prompts make prefill compute-bound; H100's 3x FLOP/s advantage helps here.

**Step 4: Cost check.**
- Cloud H100 ~ 2-3x A100 hourly rate; if your workload is bandwidth-bound, the speedup justifies it. If you batch heavily and are compute-bound, the gap is even larger in H100's favor.

**Conclusion**: H100 (or H200) for chat serving; A100 80 GB if budget-constrained and quantization is acceptable.
