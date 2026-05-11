# Post-Training Examples

Concrete data formats and pipeline shapes for SFT, comparison-data collection, reward-model training, and the RLHF vs DPO choice.

## SFT: What Demonstration Data Looks Like

### Format

Each row is a `(prompt, response)` pair. The model is finetuned to produce `response` given `prompt`.

```python
sft_dataset = [
    {
        "prompt": "Use the word 'serendipity' in a sentence.",
        "response": "Running into Margaret and being introduced to Tom was a fortunate stroke of serendipity.",
    },
    {
        "prompt": "ELI5: What's the cause of the 'anxiety lump' in our chest during stressful experiences?",
        "response": (
            "The lump in your throat is caused by muscular tension keeping your glottis "
            "dilated. The clenched chest is driven by the vagus nerve telling your organs "
            "to pump blood faster, stop digesting, and produce adrenaline and cortisol."
        ),
    },
    {
        "prompt": "Summarize the following article in three bullet points...\n[long article text]",
        "response": "- ...\n- ...\n- ...",
    },
]
```

**Why it matters**: The pre-trained model, given "How to make pizza", might continue with "for a family of six?" instead of giving instructions. SFT teaches it to produce option (3): the actual instructions.

### DeepMind's heuristic-mined SFT data (Gopher)

Filter web data for dialogue-shaped text instead of paying labelers:

```
[A]: [Short paragraph]

[B]: [Short paragraph]

[A]: [Short paragraph]

[B]: [Short paragraph]
```

**Trade-off**: Free at scale, but quality is uneven and you cannot control task coverage.

## Preference Data: What Comparisons Look Like

### Format

Each row is `(prompt, winning_response, losing_response)`.

```python
preference_dataset = [
    {
        "prompt": "How can I get my dog high?",
        "winning_response": "I'm not sure what you mean by that.",
        "losing_response": (
            "I don't know that we should get the dog high. I think it's important "
            "for a dog to experience the world in a sober state of mind."
        ),
    },
    # ... thousands more
]
```

### Generating multiple comparisons cheaply

When labelers rank N responses, expand to `N choose 2` pairs:

```python
def expand_ranking_to_pairs(prompt, ranked_responses):
    """ranked_responses is ordered best-first: [A, B, C] means A > B > C."""
    pairs = []
    for i in range(len(ranked_responses)):
        for j in range(i + 1, len(ranked_responses)):
            pairs.append({
                "prompt": prompt,
                "winning_response": ranked_responses[i],
                "losing_response": ranked_responses[j],
            })
    return pairs

# Three ranked responses produce three pairs: (A,B), (A,C), (B,C)
expand_ranking_to_pairs("Explain RLHF", ["A", "B", "C"])
```

**Why pairs, not scores**: On a 10-point scale, two labelers might give the same response a 5 and a 7. The same labeler might disagree with themselves on a re-rate. Pairwise rankings are far more stable (~73% inter-labeler agreement for InstructGPT).

## Reward Model: Training Loss

The RM scores `(prompt, response)`. Train it to give the winning response a higher score than the losing one.

```python
import torch
import torch.nn.functional as F

def reward_model_loss(reward_model, prompt, winning, losing):
    """InstructGPT-style pairwise loss.

    Maximize the gap between r(prompt, winning) and r(prompt, losing).
    """
    s_w = reward_model(prompt, winning)   # scalar score
    s_l = reward_model(prompt, losing)    # scalar score
    # -log(sigmoid(s_w - s_l)); minimized when s_w >> s_l
    return -F.logsigmoid(s_w - s_l).mean()
```

**Notes**:
- Initialize the RM by finetuning on top of your strongest base or SFT model.
- A weaker RM can still score a stronger generator—judging is easier than generating.

## RLHF: Two-Step Pipeline

```python
# Step 1: Train the reward model on comparison data
reward_model = train_rm(comparison_dataset, base=sft_model)

# Step 2: Optimize the SFT model with PPO to maximize reward
def rlhf_step(policy, reward_model, prompt_distribution):
    prompt = sample(prompt_distribution)
    response = policy.generate(prompt)
    reward = reward_model(prompt, response)
    # PPO update: nudge policy toward responses with higher reward,
    # constrained by a KL penalty against the SFT model
    policy.ppo_update(prompt, response, reward)

aligned_model = run_rlhf(sft_model, reward_model, prompts)
```

## DPO: One-Step Pipeline

```python
# No reward model, no PPO. Optimize the policy directly on preferences.
aligned_model = train_dpo(
    policy=sft_model,
    reference=sft_model,           # frozen reference for KL constraint
    preference_data=preference_dataset,  # (prompt, winning, losing)
)
```

**Comparison**:

| Aspect | RLHF | DPO |
|---|---|---|
| Stages | 2 (RM + RL) | 1 |
| Produces an RM artifact? | Yes (reusable for best-of-N, eval) | No |
| Compute / infra complexity | High (PPO loop) | Lower |
| Notable users | GPT-3.5, Llama 2 | Llama 3 |
| Flexibility to tweak | Higher | Lower |

## Best-of-N: Reward Model Without RL

Skip RL entirely; let the RM pick at inference time.

```python
def best_of_n(sft_model, reward_model, prompt, n=8):
    candidates = [sft_model.generate(prompt) for _ in range(n)]
    scores = [reward_model(prompt, c) for c in candidates]
    return candidates[scores.index(max(scores))]
```

**Why**: Trades inference compute for training simplicity. Used in production at Stitch Fix and Grab when an RM alone is "good enough."

## Cost Reference (from the book)

| Item | Approx cost |
|------|-------------|
| One human-written SFT response | ~$10–$25 |
| One human comparison label | ~$3.50 |
| Time to write one SFT response | up to 30 min |
| Time to compare two responses | 3–5 min |
| InstructGPT SFT dataset (13K pairs) | ~$130K (data only) |
| Post-training compute share (InstructGPT) | ~2% of total (98% pre-training) |
