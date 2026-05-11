# Model Optimization Rules

Guidelines for choosing and applying model-level optimization techniques.

## Core Rules

### 1. Start with Quantization Before Anything Else

Weight-only quantization is the default first move - easy, works out of the box, extremely effective.

- FP32 -> FP16 halves memory with negligible quality impact for most models
- INT8 quantization is the next standard step (typical 2x throughput gain)
- INT4 is aggressive - validate quality on your task before shipping
- You cannot quantize below 1 bit - this is the floor

**Example**:
```python
# Bad: deploying full FP32 weights and complaining about cost
model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-2-7b")

# Good: quantize first, measure quality, then iterate
from transformers import BitsAndBytesConfig
bnb = BitsAndBytesConfig(load_in_8bit=True)
model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-2-7b", quantization_config=bnb)
```

### 2. Use Speculative Decoding When Output is Latency-Critical

Speculative decoding is lossless and easy to add via vLLM, TensorRT-LLM, or llama.cpp.

- Best ROI when target model is large (70B+) and a small same-vocab draft model exists
- Expect 1.5x-2x throughput; higher for structured outputs like code
- Acceptance rate is domain-dependent; benchmark on your traffic
- Draft model must share vocabulary/tokenizer with target model

### 3. Don't Pick Pruning by Default

Use only when you have architectural expertise, sparse-aware hardware, and quantization/distillation aren't enough.

- Sparse models need hardware support to realize speedup
- Performance recovery often requires finetuning
- Most teams should choose distillation before pruning

### 4. Always Account for KV Cache in Memory Budget

KV cache often exceeds model weight memory at long context or large batch sizes.

- Calculate before deploying: `2 x B x S x L x H x M` bytes
- Llama 2 13B at batch 32, seq 2048, FP16 = 54 GB KV cache alone
- For long context, KV cache is the dominant memory consumer

### 5. Use FlashAttention When Available

Use the existing kernel - don't write your own.

- FlashAttention is bundled in PyTorch 2+, vLLM, TensorRT-LLM
- FlashAttention v2/v3 target newer GPUs (H100); pick the version matching your hardware
- Rely on `torch.compile` or `transformers` integrations rather than manual kernel writing

### 6. Pick Attention Variant at Training Time, Not Inference

MQA, GQA, and local attention are architectural changes - they require training or finetuning.

- GQA balances quality and KV reduction; default for new model designs (Llama 3 uses GQA)
- MQA is more aggressive; can hurt quality on some tasks
- Local windowed attention combined with sparse global attention works for very long context

## Guidelines

- **Layer optimizations cumulatively**: PyTorch case study showed `torch.compile` -> INT8 -> INT4 -> speculative decoding stacks for compounding gains
- **Use inference with reference for retrieval/coding/multi-turn**: Up to 2x speedup when output overlaps input
- **Use vLLM if you can't justify custom infra**: PagedAttention solves KV cache fragmentation for free
- **Validate quality after every step**: Optimization can degrade outputs in ways benchmarks don't catch
- **Profile before optimizing**: Confirm whether you're memory-bound, compute-bound, or latency-bound

## Exceptions

When these rules may be relaxed:

- **Edge / mobile deployment**: INT4 or aggressive pruning may be required despite quality cost
- **Custom hardware**: When deploying on a chip without standard kernels, custom kernel work is unavoidable
- **Hard real-time constraints**: Speculative decoding can hurt p99 latency if all draft tokens are rejected; measure both p50 and p99
- **Tiny draft model unavailable**: Use inference with reference if you can't get a same-vocab draft model

## When Custom Kernels Are Worth It

Only invest in custom kernels when:
- Profiling identifies a specific op as a bottleneck >20% of inference time
- Existing kernels (FlashAttention, cuBLAS) don't cover your op
- You have CUDA/Triton expertise on the team
- The model will run unchanged on the same hardware long enough to amortize the engineering cost

## Quick Reference

| Situation | Recommended Technique |
|-----------|----------------------|
| Memory-bound, easy win | Weight-only quantization (INT8) |
| Need smaller model with similar behavior | Distillation |
| Latency-bound generation | Speculative decoding |
| Long input/output overlap (RAG, code) | Inference with reference |
| Long context, memory bottleneck | GQA + PagedAttention + KV quantization |
| Throughput on attention-heavy workload | FlashAttention via vLLM |
| Whole-model speedup | torch.compile + quantization + speculative decoding |
| New hardware, no kernel exists | Custom kernel (last resort) |
