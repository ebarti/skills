# Micro-Context Engineering Knowledge

Core concepts and foundational understanding for prompt design WITHIN agents.

## Overview

Micro-context engineering is the discipline of crafting the precise, internal instructions a single agent receives so that a generic LLM tool becomes a high-precision, task-specific instrument. While macro context engineering shapes the engine that orchestrates agents, micro context engineering shapes what each agent actually executes.

## Key Concepts

### Macro vs Micro Context Engineering

**Definition**: Two complementary scales of context design within a multi-agent system.

- **Macro**: Architecting the engine, registry, planner, and inter-agent flow.
- **Micro**: Architecting the prompt and objective inside an individual agent so it performs its slice of work correctly.

**Key points**:
- Macro decides *which* agent runs and *when*.
- Micro decides *how well* that agent performs once activated.
- Both must be engineered; neither alone yields a robust system.

### The Agent as a Mini Context Engine

**Definition**: Each specialist agent is itself a tiny context engine whose system prompt + objective produce a focused behavior.

An LLM, like any powerful tool, performs best when given clear, unambiguous instructions. The same LLM call can be a vague summarizer or a precision entity-extractor depending purely on the micro-context supplied.

**Key points**:
- A reusable agent (e.g., Summarizer) is dynamically repurposed via its objective string.
- The objective acts as a "miniature semantic blueprint" for that single call.
- The agent's flexibility comes from the micro-context, not from new code.

### The Objective as a Semantic Blueprint

**Definition**: A well-architected objective is specific, constrained, and defines the desired output shape.

A poor objective forces the LLM to guess what the user deems important; a strong objective leaves no room for ambiguity and guarantees a useful, structured output.

**Key points**:
- Specificity > generality.
- Include constraints (what to exclude).
- Declare output shape (e.g., JSON object).

### Instruction Reinforcement

**Definition**: Strengthening an agent's internal logic and prompt so it can collaborate with new sibling agents without breaking.

When the Summarizer was added, the Writer had to be reinforced to accept either `'facts'` (from Researcher) or `'summary'` (from Summarizer). The reinforcement is at the data-contract layer, not just textual prompt.

**Key points**:
- Reinforcement targets resilience across collaborators.
- A "bilingual" agent reads multiple data formats from upstream agents.
- Reinforcement is applied when a new agent introduces a new schema.

### Data Contract Violation

**Definition**: A failure mode in which an agent receives correctly-routed data in an unexpected schema.

Example: Researcher emits `{'facts': '...'}` while Summarizer emits `{'summary': '...'}`. The Writer originally only spoke the first dialect.

**Key points**:
- Detected in integration testing, not unit testing.
- Resolved by teaching the consuming agent to check multiple keys.
- Caused by macro-level routing meeting micro-level rigidity.

### From Development to Design

**Definition**: The paradigm shift in which engineering value comes from designing precise instructions, not from writing more code.

A good context engineer supplies solid, purposeful inputs; a poor one never obtains the expected results. Upskilling means investing in instruction design as a first-class discipline.

## Terminology

| Term | Definition |
|------|------------|
| Micro-context | Prompt/objective supplied to an individual agent call |
| Macro-context | The orchestrating engine, registry, and plan |
| Objective | A specific, constrained instruction string fed to an agent (e.g., `summary_objective`) |
| Semantic blueprint | A precise, structured instruction that defines task + constraints + output |
| Instruction reinforcement | Hardening an agent's prompt/logic to handle new collaborators |
| Data contract | The schema (keys, types) of data passed between agents |
| Bilingual agent | An agent that accepts multiple upstream schemas |

## How It Relates To

- **Summarizer agent**: Built around its `summary_objective` micro-context.
- **Writer agent**: Reinforced so its micro-context can ingest multiple input schemas.
- **AgentRegistry / Planner**: Macro layer that chooses which agent runs; relies on each agent's micro-context being precise.

## Common Misconceptions

- **Myth**: A reusable agent is defined only by its code.
  **Reality**: It is defined just as much by the objective string passed in at runtime.

- **Myth**: "Summarize this text" is a sufficient instruction.
  **Reality**: That is an old-fashioned prompt; it forces the LLM to guess priorities and yields generic output.

- **Myth**: Once an agent works, it never needs prompt changes.
  **Reality**: Adding new sibling agents (new data contracts) requires reinforcing the consuming agent.

- **Myth**: Micro and macro context engineering are interchangeable.
  **Reality**: They operate at different scales; both are required for a robust system.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Macro vs micro | Engine-level design vs in-agent prompt design |
| Mini context engine | Each agent is its own miniature context engine |
| Semantic blueprint | A precise, constrained, output-shaped objective |
| Reinforcement | Upgrading an agent to collaborate with new siblings |
| Data contract violation | Right data, wrong key — fixed by bilingual unpacking |
