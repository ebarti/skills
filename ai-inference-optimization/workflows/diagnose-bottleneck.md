# Diagnose Inference Bottleneck Workflow

Identify and fix the bottleneck that's hurting inference performance.

## When to Use

- Inference is too slow (latency)
- Throughput is too low
- Cost per request is too high
- OOM errors during inference
- High GPU utilization but low effective output

## Prerequisites

- Access to the inference service / GPU(s)
- Ability to instrument or profile the model
- Defined SLO (latency target, throughput target, cost target)

**Reference**: `references/inference-fundamentals/rules.md`

---

## Workflow Steps

### Step 1: Define the Performance Goal

**Goal**: Be specific about what "fast enough" means.

- [ ] Pick the metric that matters: TTFT, TPOT, total latency, throughput, cost/req
- [ ] Set a numeric target (with percentile, e.g., p95 TTFT < 500ms)
- [ ] Define the SLO (e.g., 95% of requests under target)
- [ ] **Avoid**: tuning throughput when latency matters; tuning latency when throughput matters

**Reference**: `references/inference-fundamentals/rules.md`

---

### Step 2: Measure Current Performance

**Goal**: Establish a baseline.

- [ ] Measure TTFT, TPOT, total latency at your typical input/output lengths
- [ ] Measure throughput (requests/sec)
- [ ] Measure goodput (requests meeting SLO per second)
- [ ] Measure MFU and MBU
- [ ] Use percentiles (p50, p95, p99), not averages
- [ ] **Don't trust nvidia-smi for utilization** — use proper profiling

**Reference**: `references/inference-fundamentals/examples.md`

---

### Step 3: Triage the Bottleneck

**Goal**: Identify whether you're compute-bound or memory-bound.

| Signal | Bottleneck |
|--------|------------|
| High MFU, low MBU | Compute-bound |
| Low MFU, high MBU | Memory-bandwidth-bound |
| Both low | Service / batching issue |
| OOM | Memory size |

For LLMs:
- **Prefill**: typically compute-bound (long input processed in parallel)
- **Decode**: typically memory-bandwidth-bound (one token at a time, KV cache loads dominate)

- [ ] Identify whether it's prefill or decode that's slow
- [ ] Identify the dominant bottleneck

**Reference**: `references/inference-fundamentals/patterns.md`

---

### Step 4: Apply Bottleneck-Specific Fixes

**Goal**: Apply the right techniques in priority order.

#### TTFT (prefill) bottleneck
- [ ] **Prompt caching** (Anthropic: 79% TTFT reduction on cached prompts)
- [ ] **Decouple prefill from decode** (DistServe pattern)
- [ ] **Better hardware** (compute-rich)

#### TPOT (decode) bottleneck
- [ ] **Speculative decoding** (lossless 1.5-2x speedup)
- [ ] **FlashAttention** (don't write your own kernel)
- [ ] **GQA / MQA attention** (reduce KV cache size)
- [ ] **Quantization** (INT8 / INT4 weights → less memory bandwidth)

#### Throughput bottleneck
- [ ] **Continuous batching** (vLLM, TGI, TensorRT-LLM)
- [ ] **Tensor parallelism** for large models
- [ ] **Replica parallelism** for horizontal scale

#### OOM
- [ ] **Quantize weights** (FP16 → INT8 → INT4)
- [ ] **Reduce KV cache** (GQA, paged attention)
- [ ] **Larger GPU** or sharded inference

#### Cost bottleneck
- [ ] **Prompt caching** (Anthropic: 90% cost reduction)
- [ ] **Continuous batching** (higher utilization)
- [ ] **Quantization** (smaller GPU)
- [ ] **Smaller / distilled model**

**Reference**: `references/model-optimization/rules.md`, `references/service-optimization/rules.md`

---

### Step 5: Apply in Recommended Order

**Goal**: Stack optimizations efficiently.

Recommended stacking order (cheapest to most expensive eng effort):
1. Architecture choice (GQA/MQA model variants)
2. FlashAttention (just enable it)
3. Quantization (INT8 weights)
4. Compile / vLLM serving framework
5. Speculative decoding
6. Custom CUDA kernels (last resort)

- [ ] Apply techniques in this order, measuring after each
- [ ] Stop when you hit your SLO

**Reference**: `references/model-optimization/patterns.md`

---

### Step 6: Verify and Monitor

**Goal**: Confirm the fix and prevent regression.

- [ ] Re-measure all metrics from Step 2
- [ ] Confirm SLO is met
- [ ] Add monitoring on the metric so you catch regressions
- [ ] Document the configuration (which optimizations are on, version pins)

**Reference**: `ai-production-architecture/references/monitoring-observability/rules.md`

---

## Quick Checklist

```
[ ] Step 1: Performance goal defined (metric + target + SLO)
[ ] Step 2: Baseline measured (with percentiles)
[ ] Step 3: Bottleneck triaged (compute/memory/service)
[ ] Step 4: Bottleneck-specific fixes applied
[ ] Step 5: Optimizations stacked in order
[ ] Step 6: Verified + monitored
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Optimizing without baseline | Can't measure improvement | Always measure first |
| Using mean latency | Hides tail | Use p95/p99 |
| Trusting nvidia-smi utilization | Misleading | Use MFU/MBU |
| Quantizing without testing quality | Quality regression | Eval after each optimization |
| Custom kernels first | Huge effort, marginal gains | Use existing solutions first |
| Tuning throughput on a latency-bound service | Wrong objective | Pick the right metric |

---

## Exit Criteria

- [ ] SLO is met
- [ ] Configuration documented
- [ ] Monitoring catches regressions
- [ ] Cost-per-request within budget
