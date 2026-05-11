# Memory Bottlenecks Rules

Practical rules for sizing GPUs, choosing precision, and applying quantization to fit models in memory.

## Core Rules

### 1. Estimate Inference Memory with N x M x 1.2

For a model of N parameters using M bytes per parameter:

- Weights: `N × M`
- Add ~20% for activations + KV cache: `N × M × 1.2`
- Increase further if you use long context windows or large batch sizes.

**Example**:
```python
# 13B model in FP16 (M = 2 bytes)
weights_gb = 13e9 * 2 / 1e9          # 26 GB
inference_gb = weights_gb * 1.2      # ~31.2 GB
```

### 2. Estimate Training Memory as Weights + Activations + Gradients + Optimizer States

For each trainable parameter, add:

- 1 value for the gradient
- 0 (SGD), 1 (momentum), or 2 (Adam) values for optimizer state

**Adam rule of thumb**: each trainable param needs `3 × bytes_per_value` of extra memory on top of weights and activations.

```python
# 13B params, all trainable, Adam, 2 bytes/value
extra_gb = 13e9 * 3 * 2 / 1e9        # 78 GB on top of weights+activations
```

### 3. Reduce Trainable Parameters to Cut Training Memory

Gradients and optimizer states scale with trainable params, not total params. Freezing params or using PEFT (LoRA, adapters) can shrink training memory by 10x or more.

```python
# Same 13B model, only 1B trainable, Adam, 2 bytes/value
extra_gb = 1e9 * 3 * 2 / 1e9         # 6 GB extra
```

### 4. Match Numerical Format to How the Model Was Trained

Loading a BF16-trained model as FP16 (or vice versa) can silently degrade quality.

```python
# Bad: loading a BF16 model in FP16
model = AutoModel.from_pretrained("meta-llama/Llama-2-7b", torch_dtype=torch.float16)

# Good: use the format the model was trained in
model = AutoModel.from_pretrained("meta-llama/Llama-2-7b", torch_dtype=torch.bfloat16)
```

### 5. Quantize for Inference Aggressively, for Training Cautiously

- **Inference**: 16-bit is the default; 8-bit and 4-bit are widely usable. PTQ in PyTorch / Transformers / TF Lite is one-line.
- **Training**: prefer mixed precision (BF16/FP16 with FP32 master weights). Going below 16-bit during training is harder; backprop is sensitive to low precision.

### 6. Use Gradient Checkpointing When Activations Dominate

Long sequences and large batch sizes make activation memory dwarf weight memory. Gradient checkpointing (activation recomputation) trades ~30% extra training time for large memory savings.

```python
model.gradient_checkpointing_enable()
```

### 7. Prefer BF16 over FP16 for Training Stability

BF16 matches FP32's range, which avoids overflow on large activations and gradients. FP16 is more precise but more prone to NaN/Inf during training.

## Guidelines

- **Round generously when sizing GPUs**: leave 10–20% headroom for fragmentation, framework overhead, and CUDA workspaces.
- **Profile activation memory** before assuming it's only ~20% of weights — for transformers with long context it can exceed weights.
- **Use AMP (`torch.cuda.amp` / `accelerate`)** rather than hand-managing mixed precision.
- **Combine PEFT + quantization** (e.g., QLoRA: 4-bit base weights + LoRA adapters) for the largest models on consumer GPUs.
- **For deployment to edge devices**, plan for INT8 or INT4 from the start; some hardware only supports quantized inference.

## Exceptions

- **Edge / mobile inference**: low-bit (INT8, INT4) is not optional — required by the runtime.
- **Numerical-sensitive workloads** (scientific, some RL): may need to keep FP32 for parts of the graph.
- **Embeddings and norm layers**: often kept in higher precision even when other layers are quantized (cf. LLM-QAT).
- **Models small enough to fit easily**: don't quantize prematurely; you trade quality for memory you don't need.

## Quick Reference

| Rule | Summary |
|------|---------|
| Inference memory | N × M × 1.2 |
| Training extra (Adam) | trainable × 3 × bytes_per_value |
| Match dtype to training | BF16 model → load as BF16 |
| Reduce trainable | Use PEFT to slash gradient/optimizer memory |
| Activations large | Enable gradient checkpointing |
| Training precision | BF16 mixed precision is the safe default |
| Inference precision | Default 16-bit; 8/4-bit when memory-constrained |
