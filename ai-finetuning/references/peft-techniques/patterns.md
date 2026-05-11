# PEFT Techniques Patterns

Reusable patterns for common PEFT use cases.

## Pattern: Single-Task LoRA Finetune

### Intent

Adapt one base model to one downstream task with minimal memory and a portable artifact.

### When to Use

- One task, one model; base fits in GPU at FP16/BF16
- Want zero inference overhead at deploy time

### Structure

```python
base = AutoModelForCausalLM.from_pretrained(BASE_ID, torch_dtype=torch.bfloat16)
config = LoraConfig(task_type="CAUSAL_LM", r=8, lora_alpha=16,
                    target_modules=["q_proj","k_proj","v_proj","o_proj"])
model = get_peft_model(base, config)
Trainer(model=model, ...).train()
merged = model.merge_and_unload()  # zero inference cost
merged.save_pretrained("./deploy/model")
```

### Benefits

- Smallest deployable footprint; no latency overhead vs. full FT; cheap to train

### Considerations

- After merging you lose the modular adapter file; keep the unmerged adapter as backup

---

## Pattern: QLoRA for Oversized Base Model

### Intent

Finetune a model whose FP16 weights exceed available GPU memory.

### When to Use

- Model would not fit in GPU at FP16/BF16
- 30B+ models on a single consumer/prosumer GPU
- Long context lengths increase activation memory

### Structure

```python
bnb = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_quant_type="nf4",
                         bnb_4bit_compute_dtype=torch.bfloat16,
                         bnb_4bit_use_double_quant=True)

base = AutoModelForCausalLM.from_pretrained(BASE_ID, quantization_config=bnb,
                                            device_map="auto")
base = prepare_model_for_kbit_training(base)

config = LoraConfig(r=16, lora_alpha=32,
                    target_modules=["q_proj","k_proj","v_proj","o_proj"],
                    task_type="CAUSAL_LM")
model = get_peft_model(base, config)
# train as usual
```

### Benefits

- Enables 65B-class finetuning on a single 48 GB GPU
- Paged optimizers handle long-context memory spikes
- Adapter is still small and reusable

### Considerations

- Slower per training step (quantize/dequantize overhead)
- NF4 dequantization happens on every forward/backward pass

---

## Pattern: Multi-LoRA Serving (One Base, Many Adapters)

### Intent

Serve many task- or customer-specific finetunes from a single base model in memory.

### When to Use

- Per-customer finetunes (e.g., 100 customers)
- Many specialized tasks sharing one foundation model
- Need fast task switching (no full model reload)

### Structure

```python
base = AutoModelForCausalLM.from_pretrained(BASE_ID, device_map="auto")
model = PeftModel.from_pretrained(base, ADAPTER_PATHS[0],
                                  adapter_name=NAMES[0])
for path, name in zip(ADAPTER_PATHS[1:], NAMES[1:]):
    model.load_adapter(path, adapter_name=name)

def serve(request):
    model.set_adapter(request.customer_id)
    return model.generate(**request.inputs)
```

### Benefits

- Storage: 100 adapters at ~10s of MB each vs. 100 full models at GBs each
- Fast switching: load adapter, not full model
- Lets you offer per-tenant models cheaply

### Considerations

- Small inference latency overhead vs. merged single model
- Adapter routing logic must match request to adapter name

---

## Pattern: On-Device Adapter Stack (Apple-style)

### Intent

Ship one quantized base model plus many small task adapters to constrained devices.

### When to Use

- Mobile / embedded deployment with tight storage
- Multiple features need bespoke behavior on one device

### Structure

```text
Device:
  base_model.q4 (e.g., 3B in 4-bit)
  adapters/{summarize,rewrite,classify}.lora (few MB each)
Runtime: load base once -> register adapters -> switch per request
```

### Benefits

- One base, many specialized behaviors; ship features as new adapters

### Considerations

- Quantization + PEFT compounds approximation error

---

## Pattern: Soft-Prompt Tuning for Lightest Touch

### Intent

Customize behavior with the smallest possible parameter footprint by training prepended virtual tokens.

### When to Use

- Want more control than prompt engineering, but don't want LoRA
- Need many specialized "prompt heads" with tiny storage per head

### Structure

```python
from peft import PromptTuningConfig, get_peft_model, TaskType
config = PromptTuningConfig(task_type=TaskType.CAUSAL_LM,
                            num_virtual_tokens=20,
                            tokenizer_name_or_path=BASE_ID)
model = get_peft_model(base, config)
```

### Benefits

- Smallest trainable footprint of any PEFT method

### Considerations

- Generally lower quality ceiling than LoRA
- Variant zoo (prefix tuning, P-Tuning, prompt tuning); use what your framework supports

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|-------------------|
| One task, base fits in GPU | Single-Task LoRA Finetune |
| Base too big for GPU memory | QLoRA for Oversized Base Model |
| Many customers, one base | Multi-LoRA Serving |
| Mobile / embedded device | On-Device Adapter Stack |
| Need lightest possible footprint | Soft-Prompt Tuning |
| Need maximum quality, have compute | Full finetuning (not PEFT) |
