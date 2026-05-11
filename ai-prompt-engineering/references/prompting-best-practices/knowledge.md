# Prompting Best Practices Knowledge

Core concepts and foundational understanding for effective prompt engineering.

## Overview

Prompt engineering best practices are general techniques that work across a wide range of models and remain relevant as models improve. They focus on clarity, context, decomposition, and iteration rather than model-specific tricks (like "Q:" formatting or "$300 tip" promises) that become outdated quickly.

## Key Concepts

### Clear and Explicit Instructions

**Definition**: Communication with AI follows the same rules as communication with humans: clarity reduces ambiguity and improves output quality.

**Key points**:
- Specify scoring scales, output ranges, and edge case handling
- Tell the model exactly what to do when uncertain (e.g., "output 'I don't know'")
- Iterate prompts to address undesirable behaviors observed during experimentation

### Persona Adoption

**Definition**: Asking the model to take on a specific role or perspective when generating responses.

A persona helps the model understand the perspective from which to evaluate or generate. The same essay scored by a "first-grade teacher" persona will get different results than scoring with default behavior.

### Examples (Few-Shot)

**Definition**: Including sample input/output pairs in the prompt to demonstrate desired behavior.

Examples reduce ambiguity about response format, tone, and content. They are especially useful when handling edge cases (e.g., responding to children about fictional characters like Santa).

### Output Format Specification

**Definition**: Explicitly stating the structure, length, and format of expected outputs.

**Key points**:
- Long outputs cost more (per-token billing) and increase latency
- Suppress preambles ("Based on the content of this essay...") explicitly
- For structured outputs (JSON), specify keys and provide examples
- Use end-of-prompt markers (e.g., `-->`) to signal where output begins

### Sufficient Context

**Definition**: Providing the reference material or tools needed for the model to answer accurately.

Like reference texts on an exam, context improves performance and mitigates hallucinations. Without context, the model relies on internal knowledge that may be unreliable. Context can be provided directly or gathered via tools (RAG, web search) — a process called *context construction*.

### Task Decomposition

**Definition**: Breaking complex multi-step tasks into smaller subtasks, each with its own prompt, chained together.

**Key points**:
- Models perform better with simpler instructions
- Enables monitoring of intermediate outputs
- Enables independent debugging of each step
- Allows parallelization of independent steps
- Allows mixing model tiers (cheaper for simple steps, stronger for complex)

### Chain-of-Thought (CoT)

**Definition**: Prompting technique where the model is explicitly asked to think step-by-step before answering.

Introduced by Wei et al. (2022), CoT improves reasoning across model sizes and reduces hallucinations. The simplest implementation: append "think step by step" or "explain your decision" to the prompt.

### Self-Critique

**Definition**: Asking the model to check, evaluate, or critique its own outputs (also called self-eval).

Like CoT, this nudges the model to reason critically before finalizing an answer.

### Prompt Iteration and Versioning

**Definition**: Treating prompts as versioned artifacts that are systematically tested and tracked across experiments.

**Key points**:
- Each model has quirks (some prefer system instructions at start, others at end)
- Test changes systematically, version every prompt
- Use experiment tracking tools and standardized evaluation metrics
- Evaluate prompts in context of the whole system, not just subtasks

### Prompt Engineering Tools

**Definition**: Tools that automate or assist prompt generation, optimization, and structured output enforcement.

Examples: OpenPrompt, DSPy, Promptbreeder, TextGrad (full automation); Guidance, Outlines, Instructor (structured outputs). Beware: tools generate hidden API calls, may have bugs in templates, and can change without warning.

### Prompt Organization

**Definition**: Separating prompts from application code, storing them in dedicated files or catalogs with metadata.

A *prompt catalog* versions each prompt independently of code so different applications can use different versions of the same prompt.

## Terminology

| Term | Definition |
|------|------------|
| CoT | Chain-of-thought prompting; "think step by step" |
| Zero-shot CoT | CoT without examples, just instructions to think step by step |
| One-shot CoT | CoT with one worked example |
| Self-critique | Model evaluates its own output |
| Context construction | Process of gathering context for a query (e.g., RAG, web search) |
| Prompt catalog | A versioned store of prompts separate from code |
| Dotprompt | A `.prompt` file format (Google Firebase) for storing prompts |
| Preamble | Boilerplate text the model adds before the actual answer |
| End-of-prompt marker | Token/symbol indicating where structured output should start |

## How It Relates To

- **Defensive Prompting**: Best practices reduce attack surface; clear instructions and context limits also harden against injection
- **RAG and Agents**: Context construction tools (Chapter 6) implement the "provide sufficient context" principle
- **Evaluation**: Versioned prompts enable systematic A/B testing across prompt variants

## Common Misconceptions

- **Myth**: Decomposition always increases cost
  **Reality**: Smaller prompts often use fewer tokens, and cheaper models can handle simpler steps; total cost may not double

- **Myth**: Prompt engineering tools eliminate the need to understand prompts
  **Reality**: Tools can have bugs, generate hidden API calls, and change without warning — always inspect generated prompts

- **Myth**: CoT works for every task
  **Reality**: CoT increases latency and cost; the right CoT variation (zero-shot vs few-shot, model-driven vs scripted) depends on the task

- **Myth**: Storing prompts in git is the best versioning solution
  **Reality**: Git couples prompt versions to code; multi-app reuse requires a separate prompt catalog so apps can pin different versions

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Clear instructions | Remove ambiguity; specify scales, formats, edge cases |
| Persona | Tell the model what role to play |
| Examples | Show, don't just tell |
| Output format | Specify structure, suppress preambles, use end markers |
| Context | Reference material reduces hallucination |
| Decomposition | Many small prompts beat one giant prompt |
| CoT | "Think step by step" improves reasoning |
| Self-critique | Have the model grade its own work |
| Iterate | Each model has quirks; test systematically |
| Versioning | Separate prompts from code; use a catalog |
