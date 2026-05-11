# MCP Protocol Knowledge

Core concepts for the Model Context Protocol (MCP) as applied to multi-agent system (MAS) communication in the book.

## Overview

MCP (Model Context Protocol) provides the rules for how agents pass tasks and information to one another. In this book, MCP principles — originally designed for agent-to-tool interaction — are adapted to agent-to-agent communication. It is the connective tissue that turns a collection of individual agents into an integrated system.

## Key Concepts

### What MCP Is

**Definition**: A protocol that gives agents a shared language for collaboration, ensuring every message is structured, reliable, and predictably understood.

**Key points**:
- Originally designed for agent-tool interaction; the book extends its principles to agent-to-agent (A2A) coordination
- Ensures tasks and results are always passed with full context
- Provides a consistent, predictable, reliable format
- Implemented in this book as a simplified Python dictionary that stands in for a formal JSON-RPC object

### MCP Message Format (Official)

**Definition**: A strictly defined structure that ensures consistency across systems.

**Key points**:
- All messages follow **JSON-RPC 2.0** as clean JSON objects
- Messages must be **UTF-8 encoded** for universal compatibility
- Each message must appear on a **single line with no embedded newlines** — making parsing fast and reliable

### MCP Message Format (Book's Simplified Version)

**Definition**: A Python dictionary with four key fields used to illustrate MCP without protocol overhead.

**Key fields**:
- `protocol_version` — version string (e.g., `"1.0"`)
- `sender` — the agent that produced the message (e.g., `"Orchestrator"`)
- `content` — the task or information payload
- `metadata` — optional dict for ancillary data (e.g., `task_id`, `priority`)

### Transport Layers

**Definition**: How MCP messages are transmitted between agents.

**Two primary methods**:
- **STDIO (standard input/output)**: For agents on the same machine (e.g., a Colab notebook). Simplest and most direct method.
- **HTTP**: For agents on different servers, sent over the internet using standard HTTP requests.

### Protocol Management

**Definition**: Rules MCP includes for compatibility and safety.

**Two areas**:
- **Versioning**: When using HTTP, a version header is required so client and server use the same rule set
- **Security**: Rules for validating connections to prevent common cyberattacks and confirm you are talking to the intended server

### Client Initialization (OpenAI)

**Definition**: Setup of the OpenAI client that serves as the gateway to the LLM powering each agent.

**Key points**:
- The `openai` library is required to communicate with the LLM
- The notebook assumes a setup cell already loaded the API key from Colab Secrets into an environment variable
- `OpenAI()` automatically reads `OPENAI_API_KEY` from the environment — no key is passed in code
- The `json` library is imported alongside it to display structured messages in readable form

### How MCP Enables Agent Communication

**Definition**: MCP packages every interaction between agents as a structured message rather than raw text.

**Key points**:
- Every interaction is wrapped in an MCP message — never raw text
- Guarantees full context is carried with each task/result
- Consistency of structure is the foundation of system reliability
- Messages can flow between agents without risk of being lost, misread, or misunderstood

### MAS Workflow with MCP

**Definition**: A three-component cognitive pipeline where MCP messages are the connective tissue.

**Three components**:
- **Orchestrator (project manager)**: The brain. Receives the user's high-level goal, breaks it into steps, delegates each to the right agent, and applies *context chaining* by passing results from one agent as context to the next.
- **Researcher Agent (information specialist)**: Takes a topic, finds relevant information, and synthesizes a structured (bullet-pointed) summary.
- **Writer Agent (content creator)**: Takes the Researcher's summary and transforms it into polished, human-readable content with attention to tone, style, and narrative.

## Terminology

| Term | Definition |
|------|------------|
| MAS | Multi-Agent System — multiple independent specialized agents |
| MCP | Model Context Protocol — shared language for agent communication |
| JSON-RPC 2.0 | Official message format MCP messages must follow |
| STDIO | Standard input/output transport for same-machine agents |
| HTTP | Network transport for agents on different servers |
| Context chaining | Passing one agent's output as the next agent's input context |
| Orchestrator | Coordinator agent that delegates and chains context |
| MCP message | A single structured packet of inter-agent communication |

## How It Relates To

- **Multi-Agent Systems (MAS)**: MCP is the protocol layer that makes a MAS coherent rather than a loose collection of agents
- **Context engineering**: MCP enforces full-context message passing between agents
- **Agent2Agent communication**: This book applies MCP to A2A patterns, building on Microsoft's exploration "Can You Build Agent2Agent Communication on MCP? Yes!"

## Common Misconceptions

- **Myth**: MCP is only for connecting agents to tools.
  **Reality**: MCP was originally designed for agent-tool interaction, but its principles can be applied to agent-to-agent communication.

- **Myth**: A Python dictionary is the real MCP message format.
  **Reality**: The book uses a Python dictionary as a simplified stand-in. The official format is JSON-RPC 2.0, UTF-8, single-line.

- **Myth**: MCP messages can carry raw multi-line text directly.
  **Reality**: Each official MCP message must appear on a single line with no embedded newlines.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| MCP | Shared, structured language for agent collaboration |
| Message format | JSON-RPC 2.0, UTF-8, single line (official) |
| Simplified format | Python dict with `protocol_version`, `sender`, `content`, `metadata` |
| STDIO transport | Same-machine direct I/O |
| HTTP transport | Cross-server, requires version header |
| Versioning | Header required over HTTP |
| Security | Connection validation against attacks |
| Client init | `OpenAI()` reads `OPENAI_API_KEY` from env |
| Workflow | Orchestrator → Researcher → Writer, chained via MCP |
