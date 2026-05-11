# Agent Planning Knowledge

Core concepts for foundation model (FM) agent planning, plan generation, reflection, and tool selection.

## Overview

A task is defined by its **goal** and **constraints**. Complex tasks require planning: the agent must understand the task, consider options, and choose a promising path. Effective agents decouple planning from execution and add reflection to catch errors.

## Key Concepts

### Plan

**Definition**: A roadmap (sequence of manageable actions) outlining steps to accomplish a task. Also called *task decomposition*.

**Key points**:
- A plan can be end-to-end or for a subtask
- Plans need not be sequential (parallel, conditional, loop control flows)
- Plans can be expressed as function calls or natural language

### Decoupled Planning and Execution

**Definition**: The pattern of generating a plan first, validating it, and only then executing it.

Without decoupling, an agent could execute a 1,000-step plan that never reaches the goal, wasting time and money. Validation can be done with heuristics (e.g., reject plans with invalid actions or too many steps) or AI judges.

### Three-Component Agent System

A planning agent is effectively a multi-agent system with three roles:
1. **Plan generator** - proposes plans
2. **Plan validator** - evaluates plans (heuristic or AI judge)
3. **Plan executor** - runs the plan (often via function calling)

### Intent Classification

**Definition**: A pre-planning step that identifies what the user is trying to do.

Intent helps the agent pick the right tools (e.g., billing tools for billing queries vs. doc retrieval for password resets). Out-of-scope intents should be classified as `IRRELEVANT` so the agent can politely reject instead of wasting compute.

### Reflection

**Definition**: Evaluating outputs (plan, step, or full execution) to detect mistakes and trigger correction.

Reflection is not mandatory but significantly boosts performance. It can be done by the same agent (self-critique) or a separate scorer/evaluator agent.

### Function Calling

**Definition**: Invoking a declared tool (function) with model-generated parameters.

Standard tool-use settings:
- `required` — model must use at least one tool
- `none` — model must not use any tool
- `auto` — model decides

APIs may guarantee valid function names but cannot guarantee correct parameter values.

### Planning Granularity

**Definition**: Level of detail in the plan. Detailed plans are harder to generate but easier to execute; high-level plans are the reverse.

Hierarchical planning resolves the trade-off: generate a high-level plan first, then expand each step.

### Control Flow Types

| Flow | Behavior |
|------|----------|
| Sequential | B runs after A completes (B depends on A) |
| Parallel | A and B run simultaneously |
| If statement | Run B or C based on previous output |
| For loop | Repeat A until condition met |

### FMs as Planners (Open Question)

Planning is a **search problem** requiring backtracking. Critics (LeCun, Kambhampati) argue autoregressive LLMs cannot truly plan. Defenders argue:
- LLMs *can* backtrack by revising prior actions or restarting
- Plans need outcome prediction (world model), not just action sequences
- LLMs may need augmentation (search tools, state tracking) to plan well

### FM vs RL Planners

| Aspect | RL Planner | FM Planner |
|--------|-----------|------------|
| Training | Trained with RL algorithm | Prompted or finetuned |
| Cost | Heavy time/compute | Lighter |
| Likely future | Merge with FM | Merge with RL |

## Terminology

| Term | Definition |
|------|------------|
| Task | Goal + constraints |
| Plan | Sequence of actions toward goal |
| Trajectory | A plan (Reflexion terminology) |
| Tool inventory | Set of tools available to the agent |
| Control flow | Order in which actions execute |
| Backtracking | Returning to a prior state to try a different action |
| Skill manager | Module that stores newly acquired tools/skills |

## How It Relates To

- **RAG**: Retrieval can be one of the agent's tools
- **Memory**: Past tool outputs and reflections feed the next planning step
- **Tool use**: Function calling is the execution mechanism for plans

## Common Misconceptions

- **Myth**: Chain-of-thought equals planning.
  **Reality**: CoT generates a forward action sequence; true planning needs outcome prediction and validation.
- **Myth**: Autoregressive LLMs cannot backtrack.
  **Reality**: They can revise paths or restart, effectively backtracking.
- **Myth**: More tools always means a better agent.
  **Reality**: Too many tools degrade selection accuracy and inflate context cost.

## Quick Reference

| Concept | Summary |
|---------|---------|
| Decoupled planning | Generate, validate, then execute |
| Reflection | Evaluate outcomes; correct errors |
| ReAct | Interleave Thought / Act / Observation |
| Reflexion | Evaluator + self-reflection module |
| Hierarchical planning | High-level plan, then detailed sub-plans |
| Tool transition | Pattern of which tool follows which |
