# Model Optimization Patterns

Reusable optimization patterns organized by bottleneck type.

## Pattern: Memory-Bound Decoding

### Intent

Reduce GPU memory pressure when model + KV cache exceeds VRAM, or when memory bandwidth dominates latency.

### When to Use

- Single-GPU deployment where the model barely fits
- Long context windows (>4k tokens), large-batch serving
- Profiling shows low compute utilization, high memory bandwidth use

### Structure

```python
config = BitsAndBytesConfig(load_in_8bit=True)
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Meta-Llama-3-8B",   # native GQA
    quantization_config=config,
    attn_implementation="flash_attention_2",
)
# Then use vLLM PagedAttention for KV cache layout
```

### Benefits / Considerations

- Frees memory for larger batches; stacks with kernel optimizations
- Quantization may degrade quality on niche tasks

---

## Pattern: Latency-Bound Generation

### Intent

Reduce time-to-last-token for interactive or low-latency generation use cases.

### When to Use

- Chat applications with strict response-time SLOs
- Code generation where users wait for full output
- Long output sequences (>500 tokens)

### Structure

```python
# 1. Add speculative decoding (lossless)
out = target_model.generate(**inputs, assistant_model=draft_model, max_new_tokens=N)

# 2. Use a fused attention kernel
# attn_implementation="flash_attention_2"

# 3. Compile for kernel fusion
model = torch.compile(model, mode="reduce-overhead")
```

### Benefits

- 1.5-2x speedup typical, often more for code/structured output
- No quality regression
- Works on top of quantization

### Considerations

- p99 latency can suffer when draft tokens are rejected
- Need same-vocab draft model

---

## Pattern: Compute-Bound Throughput

### Intent

Maximize tokens-per-second across many concurrent requests in a serving setup.

### When to Use

- Batch inference / offline jobs
- Multi-tenant API serving
- Profiling shows GPU compute is saturated, but throughput is below hardware limits

### Structure

```python
# Use vLLM with continuous batching, prefix caching, FlashAttention
from vllm import LLM, SamplingParams

llm = LLM(
    model="meta-llama/Llama-2-13b-hf",
    enable_prefix_caching=True,
    max_num_seqs=256,
    gpu_memory_utilization=0.9,
    speculative_model="meta-llama/Llama-2-7b-hf",
    num_speculative_tokens=5,
)
```

### Benefits

- Continuous batching keeps GPU saturated
- Prefix caching eliminates repeated prompt prefill
- Speculative decoding compounds with batching

### Considerations

- Tail latency may suffer during batch dynamics
- Requires careful tuning of `max_num_seqs` and memory utilization

---

## Pattern: Long-Context Workloads

### Intent

Serve very long contexts (>32k tokens) where KV cache dominates and attention compute scales quadratically.

### When to Use

- RAG with large retrieved chunks
- Long-document summarization
- Multi-turn conversations with extensive history (Character.AI's 180-message average)

### Structure

```python
# 1. Choose architecture with GQA or MQA
# 2. Use local windowed attention if model architecture allows
# 3. KV cache quantization or selective KV cache
# 4. PagedAttention via vLLM
# 5. Inference-with-reference for input-overlapping outputs
```

### Benefits

- Character.AI reduced KV cache 20x via MQA + interleaved local/global + cross-layer attention
- Memory ceases being a bottleneck for large batches

### Considerations

- Architectural changes (MQA, GQA, local attention) require training time decisions
- Inference-with-reference only helps when output overlaps input

---

## Pattern: Input-Overlapping Output

### Intent

Speed up generation when output substantially repeats input tokens (RAG quoting, code edits, multi-turn echoing).

### When to Use

- RAG with verbatim quoting from documents
- Code editing/refactoring (most code unchanged)
- Multi-turn chat referencing earlier turns

### Structure

```python
# Inference with reference: copy n-gram matches from input as draft tokens
llm = LLM(model="meta-llama/Llama-2-7b-hf")
params = SamplingParams(max_tokens=512, prompt_lookup_num_tokens=10)
out = llm.generate([long_doc + question], params)
```

### Benefits

- ~2x speedup in overlapping scenarios; no extra model; lossless

### Considerations

- Useless when output is novel

---

## Pattern Selection Guide

| Bottleneck Symptom | Recommended Pattern |
|--------------------|---------------------|
| OOM at long context | Long-Context Workloads |
| Low GPU utilization, high memory I/O | Memory-Bound Decoding |
| High user-perceived latency | Latency-Bound Generation |
| Throughput cap on serving cluster | Compute-Bound Throughput |
| Output mostly echoes input | Input-Overlapping Output |
| Need maximum speedup, willing to stack | Combine all patterns: torch.compile + INT8/INT4 + FlashAttention + speculative decoding + PagedAttention |

## Stacking Order (Recommended)

1. Pick best architecture (GQA model)
2. Add `attn_implementation="flash_attention_2"`
3. Quantize weights (INT8 default, INT4 for tight memory)
4. Add `torch.compile` or use vLLM
5. Enable speculative decoding or inference-with-reference
6. Tune batch size and PagedAttention settings
7. Only consider custom kernels after all of the above
