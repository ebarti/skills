# Model Optimization Examples

Concrete Python examples for the major model-optimization techniques.

## Quantization Examples

### INT8 Quantization with bitsandbytes

```python
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig

bnb = BitsAndBytesConfig(load_in_8bit=True)
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-7b-hf",
    quantization_config=bnb,
    device_map="auto",
)
tok = AutoTokenizer.from_pretrained("meta-llama/Llama-2-7b-hf")
# 7B model footprint: ~14 GB FP16 -> ~7 GB INT8
```

**Why it works**: Halves memory footprint vs FP16; runs on a single 16GB GPU.

### INT4 Quantization (Aggressive)

```python
bnb = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_compute_dtype="float16",
    bnb_4bit_quant_type="nf4",       # NormalFloat4 keeps quality
    bnb_4bit_use_double_quant=True,  # Quantize quantization constants too
)
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-7b-hf",
    quantization_config=bnb,
    device_map="auto",
)
# ~3.5 GB footprint - fits on consumer GPUs
```

**Why it works**: NF4 + double quantization minimizes the quality loss that aggressive 4-bit causes.

## Speculative Decoding Setup

### vLLM with Draft Model

```python
from vllm import LLM, SamplingParams

llm = LLM(
    model="meta-llama/Llama-2-70b-hf",
    speculative_model="meta-llama/Llama-2-7b-hf",  # smaller, same vocab
    num_speculative_tokens=5,                      # K tokens to draft
    use_v2_block_manager=True,
)

params = SamplingParams(temperature=0.7, max_tokens=256)
out = llm.generate(["Explain attention in 3 sentences."], params)
print(out[0].outputs[0].text)
```

**Why it works**: Llama-2-7b drafts 5 tokens, Llama-2-70b verifies them in parallel. Lossless quality, ~1.5-2x throughput on typical text.

### Hugging Face transformers Assisted Generation

```python
from transformers import AutoModelForCausalLM, AutoTokenizer

target = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-2-70b-hf", device_map="auto")
draft  = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-2-7b-hf",  device_map="auto")
tok    = AutoTokenizer.from_pretrained("meta-llama/Llama-2-70b-hf")

inputs = tok("def quicksort(arr):", return_tensors="pt").to("cuda")
out = target.generate(
    **inputs,
    assistant_model=draft,    # draft proposes; target verifies
    max_new_tokens=200,
)
print(tok.decode(out[0]))
```

**Why it works**: Built into transformers; one-line addition (`assistant_model=draft`).

## KV Cache Size Calculation

### Manual Calculation

```python
def kv_cache_bytes(batch, seq_len, num_layers, model_dim, bytes_per_value=2):
    """KV cache size = 2 (K and V) * B * S * L * H * M."""
    return 2 * batch * seq_len * num_layers * model_dim * bytes_per_value

# Llama 2 13B example from the book
size = kv_cache_bytes(batch=32, seq_len=2048, num_layers=40, model_dim=5120)
print(f"{size / 1e9:.1f} GB")  # ~54 GB - bigger than the model weights

# Llama 2 70B with long context
size = kv_cache_bytes(batch=8, seq_len=8192, num_layers=80, model_dim=8192)
print(f"{size / 1e9:.1f} GB")  # ~86 GB
```

**Why it matters**: KV cache often dwarfs model weights at long context or large batch.

### Reducing KV Cache via GQA

```python
# Llama 2 70B uses GQA: 64 query heads, 8 KV heads -> 8x KV cache reduction
# Effective formula: 2 * B * S * L * H * M / (num_query_heads / num_kv_heads)

def kv_cache_gqa(batch, seq_len, num_layers, model_dim, q_heads, kv_heads, bytes_per_value=2):
    raw = 2 * batch * seq_len * num_layers * model_dim * bytes_per_value
    return raw * (kv_heads / q_heads)

orig = kv_cache_bytes(batch=8, seq_len=8192, num_layers=80, model_dim=8192)
gqa  = kv_cache_gqa(batch=8, seq_len=8192, num_layers=80, model_dim=8192,
                    q_heads=64, kv_heads=8)
print(f"MHA: {orig/1e9:.1f} GB  GQA: {gqa/1e9:.1f} GB")  # ~86 GB vs ~10.7 GB
```

## FlashAttention Usage

### PyTorch SDPA (FlashAttention Built-In)

```python
import torch
import torch.nn.functional as F

# PyTorch 2+ auto-selects FlashAttention when shapes/dtypes are eligible
with torch.backends.cuda.sdp_kernel(
    enable_flash=True, enable_math=False, enable_mem_efficient=False,
):
    out = F.scaled_dot_product_attention(q, k, v, is_causal=True)
```

**Why it works**: Fused kernel = single GPU pass; major speed/memory gains over naive attention.

### Direct FlashAttention v2

```python
from flash_attn import flash_attn_func

# q, k, v: (batch, seqlen, num_heads, head_dim), fp16/bf16
out = flash_attn_func(q, k, v, causal=True)
```

**Why it works**: Tile-based attention computation that never materializes the full attention matrix.

### Enabling in Hugging Face transformers

```python
from transformers import AutoModelForCausalLM

model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-7b-hf",
    torch_dtype="bfloat16",
    attn_implementation="flash_attention_2",  # one line, big throughput win
    device_map="auto",
)
```

## Stacked Optimization (PyTorch Llama-7B Case Study)

```python
import torch
from transformers import AutoModelForCausalLM

# Step 1: torch.compile -> efficient kernels
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-7b-hf",
    torch_dtype=torch.bfloat16,
    attn_implementation="flash_attention_2",
)
model = torch.compile(model, mode="reduce-overhead")

# Step 2: Quantize weights to INT8 (use bitsandbytes or torchao)
# Step 3: Quantize weights to INT4 (NF4 via bitsandbytes)
# Step 4: Add speculative decoding via assistant_model in generate()

# These optimizations stack - the throughput gains compound.
```

**Why it works**: Each step targets a different bottleneck (kernel efficiency, memory bandwidth, decoding sequentiality).

## PagedAttention via vLLM (KV Cache Management)

```python
from vllm import LLM, SamplingParams

llm = LLM(
    model="meta-llama/Llama-2-13b-hf",
    gpu_memory_utilization=0.9,    # vLLM pre-allocates pages
    max_num_seqs=256,              # higher batch thanks to PagedAttention
    enable_prefix_caching=True,    # share KV across prompts with same prefix
)
out = llm.generate(["Hello"] * 256, SamplingParams(max_tokens=128))
```

**Why it works**: Block-based KV memory eliminates fragmentation; large batch sizes become feasible without quadratic memory growth.
