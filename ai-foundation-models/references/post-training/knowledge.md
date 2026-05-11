# Post-Training Knowledge

Core concepts for transforming a pre-trained foundation model into a useful, safe assistant.

## Overview

Post-training takes a pre-trained model (which only knows how to complete text) and turns it into a model that holds conversations and aligns with human preferences. It addresses two problems left over from pre-training: the model is optimized for completion (not dialogue), and outputs from indiscriminate web data can be rude, biased, or wrong.

## Key Concepts

### Pre-training vs Post-training

**Definition**: Pre-training optimizes token-level quality (predict the next token). Post-training optimizes response-level quality (generate full responses users prefer).

**Key points**:
- Analogy: pre-training is reading to acquire knowledge; post-training is learning how to use it.
- Post-training uses a tiny share of compute (InstructGPT used ~2% for post-training, 98% for pre-training).
- Post-training "unlocks" capabilities the base model already has but are hard to access via prompting alone.

### Supervised Finetuning (SFT)

**Definition**: Finetune the pre-trained model on high-quality `(prompt, response)` demonstration data so it learns to respond instead of merely complete text.

**Key points**:
- Also called *behavior cloning*: the model clones demonstrated behavior.
- Demonstration data must cover the range of tasks you want supported (Q&A, summarization, translation, etc.).
- Quality of labelers matters far more than for traditional labeling tasks—responses can require critical thinking and judgment.

### Preference Finetuning

**Definition**: A second post-training step that aligns model responses with human preferences (helpful, harmless, appropriate).

**Key points**:
- SFT teaches the model *to* converse, but not *what kind* of conversations to have.
- Goal is ambitious and underspecified: assumes a universal-enough preference exists and can be embedded.
- Common techniques: RLHF, DPO, RLAIF.

### Reward Model (RM)

**Definition**: A model that, given `(prompt, response)`, outputs a scalar score indicating how good the response is.

**Key points**:
- Trained from *comparison data* `(prompt, winning_response, losing_response)` rather than absolute scores (humans disagree on numeric scales).
- Loss maximizes the score gap between winning and losing responses (logistic loss on score difference).
- Can be trained from scratch or finetuned on top of the pre-trained / SFT model; finetuning the strongest base tends to work best.
- Judging is believed to be easier than generating, so a weaker RM can still score a stronger model.

### RLHF (Reinforcement Learning from Human Feedback)

**Definition**: Two-step preference finetuning: (1) train a reward model on human comparison data, (2) optimize the SFT model to maximize reward-model scores, typically with PPO.

**Key points**:
- Used by GPT-3.5 and Llama 2.
- Llama 2 authors credited RLHF for surpassing human writing quality on some tasks.
- More complex than DPO but offers more flexibility to tweak the model.

### DPO (Direct Preference Optimization)

**Definition**: A preference-finetuning method that optimizes the model directly on comparison data, skipping the explicit reward model and RL loop.

**Key points**:
- Used by Llama 3 (Meta switched from RLHF to DPO to reduce complexity).
- Simpler pipeline; typically matches or beats SFT-only.

### RLAIF (Reinforcement Learning from AI Feedback)

**Definition**: Like RLHF, but the comparison labels come from an AI judge instead of human labelers.

**Key points**:
- Reduces annotation cost and may scale better than RLHF.
- Potentially used by Claude.

### Best-of-N Sampling (RM-only inference trick)

**Definition**: Generate N responses from the SFT model and return the one with the highest reward-model score, skipping RL entirely.

**Key points**:
- Used by teams like Stitch Fix and Grab when the reward model alone is good enough.
- Trades inference compute for skipping a costly RL training stage.

## Terminology

| Term | Definition |
|------|------------|
| Demonstration data | `(prompt, response)` pairs used in SFT |
| Comparison data | `(prompt, winning_response, losing_response)` triples used to train an RM |
| Behavior cloning | Training a model to imitate demonstrated responses |
| Pointwise evaluation | Scoring each response independently (noisier than comparisons) |
| Inter-labeler agreement | Fraction of labelers who rank a pair the same way (~73% for InstructGPT) |
| PPO | Proximal Policy Optimization, the RL algorithm typically used in RLHF |
| Instruction finetuning | Ambiguous term; sometimes means SFT only, sometimes SFT + preference (avoid) |

## How It Relates To

- **Pre-training**: Post-training assumes a working base model; it cannot inject new knowledge at scale.
- **Sampling**: Best-of-N uses sampling to amplify a reward model without RL.
- **Evaluation**: Reward models are essentially learned evaluators—judging is easier than generating.
- **Dataset engineering**: Both demonstration and comparison data quality dominate post-training results.

## Common Misconceptions

- **Myth**: Post-training teaches the model new facts.
  **Reality**: It mostly unlocks and shapes existing pre-trained capabilities.

- **Myth**: You always need RLHF/DPO.
  **Reality**: You can skip it (SFT-only), or skip RL by using best-of-N with a reward model.

- **Myth**: Reward models must be larger than the base model to score it.
  **Reality**: Judging is easier than generating; a weaker RM can score a stronger model.

- **Myth**: Direct numeric scoring is the cleanest training signal.
  **Reality**: Pairwise comparisons are far more reliable; the same labeler scores the same pair differently across sittings.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| SFT | Teach the model to respond using `(prompt, response)` demonstrations |
| Preference finetuning | Align responses with human preference |
| Reward model | Scalar scorer trained on pairwise comparisons |
| RLHF | RM + PPO loop to maximize reward |
| DPO | Skip the RM, optimize on preferences directly |
| RLAIF | Like RLHF but with AI-generated preferences |
| Best-of-N | Use the RM at inference time instead of running RL |
