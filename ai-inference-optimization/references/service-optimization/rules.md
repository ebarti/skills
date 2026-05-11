# Service Optimization Rules

Guidelines for choosing batching, prefill/decode disaggregation, prompt caching, and parallelism strategies.

## Core Rules

### 1. Use Continuous Batching for LLM Serving

For autoregressive LLMs, continuous batching is the default. Static and naive dynamic batching force short responses to wait for the longest in the batch.

- Adopt frameworks that implement it (vLLM, TGI, TensorRT-LLM with in-flight batching)
- Reserve static batching for offline batch jobs where latency is irrelevant
- Use dynamic batching only for non-LLM models (classification, embedding) where all responses finish together

### 2. Decouple Prefill and Decode at Scale

When you serve enough traffic that prefill jobs measurably stall decode TPOT, separate them onto different instances.

- Tune the prefill:decode instance ratio to your workload
- Long inputs + TTFT priority: prefill:decode ratio between 2:1 and 4:1
- Short inputs + TPOT priority: prefill:decode ratio between 1:2 and 1:1
- Skip this for low-traffic services; the operational complexity isn't worth it

### 3. Cache Long, Stable Prefixes

Prompt caching pays off when the same prefix is reused many times.

- Cache system prompts (especially >500 tokens)
- Cache long reference documents queried repeatedly (codebase, book, contract)
- Cache conversation history in multi-turn chat
- Don't cache one-off prompts or highly variable prefixes

**Example**:
```python
# Bad: rebuilding system prompt + doc on every call (no cache)
for query in user_queries:
    response = model.complete(system_prompt + long_doc + query)

# Good: leverage prompt caching API
for query in user_queries:
    response = model.complete(
        system=[{"text": system_prompt, "cache_control": {"type": "ephemeral"}},
                {"text": long_doc, "cache_control": {"type": "ephemeral"}}],
        messages=[{"role": "user", "content": query}],
    )
```

### 4. Choose Parallelism by Constraint

Match the strategy to what's binding you.

- **Model fits on one chip + need throughput**: replica parallelism
- **Model too large for one chip**: tensor parallelism (preferred for inference)
- **Model too large for one node + training/throughput**: pipeline parallelism
- **Latency-critical inference**: avoid pipeline parallelism
- **Very long sequences**: consider context or sequence parallelism

### 5. Don't Over-Provision Replicas

Replicas are simple but costly. Right-size based on measured QPS, not peak burst fantasies.

- Pack mixed model sizes onto GPUs with bin-packing (e.g., three 13B-int8 fit on one 40GB)
- Prefer fewer larger replicas when latency permits

## Guidelines

- Measure TTFT and TPOT separately; they need different fixes
- Prompt caching has the biggest ROI for chat-with-document workloads (Anthropic reports 79% TTFT reduction, 90% cost reduction on 100K-token cached prompts)
- Most impactful service techniques across use cases: continuous batching, replica parallelism, tensor parallelism, prompt caching
- Use online vs. batch APIs to prioritize latency-sensitive traffic when capacity is constrained

## Exceptions

- **Tiny models on a single GPU**: tensor parallelism communication overhead may exceed compute savings; prefer replicas
- **Highly variable prompts**: prompt cache hit rate is too low to justify storage cost
- **Strict TTFT SLOs with bursty traffic**: static batching is unacceptable; use dynamic with a small window
- **Single-tenant deployment**: prefill/decode disaggregation may add latency you don't recover

## Quick Reference

| Decision | Rule |
|----------|------|
| LLM batching strategy | Continuous batching (vLLM, TGI) |
| Non-LLM batching | Dynamic batching with timeout |
| Cache system prompt? | Yes if >500 tokens and reused |
| Disaggregate prefill/decode? | Only at scale where contention is measurable |
| Large model, latency-critical | Tensor parallelism |
| Large model, training | Pipeline parallelism |
| Need more throughput, model fits | Replica parallelism |
| Long input sequences | Context or sequence parallelism |
