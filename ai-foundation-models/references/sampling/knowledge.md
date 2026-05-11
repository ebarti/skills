# Sampling Knowledge

Core concepts and foundational understanding for how foundation models generate output tokens.

## Overview

Sampling is the process by which a model selects the next token from a probability distribution. It is what makes foundation models *probabilistic* (the same prompt can yield different outputs) and is the root cause of both their creativity and their tendency toward inconsistency and hallucination.

## Key Concepts

### Probability Distribution Over Tokens

**Definition**: For each generation step, the model computes a probability for every token in its vocabulary, then picks one according to a sampling strategy.

A neural network outputs a *logit vector* (one logit per vocab token). Logits are unnormalized scores: they don't sum to 1 and can be negative. A *softmax* converts logits to probabilities: `p_i = exp(x_i) / sum_j exp(x_j)`.

### Greedy Sampling

**Definition**: Always pick the token with the highest probability.

Works for classification but produces boring, repetitive text from a language model.

### Probabilistic Sampling

**Definition**: Pick the next token according to the probability distribution (e.g., a 30%-likely token gets picked 30% of the time).

This is what makes LLM outputs creative but also non-deterministic.

### Temperature

**Definition**: A constant `T` that scales logits before softmax: adjusted logit = `x_i / T`.

- **Higher T** flattens the distribution -> rarer tokens become more likely -> more creative, less coherent.
- **Lower T** sharpens the distribution -> common tokens dominate -> more consistent, more boring.
- **T = 0** (in practice): skip softmax, return argmax (greedy).
- Most providers cap T in [0, 2]; 0.7 is a common balanced default.

### Top-k Sampling

**Definition**: Restrict softmax to the top `k` highest-logit tokens, then sample from those.

- Reduces softmax compute over a huge vocabulary.
- Typical `k`: 50 to 500.
- Smaller k = more predictable, less diverse.

### Top-p (Nucleus) Sampling

**Definition**: Sample from the smallest set of tokens whose cumulative probability reaches `p`.

- Adapts the candidate set to the context (small set when one token dominates, large set when probabilities are spread).
- Typical `p`: 0.9 to 0.95.
- Doesn't reduce softmax cost, but produces more contextually appropriate outputs.

### Min-p

**Definition**: Set a minimum probability a token must have to be a candidate.

### Stopping Conditions

**Definition**: Rules that end generation early to control latency, cost, and length.

- Max token limit (risk: cut mid-sentence).
- Stop tokens / stop words (e.g., end-of-sequence token).
- Risk: premature stop can break structured formats (e.g., unclosed JSON brackets).

### Logprobs

**Definition**: Log-scale probabilities. Used to avoid underflow when probabilities are tiny.

`log(a*b) = log(a) + log(b)`, so a sequence's logprob is the sum of per-token logprobs. Useful for classification, evaluation, and debugging.

### Test Time Compute

**Definition**: Sample multiple outputs per query and select the best one to improve quality.

Selection methods:
- Highest average logprob (used by OpenAI's `best_of`).
- Reward model / verifier score.
- Most frequent answer (self-consistency, good for math/multiple-choice).
- Application heuristic (e.g., shortest, or first valid SQL).

A verifier can deliver roughly the same quality boost as a 30x model size increase. Diminishing returns past ~400 samples in some setups; cost scales linearly with samples.

### Structured Outputs

**Definition**: Outputs constrained to a specific format (JSON, YAML, regex, SQL, valid class).

Five layers where you can enforce structure: prompting, post-processing, test time compute, constrained sampling, finetuning.

### Constrained Sampling

**Definition**: Filter the logit vector at each step to allow only tokens that satisfy a grammar.

Requires a grammar per format. Less generalizable but enforces validity.

### Inconsistency

**Definition**: The model produces different outputs for the same or near-identical inputs.

Two scenarios:
1. Same input -> different outputs (sampling randomness).
2. Slightly different input (e.g., capitalization) -> drastically different outputs (model brittleness).

### Hallucination

**Definition**: The model generates content that is not grounded in facts.

Two leading hypotheses:
1. **Self-delusion** (DeepMind, Ortega et al. 2021): the model treats its own generated tokens as ground truth and snowballs from a wrong start.
2. **Knowledge mismatch** (Leo Gao, OpenAI): SFT teaches the model to mimic labeler answers that use knowledge the model lacks, training it to fabricate.

## Terminology

| Term | Definition |
|------|------------|
| Logit | Unnormalized per-token score from the network's last layer |
| Softmax | Function that converts logits to a probability distribution |
| Logprob | Log of a probability; used to avoid numerical underflow |
| Greedy sampling | Always pick the highest-probability token (argmax) |
| Temperature | Scalar dividing logits before softmax; controls randomness |
| Top-k | Sample from the k highest-probability tokens |
| Top-p (nucleus) | Sample from the smallest set whose cumulative probability >= p |
| Stop token | Token that ends generation when produced |
| Test time compute | Generating multiple outputs at inference and picking the best |
| Beam search | Maintain k most-promising partial sequences during generation |
| Self-consistency | Sample many outputs, pick the most common answer |
| Constrained sampling | Mask logits each step to satisfy a grammar |
| Seed | Initial value for the sampling RNG; fixing it aids reproducibility |
| Snowballing hallucination | Model doubles down on a wrong assumption it produced earlier |

## How It Relates To

- **Post-training (SFT, RLHF)**: shapes the underlying probability distribution; RLHF can both reduce or worsen hallucination depending on the reward signal.
- **Prompt engineering**: shifts probabilities toward desired tokens without changing sampling settings.
- **Evaluation**: inconsistency and hallucination are the main reasons evaluation pipelines must be probabilistic and test-set-based.
- **Agents and tools**: structured outputs are critical when LLM output is parsed by downstream tools.

## Common Misconceptions

- **Myth**: Setting temperature=0 makes the model fully deterministic.
  **Reality**: Hardware differences, batch effects, and provider-side non-determinism can still cause variation even at T=0.

- **Myth**: JSON mode guarantees the JSON content is correct.
  **Reality**: It only guarantees valid JSON syntax; values can still be wrong, and outputs can be truncated by token limits.

- **Myth**: More test-time samples always helps.
  **Reality**: Performance plateaus and can even degrade past a threshold (~400 samples in OpenAI's experiments) as adversarial outputs fool the verifier.

- **Myth**: Hallucination is purely a sampling problem.
  **Reality**: Sampling explains inconsistency; hallucination has deeper causes (self-delusion, labeler-knowledge mismatch).

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Temperature | Scales logits; higher = more creative, lower = more consistent |
| Top-k | Sample from k most likely tokens (fixed candidate count) |
| Top-p | Sample from smallest set with cumulative prob >= p (dynamic count) |
| Stop tokens | End generation early; risk truncating structured output |
| Test time compute | Multiple samples + selection beats one sample |
| Constrained sampling | Grammar-aware logit masking enforces output format |
| Inconsistency | Same/near-same input -> different output, mitigated with caching/seed |
| Hallucination | Ungrounded output, caused by self-delusion or knowledge mismatch |
