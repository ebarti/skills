# Agent Overview Knowledge

Core concepts and foundational understanding for AI agents and their tools.

## Overview

An AI agent is anything that can perceive its environment and act upon it. Agents are characterized by two things: the environment they operate in and the set of actions (tools) they can perform. Foundation models serve as the agent's "brain" — they process input, plan actions, and decide when a task is complete.

## Key Concepts

### Agent

**Definition**: A system that perceives its environment and acts upon that environment using a set of available actions.

The AI (foundation model) is the brain that processes information, plans a sequence of actions, and determines task completion.

**Key points**:
- Characterized by its environment + set of actions
- AI plans, reasons, invokes tools, and evaluates results
- Examples: ChatGPT (web search, code exec, image gen), RAG systems, SWE-agent

### Environment

**Definition**: The context in which an agent operates, defined by its use case.

Examples of environments:
- A game (Minecraft, Go, Dota) for game-playing agents
- The internet for web scraping agents
- A kitchen for a cooking robot
- A computer terminal + filesystem for SWE-agent
- The road for self-driving cars

**Strong dependency**: Environment determines which tools are possible; tool inventory restricts which environments the agent can operate in.

### Tools

**Definition**: External capabilities that augment what an agent can do beyond its base model action (e.g., text generation).

Without tools, an LLM can only generate text. With tools, agents become vastly more capable.

**Two types of actions**:
- **Read-only actions**: Perceive the environment (e.g., search, retrieval)
- **Write actions**: Modify the environment (e.g., send email, write to DB)

### Tool Inventory

**Definition**: The complete set of tools an agent has access to.

- More tools = more capabilities, but harder to select/use correctly
- Experimentation needed to find the right set
- Determines what the agent can do

## The Three Tool Categories

### 1. Knowledge Augmentation (Context Construction)

Tools that bring relevant context into the model's reasoning.

**Examples**:
- Text/image retrievers (RAG)
- SQL executor (read-only queries)
- Internal people search, inventory API, Slack retrieval, email reader
- Web browsing (search APIs, news APIs, GitHub APIs, social media APIs)

**Purpose**: Prevents model staleness; injects organization-private or up-to-date public info.

### 2. Capability Extension

Tools that compensate for inherent model weaknesses.

**Examples**:
- Calculator (math is a model weakness)
- Calendar, timezone converter, unit converter, translator
- Code interpreter (runs code, returns results)
- Image generators (e.g., DALL-E) for text-only models
- OCR, image captioning, transcription tools (multimodal access)

**Purpose**: Cheaper than retraining; turns text-only models into multimodal systems.

### 3. Write Actions

Tools that modify data sources or external systems.

**Examples**:
- SQL executor (UPDATE/DELETE)
- Email API (send/respond)
- Banking API (initiate transfer)
- Database writers, CRM updaters

**Purpose**: Enable end-to-end automation (e.g., full customer outreach: research → contact → send → follow up → update DB).

## Why Agents Need More Powerful Models

| Reason | Detail |
|--------|--------|
| Compound mistakes | 95% per-step accuracy → 60% over 10 steps → 0.6% over 100 steps |
| Higher stakes | Tool access means failures have larger consequences |

## Terminology

| Term | Definition |
|------|------------|
| Agent | Something that perceives and acts on an environment |
| Environment | The context the agent operates in |
| Tool | External capability that extends agent action |
| Tool inventory | Full set of tools available to the agent |
| Read-only action | Perceives environment without modifying it |
| Write action | Modifies the environment |
| Function calling | Common name for tool use in model APIs |
| Stale model | Model whose training data is outdated |

## How It Relates To

- **RAG**: A simple agent — retrieval is its tool, response generation is its action
- **Planning**: Determines which tools to invoke and in what order
- **Self-critique / Chain-of-thought**: Used by the AI brain to reason between tool calls
- **Structured outputs**: How agents format tool invocations and results

## Common Misconceptions

- **Myth**: An agent must have external tools to be an agent.
  **Reality**: A system can be an agent without tools, but its capabilities are very limited.

- **Myth**: More tools always make a better agent.
  **Reality**: More tools = more confusion. Right-size the inventory.

- **Myth**: ChatGPT is "just an LLM."
  **Reality**: ChatGPT is an agent — it has web search, code execution, and image generation tools.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Agent | Perceives + acts on an environment via tools |
| Environment | Defines what tools are possible |
| Knowledge tool | Augments context (RAG, web search) |
| Capability tool | Fixes model weaknesses (calculator, code interp) |
| Write tool | Modifies external state (send, update, delete) |
| Function calling | Provider-supported tool invocation mechanism |
