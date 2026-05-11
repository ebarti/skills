# AI Accelerator Selection Rules

Guidelines for choosing accelerators based on workload, memory profile, and power/cost constraints.

## Core Rules

### 1. Match the Accelerator to the Workload Type

Pick hardware based on whether your workload is compute-bound or memory-bound, not on headline specs.

- **Compute-bound** (large batches, training, prefill of long prompts): prioritize FLOP/s.
- **Memory-bound** (single-stream LLM decoding, small batch inference): prioritize HBM bandwidth and capacity.
- **Latency-sensitive** (interactive serving): prefer inference-optimized chips (Inferentia, Groq LPU, Edge TPU) over training-class GPUs.
- **Throughput-sensitive** (offline batch jobs): training-class GPUs (A100, H100, TPU v4/v5) are usually the best fit.

### 2. Answer the Three Buying Questions

Before purchasing or renting, evaluate every candidate chip against:

1. **Can the hardware run your workload?** (Does the model fit in memory at the precision you need?)
2. **How long does it take?** (Use FLOP/s and bandwidth to estimate latency and throughput.)
3. **How much does it cost?** (Cloud usage rates are similar across providers; for owned hardware, factor in upfront price plus ongoing power.)

### 3. Use the Lowest Numerical Precision Your Accuracy Tolerates

Lower precision increases FLOP/s and reduces memory pressure simultaneously.

- Train: BF16 / TF32 typical, FP8 emerging.
- Inference: FP16, FP8, INT8, or INT4 depending on quality budget.
- Always benchmark accuracy after dropping precision; not all chips support every format with the same quality.

### 4. Account for Sparsity Specs Carefully

Vendor-published "with sparsity" FLOP/s assume your model exploits 2:4 structured sparsity. Without that, halve the number.

- Verify your model and framework actually trigger the sparse path before budgeting around the headline figure.

### 5. Treat HBM Capacity as a Hard Gate

A model that does not fit in HBM either cannot run or must be offloaded, which collapses throughput.

- Required HBM per model (FP16): roughly `2 bytes x parameters` plus KV cache (`2 x layers x hidden x seq_len x batch x bytes_per_element`).
- 7B model in FP16: ~14 GB weights -> fits on a 24 GB consumer GPU.
- 70B model in FP16: ~140 GB weights -> needs multi-GPU (e.g., 2x H100 80 GB) or quantization.
- Always reserve headroom for KV cache and activations.

### 6. Budget Power Realistically

- Use **max power draw** for electrical/PSU sizing.
- Use **TDP** for thermal/cooling design.
- Approximation: max power draw ~ 1.1-1.5x TDP (varies by architecture and workload).
- For owned hardware, annual energy cost can rival the depreciated chip cost.

## Guidelines

When in doubt:

- Datacenter LLM serving at scale: H100 (or H200/B100 if available) for the bandwidth and FP8 throughput.
- Cost-sensitive serving at small/medium scale: A100 80 GB or AMD MI300X.
- Edge / on-device: Apple Neural Engine, Edge TPU, or Jetson; design around their precision and memory limits.
- Need vendor-locked optimizations: NVIDIA + CUDA still has the deepest ecosystem; AMD ROCm and Triton are catching up but require more engineering effort.
- Use cloud first if the workload may shift; buy hardware only when steady-state utilization is high enough to amortize the capex.

## Exceptions

- **Multi-modal or vision workloads**: image and video pipelines may rebalance toward FLOP/s even at small batch sizes, so the "decoding is memory-bound" rule does not apply blindly.
- **Mixture-of-experts models**: effective active parameters are smaller than total, so memory bandwidth still dominates but capacity must hold the full expert pool.
- **Speculative decoding / draft models**: change the compute/memory ratio; revisit hardware choice when adopting them.

## When Memory Bandwidth Matters More Than FLOP/s

Memory bandwidth dominates when arithmetic intensity (FLOPs per byte loaded) is low.

- Single-batch autoregressive decoding: each token requires loading the full weights from HBM.
- Long-context inference with large KV caches.
- Models that don't fit in cache, forcing repeated HBM reads.

In these cases, an H100 (3.35 TB/s HBM3) outperforms an A100 (2 TB/s HBM2e) by close to the bandwidth ratio, regardless of the bigger FLOP/s gap.

## When FLOP/s Matters More Than Bandwidth

FLOP/s dominates when arithmetic intensity is high.

- Training with large batches.
- Prefill (processing the full input prompt) before token generation.
- Convolutional or vision-transformer workloads with substantial reuse of loaded weights.

## Power and Cost Considerations

- **Cloud pricing** is mostly usage-based and similar across hyperscalers; pick on availability, region, and supported instance types.
- **Owned hardware total cost**: chip price + power + cooling + networking + opportunity cost of underutilization.
- An H100 at full utilization for a year ~ 7,000 kWh; multiply by your local $/kWh for a baseline.
- Cooling overhead in data centers (PUE) typically adds 20-50% on top of chip energy.
- Greener regions (hydro, nuclear) lower environmental impact for the same workload.

## Quick Reference

| Rule | Summary |
|------|---------|
| Match to workload | Compute-bound -> FLOP/s; memory-bound -> bandwidth |
| Three questions | Can it run? How fast? At what cost? |
| Drop precision | Use lowest precision quality tolerates |
| Verify sparsity | Headline FLOP/s often assume 2:4 sparsity |
| HBM capacity gates | Model + KV cache must fit, with headroom |
| Power planning | Max draw ~ 1.1-1.5x TDP |
