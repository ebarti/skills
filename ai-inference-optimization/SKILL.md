---
name: ai-inference-optimization
description: |
  Practical knowledge for optimizing inference for foundation models. Covers inference fundamentals (computational bottlenecks, online vs batch APIs, latency/throughput metrics), AI accelerators (GPUs, TPUs, computational/memory characteristics), model optimization (compression, speculative decoding, attention optimization, kernels/compilers), and service optimization (batching, prefill/decode separation, prompt caching, parallelism).

  Use this skill when:
  - Optimizing inference latency or throughput
  - Choosing AI accelerators for inference
  - Implementing prompt caching
  - Setting up batching strategies
  - Reducing model size (quantization, pruning, distillation)
  - Diagnosing inference performance bottlenecks
---

# AI Inference Optimization

Knowledge from "AI Engineering" by Chip Huyen (Chapter 9). Practical techniques for making inference faster and cheaper.

## Quick Start

1. Check `guidelines.md` to find which files to load for your task
2. Load only relevant files (each topic has knowledge.md, rules.md, examples.md)
3. Apply guidance to your work

## Contents

### References

| Category | Purpose |
|----------|---------|
| `inference-fundamentals` | Computational bottlenecks, online/batch APIs, latency/throughput/utilization metrics |
| `ai-accelerators` | GPUs/TPUs, computational capabilities, memory size/bandwidth, power |
| `model-optimization` | Compression, speculative decoding, attention optimization, kernels/compilers |
| `service-optimization` | Batching, prefill/decode decoupling, prompt caching, parallelism |

### Workflows

| Task | Workflow |
|------|----------|
| Diagnose and fix inference bottlenecks | `workflows/diagnose-bottleneck.md` |

## Guidelines

See `guidelines.md` for task-based file selection.
