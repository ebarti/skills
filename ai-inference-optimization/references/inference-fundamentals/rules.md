# Inference Fundamentals Rules

Guidelines for choosing inference APIs, picking metrics, and diagnosing bottlenecks.

## Core Rules

### 1. Match the API type to latency tolerance

Pick **online** APIs when end users are waiting; pick **batch** APIs when results can wait hours for ~50% cost savings.

- **Online**: chatbots, code generation, autocomplete, agentic tools - any user-facing interactive flow.
- **Batch**: synthetic data generation, periodic reporting, bulk reprocessing for model migration, document onboarding, recommendation refresh, knowledge base reindexing.

### 2. Use streaming mode for long generations on online APIs

Streaming reduces perceived TTFT and lets users start reading immediately. The trade-off is losing pre-display moderation - mitigate with retroactive removal.

- Always stream when output > a few tokens and a human is reading.
- Do **not** stream when the consumer is downstream code that needs the whole response (e.g., JSON parsing).

### 3. Pick the metric that matches the user's experience

| Use case | Optimize for |
|----------|--------------|
| Chatbot, autocomplete | TTFT (then TPOT) |
| Long-form streaming generation | TPOT >= human reading speed |
| Batch / offline jobs | Throughput, cost per request |
| Multi-tenant production service | Goodput against your SLO |
| Hardware efficiency tracking | MFU (compute) and MBU (bandwidth) |

### 4. Always look at latency percentiles, not averages

Latency is long-tailed; a single outlier ruins the mean.

- Track at minimum: p50, p90, p95, p99.
- Plot TTFT against input length to spot prefill outliers.
- Investigate p99 spikes - they often surface real bugs (network errors, pathological prompts).

### 5. Diagnose the bottleneck before optimizing

Different bottlenecks need different fixes. Don't add GPUs to a bandwidth-bound workload.

- Use a profiler that produces a roofline chart (NVIDIA Nsight or equivalent).
- Compute arithmetic intensity = ops / bytes accessed.
- For LLMs: prefill is compute-bound, decode is bandwidth-bound (default assumption).

**Bandwidth-bound symptoms**:
- High MBU, low MFU.
- Decode step dominates total latency.
- Throughput improves with quantization (fewer bytes/param) more than with more FLOP/s.

**Compute-bound symptoms**:
- High MFU, low MBU.
- Prefill step dominates (e.g., very long inputs).
- Throughput improves with more chips or higher FLOP/s.

### 6. Prefer goodput over raw throughput for user-facing services

Throughput maximizes tokens/s but can blow your SLO. Goodput counts only requests that satisfied the SLO.

- Define SLO explicitly (e.g., TTFT <= 200 ms, TPOT <= 100 ms).
- Tune batching, scheduling, and decoupling to maximize requests/min that meet SLO.

### 7. Don't trust `nvidia-smi` GPU utilization as an efficiency signal

It only reports % time active, not % capacity used. A GPU running 1 of 100 possible ops/sec still reports 100%.

- Use **MFU** for compute efficiency.
- Use **MBU** for bandwidth efficiency.
- Use `nvidia-smi` only to confirm the GPU is doing **something**, not how well.

### 8. Compare inference servers on cost per request, not on raw throughput

Tokenizers differ, so token counts aren't comparable across models.

- Compute: cost/hour / (tokens/s) -> $ per 1M tokens.
- Multiply by avg tokens/request -> $ per 1K requests (sum prefill + decode).

## Guidelines

- Decouple prefill and decode onto separate machines when their bottleneck profiles diverge enough.
- Quantize model weights when MBU is high - directly cuts the bandwidth budget.
- Treat MFU > 50% as good for **training**; inference MFU is typically lower (decode dominates).
- Prefill MFU > decode MFU (prefill is compute-bound).
- Track MBU and MFU together - one high and the other low confirms the bottleneck.
- For agentic/CoT systems, distinguish "model TTFT" from "user time-to-publish" (the user's true first-token wait).

## Exceptions

- **Streaming mode for tool-calling LLMs**: skip streaming when the entire response must be parsed before action.
- **Goodput tracking**: less useful for batch APIs - throughput and cost dominate there.
- **MFU/MBU at very small batch sizes**: numbers are noisy; aggregate over many requests.

## Quick Reference

| Rule | Summary |
|------|---------|
| API choice | Online for interactive, batch for offline |
| Metric for chatbots | TTFT first, then TPOT |
| Metric for SLO services | Goodput, not throughput |
| Latency reporting | Percentiles, never averages |
| Bottleneck check | MFU high = compute-bound; MBU high = bandwidth-bound |
| GPU efficiency | MFU/MBU, never `nvidia-smi` % |
| Cross-server comparison | $ per request, not tokens/s |
