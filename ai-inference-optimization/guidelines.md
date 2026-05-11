# AI Inference Optimization Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use**: Find your situation below, then load ONLY the listed files.

---

## By Task

### Understanding Performance

| What you're doing | Load these files |
|-------------------|------------------|
| Learning inference fundamentals | `references/inference-fundamentals/knowledge.md` |
| Picking metrics for your use case | `references/inference-fundamentals/rules.md` |
| Diagnosing a performance bottleneck | `references/inference-fundamentals/rules.md`, `references/inference-fundamentals/patterns.md` |
| Calculating TTFT/TPOT/MFU/MBU | `references/inference-fundamentals/examples.md` |

### Choosing Hardware

| What you're doing | Load these files |
|-------------------|------------------|
| Picking GPU/TPU for a workload | `references/ai-accelerators/rules.md`, `references/ai-accelerators/examples.md` |
| Estimating GPU count for a model | `references/ai-accelerators/examples.md` |
| Power and cost planning | `references/ai-accelerators/rules.md`, `references/ai-accelerators/examples.md` |

### Optimizing the Model

| What you're doing | Load these files |
|-------------------|------------------|
| Quantizing for inference (INT8/INT4) | `references/model-optimization/rules.md`, `references/model-optimization/examples.md` |
| Speeding up autoregressive decoding | `references/model-optimization/rules.md`, `references/model-optimization/examples.md` |
| Implementing speculative decoding | `references/model-optimization/examples.md`, `references/model-optimization/patterns.md` |
| Adding FlashAttention | `references/model-optimization/rules.md`, `references/model-optimization/examples.md` |
| KV cache management | `references/model-optimization/rules.md`, `references/model-optimization/examples.md` |
| Choosing optimization order | `references/model-optimization/patterns.md` |

### Optimizing the Service

| What you're doing | Load these files |
|-------------------|------------------|
| Setting up batching (vLLM, TGI) | `references/service-optimization/rules.md`, `references/service-optimization/examples.md` |
| Decoupling prefill/decode | `references/service-optimization/rules.md`, `references/service-optimization/examples.md` |
| Implementing prompt caching | `references/service-optimization/rules.md`, `references/service-optimization/examples.md` |
| Scaling with parallelism (TP/PP/DP) | `references/service-optimization/rules.md`, `references/service-optimization/patterns.md` |

---

## By Symptom/Problem

| If you notice... | Load these files |
|------------------|------------------|
| Slow first-token (high TTFT) | `references/inference-fundamentals/patterns.md` (prefill bottleneck), `references/service-optimization/rules.md` (caching) |
| Slow per-token (high TPOT) | `references/inference-fundamentals/patterns.md` (decode), `references/model-optimization/rules.md` (speculative, attention) |
| Throughput too low | `references/service-optimization/rules.md` (continuous batching), `references/inference-fundamentals/rules.md` (goodput) |
| OOM during inference | `references/model-optimization/rules.md` (quantization, KV cache), `references/ai-accelerators/rules.md` (memory) |
| Low GPU utilization | `references/inference-fundamentals/rules.md` (MFU/MBU), `references/service-optimization/rules.md` (batching) |
| High serving cost per request | `references/service-optimization/rules.md` (caching, batching), `references/model-optimization/rules.md` (quantization) |
| Long contexts crash | `references/model-optimization/patterns.md` (long-context), `references/model-optimization/rules.md` (FlashAttention) |
| Repeated system prompts wasting tokens | `references/service-optimization/examples.md` (prompt caching) |

---

## By Topic (Direct Index)

### Inference Fundamentals
- `references/inference-fundamentals/knowledge.md` — Compute/memory bound, prefill/decode, all metrics
- `references/inference-fundamentals/rules.md` — 8 rules (online vs batch, metric selection)
- `references/inference-fundamentals/examples.md` — TTFT/TPOT/MFU/MBU calculations
- `references/inference-fundamentals/patterns.md` — 5 diagnostic patterns

### AI Accelerators
- `references/ai-accelerators/knowledge.md` — GPU/TPU, FLOPS, HBM, memory hierarchy
- `references/ai-accelerators/rules.md` — Selection rules
- `references/ai-accelerators/examples.md` — H100 specs, memory matrix, decision walkthrough

### Model Optimization
- `references/model-optimization/knowledge.md` — Compression, decoding, attention, kernels
- `references/model-optimization/rules.md` — 6 core rules
- `references/model-optimization/examples.md` — Quantization, speculative, KV cache, FlashAttention
- `references/model-optimization/patterns.md` — 5 bottleneck-driven patterns

### Service Optimization
- `references/service-optimization/knowledge.md` — Batching, prefill/decode, caching, parallelism
- `references/service-optimization/rules.md` — Decision rules
- `references/service-optimization/examples.md` — vLLM, Anthropic caching, TP configs
- `references/service-optimization/patterns.md` — 5 service patterns

---

## Decision Tree

```
What is the bottleneck?
│
├─► Don't know yet
│   ├─► Diagnose → inference-fundamentals/rules.md (MFU/MBU)
│   └─► Pattern triage → inference-fundamentals/patterns.md
│
├─► TTFT too slow (prefill-bound)
│   ├─► Prompt caching → service-optimization/examples.md
│   ├─► Decouple prefill → service-optimization/rules.md
│   └─► Better hardware (compute) → ai-accelerators/rules.md
│
├─► TPOT too slow (decode-bound)
│   ├─► Speculative decoding → model-optimization/examples.md
│   ├─► Better attention (FlashAttn, GQA) → model-optimization/rules.md
│   └─► Quantize → model-optimization/rules.md
│
├─► Throughput too low
│   ├─► Continuous batching → service-optimization/rules.md
│   └─► Tensor parallelism → service-optimization/examples.md
│
└─► OOM
    ├─► Quantize → model-optimization/rules.md
    ├─► Smaller KV cache → model-optimization/rules.md (GQA, paged)
    └─► More memory → ai-accelerators/rules.md
```

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| Production LLM serving (first time) | `service-optimization/rules.md` + `service-optimization/patterns.md` + `model-optimization/rules.md` |
| Latency-sensitive chatbot | `inference-fundamentals/patterns.md` + `model-optimization/rules.md` + `service-optimization/examples.md` (caching) |
| Throughput-sensitive batch processing | `service-optimization/rules.md` (continuous batching) + `inference-fundamentals/rules.md` (goodput) |
| Self-hosting a 70B model | `ai-accelerators/examples.md` + `service-optimization/examples.md` (TP) + `model-optimization/examples.md` (quantization) |
| Reducing inference cost | `model-optimization/rules.md` (quantization) + `service-optimization/rules.md` (caching, batching) |
