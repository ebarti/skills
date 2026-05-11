# Finetuning Tactics Examples

Concrete examples for hyperparameters, framework setup, and base model selection.

## Hyperparameter Examples

### LoRA on a 7B Model with ~5,000 Instruction Examples

```python
training_args = {
    "learning_rate": 2e-4,        # Typical LoRA range: 1e-4 to 5e-4
    "per_device_train_batch_size": 4,
    "gradient_accumulation_steps": 4,   # Effective batch size = 16
    "num_train_epochs": 5,        # Small-medium dataset
    "lr_scheduler_type": "cosine",
    "warmup_ratio": 0.03,
    "weight_decay": 0.0,
    "prompt_loss_weight": 0.1,    # ~10% default
}
```

### Full Finetuning of a 7B Model with ~100k Examples

```python
training_args = {
    "learning_rate": 2e-5,        # Full FT: 1e-6 to 5e-5
    "per_device_train_batch_size": 2,
    "gradient_accumulation_steps": 16,  # Effective batch size = 32
    "num_train_epochs": 2,        # Large dataset
    "lr_scheduler_type": "cosine",
    "warmup_ratio": 0.03,
    "weight_decay": 0.01,
    "prompt_loss_weight": 0.1,
}
```

### Distillation: Strong Teacher with 200 Examples

```python
# Step 1: Finetune strongest model on 200 high-quality examples
teacher_args = {
    "base_model": "meta-llama/Llama-3.1-70B-Instruct",
    "method": "lora",
    "learning_rate": 3e-4,
    "num_train_epochs": 8,        # Few examples => more epochs
    "per_device_train_batch_size": 2,
}

# Step 2: Generate ~10k synthetic examples with the teacher
# Step 3: Finetune a cheaper student
student_args = {
    "base_model": "meta-llama/Llama-3.1-8B-Instruct",
    "method": "lora",
    "learning_rate": 2e-4,
    "num_train_epochs": 3,        # Larger synthetic dataset
}
```

## Framework Setup Snippets

### Hugging Face Transformers + PEFT (LoRA)

```python
from transformers import AutoModelForCausalLM, AutoTokenizer, TrainingArguments, Trainer
from peft import LoraConfig, get_peft_model

model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-3.1-8B")
tokenizer = AutoTokenizer.from_pretrained("meta-llama/Llama-3.1-8B")

lora_cfg = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules=["q_proj", "v_proj"],
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM",
)
model = get_peft_model(model, lora_cfg)

args = TrainingArguments(
    output_dir="./out",
    learning_rate=2e-4,
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    num_train_epochs=3,
    lr_scheduler_type="cosine",
    warmup_ratio=0.03,
    logging_steps=10,
    save_strategy="epoch",
)
trainer = Trainer(model=model, args=args, train_dataset=train_ds, eval_dataset=val_ds)
trainer.train()
```

### Axolotl (YAML-driven finetuning)

```yaml
# axolotl-config.yaml
base_model: meta-llama/Llama-3.1-8B-Instruct
load_in_4bit: true
adapter: qlora
lora_r: 16
lora_alpha: 32
lora_dropout: 0.05
sequence_len: 2048

datasets:
  - path: ./data/train.jsonl
    type: alpaca

micro_batch_size: 4
gradient_accumulation_steps: 4
num_epochs: 4
learning_rate: 2e-4
lr_scheduler: cosine
warmup_ratio: 0.03
```

```bash
# Run via accelerate
accelerate launch -m axolotl.cli.train axolotl-config.yaml
```

### Unsloth (memory-efficient LoRA)

```python
from unsloth import FastLanguageModel
import torch

model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="unsloth/llama-3-8b-bnb-4bit",
    max_seq_length=2048,
    dtype=torch.bfloat16,
    load_in_4bit=True,
)

model = FastLanguageModel.get_peft_model(
    model,
    r=16,
    lora_alpha=32,
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],
    lora_dropout=0.05,
)

# Train with HF Trainer or SFTTrainer; Unsloth speeds up step-time 2x.
```

### Smoke Test Before a Long Run

```python
# Run on 50 examples for 10 steps to validate the pipeline end-to-end.
smoke_args = TrainingArguments(
    output_dir="./smoke", max_steps=10, per_device_train_batch_size=2,
    learning_rate=2e-4, save_strategy="steps", save_steps=5, logging_steps=1,
)
trainer = Trainer(model=model, args=smoke_args, train_dataset=train_ds.select(range(50)))
trainer.train()
```

## Base Model Selection Examples

### Progression Path (English summarization, ~50k examples)

| Step | Model | Purpose |
|------|-------|---------|
| 1 | Llama-3.2-1B | Verify code runs end-to-end |
| 2 | Llama-3.1-8B | Verify training loss decreases with data |
| 3 | Llama-3.1-70B | Push best-case performance |
| 4 | Sweep 1B / 8B / 70B | Pick best price/performance |

### Distillation Path (legal document Q&A, 300 examples)

| Step | Model | Purpose |
|------|-------|---------|
| 1 | Llama-3.1-70B-Instruct + LoRA | Train strong teacher on 300 examples |
| 2 | Teacher | Generate 5,000 synthetic Q&A pairs |
| 3 | Llama-3.1-8B-Instruct + LoRA | Train cheap student on 5,300 examples |

### Choosing Instruct vs Base

| Task | Choose |
|------|--------|
| Instruction following / chat | Instruct variant |
| Continued pretraining on domain text | Base variant |
| Style transfer with prompts | Instruct variant |
| Embedding / classifier head | Base variant |

## Diagnosing the Loss Curve

| Symptom | Action |
|---------|--------|
| Loss bouncing wildly | Lower LR by 3-10x |
| Loss flat across many steps | Raise LR by 3-10x |
| Train falling, val rising | Reduce epochs (overfitting) |
| Both falling steadily at end | Add epochs or more data |
| Loss diverges to NaN | Lower LR; check data for outliers |
