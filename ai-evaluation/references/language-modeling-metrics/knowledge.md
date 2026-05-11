# Language Modeling Metrics Knowledge

Core concepts for understanding entropy, cross entropy, perplexity, BPC, and BPB — the metrics that guide language model training and serve as proxies for downstream performance.

## Overview

Most autoregressive language models are trained using cross entropy or its relative perplexity. These metrics measure how well a model predicts the next token in a sequence. For models with a language model component, these scores tend to correlate well with downstream task performance, making them useful proxies even outside of training.

## Why Evaluating Foundation Models Is Hard

1. **Smarter models are harder to grade** — verifying a PhD-level math answer or a coherent summary requires expertise and time.
2. **Open-ended outputs break ground-truth comparison** — for any input there are many valid responses, so you cannot enumerate "correct" outputs.
3. **Models are black boxes** — architecture, training data, and process are often hidden, leaving only outputs to inspect.
4. **Benchmarks saturate fast** — GLUE (2018) was replaced by SuperGLUE in a year; MMLU was replaced by MMLU-Pro.
5. **Scope expanded** — general-purpose models must be evaluated on emergent capabilities, not just trained tasks.

## Key Concepts

### Entropy

**Definition**: The average amount of information a token carries, measured in bits (or nats).

Higher entropy means each token carries more information and requires more bits to represent. It also reflects how unpredictable the language is — the lower the entropy, the more predictable the next token.

**Intuition**: A 2-token language describing "upper/lower" of a square has entropy 1 (one bit per token). A 4-token language describing the four quadrants has entropy 2.

### Cross Entropy

**Definition**: How difficult it is for a model with learned distribution Q to predict tokens from the true distribution P of a dataset.

Decomposes into two parts:
- `H(P)` — the entropy of the data itself (irreducible)
- `D_KL(P || Q)` — divergence between the model's distribution and the true one

Formula: `H(P, Q) = H(P) + D_KL(P || Q)`

**Key points**:
- Training minimizes cross entropy on the training set
- A perfect model reaches `H(P, Q) = H(P)` (KL divergence = 0)
- Cross entropy is **not symmetric**: `H(P, Q) != H(Q, P)`

### Bits-per-Character (BPC) and Bits-per-Byte (BPB)

**Definition**: Cross entropy normalized to a unit smaller than a token, so values are comparable across models with different tokenizers.

- **BPC** = bits-per-token / characters-per-token. Confounded by encoding (ASCII = 7 bits/char; UTF-8 = 8–32 bits/char).
- **BPB** = bits per byte of original training data. Standardized across encodings and the preferred cross-tokenizer comparison.

**Compression intuition**: BPB of 3.43 means the model can represent each 8-bit byte using 3.43 bits — roughly compressing the text to under half its original size.

### Perplexity (PPL)

**Definition**: The exponential of cross entropy. Measures the effective number of equally-likely options the model is choosing among at each token.

- Bits unit: `PPL = 2^H(P, Q)`
- Nats unit (PyTorch/TensorFlow default): `PPL = e^H(P, Q)`

**Key points**:
- Lower perplexity = the model is more certain / better at predicting
- A model with cross entropy of 2 bits has perplexity 4 (it behaves as if choosing among 4 equally likely tokens)
- The bit/nat confusion is why most papers report perplexity rather than raw cross entropy

## Terminology

| Term | Definition |
|------|------------|
| Entropy `H(P)` | Average information per token in the true distribution |
| Cross entropy `H(P, Q)` | Avg bits a model with distribution Q needs per token from P |
| KL divergence `D_KL(P || Q)` | How much Q diverges from P |
| Perplexity (PPL) | `2^H` (bits) or `e^H` (nats); effective branching factor |
| BPC | Bits per character |
| BPB | Bits per byte (encoding-independent) |
| Bit | Unit of entropy with base 2 |
| Nat | Unit of entropy with base e (natural log) |

## How It Relates To

- **Training**: Cross entropy is the loss function for autoregressive LMs.
- **Downstream evaluation**: Lower perplexity correlates with better task performance for base models (Liu et al., 2023).
- **Data contamination detection**: Anomalously low perplexity on a benchmark suggests it leaked into training data.
- **Deduplication**: Add new training data only if model's perplexity on it is high (i.e., it's actually new).
- **Anomaly detection**: Very high perplexity flags gibberish or unusual text.

## Common Misconceptions

- **Myth**: Lower perplexity always means a better model.
  **Reality**: Perplexity is unreliable for post-trained models (SFT, RLHF) — those typically have *higher* perplexity than the base model, since post-training "collapses entropy" toward task-completion behavior. Quantization can also shift perplexity unexpectedly.

- **Myth**: Perplexity is comparable across any two models.
  **Reality**: Only comparable when tokenizer, vocabulary, context length, and dataset are the same. Use BPB if you need to compare across tokenizers.

- **Myth**: Cross entropy and perplexity report the same number.
  **Reality**: Cross entropy is in bits or nats; perplexity is the exponential. Always check the unit.

- **Myth**: You can compute perplexity for any model.
  **Reality**: You need access to per-token probabilities (logprobs). Many commercial APIs do not expose them.

## Quick Reference

| Metric | Unit | Formula | What it measures |
|--------|------|---------|------------------|
| Entropy | bits/nats | `H(P)` | Inherent unpredictability of the data |
| Cross entropy | bits/nats | `H(P, Q) = H(P) + D_KL(P || Q)` | Model's prediction difficulty on data |
| Perplexity | unitless | `2^H` or `e^H` | Effective branching factor |
| BPC | bits/char | `bits_per_token / chars_per_token` | Cross entropy per character |
| BPB | bits/byte | `BPC / (bytes_per_char)` | Encoding-independent cross entropy |
