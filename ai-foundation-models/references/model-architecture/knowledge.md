# Model Architecture Knowledge

Core concepts for foundation model architecture and sizing decisions.

## Overview

Foundation model design rests on two key decisions: architecture (transformer vs alternatives) and size (parameter count, training tokens, FLOPs). These decisions shape both model capability and downstream usability — a 7B-parameter model is far easier to deploy than a 175B model, and optimizing a transformer for latency differs greatly from optimizing other architectures.

## Key Concepts

### Transformer Architecture

**Definition**: A neural network architecture introduced by Vaswani et al. (2017) that replaces RNN-based sequential processing with the attention mechanism, enabling parallel input processing.

**Key points**:
- Solved two seq2seq problems: information bottleneck (only final hidden state used) and slow sequential processing
- Input tokens process in parallel; output tokens still generated sequentially (autoregressive)
- Inference has two phases: **prefill** (parallel input processing, computes K/V vectors) and **decode** (one output token at a time)
- Dominant architecture for language foundation models since 2017

### Attention Mechanism

**Definition**: A mechanism that lets the model weigh the importance of different input tokens when generating each output token, using query (Q), key (K), and value (V) vectors.

**How it works**:
- Q vector represents the current decoder state (the "question" being asked)
- K vectors represent previous tokens (like "page numbers")
- V vectors represent the actual content of previous tokens
- Attention score = dot product of Q and K, scaled by sqrt(d), passed through softmax, then multiplied by V
- Formula: `Attention(Q, K, V) = softmax(QK^T / sqrt(d)) * V`
- Almost always **multi-headed**: vectors are split across heads so the model attends to different token groups simultaneously

### Transformer Block

**Definition**: The repeating unit of a transformer model, containing an attention module and an MLP (multi-layer perceptron) module.

**Composition**:
- **Attention module**: 4 weight matrices (Q, K, V, output projection)
- **MLP module**: linear (feedforward) layers separated by nonlinear activations (ReLU, GELU)
- Number of transformer blocks = model's number of **layers**
- Surrounded by an embedding module (token + positional embeddings) before and an output/unembedding layer ("head") after

### Model Size

**Definition**: Typically measured by parameter count (e.g., Llama-13B has 13 billion parameters), but also by training tokens and training FLOPs.

**Three signals of scale**:
- **Parameters**: proxy for learning capacity
- **Training tokens**: proxy for how much was learned
- **FLOPs**: proxy for training cost

### Sparse Models and Mixture-of-Experts (MoE)

**Definition**: A sparse model has many zero-value parameters; an MoE model splits parameters into "expert" groups, with only a subset active per token.

**Example**: Mixtral 8x7B has 46.7B total parameters (some shared) but activates only 2 experts (~12.9B parameters) per token, giving inference cost similar to a 12.9B dense model.

### FLOPs vs FLOP/s

**Definition**: FLOP = one floating point operation. FLOPs (plural) measures total compute for a task. FLOP/s measures per-second throughput of hardware.

- GPT-3-175B was trained using ~3.14 × 10^23 FLOPs
- An H100 NVL delivers ~6 × 10^13 FLOP/s peak
- 1 FLOP/s-day = 86,400 FLOPs (OpenAI's preferred unit)

### Chinchilla Scaling Law

**Definition**: For compute-optimal training, training tokens should be approximately **20× the model parameter count** (DeepMind, 2022).

A 3B-parameter model needs ~60B training tokens. Doubling model size requires doubling training tokens.

### Emergent Abilities

**Definition**: Capabilities that appear only at scale and are not observable in smaller models, making hyperparameter and behavior extrapolation harder.

## Terminology

| Term | Definition |
|------|------------|
| Parameter | A learned weight in the model |
| Hyperparameter | A user-set value (layers, batch size, learning rate) controlling model/training |
| Layer | One transformer block |
| Model dim (hidden dim) | Dimension of K/Q/V matrices and embeddings |
| Feedforward dim | Dimension of the MLP linear layer (often ~4× model dim) |
| Vocab size | Number of distinct tokens the model knows |
| Context length | Max sequence length the model can process |
| Epoch | One complete pass through the training dataset |
| Compute-optimal | Best model performance achievable for a given compute budget |
| Prefill | Parallel input-processing phase of transformer inference |
| Decode | Sequential output-token generation phase |

## How It Relates To

- **Inference optimization**: prefill is parallelizable; decode is sequential — different bottlenecks demand different optimizations
- **Context length**: every previous token needs cached K/V vectors, making long contexts memory-expensive for transformers
- **Training data**: model size alone is insufficient — sufficient training tokens (Chinchilla ratio) are required

## Common Misconceptions

- **Myth**: A bigger model always performs better.
  **Reality**: A larger model trained on insufficient data underperforms a smaller well-trained model. Newer-generation models often beat older larger ones (Llama 3-8B > Llama 2-70B on MMLU).

- **Myth**: Parameter count determines inference cost.
  **Reality**: Sparse/MoE models activate only some parameters per token. Mixtral 8x7B (46.7B params) costs like a 12.9B dense model.

- **Myth**: FLOPs and FLOP/s mean the same thing.
  **Reality**: FLOPs = total operations for a task; FLOP/s = hardware throughput per second.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Transformer | Attention-based architecture with parallel input, sequential output |
| Attention | Weights past tokens via Q·K dot product, retrieves V vectors |
| Multi-head | Splits Q/K/V across heads to attend to different patterns |
| Layers | Number of transformer blocks stacked in the model |
| Chinchilla | Train on ~20 tokens per parameter for compute-optimal results |
| MoE | Activate only a subset of parameters per token to cut inference cost |
| Scaling bottlenecks | Internet data exhaustion and electricity supply |
