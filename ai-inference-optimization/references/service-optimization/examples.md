# Service Optimization Examples

Concrete examples for batching, prompt caching, and tensor parallelism configurations.

## Continuous Batching with vLLM

### Bad: Sequential Processing

```python
from transformers import AutoModelForCausalLM, AutoTokenizer

model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-3-8B")
tokenizer = AutoTokenizer.from_pretrained("meta-llama/Llama-3-8B")

# One request at a time, GPU mostly idle
for prompt in prompts:
    inputs = tokenizer(prompt, return_tensors="pt").to("cuda")
    outputs = model.generate(**inputs, max_new_tokens=256)
    print(tokenizer.decode(outputs[0]))
```

**Problems**:
- No batching, GPU compute wasted
- Throughput scales linearly with requests
- Long requests block short ones if you naively batch

### Good: Continuous Batching with vLLM

```python
from vllm import LLM, SamplingParams

# Continuous batching is on by default in vLLM
llm = LLM(
    model="meta-llama/Llama-3-8B",
    tensor_parallel_size=1,
    max_num_batched_tokens=8192,   # tokens processed per iteration
    max_num_seqs=256,              # concurrent sequences in flight
    gpu_memory_utilization=0.90,
)

sampling_params = SamplingParams(temperature=0.7, max_tokens=256)

# vLLM internally schedules requests, slots in new ones as others finish
outputs = llm.generate(prompts, sampling_params)
for o in outputs:
    print(o.outputs[0].text)
```

**Why it works**:
- vLLM's scheduler implements Orca-style continuous batching out of the box
- `max_num_seqs` controls in-flight concurrency
- Short responses return without waiting for long ones in the same batch

### Good: vLLM as an OpenAI-Compatible Server

```bash
python -m vllm.entrypoints.openai.api_server \
    --model meta-llama/Llama-3-8B \
    --tensor-parallel-size 2 \
    --max-num-seqs 256 \
    --enable-prefix-caching
```

`--enable-prefix-caching` turns on automatic prompt caching at the KV-cache level.

## Prompt Caching Configuration

### Anthropic Prompt Caching

```python
import anthropic

client = anthropic.Anthropic()

LONG_DOC = open("manual.md").read()          # ~50K tokens
SYSTEM_PROMPT = "You are a helpful assistant."

response = client.messages.create(
    model="claude-opus-4-7",
    max_tokens=1024,
    system=[
        {"type": "text", "text": SYSTEM_PROMPT},
        {
            "type": "text",
            "text": LONG_DOC,
            "cache_control": {"type": "ephemeral"},   # cache this block
        },
    ],
    messages=[{"role": "user", "content": "Summarize chapter 3."}],
)
```

**Why it works**:
- The 50K-token doc is processed once, then reused across calls
- First call: full prefill cost (and a write to cache)
- Subsequent calls within TTL: cache hit, ~90% input cost reduction, ~75% latency reduction

### Google Gemini Context Caching

```python
import google.generativeai as genai
from google.generativeai import caching
from datetime import timedelta

# Create the cache once
cache = caching.CachedContent.create(
    model="models/gemini-1.5-pro",
    contents=[LONG_DOC],
    system_instruction=SYSTEM_PROMPT,
    ttl=timedelta(hours=1),
)

model = genai.GenerativeModel.from_cached_content(cache)

# Reuse across many queries
for q in user_queries:
    print(model.generate_content(q).text)
```

**Why it works**:
- Cache lives for the TTL; pay storage ($1/1M tokens/hour) but cached input is 75% off
- Best for batch workloads against the same long context

## Tensor Parallelism Configuration

### vLLM Tensor Parallel

```python
from vllm import LLM

# Split a 70B model across 4 GPUs
llm = LLM(
    model="meta-llama/Llama-3-70B",
    tensor_parallel_size=4,        # shard across 4 GPUs in one node
    pipeline_parallel_size=1,      # no pipeline split
    dtype="bfloat16",
)
```

**Why it works**:
- `tensor_parallel_size` shards each operator (e.g., matmul) across GPUs
- Requires NVLink (or fast intra-node interconnect) to keep communication cheap
- Enables serving a model that doesn't fit on a single 80GB GPU

### Multi-Node Deployment (Pipeline + Tensor)

```python
# 70B model across 2 nodes x 4 GPUs each
llm = LLM(
    model="meta-llama/Llama-3-70B",
    tensor_parallel_size=4,        # shard within each node (intra-node, NVLink)
    pipeline_parallel_size=2,      # stage across nodes (inter-node, slower)
    dtype="bfloat16",
)
```

**Why it works**:
- Tensor parallelism inside the node where bandwidth is high
- Pipeline parallelism across nodes where bandwidth is lower
- Acceptable for offline / throughput workloads; adds latency for online serving

### TGI Sharded Deployment

```bash
docker run --gpus all -p 8080:80 \
    -e NUM_SHARD=4 \
    -e MODEL_ID=meta-llama/Llama-3-70B \
    ghcr.io/huggingface/text-generation-inference:latest
```

`NUM_SHARD=4` enables tensor parallelism across 4 GPUs.

## Refactoring Walkthrough

### Before: Naive Single-GPU Service

```python
# Single replica, no batching, no caching, blocks per request
model = AutoModelForCausalLM.from_pretrained("Llama-3-70B").to("cuda")
# Fails: 70B in fp16 = 140GB, doesn't fit on 80GB GPU
```

### After: Production-Ready vLLM Service

```python
from vllm import LLM, SamplingParams

llm = LLM(
    model="meta-llama/Llama-3-70B",
    tensor_parallel_size=4,           # shard across 4 GPUs
    max_num_seqs=128,                 # continuous batching concurrency
    enable_prefix_caching=True,       # automatic prompt caching
    gpu_memory_utilization=0.92,
)
```

### Changes Made

1. **Tensor parallelism (4-way)**: Fits the 70B model and reduces per-token latency
2. **Continuous batching**: `max_num_seqs=128` lets the scheduler interleave requests
3. **Prefix caching**: Reuses KV state for repeated system prompts and document prefixes
