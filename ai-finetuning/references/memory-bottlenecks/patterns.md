# Memory Bottlenecks Patterns

Reusable patterns for fitting large models in limited GPU memory.

## Pattern: Quantize-then-Finetune (QLoRA-style)

### Intent

Finetune a very large base model on a single consumer or mid-tier GPU.

### When to Use

- Base model weights don't fit in VRAM at FP16.
- Only a small fraction of parameters needs to update.
- Inference will tolerate quantized weights.

### Structure

```python
from transformers import AutoModelForCausalLM, BitsAndBytesConfig
from peft import LoraConfig, get_peft_model
import torch

bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_compute_dtype=torch.bfloat16,
    bnb_4bit_quant_type="nf4",
)
base = AutoModelForCausalLM.from_pretrained(
    MODEL_NAME, quantization_config=bnb_config, device_map="auto",
)
lora = LoraConfig(r=16, lora_alpha=32, target_modules=["q_proj", "v_proj"])
model = get_peft_model(base, lora)
```

### Trade-offs

- 4-bit base ~ 1/4 the memory of FP16; LoRA cuts trainable params 100-1000x.
- Quality typically slightly below full BF16 finetuning; needs compatible dequant kernels at inference.

---

## Pattern: Gradient Checkpointing for Long Context

### Intent

Train with long sequences when activations would otherwise dominate memory.

### When to Use

- Sequence length >= 4k tokens.
- Activation memory > weight memory in profiler.
- Compute is cheaper than memory.

### Structure

```python
model.gradient_checkpointing_enable()
model.config.use_cache = False  # required for HF transformers
```

### Trade-offs

- Reduces activation memory 5-10x.
- ~25-35% slower training step due to recomputation.

---

## Pattern: Mixed Precision with FP32 Master Weights

### Intent

Combine FP16/BF16 speed and memory savings with FP32 stability.

### When to Use

- Default for transformer training on modern GPUs.
- Loss spikes or NaNs when running pure FP16.

### Structure

```python
from torch.cuda.amp import autocast, GradScaler

scaler = GradScaler()  # not needed for pure BF16
for batch in loader:
    with autocast(dtype=torch.bfloat16):
        loss = model(batch).loss
    scaler.scale(loss).backward()
    scaler.step(optimizer)
    scaler.update()
```

### Trade-offs

- ~2x memory and throughput vs FP32; stability close to FP32.
- BF16 generally needs no GradScaler; FP16 does.

---

## Pattern: Freeze Layers to Cut Trainable Parameters

### Intent

Limit gradient and optimizer memory when full finetuning is too costly but PEFT isn't desired.

### When to Use

- Domain adaptation where only top layers need to change.
- You want to keep the base architecture untouched.

### Structure

```python
for p in model.parameters():
    p.requires_grad = False
for p in model.lm_head.parameters():
    p.requires_grad = True
for p in model.transformer.h[-2:].parameters():  # last 2 blocks
    p.requires_grad = True
```

### Trade-offs

- Cuts gradient/optimizer memory proportionally to frozen ratio.
- Less flexible than LoRA; may underperform PEFT on equal compute budget.

---

## Pattern: Sharded / Offloaded Training (ZeRO, FSDP, DeepSpeed)

### Intent

Spread weights, gradients, and optimizer states across multiple GPUs (or to CPU/NVMe) when no single device fits the model.

### When to Use

- Total training memory exceeds a single GPU.
- Multiple GPUs or NVMe-backed offload available.

### Structure

```python
from accelerate import Accelerator
# DeepSpeed ZeRO Stage 3 with offload:
# {"zero_optimization": {"stage": 3,
#                        "offload_optimizer": {"device": "cpu"},
#                        "offload_param": {"device": "cpu"}}}
accelerator = Accelerator(mixed_precision="bf16")
model, optimizer, loader = accelerator.prepare(model, optimizer, loader)
```

### Trade-offs

- Enables training models far larger than a single GPU.
- Inter-GPU bandwidth becomes the bottleneck; CPU/NVMe offload is 5-10x slower.

---

## Pattern: Match Inference Precision to Hardware

### Intent

Pick the smallest precision your target hardware supports natively for fastest, cheapest serving.

### When to Use

- Choosing a deployment dtype.
- Targeting edge devices, mobile, or specialized accelerators.

### Hardware Mapping

| Hardware | Recommended Format |
|----------|---------------------|
| NVIDIA Hopper / Blackwell | FP8, FP4, INT8 |
| NVIDIA Ampere / Ada | BF16, FP16, INT8 |
| Apple Silicon (Neural Engine) | INT8, mixed 2/4-bit |
| TPU | BF16 |
| CPU (AVX-512 VNNI) | INT8 |
| Edge / mobile | INT8, INT4 |

### Trade-offs

- Maximizes throughput by using native low-precision kernels.
- May require specific runtimes (TensorRT, TF Lite, Core ML, ONNX); always re-evaluate quality after PTQ.

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|---------------------|
| Model weights too large for one GPU | QLoRA-style or FSDP/ZeRO |
| Long-context training OOMs on activations | Gradient checkpointing |
| Want speed + stability for training | Mixed precision (BF16) |
| Need to update a few layers only | Freeze layers |
| Multi-GPU / cluster available | Sharded training (FSDP, DeepSpeed) |
| Targeting edge / mobile | INT8/INT4 PTQ matching hardware |
