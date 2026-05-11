# Language Modeling Metrics Examples

Concrete numbers for entropy, cross entropy, perplexity, BPC, and BPB. Includes Python snippets, real GPT-2 numbers, and edge cases.

## Worked Numerical Examples

### Entropy of a simple language

A language describing positions in a square:

| Tokens | Possible values | Entropy (bits) | Perplexity |
|--------|-----------------|----------------|------------|
| `upper`, `lower` | 2 | 1 | 2 |
| `upper-left`, `upper-right`, `lower-left`, `lower-right` | 4 | 2 | 4 |

**Interpretation**: With 4 equally likely options, a perfect model still has perplexity 4 — it really does have to choose among 4 outcomes.

### Cross entropy to perplexity conversion

```python
import math

# If your loss (cross entropy) is reported in nats (PyTorch default)
loss_nats = 2.155
ppl = math.exp(loss_nats)
# ppl ≈ 8.63 — matches GPT-2 1542M on LAMBADA

# If your loss is reported in bits
loss_bits = 3.11
ppl = 2 ** loss_bits
# ppl ≈ 8.63

# Convert between units
bits = loss_nats / math.log(2)   # 3.11
nats = loss_bits * math.log(2)   # 2.155
```

### BPC to BPB conversion

```python
# Suppose model reports 6 bits per token, average 2 chars per token
bits_per_token = 6
chars_per_token = 2
bpc = bits_per_token / chars_per_token  # 3.0

# If chars are 7 bits each (ASCII), each char is 7/8 of a byte
bytes_per_char = 7 / 8
bpb = bpc / bytes_per_char  # 3.43

# Compression interpretation: 3.43 bits to represent each 8-bit byte
compression_ratio = bpb / 8  # 0.43 — text compressed to ~43% of original
```

## Real-World Perplexity Reference (GPT-2)

From the GPT-2 report (lower is better for PPL/BPB/BPC; higher for ACC):

| Model size | LAMBADA PPL | WikiText2 PPL | PTB PPL | enwiki8 BPB | text8 BPC | WikiText103 PPL | 1BW PPL |
|------------|-------------|---------------|---------|-------------|-----------|-----------------|---------|
| 117M | 35.13 | 29.41 | 65.85 | 1.16 | 1.17 | 37.50 | 75.20 |
| 345M | 15.60 | 22.76 | 47.33 | 1.01 | 1.06 | 26.37 | 55.72 |
| 762M | 10.87 | 19.93 | 40.31 | 0.97 | 1.02 | 22.05 | 44.575 |
| 1542M | 8.63 | 18.34 | 35.76 | 0.93 | 0.98 | 17.48 | 42.16 |

**Key takeaways**:
- Bigger models -> lower perplexity, consistently across datasets
- BPB and BPC are roughly 1.0 for character/byte-level evaluation on English text
- Perplexity numbers vary wildly by dataset (8.63 vs. 42.16 for the same 1542M model)

## Computing Perplexity in Python

### With Hugging Face transformers

```python
import math
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM

tokenizer = AutoTokenizer.from_pretrained("gpt2")
model = AutoModelForCausalLM.from_pretrained("gpt2").eval()

text = "The capital of France is Paris."
inputs = tokenizer(text, return_tensors="pt")
input_ids = inputs["input_ids"]

with torch.no_grad():
    # labels=input_ids makes the model compute mean token-level NLL (in nats)
    outputs = model(input_ids, labels=input_ids)

# loss is mean cross entropy in nats
loss_nats = outputs.loss.item()
perplexity = math.exp(loss_nats)
print(f"Cross entropy: {loss_nats:.3f} nats, perplexity: {perplexity:.2f}")
```

### From an API that returns logprobs

```python
import math

# logprobs is a list of natural-log probabilities the model assigned
# to each generated token, e.g. from a /completions endpoint
logprobs = [-0.5, -1.2, -0.3, -2.1, -0.8]

# Mean negative log-likelihood = cross entropy estimate (nats)
mean_nll = -sum(logprobs) / len(logprobs)
perplexity = math.exp(mean_nll)
print(f"Perplexity: {perplexity:.2f}")
```

## Edge Cases

### Post-training raises perplexity

```python
# Same architecture, two checkpoints, same eval set
base_model_ppl = 4.2          # base GPT trained on raw text
chat_model_ppl = 9.7          # same model after SFT + RLHF

# WRONG conclusion: "the chat model is worse"
# RIGHT interpretation: post-training "collapses entropy" — the model is now
# specialized for completing instructions, not predicting raw text. Use
# task-level evaluation instead.
```

### Unit confusion

```python
# Paper A reports loss = 2.0
# Paper B reports loss = 1.4
# Paper B looks better, but...

ppl_a_if_nats = math.exp(2.0)   # 7.39
ppl_b_if_bits = 2 ** 1.4         # 2.64

# If A is in nats and B is in bits, A is actually better in absolute terms.
# Always confirm the unit before comparing.
```

### Cross-tokenizer comparison via BPB

```python
# Two models on the same English corpus
# Model X: BPE tokens, perplexity 12, avg 4 chars/token, ASCII (7 bits/char)
# Model Y: char-level, perplexity 3, 1 char/token, ASCII

import math

def bpb_from_ppl(ppl, chars_per_token, bits_per_char=7):
    bits_per_token = math.log2(ppl)
    bpc = bits_per_token / chars_per_token
    bytes_per_char = bits_per_char / 8
    return bpc / bytes_per_char

bpb_x = bpb_from_ppl(12, 4)   # 1.024
bpb_y = bpb_from_ppl(3, 1)    # 1.811

# Model X is actually a better text predictor per byte, despite higher PPL.
```

### Detecting data contamination

```python
benchmark_ppl = compute_perplexity(model, benchmark_text)  # 1.4
typical_ppl   = compute_perplexity(model, held_out_text)   # 8.2

if benchmark_ppl < 0.5 * typical_ppl:
    print("Suspiciously low perplexity — benchmark may be in training data")
```

### Anomaly / gibberish detection

```python
texts = [
    "The cat sat on the mat.",                    # normal -> low PPL
    "my dog teaches quantum physics in his free time",  # unusual -> high PPL
    "home cat go eye",                             # gibberish -> very high PPL
]

ppls = [compute_perplexity(model, t) for t in texts]
# Use a threshold to flag outliers for review or filtering.
```
