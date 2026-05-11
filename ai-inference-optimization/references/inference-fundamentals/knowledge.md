# Inference Fundamentals Knowledge

Core concepts for understanding AI inference: the workload, its bottlenecks, the API patterns that serve it, and the metrics that measure it.

## Overview

Inference is the process of using a trained model to compute outputs for given inputs. Optimizing inference means making models faster and cheaper without sacrificing quality. To optimize anything, you must first understand its bottlenecks (compute vs memory bandwidth) and measure its behavior with the right metrics (latency, throughput, utilization).

## Key Concepts

### Inference Server vs Inference Service

**Definition**: The inference server runs the model on hardware and returns predictions. The inference service is the broader system that receives, routes, and preprocesses requests before they reach the server.

**Key points**:
- Model APIs (OpenAI, Google) are inference services - you don't operate them.
- Self-hosting open source models means you own the inference service.

### Computational Bottlenecks

Every inference workload is gated by either compute capacity or memory bandwidth. Identifying which one determines which optimization techniques work.

**Compute-bound**: Time-to-complete is determined by the arithmetic operations required (e.g., password decryption, image generation).

**Memory bandwidth-bound** (often "memory-bound"): Time-to-complete is constrained by data transfer rate between memory and processors (e.g., loading large weight matrices on each decode step).

**Arithmetic intensity** = arithmetic operations per byte of memory access. Roofline charts (e.g., NVIDIA Nsight) plot this to classify workloads.

**Bottleneck mitigation**:
- Compute-bound -> more chips, higher FLOP/s chips.
- Bandwidth-bound -> chips with higher memory bandwidth.

### Prefill vs Decode (Transformer LLMs)

Transformer LLM inference has two distinct phases with different computational profiles:

**Prefill**: Processes all input tokens in parallel. Limited by hardware operations per second -> **compute-bound**.

**Decode**: Generates one output token at a time. Each step loads large matrices (weights) into GPUs -> **memory bandwidth-bound**.

**Why it matters**: Production systems often decouple prefill and decode onto separate machines because their bottlenecks differ. Factors affecting their balance: context length, output length, batching strategy.

### Online vs Batch Inference APIs

| API | Optimizes For | Latency | Cost | Example Use |
|-----|---------------|---------|------|-------------|
| Online | Latency | Seconds | Higher | Chatbots, code generation |
| Batch | Throughput / cost | Hours | ~50% lower | Synthetic data, periodic reports |

Batch APIs allow aggressive batching and cheaper hardware. Online APIs may still batch when it doesn't materially hurt latency.

**Streaming mode** (online): Returns each token as generated to lower perceived TTFT. Trade-off: cannot score the response before the user sees it.

### Performance Metrics

**Latency**: Time from query sent to complete response received.

**TTFT (Time To First Token)**: Time until first token appears. Equals duration of the prefill step. Depends on input length.

**TPOT (Time Per Output Token)**: Time per token after the first. In streaming, ~120 ms/token (6-8 tokens/s) suffices for human reading speed.

**Total latency** = `TTFT + TPOT * (number of output tokens)`.

**Time to publish**: Time to first token the **user** sees (excludes hidden CoT/agentic steps).

**Throughput**: Tokens generated per second across all users (TPS). Sometimes tokens/s/user. Also requests/min (RPM) for completed requests.

**Goodput**: Requests/second that meet the SLO (e.g., TTFT <= 200 ms AND TPOT <= 100 ms). A more honest measure than raw throughput.

**Utilization metrics**:
- **GPU utilization (`nvidia-smi`)**: % time the GPU is processing. Misleading - says nothing about efficiency.
- **MFU (Model FLOP/s Utilization)**: Observed throughput / theoretical peak FLOP/s throughput. Higher when compute-bound.
- **MBU (Model Bandwidth Utilization)**: Observed bandwidth used / theoretical peak bandwidth. Higher when bandwidth-bound.

## Terminology

| Term | Definition |
|------|------------|
| Inference | Using a trained model to produce outputs for inputs |
| Prefill | Parallel processing of input tokens (compute-bound) |
| Decode | Sequential generation of output tokens (bandwidth-bound) |
| TTFT | Time to first generated token |
| TPOT | Time per output token after the first |
| TBT/ITL | Time between tokens / inter-token latency |
| TPS | Tokens per second (throughput) |
| RPM | Requests per minute (completed) |
| SLO | Service-level objective (latency target) |
| Goodput | Requests/sec that meet the SLO |
| MFU | Model FLOP/s utilization (vs theoretical peak compute) |
| MBU | Model bandwidth utilization (vs theoretical peak bandwidth) |
| Roofline | Chart classifying workload as compute- or bandwidth-bound |
| Streaming mode | Online API that emits tokens as they are generated |

## Common Misconceptions

- **Myth**: High `nvidia-smi` GPU utilization means the GPU is being used efficiently.
  **Reality**: It only measures % time active, not how many of the chip's max ops/sec are used. Use MFU/MBU instead.

- **Myth**: Higher throughput is always better.
  **Reality**: Batching boosts throughput but hurts latency. If TTFT/TPOT exceeds your SLO, throughput gains produce a worse user experience. Track goodput.

- **Myth**: Average latency is a fine summary.
  **Reality**: Latency is a long-tailed distribution; one slow outlier (e.g., 3,000 ms) skews the mean. Use p50, p90, p95, p99.

- **Myth**: Memory-bound means "ran out of memory."
  **Reality**: Usually it means memory **bandwidth**-bound. Capacity issues (OOM) are different and can often be split/tiled.

- **Myth**: Batch inference for LLMs is the same as traditional ML batch inference.
  **Reality**: Traditional batch ML precomputes predictions before requests arrive. LLM batch APIs process requests after they arrive, just with high-throughput / high-latency execution.

## How It Relates To

- **Quantization**: Reducing bytes/param directly reduces decode bandwidth pressure (MBU formula).
- **Service optimization**: Decoupling prefill/decode, batching strategies depend on these metrics.
- **Hardware selection**: Compute-bound workloads benefit from FLOP/s; bandwidth-bound from HBM bandwidth.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Prefill | Parallel input processing; compute-bound |
| Decode | Sequential output generation; bandwidth-bound |
| TTFT | Latency of the prefill step |
| TPOT | Latency per generated token |
| Throughput | Output tokens/s across the system |
| Goodput | Requests/s that satisfy the SLO |
| MFU | % of peak compute actually used |
| MBU | % of peak bandwidth actually used |
