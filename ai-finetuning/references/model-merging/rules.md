# Model Merging Rules

Guidelines for choosing when to merge, which approach to use, and what compatibility constraints to respect.

## Core Rules

### 1. Prefer parallel finetuning + merging over sequential multi-task finetuning

Sequential finetuning causes **catastrophic forgetting**. Train each task on a separate copy of the same base, then merge.

- Use simultaneous (single mixed dataset) only when you have abundant data and compute.
- Use parallel + merge when you want each task learned cleanly and want to limit forgetting.

**Example**:
```python
# Bad: sequential finetuning forgets task A while learning task B
model = finetune(base, dataset_A)
model = finetune(model, dataset_B)   # task A skill degrades

# Good: parallel finetuning, then merge
model_A = finetune(base, dataset_A)
model_B = finetune(base, dataset_B)
merged  = merge_linear([model_A, model_B], weights=[0.5, 0.5])
```

### 2. Linear combination is most effective when constituents share the same base

Task vectors only compose meaningfully when computed against the same base model.

- All constituents should be finetuned from the same pre-trained checkpoint.
- If bases differ, expect degraded merged quality and consider layer stacking instead.

### 3. Rescale before summing if parameter scales differ

If one model's weights are much larger than the other's, summing biases the result toward the larger model unintentionally.

- Inspect weight magnitudes before summing.
- Apply per-tensor or per-layer normalization to bring scales into the same range.

### 4. Use SLERP only for pairs; chain for more

SLERP is mathematically defined for two vectors.

- Two models: SLERP directly with an interpolation factor `t ∈ [0, 1]`.
- Three or more: chain — `slerp(slerp(A, B, t1), C, t2)`. Note: order affects the result.

### 5. Prune redundant task-vector parameters before summing many models

TIES / DARE remove parameters that don't contribute to performance to reduce inter-task interference.

- Required when merging 3+ task vectors — interference grows with count.
- Prune ratios of 50–90% are common and well-tolerated.

### 6. Re-finetune after layer stacking

Layer-stacked (frankenmerged) models almost always need further training to recover or surpass the constituents' performance.

- Budget post-merge finetuning compute when planning a layer-stacking project.
- Skip post-finetuning only if you are stacking copies of the same model (some upscaling cases).

### 7. Avoid concatenation unless extra params are justified

Concatenation grows parameter count (e.g., r1 + r2 for LoRA ranks) and gives up the memory-saving benefit of merging.

- Prefer summing when you want one model with no size growth.
- Use concatenation only when measured quality gain outweighs the memory cost.

### 8. Confirm architecture/size compatibility before merging

Summing and SLERP assume matching shapes per tensor.

- Same architecture + same size: merge directly.
- Different sizes: project layers to a common dimension (extra step, error-prone).
- Different architectures: usually not worth it; consider distillation or ensembling.

## Guidelines

- For LoRA-finetuned models that share a base, **merging adapters is the default move** — cheap, fast, no GPU needed.
- For on-device deployment, merge multiple task models into one to fit memory; one model with multi-task capability beats juggling N models.
- When deploying federated-learning aggregations, linear combination is the standard merge operator.
- For task removal (debiasing, capability stripping), use **task-vector subtraction** instead of full retraining.
- When upscaling a model to use new GPU headroom, depthwise layer stacking is cheaper than training from scratch.
- Mix approaches per layer (sum some, stack others) when one technique alone underperforms.
- Verify merged-model quality on each constituent task — merging can regress one task while helping another.

## Exceptions

- **Different bases**: linear combination still works for some narrow cases (e.g., model soups across hyperparameter sweeps), but expect lower quality.
- **Architectural mismatch**: project layers to a common dim if you must merge — but ensembling is usually the better fallback.
- **Very small models / very different domains**: ensembling may beat merging because constituents stay intact.
- **Two-vector SLERP**: skip pruning — interference is minimal with only two task vectors.

## Quick Reference

| Rule | Summary |
|------|---------|
| Parallel + merge | Avoids catastrophic forgetting in multi-task FT |
| Same base | Linear combo / task vectors require it |
| Rescale | Match parameter scales before summing |
| SLERP pairs only | Chain for more than two |
| Prune for many | Use TIES / DARE when merging 3+ task vectors |
| Re-finetune stacks | Layer stacking needs post-merge training |
| Avoid concat | Unless quality gain justifies more params |
| Match shapes | Or project layers to a common dimension |
