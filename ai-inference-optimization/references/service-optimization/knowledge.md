# Service Optimization Knowledge

Core concepts for optimizing inference at the service level (resource management, no model changes).

## Overview

Service-level optimization focuses on efficiently allocating fixed compute/memory resources across dynamic inference workloads. Unlike model-level techniques, these don't modify models and don't change output quality. The four major levers: batching, decoupling prefill/decode, prompt caching, and parallelism.

## Key Concepts

### Batching

**Definition**: Grouping multiple inference requests to process them together, improving throughput by maximizing accelerator utilization.

Three main strategies:

- **Static batching**: Service waits for a fixed batch size to be filled before processing. Like a bus waiting for every seat to fill. First request can be delayed indefinitely until last arrives.
- **Dynamic batching**: Sets a maximum time window. Processes when batch is full OR window expires (e.g., 4 requests OR 100 ms). Caps latency but may waste compute on partial batches.
- **Continuous batching** (a.k.a. *in-flight batching*): Returns responses as soon as they finish; new requests slot into freed positions in the running batch. Introduced by Orca (Yu et al., 2022). Used in vLLM, TensorRT-LLM, TGI.

### Decoupling Prefill and Decode

**Definition**: Running the prefill phase (compute-bound) and decode phase (memory bandwidth-bound) on separate instances/GPUs to prevent resource contention.

A single prefill job can drain compute from concurrent decode jobs, slowing TPOT for everyone in the batch. Disaggregation (DistServe, "Inference Without Interference") improves throughput while meeting latency SLOs. Communication overhead for transferring KV state is small with NVLink-class interconnects.

### Prompt Caching

**Definition**: Stores processed token segments (KV cache) of overlapping prompt prefixes for reuse across queries.

Also known as *context cache* or *prefix cache*. Common targets: system prompts, long documents (codebase, book), conversation history. Introduced Nov 2023 by Gim et al. Now supported by Anthropic, Google Gemini, OpenAI, vLLM, llama.cpp, etc.

**Tradeoffs**: Cache storage costs memory (KV cache is large). Providers charge for storage time (e.g., Gemini $1.00/1M tokens/hour) but discount cached input (Gemini 75% off, Anthropic up to 90% off).

### Parallelism

**Definition**: Splitting inference work across multiple devices to enable larger models or higher throughput.

- **Replica parallelism (data parallelism)**: Multiple full copies of the model. Adds throughput proportional to chips. Bin-packing problem when mixing model sizes and GPU memory tiers.
- **Tensor parallelism (intra-operator)**: Partitions tensors within an operator (e.g., split a matmul matrix columnwise). Enables serving models too large for one device AND reduces latency. Communication overhead can erode latency gains.
- **Pipeline parallelism**: Splits the model into sequential stages on different devices; micro-batches flow through. Increases per-request latency due to cross-stage communication. Common in training, less common in latency-sensitive inference.
- **Context parallelism**: Splits the input sequence itself across devices (e.g., first half on GPU 1, second half on GPU 2). For long-input efficiency.
- **Sequence parallelism**: Splits operators across devices (e.g., attention on GPU 1, FFN on GPU 2). For long-input efficiency.

## Terminology

| Term | Definition |
|------|------------|
| TTFT | Time to first token; dominated by prefill |
| TPOT | Time per output token; dominated by decode |
| In-flight batching | NVIDIA's name for continuous batching |
| Prefix cache | Another name for prompt cache |
| Disaggregated serving | Decoupled prefill/decode on different machines |
| Bin-packing | Fitting models of varying sizes onto GPUs of varying memory |
| MFU | Model FLOP/s utilization |

## How It Relates To

- **KV cache optimization**: Prompt cache is essentially a persisted/shared KV cache for prefixes
- **Hardware**: Tensor parallelism requires high-bandwidth interconnects (NVLink)
- **Model APIs**: Most application developers consume these optimizations through provider APIs

## Common Misconceptions

- **Myth**: Static batching is always cheapest.
  **Reality**: It maximizes throughput per batch but tail latency is unbounded; continuous batching wins for LLMs.

- **Myth**: Tensor parallelism always reduces latency.
  **Reality**: Communication overhead between shards can dominate for small models or weak interconnects.

- **Myth**: Pipeline parallelism is good for latency.
  **Reality**: It increases per-request latency; prefer it for training throughput, not latency-sensitive inference.

- **Myth**: Prompt caching is free.
  **Reality**: Cache storage costs memory and (on hosted APIs) money per hour.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Static batching | Fixed batch size, blocks until full |
| Dynamic batching | Fixed time window OR batch size, whichever first |
| Continuous batching | Slot in new requests as old ones finish (Orca/vLLM) |
| Prefill/decode split | Run compute-bound prefill separately from memory-bound decode |
| Prompt cache | Persist KV state of common prefixes (system prompt, docs) |
| Replica parallelism | More copies = more throughput |
| Tensor parallelism | Split operators across GPUs to fit large models |
| Pipeline parallelism | Split model into stages; good for training, bad for latency |
