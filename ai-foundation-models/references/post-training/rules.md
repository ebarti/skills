# Post-Training Rules

Guidelines for deciding when to run SFT, when to add preference finetuning, and how to source the data each step needs.

## Core Rules

### 1. Always run SFT before preference finetuning

A pre-trained model completes text; it does not converse. SFT is the cheapest, most reliable way to convert completion behavior into response behavior.

- Skip only if your base model is already an instruct/chat model.
- Do not jump to RLHF/DPO on a raw base model—the preference signal will be wasted on a model that does not yet know how to respond.

### 2. Use SFT when behavior is teachable by example

If you can write down what a "good" response looks like, SFT is appropriate.

- Good fits: domain-specific Q&A style, summarization formats, tool-call formatting, language translation, custom personas.
- Poor fits: judgments where reasonable people disagree (politics, taste)—those need preference data.

### 3. Add preference finetuning when "what kind of conversation" matters

SFT teaches *how to respond*; preference finetuning teaches *which response to prefer* among many plausible ones.

- Use it for: harmlessness, helpfulness trade-offs, tone, refusal behavior, nuanced quality differences.
- Skip it for: narrow tasks with one obviously correct answer (extraction, classification).

### 4. Treat demonstration data quality as the dominant factor

The model clones what you show it. Cheap data produces cheap models.

- Use educated, vetted labelers. InstructGPT labelers were ~90% college-educated, >1/3 with master's degrees.
- Budget realistically: a single high-quality `(prompt, response)` pair can take up to 30 minutes and cost ~$10; 13K pairs is ~$130K before overhead.
- Cover the full task distribution you intend to support; gaps in the demonstration set become gaps in the model.

### 5. Use comparison data, not pointwise scores, to train reward models

Numeric scores from humans are noisy and inconsistent—even the same labeler scores the same pair differently on different days.

- Collect data as `(prompt, winning_response, losing_response)`.
- A ranked list of N responses gives you `N choose 2` pairs cheaply (e.g., `A > B > C` yields 3 pairs).
- Expect ~73% inter-labeler agreement; aim higher with clearer rubrics.

### 6. Make labeler demographics representative

Your model inherits the preferences of the people who labeled it.

- Document labeler demographics; LAION's volunteer pool was 90% male and produced visibly biased preferences.
- Recruit deliberately for representativeness, not just convenience.

### 7. Prefer DPO over RLHF when simplicity matters more than control

Both improve over SFT; DPO removes the explicit RM and PPO loop.

- DPO when: small team, limited RL infra, want fewer moving parts (Llama 3's choice).
- RLHF when: you need the RM as a separate artifact (best-of-N, evaluation), or want fine-grained control over the optimization (Llama 2's choice).

### 8. Consider best-of-N before committing to RL

If you already have a reward model, you can sample N candidates and return the top-scored one—no PPO required.

- Trades inference compute for training simplicity.
- Used in production by teams like Stitch Fix and Grab.
- Good first step before investing in a full RL pipeline.

## Guidelines

- Cost order (cheapest → most expensive labeling): comparison data (~$3.50/pair) < written response (~$25/pair).
- Reward models can be finetuned on top of the SFT model; finetuning the strongest base tends to give the best RM.
- A weaker RM can still score a stronger model—judging is easier than generating.
- Synthetic / AI-generated data (RLAIF, AI-labeled SFT) is a valid cost-reduction lever; just account for the bias of the generating model.
- Avoid the term "instruction finetuning"—it ambiguously means SFT or SFT + preference depending on the author.

## Exceptions

- **Already-aligned base model**: If you start from an existing chat model, you may only need light SFT for domain adaptation and skip preference finetuning entirely.
- **Narrow extraction/classification tasks**: A small SFT pass alone is often sufficient; preference finetuning adds little.
- **No RL infra**: Skip RL with best-of-N or use DPO.
- **Future better base models**: SFT and preference finetuning exist to patch low-quality pre-training data; better pre-training could shrink or eliminate the need for them.

## Quick Reference

| Rule | Summary |
|------|---------|
| SFT first | Always SFT before preference finetuning on a raw base |
| Demonstration quality | Educated labelers, full task coverage, real budget |
| Pairs over scores | Train RMs on comparisons, not numeric ratings |
| Representative labelers | Demographics shape preferences |
| DPO for simplicity | Switch from RLHF when complexity hurts |
| Best-of-N first | Try RM-at-inference before RL |
| Skip when narrow | Classification/extraction rarely needs RLHF |
