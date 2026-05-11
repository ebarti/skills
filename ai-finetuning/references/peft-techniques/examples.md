# PEFT Techniques Examples

Practical Python examples for setting up LoRA and QLoRA, choosing rank/alpha, and serving multiple LoRA adapters.

## Bad Examples

### Full Finetuning a 7B Model on a Consumer GPU

```python
model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-2-7b-hf",
                                             torch_dtype="float16")
# 14 GB weights + 42 GB Adam (3x weights) = 56 GB --> OOM on 24 GB GPU
Trainer(model=model, args=TrainingArguments(...)).train()
```

**Problems**: exceeds GPU memory; needs lots of data; no reusable adapter artifact.

### LoRA on Only One Attention Matrix

```python
config = LoraConfig(r=8, lora_alpha=16, target_modules=["q_proj"])
```

**Problems**: leaves quality on the table; for a two-matrix budget pick Wq + Wv, not Wq alone.

### Picking a Huge Rank Hoping for Better Quality

```python
config = LoraConfig(r=512, lora_alpha=64,
                    target_modules=["q_proj", "v_proj"])
```

**Problems**: r in [4, 64] usually suffices; r = 512 inflates memory with no quality gain and risks overfitting.

## Good Examples

### Standard LoRA Setup with Hugging Face PEFT

```python
from peft import LoraConfig, get_peft_model, TaskType
from transformers import AutoModelForCausalLM

base = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-2-7b-hf")

lora_config = LoraConfig(
    task_type=TaskType.CAUSAL_LM,
    r=8,
    lora_alpha=16,           # alpha = 2 * r is a common starting point
    lora_dropout=0.05,
    bias="none",
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],  # all attention
)

model = get_peft_model(base, lora_config)
model.print_trainable_parameters()
# trainable params: ~4.2M || all params: ~6.7B || trainable%: 0.06%
```

**Why it works**:
- Targets all four attention matrices, the most common high-impact choice
- Rank 8 with alpha 16 is a safe default
- Trainable parameters are <0.1% of the total

### QLoRA for a Large Model on a Single GPU

```python
import torch
from transformers import AutoModelForCausalLM, BitsAndBytesConfig
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training

bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",        # NormalFloat-4
    bnb_4bit_compute_dtype=torch.bfloat16,
    bnb_4bit_use_double_quant=True,
)

base = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-65b-hf",
    quantization_config=bnb_config,
    device_map="auto",
)
base = prepare_model_for_kbit_training(base)

lora_config = LoraConfig(
    r=16, lora_alpha=32, lora_dropout=0.05, bias="none",
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],
    task_type="CAUSAL_LM",
)
model = get_peft_model(base, lora_config)
```

**Why it works**:
- 4-bit NF4 quantization shrinks the 65B base to fit a single 48 GB GPU
- BF16 compute keeps numerical stability during forward/backward
- LoRA still applied at full precision in the adapter

### Including FFN Layers (Stronger Quality Boost)

```python
lora_config = LoraConfig(
    r=8, lora_alpha=16, lora_dropout=0.05, bias="none",
    target_modules=[
        "q_proj", "k_proj", "v_proj", "o_proj",   # attention
        "gate_proj", "up_proj", "down_proj",      # feedforward (Llama-style)
    ],
    task_type="CAUSAL_LM",
)
```

**Why it works**:
- Databricks reported the biggest boost came from LoRA on FFN layers
- Attention + FFN coverage tends to outperform attention-only

### Common Rank/Alpha Settings

```python
LoraConfig(r=4,  lora_alpha=16, ...)   # conservative, alpha:r = 4:1
LoraConfig(r=8,  lora_alpha=16, ...)   # default,      alpha:r = 2:1
LoraConfig(r=16, lora_alpha=32, ...)   # stronger,     alpha:r = 2:1
LoraConfig(r=64, lora_alpha=16, ...)   # hard tasks,   alpha:r = 1:4
```

**Why it works**: alpha:r kept inside [1:8, 8:1]; sweep these early since optimum is task-dependent.

### Saving and Loading LoRA Adapters

```python
model.save_pretrained("./adapters/customer_a")  # small file, ~MBs

# Reload later
from peft import PeftModel
base = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-2-7b-hf")
model = PeftModel.from_pretrained(base, "./adapters/customer_a")

# Or merge into base for zero inference overhead
merged = model.merge_and_unload()
merged.save_pretrained("./merged/customer_a")
```

**Why it works**: adapter is tiny vs. base; `merge_and_unload()` produces a standard model with no LoRA layers and no inference cost.

### Multi-LoRA Serving (Keep Adapters Separate)

```python
from peft import PeftModel
from transformers import AutoModelForCausalLM

base = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-2-7b-hf",
                                            device_map="auto")
model = PeftModel.from_pretrained(base, "./adapters/customer_a",
                                  adapter_name="customer_a")
model.load_adapter("./adapters/customer_b", adapter_name="customer_b")
model.load_adapter("./adapters/customer_c", adapter_name="customer_c")

# Hot-swap per request
model.set_adapter("customer_b"); out_b = model.generate(**inputs)
model.set_adapter("customer_c"); out_c = model.generate(**inputs)
```

**Why it works**:
- One base model in memory, many small adapters share it
- Storage: e.g., one 16.8M-param W vs. 100 full Ws (1.68B) is now 1 W + 100 small (A,B) = ~23.3M
- Switching customers loads only the adapter, not a full model

## Refactoring Walkthrough

### Before (full FT, OOM-prone)

```python
model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-2-7b-hf",
                                             torch_dtype=torch.float16)
Trainer(model=model, args=TrainingArguments(num_train_epochs=3)).train()
```

### After (LoRA, fits a single GPU)

```python
base = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-2-7b-hf",
                                            torch_dtype=torch.bfloat16)
config = LoraConfig(task_type="CAUSAL_LM", r=8, lora_alpha=16,
                    lora_dropout=0.05,
                    target_modules=["q_proj","k_proj","v_proj","o_proj"])
model = get_peft_model(base, config)
model.print_trainable_parameters()
Trainer(model=model, args=TrainingArguments(num_train_epochs=3)).train()
model.save_pretrained("./adapters/v1")
```

### Changes Made

1. Wrapped base with `get_peft_model` -> only LoRA params trainable
2. Targeted all four attention matrices at r = 8, alpha = 16
3. Saved a small adapter artifact instead of a full model checkpoint
