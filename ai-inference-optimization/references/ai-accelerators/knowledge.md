# AI Accelerators Knowledge

Core concepts and foundational understanding for AI accelerator hardware.

## Overview

AI accelerators are chips designed to speed up AI workloads, dominated by GPUs but expanding to TPUs, NPUs, and inference-specialized hardware. The three characteristics that matter most when evaluating an accelerator are computational capabilities (FLOP/s), memory size and bandwidth, and power consumption.

## Key Concepts

### What's an Accelerator

**Definition**: A chip designed to accelerate a specific type of computational workload. An AI accelerator is designed for AI workloads.

**Key points**:
- GPUs (Graphics Processing Units) are the dominant AI accelerator; NVIDIA leads the market.
- CPUs have a few powerful cores (up to 64) optimized for high single-thread performance and sequential processes.
- GPUs have thousands of smaller cores optimized for parallel computation, ideal for matrix multiplication that powers ML workloads.
- Inference-specialized chips (Apple Neural Engine, AWS Inferentia, MTIA, Google Edge TPU, NVIDIA Jetson Xavier) optimize for lower precision and faster memory access rather than large memory capacity.
- Different chips have different compute primitives optimized for scalars, vectors, or tensors (e.g., TPUs are tensor-first; modern GPUs include tensor cores alongside vector units).

### Computational Capabilities (FLOP/s)

**Definition**: The peak number of floating-point operations per second a chip can perform, written as FLOPS or FLOP/s.

**Key points**:
- Real applications rarely hit peak FLOP/s; the ratio of actual to theoretical FLOP/s is the **utilization** metric.
- Lower numerical precision yields more FLOP/s (adding two 16-bit numbers requires roughly half the work of two 32-bit numbers).
- The exact ratio between precisions is not 2x because chip optimizations differ per format.
- **Sparsity** (skipping zero-valued operations) doubles effective throughput on chips that support it; vendor specs often quote "with sparsity" numbers.

### Memory Size and Bandwidth

**Definition**: The capacity of accelerator memory and the speed at which data moves from memory to compute cores.

**Key points**:
- GPUs need much higher memory bandwidth than CPUs to keep thousands of parallel cores fed.
- CPUs use **DDR SDRAM** (2D structure); high-end GPUs use **HBM** (High-Bandwidth Memory, 3D stacked) which is more expensive.
- Three-level memory hierarchy: CPU DRAM (slowest), GPU HBM (fast), GPU on-chip SRAM (fastest).
- Most GPU optimization work targets making the most of this memory hierarchy (e.g., FlashAttention).

### Power Consumption

**Definition**: The energy a chip draws to operate, driven by billions of transistors switching states.

**Key points**:
- A100 has 54B transistors; H100 has 80B transistors.
- An H100 running at peak for a year uses ~7,000 kWh (vs. 10,000 kWh for an average US household).
- Heat from compute requires cooling, which adds further electricity cost in data centers.
- Electricity is increasingly the bottleneck to scaling compute.

## Terminology

| Term | Definition |
|------|------------|
| FLOP/s (FLOPS) | Floating-point operations per second |
| Utilization | Actual FLOP/s divided by theoretical peak FLOP/s |
| Sparsity | Optimization that skips zero-valued multiplications |
| HBM | High-Bandwidth Memory; 3D-stacked GPU memory |
| DDR SDRAM | 2D CPU memory technology |
| SRAM | On-chip static RAM (L1/L2/L3 caches) |
| TDP | Thermal Design Power: max heat the cooling system must dissipate |
| Max Power Draw | Peak power the chip can pull under full load |
| CUDA | NVIDIA's GPU programming language |
| Triton | OpenAI's GPU programming language |
| ROCm | AMD's open-source CUDA alternative |
| Tensor Core | Compute unit specialized for matrix/tensor operations |

## Accelerator Categories

| Category | Examples | Optimized For |
|----------|----------|---------------|
| Datacenter training+inference | NVIDIA A100, H100; AMD MI300; Google TPU | Throughput, large memory |
| Datacenter inference-only | AWS Inferentia, MTIA, Groq LPU | Low precision, fast memory access |
| Edge inference | Google Edge TPU, NVIDIA Jetson Xavier | Power efficiency on devices |
| Consumer device | Apple Neural Engine | On-device inference |
| Architecture-specialized | Transformer-specific chips | One model family |

## Memory Hierarchy at a Glance

| Level | Bandwidth | Typical Size |
|-------|-----------|--------------|
| CPU DRAM | 25-50 GB/s | 16 GB - 1 TB+ |
| GPU HBM | 256 GB/s - 1.5 TB/s+ | 24 - 80 GB (consumer); 80-141 GB (datacenter) |
| GPU on-chip SRAM | >10 TB/s | <40 MB |

## How It Relates To

- **Inference Optimization**: Hardware characteristics dictate which model optimizations (quantization, batching, attention kernels) yield the biggest wins.
- **Numerical Precision**: Choice of FP32/BF16/FP16/FP8 directly trades accuracy for FLOP/s and memory.
- **Compute vs. Memory Bound**: The arithmetic intensity of a workload determines whether FLOP/s or HBM bandwidth is the actual ceiling.

## Common Misconceptions

- **Myth**: Higher peak FLOP/s always means faster inference.
  **Reality**: Most LLM decoding is memory-bandwidth-bound, so HBM bandwidth often dominates.
- **Myth**: TDP equals power consumption.
  **Reality**: TDP is a heat-dissipation rating; max power draw is roughly 1.1-1.5x TDP.
- **Myth**: Training and inference need the same hardware.
  **Reality**: Training emphasizes throughput and large memory; inference emphasizes latency and low precision, justifying inference-only chips.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| GPU vs CPU | Many small parallel cores vs few powerful sequential cores |
| FLOP/s | Peak compute throughput at a given precision |
| Sparsity | Doubles effective FLOP/s by skipping zeros |
| HBM | 3D stacked GPU memory, much faster than CPU DRAM |
| TDP | Cooling-system rating, ~70-90% of max power draw |
