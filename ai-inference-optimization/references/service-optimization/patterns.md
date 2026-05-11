# Service Optimization Patterns

Reusable service-level patterns for production LLM inference.

## Pattern: Continuous Batching Server

### Intent

Maximize GPU throughput on autoregressive LLMs without forcing short responses to wait for long ones.

### When to Use

- Serving generative LLMs with variable response lengths
- Mixed-length workloads (chat + summarization + code generation)
- Any time you would otherwise queue requests sequentially

### Structure

```python
from vllm import LLM, SamplingParams

llm = LLM(
    model="<hf-id>",
    max_num_seqs=<concurrency>,        # in-flight slots
    max_num_batched_tokens=<token-budget-per-step>,
    enable_prefix_caching=True,
)
sampling_params = SamplingParams(...)
outputs = llm.generate(prompts, sampling_params)
```

### Benefits

- Near-optimal GPU utilization on heterogeneous request mix
- Short responses return fast even under load
- Implemented out-of-the-box in vLLM, TGI, TensorRT-LLM

### Considerations

- Tune `max_num_seqs` to match available KV cache memory
- Larger concurrency increases throughput but raises p99 TPOT under contention

---

## Pattern: Disaggregated Prefill/Decode

### Intent

Prevent prefill jobs (compute-bound) from starving decode jobs (bandwidth-bound) on shared GPUs.

### When to Use

- High-traffic LLM service with measurable TPOT degradation under load
- Workloads with both long inputs (prefill-heavy) and long outputs (decode-heavy)
- When you can dedicate separate GPU pools

### Structure

```
[Router] ── prefill request ──> [Prefill Pool: GPUs A,B,C]
                                       │ KV state via NVLink/RDMA
                                       v
[Router] ── decode request ───> [Decode Pool: GPUs D,E]
```

### Example Ratios

```
Long-input + low-TTFT priority:  prefill:decode = 2:1 to 4:1
Short-input + low-TPOT priority: prefill:decode = 1:2 to 1:1
```

### Benefits

- Eliminates compute contention between phases
- Independent scaling of TTFT vs. TPOT capacity
- Documented gains in DistServe, "Inference Without Interference"

### Considerations

- Requires fast intra-cluster transport for KV state (NVLink within node, RDMA across)
- Adds operational complexity; not worth it for low QPS

---

## Pattern: Prefix Cache for System Prompt

### Intent

Avoid reprocessing identical prompt prefixes (system prompt, docs) on every request.

### When to Use

- Application has a long system prompt (>500 tokens) used by all users
- Chat-with-document where the doc is shared across queries
- Multi-turn conversation where history accumulates

### Structure

```python
# Mark the stable prefix as cacheable; vary only the tail
client.messages.create(
    system=[
        {"type": "text", "text": SYSTEM, "cache_control": {"type": "ephemeral"}},
        {"type": "text", "text": DOC, "cache_control": {"type": "ephemeral"}},
    ],
    messages=[{"role": "user", "content": user_query}],
    ...
)
```

### Benefits

- 75-90% cost reduction on cached input tokens (provider-dependent)
- Up to 79% TTFT reduction on long cached prompts (Anthropic data)
- Dramatic savings at scale (1B+ repetitive tokens/day eliminated for popular apps)

### Considerations

- Cache storage costs (hosted: per-hour fee; self-hosted: KV memory)
- TTL means cache misses on cold prefixes
- Place stable content at the start, variable content at the end

---

## Pattern: Tensor-Parallel Large Model Serving

### Intent

Serve a model too large for one GPU while reducing per-token latency.

### When to Use

- Model size exceeds single-GPU memory (e.g., 70B+ in bf16)
- Latency-sensitive online inference
- Single-node deployment with NVLink

### Structure

```python
LLM(model=..., tensor_parallel_size=N, pipeline_parallel_size=1)
```

Where `N` divides the number of attention heads and matches GPU count in the node.

### Benefits

- Enables serving models that don't fit on one chip
- Reduces latency vs. single-GPU (when bandwidth allows)
- Standard in production (vLLM, TGI, TensorRT-LLM)

### Considerations

- Communication overhead grows with tensor-parallel degree; typically capped at 8 within a node
- Cross-node tensor parallelism is rarely worthwhile due to slow interconnect

---

## Pattern: Replica Parallelism for Throughput

### Intent

Scale horizontally when the model fits on one device and you need more QPS.

### When to Use

- Model fits comfortably on one GPU
- Throughput is binding, not single-request latency
- Mixed model sizes to bin-pack across GPU tiers

### Structure

```
[Load Balancer]
     │
     ├──> [Replica 1: GPU 1 (full model)]
     ├──> [Replica 2: GPU 2 (full model)]
     └──> [Replica 3: GPU 3 (full model)]
```

### Benefits

- Simplest scaling pattern; linear throughput
- Independent failure domains
- Bin-pack mixed sizes (e.g., 3x 13B-int8 onto one 40GB GPU)

### Considerations

- Linear cost in chips; expensive for very large models
- No latency improvement per request

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|---------------------|
| LLM serving, mixed lengths | Continuous batching server |
| High QPS, prefill stalling decode | Disaggregated prefill/decode |
| Long shared system prompt | Prefix cache for system prompt |
| Model > single-GPU memory, low latency | Tensor-parallel serving |
| Model fits, need more throughput | Replica parallelism |
| Mixed model zoo on heterogeneous GPUs | Replica parallelism + bin-packing |
| Training large models | Pipeline parallelism (not for inference latency) |
| Very long input sequences | Context or sequence parallelism |
