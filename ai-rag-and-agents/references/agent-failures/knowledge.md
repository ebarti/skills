# Agent Failure Modes Knowledge

Core concepts for understanding why AI agents fail and how to evaluate them.

## Overview

Agents have unique failure modes beyond standard AI application failures. The more complex a task, the more possible failure points. Failures cluster into three categories: planning failures, tool failures, and efficiency issues. Evaluation means identifying these failure modes and measuring how often each occurs.

## Key Concepts

### Planning Failures

**Definition**: Errors produced while the agent constructs the plan for solving the task, before any tool actually runs.

The most common subclass is **tool use failure** in the plan itself. Variants:

- **Invalid tool**: Plan calls a tool that doesn't exist in the tool inventory (e.g., `bing_search` when only `google_search` is available).
- **Valid tool, invalid parameters**: Plan calls an existing tool with the wrong parameter shape (e.g., passing two args to `lbs_to_kg(lbs)`).
- **Valid tool, incorrect parameter values**: Plan calls an existing tool with the correct shape but wrong values (e.g., `lbs_to_kg(lbs=100)` when the input was 120).

Other planning failures:

- **Goal failure**: Plan does not solve the task, or solves it while violating constraints (wrong destination, exceeds budget, misses deadline).
- **Time-constraint failure**: Agent finishes after the work is no longer useful (e.g., grant proposal delivered after the deadline).
- **Reflection failure**: Agent believes it accomplished the task when it didn't (e.g., assigns 40 of 50 people to rooms and reports done).

### Tool Failures

**Definition**: The agent picked the right tool, but the tool's output is wrong, missing, or unreachable.

Subtypes:

- **Wrong tool output**: Tool runs but returns incorrect data (image captioner returns wrong caption, SQL generator returns wrong query).
- **Translation failure**: When the agent emits high-level plans and a translator converts them to executable commands, the translator can introduce errors.
- **Missing tool**: Agent lacks a tool required for the task (no internet access when stock prices are needed).

Tool failures are **tool-dependent** — each tool must be tested independently.

### Efficiency Failures

**Definition**: Agent produces a valid plan with the right tools, but uses too many steps, too much money, or too much time.

The agent succeeds functionally but is wasteful. Efficiency is evaluated against a baseline (another agent or a human operator), but human-vs-AI baselines must account for different modes of operation.

## Terminology

| Term | Definition |
|------|------------|
| Tool inventory | The set of tools available to the agent |
| Goal failure | Plan does not satisfy the task or its constraints |
| Reflection failure | Agent's self-assessment of completion is wrong |
| Translation error | Bug introduced when high-level plan is converted to executable commands |
| Missing tool failure | Required tool is absent from the inventory |
| Planning dataset | Eval set of `(task, tool inventory)` tuples used to score plan validity |

## How It Relates To

- **Agent planning**: Planning failures are the cost of the plan-generation step; better prompts, examples, or finetuning reduce them.
- **Tool design**: Tool failures push back on tool quality, parameter schemas, and inventory completeness.
- **Agent evaluation**: All three categories require dedicated metrics — plan validity, per-tool accuracy, steps/cost/latency.

## Common Misconceptions

- **Myth**: An agent that says "task complete" has completed the task.
  **Reality**: Reflection failures are real — verify the actual outcome, not the agent's self-report.

- **Myth**: A working plan is a good plan.
  **Reality**: A plan can be valid and correct yet wasteful. Track steps, cost, and latency.

- **Myth**: If the agent fails, the model is wrong.
  **Reality**: It may be a missing tool, a buggy tool, or a translation layer — isolate the layer before blaming the model.

## Quick Reference

| Failure Category | One-Line Summary |
|------------------|-----------------|
| Invalid tool | Plan references tool not in inventory |
| Invalid parameters | Right tool, wrong parameter shape |
| Incorrect parameter values | Right tool, right shape, wrong values |
| Goal failure | Plan misses task or violates constraints |
| Reflection failure | Agent reports done when it isn't |
| Wrong tool output | Tool returned incorrect data |
| Translation failure | Plan-to-command converter introduced bug |
| Missing tool | Required tool absent from inventory |
| Inefficiency | Too many steps, too costly, or too slow |
