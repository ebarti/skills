# Model Merging Examples

Concrete recipes for merging models, with multi-task FT vs merging tradeoffs.

## Example 1: Merging Two LoRA Adapters (Linear Combination)

Two LoRA adapters from the same base, combined into one adapter for multi-task inference.

```python
import torch
from peft import PeftModel
from transformers import AutoModelForCausalLM

BASE = "meta-llama/Llama-2-7b-hf"
base_A = AutoModelForCausalLM.from_pretrained(BASE, torch_dtype=torch.float16)
model_A = PeftModel.from_pretrained(base_A, "team/llama2-sql-lora")
model_B = PeftModel.from_pretrained(
    AutoModelForCausalLM.from_pretrained(BASE, torch_dtype=torch.float16),
    "team/llama2-fncall-lora",
)

# Average each LoRA tensor (linear combination, w_A = w_B = 1)
sd_A = {k: v for k, v in model_A.state_dict().items() if "lora_" in k}
sd_B = {k: v for k, v in model_B.state_dict().items() if "lora_" in k}
merged = {k: (sd_A[k].float() + sd_B[k].float()) / 2.0 for k in sd_A}

model_A.load_state_dict(merged, strict=False)
model_A.save_pretrained("team/llama2-sql-fncall-merged")
```

**Why it works**: shared base makes task vectors comparable; rank stays flat (no inference cost growth); no GPU needed.

## Example 2: Weighted Linear Combination (Bias Toward One Task)

When one task matters more than the other, weight it higher.

```python
# 70% SQL, 30% function calling
w_A, w_B = 0.7, 0.3
merged = {
    k: (w_A * sd_A[k].float() + w_B * sd_B[k].float()) / (w_A + w_B)
    for k in sd_A
}
```

## Example 3: Task Vector Arithmetic (Add and Subtract)

Compose capabilities by treating finetuned − base as a task vector.

```python
import torch

def task_vector(finetuned_sd, base_sd):
    return {k: finetuned_sd[k] - base_sd[k] for k in base_sd}

base_sd      = base_A.state_dict()
sql_sd       = model_A.state_dict()  # SQL-finetuned
fncall_sd    = model_B.state_dict()  # function-call-finetuned
toxic_sd     = model_C.state_dict()  # finetuned to be toxic (we want to remove)

tv_sql    = task_vector(sql_sd, base_sd)
tv_fncall = task_vector(fncall_sd, base_sd)
tv_toxic  = task_vector(toxic_sd, base_sd)

# Combine SQL + function calling, subtract toxicity
merged_sd = {
    k: base_sd[k] + tv_sql[k] + tv_fncall[k] - tv_toxic[k]
    for k in base_sd
}
```

**Use cases**:
- **Add**: combine independent skills.
- **Subtract**: remove undesired behaviors (bias, unsafe capability).

## Example 4: SLERP Between Two Models

Spherical interpolation, useful when linear average underperforms.

```python
import torch

def slerp(t, v0, v1, eps=1e-8):
    v0_n, v1_n = v0 / (v0.norm() + eps), v1 / (v1.norm() + eps)
    omega = torch.acos((v0_n * v1_n).sum().clamp(-1.0, 1.0))
    so = torch.sin(omega) + eps
    return torch.sin((1 - t) * omega) / so * v0 + torch.sin(t * omega) / so * v1

# t=0.5 = midpoint; t<0.5 favors A; t>0.5 favors B. Chain for 3+ models.
merged = {k: slerp(0.5, sd_A[k].float().flatten(), sd_B[k].float().flatten())
              .reshape(sd_A[k].shape) for k in sd_A}
```

## Example 5: Layer Stacking (Frankenmerging)

Take layers from two models and stack them — Goliath-120B style.

```python
import torch
from transformers import AutoModelForCausalLM
from copy import deepcopy

model_X = AutoModelForCausalLM.from_pretrained("team/llama2-70b-xwin")
model_Y = AutoModelForCausalLM.from_pretrained("team/llama2-70b-euryale")

# Take 72 of 80 layers from each
layers_X = model_X.model.layers[:72]
layers_Y = model_Y.model.layers[:72]

# Build a frankenmerged model: 72 from X, then 72 from Y = 144 layers
merged = deepcopy(model_X)
merged.model.layers = torch.nn.ModuleList(list(layers_X) + list(layers_Y))
merged.config.num_hidden_layers = 144

merged.save_pretrained("team/goliath-style-144L")
# Required: re-finetune to align the stacked layers
```

**Why post-merge finetuning is required**:
- Stacked layers were trained against different downstream representations.
- Without re-finetuning, signal flow breaks at the seam.

## Example 6: Concatenating Two LoRA Adapters

Rank grows from r1 + r2 — more capacity, more memory.

```python
import torch
# Adapter A: rank 8. Adapter B: rank 16. Merged rank: 24.
A_down, A_up = sd_A["lora_A.weight"], sd_A["lora_B.weight"]   # [8, d], [d, 8]
B_down, B_up = sd_B["lora_A.weight"], sd_B["lora_B.weight"]   # [16, d], [d, 16]

merged_down = torch.cat([A_down, B_down], dim=0)              # [24, d]
merged_up   = torch.cat([A_up, B_up],   dim=1)                # [d, 24]
```

**Caveat**: prefer summing — concatenation gives up the memory-saving benefit.

## Multi-Task FT vs Merging: Tradeoffs

| Strategy | Pros | Cons | Use When |
|----------|------|------|----------|
| Simultaneous FT (mixed dataset) | One model, balanced learning | Needs more data + compute; tasks compete | Tasks are similar; data abundant |
| Sequential FT | Each task learned in isolation | **Catastrophic forgetting** | Rare — usually a bad choice |
| Parallel FT + merge | No forgetting; cheap merge; per-task quality | Merge can blur per-task peak | Common case for multi-task adapters |
| Ensembling | Highest quality ceiling | N× inference cost | Latency budget allows; quality critical |

## Refactoring Walkthrough: Sequential FT to Parallel FT + Merge

### Before

```python
# Sequential — task A skill degrades while learning task B
model = finetune(base, dataset_A, epochs=3)
model = finetune(model, dataset_B, epochs=3)
model = finetune(model, dataset_C, epochs=3)
# Eval: task A is now 30% worse than the model trained on A alone
```

### After

```python
# Parallel from the same base, then merge
model_A = finetune(base, dataset_A, epochs=3)
model_B = finetune(base, dataset_B, epochs=3)
model_C = finetune(base, dataset_C, epochs=3)

# Compute task vectors and prune (TIES-style) before summing
def task_vector(ft, base): return {k: ft[k] - base[k] for k in base}
def prune(tv, keep_ratio=0.2):
    out = {}
    for k, v in tv.items():
        thresh = v.abs().flatten().kthvalue(int((1-keep_ratio) * v.numel())).values
        out[k] = torch.where(v.abs() >= thresh, v, torch.zeros_like(v))
    return out

base_sd = base.state_dict()
tvs = [prune(task_vector(m.state_dict(), base_sd)) for m in (model_A, model_B, model_C)]
merged_sd = {k: base_sd[k] + sum(tv[k] for tv in tvs) for k in base_sd}

# Eval: each task within ~5% of its standalone-finetuned peak; no forgetting
```

### Changes Made

1. Trained each task in parallel from the same base — eliminates catastrophic forgetting.
2. Computed task vectors against the shared base — enables principled summing.
3. Applied TIES-style pruning before summing — reduces inter-task interference.
4. Single merged model serves all three tasks at the cost of one model's memory.
