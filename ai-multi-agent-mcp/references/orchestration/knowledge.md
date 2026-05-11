# Orchestration Knowledge

Core concepts and foundational understanding for orchestrating multi-agent systems.

## Overview

The Orchestrator is the central coordinator that turns a high-level user goal into a sequence of agent invocations. It owns the workflow, routes MCP messages between specialized agents, and assembles the final artifact. Without it, individual agents are isolated tools with no way to collaborate.

## Key Concepts

### The Orchestrator

**Definition**: A single function (or component) that manages the entire multi-agent workflow from start to finish.

It accepts a high-level goal, decomposes it into tasks, delegates each task to the appropriate agent, threads outputs into the next agent's input, and presents the final result.

**Key points**:
- Acts as a central hub - all agent-to-agent traffic flows through it
- Owns the sequencing logic (which agent runs when)
- Owns the data hand-off between agents
- Surfaces progress and final output to the user

### Orchestrator-as-Conductor (Project Manager Metaphor)

**Definition**: The Orchestrator is described as the "project manager of our AI team."

Like a project manager, it does not do the work itself - it delegates to specialists and manages the flow of information between them. The agents are domain experts (Researcher, Writer); the Orchestrator coordinates them.

**Key points**:
- Does no domain work itself (no research, no writing)
- Decides who works on what, and in what order
- Hand-off is its primary responsibility

### Goal Decomposition

**Definition**: Taking a single high-level goal and breaking it into a sequence of agent-sized tasks.

Example: The goal "Create a blog post about the benefits of the Mediterranean diet" decomposes into (1) research the topic, then (2) write content from the research.

**Key points**:
- Decomposition happens up front, before any agent runs
- Each task maps to one specialized agent
- The decomposition can be hardcoded (basic) or planned dynamically (advanced)

### Sequential Agent Invocation

**Definition**: Calling agents one after another, where each agent's output feeds the next agent's input.

In the basic orchestrator, the Researcher must finish before the Writer starts because the Writer needs the research summary as its input.

**Key points**:
- Used when there is a data dependency (Writer needs Researcher's output)
- Output of agent N becomes content of MCP message to agent N+1
- Orchestrator holds the intermediate result between calls

### Parallel Agent Invocation

**Definition**: Calling multiple agents simultaneously when their tasks are independent.

Not used in the basic orchestrator (Researcher and Writer have a strict dependency), but is the natural extension when tasks have no shared inputs.

**Key points**:
- Use when tasks have no data dependencies on each other
- Can dramatically reduce wall-clock time
- Orchestrator collects and merges all results before continuing

### Message Routing via MCP

**Definition**: Every hand-off between Orchestrator and agent is wrapped in an MCP message.

The Orchestrator builds an MCP message with itself as `sender` and the task content, then unwraps the agent's MCP response by reading the `content` field.

**Key points**:
- Orchestrator is always the `sender` for outgoing tasks
- Agent responses arrive as MCP messages, not raw strings
- Consistent envelope makes adding/swapping agents trivial

## Terminology

| Term | Definition |
|------|------------|
| Orchestrator | Central coordinator function managing the multi-agent workflow |
| Initial goal | High-level user task passed into the Orchestrator |
| Delegation | Sending a task (as MCP message) to a specialized agent |
| Hand-off | Passing one agent's output as the next agent's input |
| Final output | Assembled artifact returned to the user at workflow end |

## How It Relates To

- **MCP Protocol**: The Orchestrator depends on MCP messages as the universal envelope for delegation
- **Agent Design**: The Orchestrator is the consumer of specialized agents; agents are useless in isolation
- **Robustness**: The basic Orchestrator has no validation or error handling - that comes next

## Common Misconceptions

- **Myth**: The Orchestrator does some of the actual work.
  **Reality**: It only coordinates. All domain logic lives inside specialized agents.

- **Myth**: The Orchestrator must be an LLM.
  **Reality**: In the basic version it is a plain Python function with hardcoded steps. LLM-based planning is an upgrade, not a requirement.

- **Myth**: Agents can talk directly to each other.
  **Reality**: All inter-agent communication is mediated by the Orchestrator (hub-and-spoke).

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Orchestrator | Central function that delegates tasks and routes MCP messages |
| Conductor metaphor | Orchestrator coordinates; agents do the work |
| Goal decomposition | Break high-level goal into agent-sized tasks |
| Sequential invocation | Output of one agent feeds the next |
| MCP routing | Every hand-off wrapped in an MCP message envelope |
