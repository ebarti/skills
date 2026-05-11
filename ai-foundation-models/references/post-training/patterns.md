# Post-Training Patterns

Reusable pipeline shapes for picking the right post-training stack given your goals, budget, and infrastructure.

## Pattern: SFT-Only

### Intent

Convert a base model into a usable assistant for a narrow task with the smallest possible pipeline.

### When to Use

- Task is well-defined with mostly-correct answers (extraction, classification, structured generation, domain Q&A).
- You can produce or curate high-quality `(prompt, response)` demonstrations.
- No strong need to handle controversial or open-ended preference trade-offs.
- Limited budget or no RL/RM infrastructure.

### Structure

```
pre-trained base
        |
        v
  SFT on demonstrations
        |
        v
   shipped model
```

### Example

A startup builds a code-comment generator. They collect 5K `(code_snippet, ideal_comment)` pairs, run SFT on a 7B base, and ship. No reward model, no RL.

### Benefits

- Cheapest end-to-end.
- Smallest engineering surface.
- Fast iteration on data.

### Considerations

- Won't help with subjective preference ("which of two valid answers do users prefer?").
- Quality cap is the quality of your demonstration set.

---

## Pattern: SFT + Best-of-N (RM-at-Inference)

### Intent

Get most of the preference-alignment benefit of RLHF without an RL training loop.

### When to Use

- You already have or can train a reward model.
- You can afford extra inference compute (N forward passes per request).
- You want a clear, reusable RM artifact (also useful for evaluation).
- You want to avoid PPO complexity.

### Structure

```
pre-trained base                        comparison data
        |                                      |
        v                                      v
  SFT on demonstrations  ---->  reward model (RM)
        |                                      |
        +-----------+--------------------------+
                    |
                    v
   inference: sample N, pick top-scored
```

### Example

Stitch Fix / Grab–style: SFT model generates 8 candidate responses per prompt; the reward model scores each; the highest-scoring response is returned. No RL training run.

### Benefits

- No PPO infrastructure required.
- RM is reusable for evaluation and ranking.
- Easy to tune N up or down per request based on cost.

### Considerations

- Inference cost grows linearly with N.
- Quality cap is set by what the RM can recognize and what the SFT model can sample.

---

## Pattern: SFT + DPO

### Intent

Add preference alignment with a single extra training stage and no RL machinery.

### When to Use

- You have comparison data `(prompt, winning, losing)`.
- You want better-than-SFT alignment but don't need an explicit RM artifact.
- Small team or limited RL infra (e.g., Llama 3's choice).

### Structure

```
pre-trained base
        |
        v
  SFT on demonstrations
        |
        v
  DPO on preference pairs
        |
        v
   shipped model
```

### Example

Open-source team finetunes a 13B base: 50K SFT pairs, then DPO on 100K preference pairs. Ships without ever standing up a reward model or PPO loop.

### Benefits

- Simpler than RLHF (one stage vs two).
- Lower compute footprint than PPO.
- Empirically competitive with RLHF.

### Considerations

- No standalone RM, so no easy best-of-N or RM-based evaluation.
- Less flexibility to tweak the optimization than full RL.

---

## Pattern: Full RLHF (SFT + RM + PPO)

### Intent

Maximize alignment quality and retain a reusable reward model, accepting higher complexity.

### When to Use

- Quality and behavior shaping matter more than infra simplicity.
- You want the RM as a separate artifact for best-of-N, evaluation, or future iteration.
- You have RL expertise and infrastructure (PPO, KL control, distributed training).
- The base is large enough that RLHF gains justify the cost (e.g., GPT-3.5, Llama 2).

### Structure

```
pre-trained base                                comparison data
        |                                              |
        v                                              v
  SFT on demonstrations  ----+------------>  reward model (RM)
                             |                         |
                             v                         |
                       PPO loop with KL <--------------+
                             |
                             v
                       aligned policy
```

### Benefits

- Highest reported quality on open-ended generation tasks.
- Reusable RM artifact (best-of-N, eval, future iterations).
- Fine-grained control via KL coefficient, reward shaping, etc.

### Considerations

- Most complex pipeline; many places to go wrong.
- PPO is sensitive to hyperparameters and reward hacking.
- Highest data and compute cost.

---

## Pattern: RLAIF (AI-Generated Preferences)

### Intent

Scale preference data far beyond what human labelers can produce.

### When to Use

- Human comparison labels are too slow or too expensive.
- A strong existing model can stand in as the judge.
- You're comfortable inheriting the judge model's biases.

### Structure

```
SFT model + judge model  --->  AI-generated comparison data  --->  RM or DPO
```

### Example

Use a strong frontier model to compare candidate outputs from your SFT model, producing comparison data automatically. Then run DPO or train an RM as usual.

### Benefits

- Massive scale at low marginal cost.
- Faster iteration than human labeling.

### Considerations

- Judge model's biases propagate into your model.
- Quality ceiling is roughly the judge's discrimination ability.

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|-------------------|
| Narrow task, clear correct answers | SFT-Only |
| Have an RM, want quality without RL | SFT + Best-of-N |
| Want preference alignment with low complexity | SFT + DPO |
| Need reusable RM and max alignment quality | Full RLHF |
| Cannot afford human comparison data | RLAIF (then DPO or RM) |
| Already shipping an instruct base, only need domain shift | Light SFT only |

## Decision Heuristics

- Start with SFT-Only. Add preference finetuning only when you observe that the model produces multiple valid responses and you can't pick a winner with prompting alone.
- Prefer DPO over RLHF unless you specifically need the RM artifact.
- Try Best-of-N before committing to PPO—often "good enough" with much less risk.
- Cost ladder (cheapest → most expensive): SFT-Only < SFT + Best-of-N < SFT + DPO < Full RLHF.
- Complexity ladder (simplest → most complex): SFT-Only < SFT + DPO < SFT + Best-of-N (extra inference) < Full RLHF.
