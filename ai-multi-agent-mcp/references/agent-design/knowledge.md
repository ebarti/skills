# Agent Design Knowledge

Core concepts for designing specialist agents in a multi-agent system that communicates via MCP messages.

## Overview

A specialist agent is a Python function that consumes a structured MCP message, performs a single focused job, and returns a structured MCP message. The agent's behavior is defined by its **system prompt**, which frames the LLM's role for that step in the workflow. A single shared helper function (`call_llm`) centralizes all LLM API interactions so agents stay focused on their unique logic.

## Key Concepts

### Specialist Agent

**Definition**: A Python function with one well-defined job, driven by an LLM behind a system prompt, with MCP messages as both input and output.

**Mental model**: `agent = function with system prompt + MCP I/O`.

**Key points**:
- Each agent owns a single role (e.g., research, writing).
- Inputs and outputs are always MCP messages — never raw strings between agents.
- The system prompt is the agent's identity; switching prompts changes what the agent does.
- Agents log activation so the workflow is traceable.

### System Prompt as Agent Identity

**Definition**: A string passed to the LLM in the `system` role that tells the model how to behave for this agent.

**Key points**:
- It encodes role, tone, format, and length constraints.
- Within a multi-agent system, prompts become carefully engineered instructions, not casual hints.
- Different agents differ primarily in their system prompt; the surrounding plumbing is identical.
- Example contrast: the Researcher prompt enforces factual synthesis; the Writer prompt enforces engaging tone and length.

### Helper Function (`call_llm`)

**Definition**: A single shared function that wraps every call to the OpenAI API and returns plain text.

**Key points**:
- Takes two inputs: `system_prompt` (behavior) and `user_content` (the specific input).
- Builds the `messages` list with explicit `system` and `user` roles.
- Returns `response.choices[0].message.content`.
- Wraps the call in `try`/`except` so a failed API call does not crash the agent.
- Centralization keeps agent code small and consistent.

### Researcher Agent Role

**Definition**: The first agent in the workflow; takes a research topic, looks up information from a (simulated) data source, and summarizes it.

**Key points**:
- Reads the topic from `mcp_input['content']`.
- Looks up the entry in `simulated_database`; falls back to `"No information found on this topic."`.
- System prompt frames the LLM as a "research analyst" producing 3–4 concise bullet points.
- Output MCP message includes `sender="ResearcherAgent"` and metadata `{"source": "Simulated Internal DB"}`.
- The simulated dictionary is a placeholder for a future RAG/vector database.

### Writer Agent Role

**Definition**: The second agent; takes the Researcher's summary and transforms it into a short blog post.

**Key points**:
- Reads the summary from `mcp_input['content']` — the Researcher's output.
- System prompt sets a "skilled content writer for a health and wellness blog" persona, with engaging tone, ~150 words, catchy title.
- Output MCP message includes `sender="WriterAgent"` and metadata `{"word_count": len(blog_post.split())}`.
- Demonstrates how a different system prompt repurposes the same plumbing for a creative task.

### How Agents Consume MCP Messages

**Definition**: Every agent receives a dict-like MCP message and returns one via `create_mcp_message`.

**Key points**:
- Read input via `mcp_input['content']`.
- Compute output (look up data, call `call_llm`).
- Wrap the result with `create_mcp_message(sender=..., content=..., metadata=...)`.
- Metadata is agent-specific (data source, word count, etc.) but the envelope is uniform.

## Terminology

| Term | Definition |
|------|------------|
| Specialist agent | A Python function with one job, driven by a system prompt |
| System prompt | Instruction string that frames the LLM's role |
| User content | The specific input the agent passes to the LLM |
| MCP message | Structured dict envelope used for all inter-agent I/O |
| `call_llm` | Shared helper that wraps the OpenAI chat completion call |
| `create_mcp_message` | Helper that builds the standardized output envelope |
| Researcher agent | Agent that retrieves and summarizes facts on a topic |
| Writer agent | Agent that turns a summary into a blog post |

## How It Relates To

- **MCP Protocol**: Agents are the producers and consumers of MCP messages; the protocol defines the contract.
- **Orchestration**: Agents are the units the orchestrator chains together; the Researcher's output is wired into the Writer's input.
- **Robustness**: The `try`/`except` inside `call_llm` is the first robustness layer for every agent.

## Common Misconceptions

- **Myth**: An agent must be a class with internal state.
  **Reality**: In this design, an agent is just a function — stateless, with its identity carried by its system prompt.

- **Myth**: Every agent should call the LLM differently for flexibility.
  **Reality**: A single shared `call_llm` keeps behavior consistent and bugs centralized; differentiation comes from the prompt, not the API call.

- **Myth**: Agents can pass raw strings between each other.
  **Reality**: All inter-agent I/O must be MCP messages so metadata, sender, and structure stay intact.

- **Myth**: The Researcher and Writer differ in code structure.
  **Reality**: They share the same shape (extract content → optional lookup → `call_llm` → `create_mcp_message`); only the prompt and metadata change.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Specialist agent | Function with system prompt and MCP I/O |
| System prompt | The agent's identity and behavior contract |
| `call_llm` | One helper, all LLM calls, with error handling |
| Researcher | Topic in, bulleted summary out |
| Writer | Summary in, blog post out |
| MCP envelope | Uniform input/output across all agents |
