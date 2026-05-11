# Model Merging Patterns

Reusable patterns for combining specialized models.

## Pattern: Parallel Multi-Task Adapters

### Intent

Build a single model that handles N tasks without catastrophic forgetting and without N× memory.

### When to Use

- You have N task-specific datasets and want one deployment artifact.
- Constituents share a base model.

### Structure

```python
adapters = [finetune_lora(base, dataset_i) for dataset_i in datasets]
merged = merge_linear_combination(adapters, weights=[1/N] * N)
```

### Considerations

- No catastrophic forgetting; one memory budget.
- Per-task quality may dip 2-5% vs standalone adapter — use weighted average if one task matters more.

---

## Pattern: Capability Subtraction (Debiasing)

### Intent

Remove an undesired behavior (bias, unsafe skill) from a finetuned model without retraining from scratch.

### When to Use

- A finetune absorbed an unwanted capability.
- You can train or construct a model that **exhibits** the undesired behavior.

### Structure

```python
tv_unwanted = task_vector(unwanted_model, base)
clean_sd = {k: target[k] - alpha * tv_unwanted[k] for k in target}
# Example: strip face-recog from a vision model
sanitized = {k: production[k] - 0.8 * tv_face[k] for k in production}
```

### Considerations

- Cheap pure parameter arithmetic.
- Sweep alpha to find the right subtraction strength.
- The "unwanted" model must isolate the behavior cleanly.

---

## Pattern: Prune-Then-Merge for Many Tasks (TIES / DARE)

### Intent

Merge many task vectors without inter-task interference dragging down quality.

### When to Use

- Merging 3+ task vectors, or seeing merged-model regression vs constituents.

### Structure

```python
tvs = [task_vector(m, base) for m in finetunes]
pruned = [prune_by_magnitude(tv, keep_ratio=0.2) for tv in tvs]
merged = {k: base[k] + sum(p[k] for p in pruned) for k in base}
```

### Considerations

- Quality scales with constituent count instead of degrading.
- Optimal `keep_ratio` is task-dependent (15-50% common) — sweep it.

---

## Pattern: Frankenmerge for New Capabilities

### Intent

Create a stronger or larger model by stacking layers from different finetunes.

### When to Use

- You have multiple strong finetunes of the same base.
- You want a single model that exceeds any constituent.
- You can afford post-merge finetuning.

### Structure

```python
front = model_A.layers[:N1]
back = model_B.layers[N2:]
merged.layers = front + back
finetune(merged, alignment_data)  # required
```

### Example

```python
# Goliath-style: 72 layers each from two Llama 70B finetunes → 144 layers
merged = stack_layers([(xwin, slice(0, 72)), (euryale, slice(0, 72))])
finetune(merged, calibration_corpus)
```

### Benefits

- Can produce SOTA models (e.g., Goliath-120B).
- Combines skills that weren't trainable into one model.

### Considerations

- Bigger model — more memory, more inference cost.
- Post-merge finetuning is essentially mandatory.

---

## Pattern: Sparse Upcycling to MoE

### Intent

Convert a dense pre-trained model into Mixture-of-Experts cheaper than training MoE from scratch.

### When to Use

- You have a strong dense checkpoint.
- You want MoE benefits (more total params, similar compute per token).

### Structure

```python
experts = [deepcopy(layer_to_upcycle) for _ in range(K)]
router = TrainableRouter(K)
upcycled = replace_layer_with_moe(dense_model, experts, router)
finetune(upcycled, corpus)  # train router + experts
```

### Considerations

- Beats from-scratch MoE (Komatsuzaki et al.).
- Need post-merge training of router and experts.
- Inference infra must support MoE routing.

---

## Pattern: Depthwise Upscaling

### Intent

Grow a model in depth to use new compute headroom without training from scratch (e.g., SOLAR 10.7B from a 7B/32-layer model).

### When to Use

- Available memory increased (better GPU).
- You want a bigger model fast, reusing known-good weights.

### Structure

```python
copy_a, copy_b = deepcopy(model), deepcopy(model)
# Sum middle layers pairwise (collapses pairs), stack the rest
new_layers = stack_with_some_summed(copy_a, copy_b, sum_ranges)
upscaled = build_model(new_layers)
finetune(upscaled, corpus)  # required to refine the upscaled model
```

### Considerations

- Post-merge finetuning is required.
- Carefully choose which layers to sum vs stack to hit the target size.

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|---------------------|
| Multi-task adapters, same base | Parallel Multi-Task Adapters |
| Strip an unwanted capability | Capability Subtraction |
| Merging 3+ task vectors | Prune-Then-Merge (TIES / DARE) |
| Combine different finetunes into a stronger model | Frankenmerge |
| Convert dense → MoE | Sparse Upcycling |
| Grow a model to fit new GPU memory | Depthwise Upscaling |
| Federated learning aggregation | Linear combination of on-device copies |
| Two models, average underperforms | SLERP between the two |
