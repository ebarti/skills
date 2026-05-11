# Language Modeling Metrics Rules

Practical guidelines for when to use perplexity and friends, how to read the values, and where they mislead.

## Core Rules

### 1. Use perplexity as a default proxy for base-model capability

Lower perplexity on a relevant dataset means the base model is better at predicting that text and likely better on related downstream tasks.

- Compare models on the **same dataset** with the **same tokenizer assumptions**
- Use it during pretraining, when comparing checkpoints, and when picking among base models

### 2. Do not trust perplexity for post-trained models

SFT and RLHF reshape the output distribution toward task completion, which usually **raises** perplexity. This is sometimes called "entropy collapse." A higher perplexity on an instruction-tuned model is not evidence it is worse.

- Never rank a chat model and a base model side-by-side on perplexity
- Use task-level evaluation (accuracy, AI-as-judge, human eval) for post-trained models

### 3. Use BPB when comparing models with different tokenizers

Bits-per-token is not comparable across tokenizers (a word-token model and a char-token model encode different amounts of text per token). BPB normalizes to bytes of original text and is encoding-independent.

- Use BPC only when both models share the same character encoding
- Prefer BPB for cross-model comparisons

**Example**:
```python
# Bad: comparing perplexity of a BPE tokenizer model with a char-level model
gpt_ppl = 8.63    # WikiText103, 1542M GPT-2 (BPE)
char_ppl = 3.0    # WikiText103, char-level baseline
# These are not directly comparable

# Good: convert both to BPB
gpt_bpb = 0.93    # comparable across tokenizers
char_bpb = 1.05   # comparable
```

### 4. Always check the unit (bit vs. nat)

PyTorch and TensorFlow report cross entropy in nats by default. Papers often report perplexity instead of cross entropy specifically to avoid this ambiguity.

- `PPL = exp(loss)` if loss is in nats
- `PPL = 2 ** loss` if loss is in bits
- Convert: `nats = bits * ln(2)` and `bits = nats / ln(2)`

### 5. Hold dataset, vocabulary, and context length constant when comparing

All four factors change perplexity:

- More structured data (HTML, code) -> lower perplexity
- Bigger vocabulary -> higher perplexity (more options per step)
- Longer context window -> lower perplexity (more conditioning info)
- Different dataset -> different baseline; never compare across datasets directly

### 6. Use perplexity to detect data contamination

If a model has unusually low perplexity on a benchmark, that benchmark likely leaked into training data. Treat the model's score on that benchmark as untrustworthy.

### 7. Use perplexity for deduplication and anomaly detection

- **Deduplication**: only add new training data if the model's perplexity on it is high (low perplexity = already seen)
- **Anomaly detection**: very high perplexity flags gibberish, unusual phrasings, or out-of-distribution text

## Guidelines

- Report perplexity rather than raw cross entropy when sharing results — fewer unit mistakes
- When you need cross-tokenizer comparison, prefer BPB > BPC > perplexity
- For modern LLMs, expect perplexity values in the low single digits on typical English text
- Conditioning on 500–10,000 prior tokens is standard now; very short context inflates perplexity
- If a commercial API doesn't expose logprobs, perplexity is not computable — pick a different metric

## Exceptions

- **Multimodal / non-text token models**: these metrics still apply to any sequence model, but interpretation thresholds differ — there are no widely accepted "good" numbers.
- **Domain-specific models**: a code model's perplexity on prose is not informative; always evaluate on representative data.
- **Quantized models**: perplexity can shift unexpectedly after quantization. Re-measure on the same eval set rather than trusting the pre-quantization number.
- **When you need user-facing quality**: skip perplexity entirely and use task accuracy, AI-as-judge, or human evaluation.

## Quick Reference

| Rule | Summary |
|------|---------|
| Default metric | Perplexity for base models on a fixed dataset |
| Cross-tokenizer | Use BPB |
| Post-trained models | Don't use perplexity to compare quality |
| Unit ambiguity | Check whether loss is in bits or nats |
| Comparison validity | Same dataset + tokenizer + context length |
| Contamination check | Low perplexity on a benchmark = suspect |
| API without logprobs | Cannot compute perplexity |
