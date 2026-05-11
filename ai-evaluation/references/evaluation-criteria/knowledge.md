# Evaluation Criteria Knowledge

Core concepts for defining what to evaluate in AI applications.

## Overview

AI applications need explicit evaluation criteria before they're built (evaluation-driven development). Criteria fall into four buckets: domain-specific capability, generation capability, instruction-following capability, and cost & latency. Each criterion answers a different question about whether the model fits the application.

## Key Concepts

### Domain-Specific Capability

**Definition**: Whether the model has the knowledge and skills required by the application's domain (e.g., coding, Latin translation, legal reasoning).

Constrained by model architecture, size, and training data. If a model never saw Latin during training, it cannot translate Latin. Typically evaluated using exact evaluation against public or private benchmarks.

**Key points**:
- Coding capabilities: evaluated via functional correctness, plus efficiency (runtime/memory) and readability
- Non-coding capabilities: usually evaluated via close-ended tasks (multiple-choice questions)
- MCQs measure ability to discriminate, not generate

### Generation Capability

**Definition**: How well the model produces open-ended text — coherent, fluent, faithful, factually consistent, and safe.

Studied historically under NLG (natural language generation). Modern foundation models have largely solved fluency/coherence for strong models, so the focus shifted to factual consistency and safety.

**Key points**:
- Old metrics (fluency, coherence): mostly solved, still useful for weak models or creative writing
- New focus: factual consistency (no hallucinations) and safety (no harm)
- Task-specific metrics: faithfulness (translation), relevance (summarization)

### Factual Consistency

**Definition**: Whether the output's claims are supported by trusted facts.

Two settings:
- **Local factual consistency**: Output evaluated against a provided context (summarization, RAG, customer support). The output is consistent if supported by the context.
- **Global factual consistency**: Output evaluated against open knowledge (general chatbots, fact-checking). Requires retrieving and trusting external sources.

### Safety

**Definition**: Whether outputs avoid causing harm to users or society.

Categories of unsafe content:
1. Inappropriate language (profanity, explicit content)
2. Harmful recommendations or tutorials
3. Hate speech (racist, sexist, homophobic, discriminatory)
4. Violence (threats, graphic detail)
5. Stereotypes (gender/role assumptions)
6. Political or religious bias

### Instruction-Following Capability

**Definition**: How well the model obeys the instructions in the prompt — formatting, content constraints, length, language, style.

Critical for structured outputs (JSON, regex matches, classification labels). A model can have the domain capability but still fail because it doesn't follow output format instructions.

**Key points**:
- Format constraints: JSON, bullet count, length, keyword inclusion
- Content constraints: "discuss only X", forbidden words
- Style constraints: tone, language register, persona
- Roleplaying is a common subcategory (character or persona)

### Cost and Latency

**Definition**: How much each query costs and how long users wait.

A high-quality model that's too slow or expensive is unusable. Treated as a Pareto optimization problem: identify hard constraints, filter to candidates that meet them, then optimize quality among the rest.

**Key points**:
- Latency metrics: time to first token, time per token, time between tokens, time per query
- Cost drivers (APIs): input + output token counts
- Cost drivers (self-hosted): compute (GPU memory, utilization)

## Terminology

| Term | Definition |
|------|------------|
| Evaluation-driven development | Defining evaluation criteria before building |
| Functional correctness | Output works as intended (e.g., code passes tests) |
| Local factual consistency | Output matches a provided context |
| Global factual consistency | Output matches open-world facts |
| Textual entailment | Classifying premise/hypothesis as entail/contradict/neutral |
| Self-verification | Checking consistency across multiple model samples |
| Knowledge-augmented verification | Using external search to fact-check claims |
| Pareto optimization | Optimizing multiple objectives with trade-offs |
| TTFT | Time to first token |
| TPM | Tokens per minute |

## How It Relates To

- **AI as judge**: Used to score factual consistency, safety, instruction-following, roleplaying
- **Exact evaluation**: Used for domain capabilities (MCQs, code execution) and verifiable instructions (regex, length)
- **Model selection**: Criteria scores feed into the selection decision
- **RAG systems**: Local factual consistency is the primary quality metric

## Common Misconceptions

- **Myth**: A model that scores high on MMLU will generate good summaries.
  **Reality**: MCQs test discrimination, not generation. They aren't ideal for generative tasks.

- **Myth**: Fluency is still a top metric for foundation models.
  **Reality**: Modern LLM outputs are nearly indistinguishable from human text in fluency. Track factual consistency and safety instead.

- **Myth**: A poor instruction-following score means the model lacks the capability.
  **Reality**: It might mean the model didn't understand the instruction. Domain capability and instruction-following are easily conflated.

- **Myth**: Lower latency is always worth pursuing.
  **Reality**: Distinguish must-haves from nice-to-haves. High latency is usually an annoyance, not a deal breaker.

## Quick Reference

| Criterion | Question Answered | Typical Method |
|-----------|-------------------|----------------|
| Domain-specific | Does it know the field? | Benchmarks (MMLU, HumanEval), MCQs |
| Generation - factual | Are the facts correct? | AI judge, entailment classifier, SAFE |
| Generation - safety | Is it harmful? | Toxicity classifier, moderation API |
| Instruction-following | Does it obey the prompt? | IFEval (auto), INFOBench (yes/no) |
| Cost | How much per query? | $/1M tokens (API) or compute cost |
| Latency | How long to wait? | TTFT, time per query (P90) |
