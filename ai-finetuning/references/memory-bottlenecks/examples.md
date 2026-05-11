# Memory Bottlenecks Examples

Concrete memory calculations and Python helpers for sizing inference and training workloads.

## Bytes per Value Reference

```python
BYTES_PER_VALUE = {
    "fp32": 4,
    "tf32": 4,    # stored in 32 bits on GPU
    "fp16": 2,
    "bf16": 2,
    "fp8":  1,
    "int8": 1,
    "fp4":  0.5,
    "int4": 0.5,
}
```

## Inference Memory Examples

### Helper

```python
def inference_memory_gb(num_params: float, bytes_per_value: float, overhead: float = 1.2) -> float:
    """Approximate inference memory in GB for a model of `num_params` parameters."""
    weights_bytes = num_params * bytes_per_value
    return weights_bytes * overhead / 1e9
```

### 7B Model — Inference

```python
# FP16 / BF16 (2 bytes per param)
inference_memory_gb(7e9, 2)   # ~16.8 GB total (14 GB weights + 2.8 GB overhead)

# INT8 (1 byte per param)
inference_memory_gb(7e9, 1)   # ~8.4 GB total (7 GB weights)

# INT4 (0.5 bytes per param) -- e.g. QLoRA base
inference_memory_gb(7e9, 0.5) # ~4.2 GB total (3.5 GB weights)
```

### 13B Model — Inference (book's worked example)

```python
inference_memory_gb(13e9, 2)  # 26 GB weights * 1.2 = 31.2 GB total
```

A 24 GB GPU (e.g., RTX 4090) cannot run a 13B model in FP16 — must quantize to INT8 or smaller.

### 70B Model — Inference

```python
inference_memory_gb(70e9, 2, overhead=1.0)  # 140 GB weights only
inference_memory_gb(70e9, 2)                # 168 GB total
inference_memory_gb(70e9, 1)                # 84 GB total (INT8)
inference_memory_gb(70e9, 0.5)              # 42 GB total (INT4)
```

## Training Memory Examples

### Helper

```python
OPTIMIZER_STATES = {"sgd": 0, "momentum": 1, "adam": 2}

def training_memory_gb(
    total_params: float,
    trainable_params: float,
    bytes_per_value: float,
    optimizer: str = "adam",
    activation_factor: float = 0.2,
) -> dict:
    """Rough training memory breakdown in GB.

    Note: activation_factor=0.2 follows the inference rule of thumb.
    Real activations can far exceed weights for long sequences.
    """
    weights = total_params * bytes_per_value
    activations = weights * activation_factor
    extra_per_param = (1 + OPTIMIZER_STATES[optimizer]) * bytes_per_value
    grads_and_states = trainable_params * extra_per_param
    total = weights + activations + grads_and_states
    return {
        "weights_gb": weights / 1e9,
        "activations_gb": activations / 1e9,
        "grad_and_optimizer_gb": grads_and_states / 1e9,
        "total_gb": total / 1e9,
    }
```

### 7B Model — Full Finetuning with Adam (BF16)

```python
training_memory_gb(7e9, 7e9, bytes_per_value=2, optimizer="adam")
# weights         : 14 GB
# activations     : ~2.8 GB
# grads + Adam    : 7e9 * 3 * 2 = 42 GB
# total           : ~58.8 GB  -- needs 80 GB A100/H100
```

### 13B Model — Full Finetuning with Adam (BF16, book example)

```python
training_memory_gb(13e9, 13e9, bytes_per_value=2, optimizer="adam")
# weights         : 26 GB
# activations     : ~5.2 GB
# grads + Adam    : 13e9 * 3 * 2 = 78 GB
# total           : ~109 GB  -- multi-GPU territory
```

### 13B Model — PEFT (only 1B Trainable, book example)

```python
training_memory_gb(13e9, 1e9, bytes_per_value=2, optimizer="adam")
# weights         : 26 GB
# activations     : ~5.2 GB
# grads + Adam    : 1e9 * 3 * 2 = 6 GB
# total           : ~37 GB  -- fits on 40 GB A100
```

### 70B Model — QLoRA-Style (4-bit Base + LoRA Adapters)

```python
# Conceptual: base weights in INT4, ~50M trainable LoRA params in BF16
base_weights_gb = 70e9 * 0.5 / 1e9         # 35 GB
lora_params = 50e6
lora_adam_extra_gb = lora_params * 3 * 2 / 1e9   # 0.3 GB
# plus activations -- still fits on a single 48-80 GB GPU
```

## Quantization Examples

### FP32 -> FP16: Halve Memory

```python
# 13B parameters
fp32_weights_gb = 13e9 * 4 / 1e9  # 52 GB
fp16_weights_gb = 13e9 * 2 / 1e9  # 26 GB  (50% reduction)
```

### FP16 -> INT8: Halve Again

```python
# 10B parameters
fp16_weights_gb = 10e9 * 2 / 1e9  # 20 GB
int8_weights_gb = 10e9 * 1 / 1e9  # 10 GB  (75% reduction vs FP32)
```

### Loading Models with Quantization (Hugging Face)

```python
from transformers import AutoModelForCausalLM, BitsAndBytesConfig
import torch

# Load in 8-bit (LLM.int8)
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-13b-hf",
    quantization_config=BitsAndBytesConfig(load_in_8bit=True),
    device_map="auto",
)

# Load in 4-bit for QLoRA
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_compute_dtype=torch.bfloat16,
    bnb_4bit_quant_type="nf4",
)
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-70b-hf",
    quantization_config=bnb_config,
    device_map="auto",
)
```

### Mixed Precision Training (PyTorch AMP)

```python
from torch.cuda.amp import autocast, GradScaler

scaler = GradScaler()
for batch in loader:
    optimizer.zero_grad()
    with autocast(dtype=torch.bfloat16):
        loss = model(batch).loss
    scaler.scale(loss).backward()
    scaler.step(optimizer)
    scaler.update()
```

## Quick GPU Sizing Table

| Model | Inference (BF16) | Inference (INT4) | Full FT (Adam, BF16) | PEFT (1% trainable) |
|-------|------------------|------------------|----------------------|---------------------|
| 7B   | ~17 GB | ~4 GB  | ~59 GB  | ~17 GB |
| 13B  | ~31 GB | ~8 GB  | ~109 GB | ~31 GB |
| 70B  | ~168 GB| ~42 GB | ~590 GB | ~168 GB |
