# Prompting Fundamentals Knowledge

Core concepts and foundational understanding for prompt engineering.

## Overview

Prompt engineering is the process of crafting an instruction that gets a model to generate the desired outcome. It guides model behavior without changing weights, making it the easiest and most common adaptation technique. Effective prompting requires understanding prompt anatomy, in-context learning, the system/user split, and context length constraints.

## Key Concepts

### Prompt

**Definition**: An instruction given to a model to perform a task.

A prompt generally consists of one or more of these parts:

- **Task description**: What the model should do, the role to play, and output format
- **Examples**: Demonstrations of how to do the task (e.g., toxicity vs non-toxicity samples)
- **The task**: The concrete instance to act on (the question, the document to summarize)

### In-Context Learning

**Definition**: Teaching a model what to do via examples and instructions in the prompt, with no weight updates.

Introduced in the GPT-3 paper (Brown et al., 2020). Lets a model incorporate new information continually, making it a form of continual learning. Example: a model trained on old JavaScript docs can answer questions about new JS by including the changes in context.

**Key points**:
- No retraining required
- Model performs tasks beyond what it was originally trained on
- Limited by the model's context window

### Zero-Shot Learning

**Definition**: Asking a model to do a task with no examples in the prompt.

The model relies entirely on its pretrained knowledge and the task description. Stronger models (GPT-4 class) increasingly close the gap between zero-shot and few-shot.

### Few-Shot Learning

**Definition**: Including N example input/output pairs in the prompt to teach the desired behavior. Each example is called a *shot* (5 examples = 5-shot).

**Key points**:
- More examples generally improve performance
- Number is bounded by context length
- More examples increase inference cost (more tokens in)
- Larger gains for domain-specific or unfamiliar APIs

### System Prompt vs User Prompt

**Definition**: A split exposed by most chat APIs where the system prompt holds the task description (developer-controlled) and the user prompt holds the task itself (user-controlled).

Under the hood, both are concatenated into a single prompt via a chat template. Performance benefits from the system prompt come from two factors:
- It comes first, and models process leading instructions better
- Models are post-trained to prioritize system prompts (instruction hierarchy)

### Chat Template

**Definition**: The model-defined format for combining system and user prompts into the final input string. Different from a developer-defined prompt template.

Example (Llama 2):
```
<s>[INST] <<SYS>>
{{ system_prompt }}
<</SYS>>

{{ user_message }} [/INST]
```

Wrong templates cause silent failures — the model still produces plausible output.

### Context Length

**Definition**: The maximum number of tokens a model can process in a single input.

Reference points:
- GPT-1/2/3: 1K, 2K, 4K tokens
- 100K tokens fits a moderate book
- This book (~120K words) ≈ 160K tokens
- Gemini-1.5 Pro: 2M tokens (~2,000 Wikipedia pages or PyTorch codebase)

### Context Efficiency

**Definition**: Getting maximum task performance from minimum tokens by placing critical information where the model attends best.

Models attend best to the **beginning** and **end** of a prompt; performance dips in the middle ("lost in the middle" effect, Liu et al., 2023). Measured via **needle in a haystack (NIAH)** tests — insert info at varied positions, ask the model to retrieve it.

### Robustness

**Definition**: A model's resistance to prompt perturbations (e.g., "5" vs "five", extra newlines, capitalization changes).

Less robust models require more prompt fiddling. Robustness correlates with overall capability — stronger models are more robust.

## Terminology

| Term | Definition |
|------|------------|
| Prompt | The full input given to the model |
| Context | The information the model needs to do the task (book uses prompt = full input, context = task info) |
| Shot | A single example in the prompt |
| Zero-shot | No examples provided |
| Few-shot | N examples provided |
| System prompt | Developer-controlled task description |
| User prompt | The end user's task or query |
| Chat template | Model's required format for combining prompts |
| NIAH | Needle in a haystack test for context retrieval |
| Token | Unit of text the model processes (~0.75 words avg) |

## How It Relates To

- **Finetuning**: Prompting is the lighter alternative; try prompting before finetuning
- **RAG**: Provides context that gets injected into the user prompt
- **Evaluation**: Prompt experiments require the same rigor as ML experiments

## Common Misconceptions

- **Myth**: Prompt engineering is just fiddling with words.
  **Reality**: It involves systematic experimentation, evaluation, and tracking — same rigor as ML.

- **Myth**: System prompts have a special "magic" mechanism.
  **Reality**: They're concatenated into the same input. Boost comes from position (first) and post-training prioritization.

- **Myth**: Always use few-shot — more examples = better.
  **Reality**: For modern strong models on general tasks (GPT-4+), few-shot gains are limited. Always increases cost and prompt length.

- **Myth**: Context = prompt always.
  **Reality**: Terminology varies. GPT-3 paper uses them interchangeably; this book uses prompt = full input, context = task info.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Prompt | Instruction to the model (task description + examples + task) |
| In-context learning | Teaching via prompt, no weight updates |
| Zero-shot | No examples |
| Few-shot | N examples in the prompt |
| System prompt | Developer task description, comes first |
| User prompt | End-user task, comes after system |
| Context length | Max tokens the model accepts |
| Context efficiency | Putting key info at start/end, not middle |
| Robustness | Resistance to prompt perturbations |
