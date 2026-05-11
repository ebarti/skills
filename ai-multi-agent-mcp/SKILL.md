---
name: ai-multi-agent-mcp
description: |
  Building multi-agent systems with the Model Context Protocol (MCP). Covers MCP message format and transport, specialist agent design (Researcher / Writer + shared helpers), Orchestrator design with goal decomposition, and robustness via validation loops + a Validator agent.

  Use this skill when:
  - Designing inter-agent communication (MCP message schema, transport choice)
  - Building specialist agents (one role per agent, system prompt as identity)
  - Implementing an Orchestrator that routes between agents
  - Adding validation loops, retries, or a Validator agent
  - Hardening a multi-agent prototype against LLM/network/data failures
---

# AI Multi-Agent MCP

Knowledge from "Context Engineering for Multi-Agent Systems" (Chapter 2). MCP-based multi-agent architecture, from naive prototype to validation-hardened system.

## Quick Start

1. Check `guidelines.md` to find which files to load
2. Load only relevant files (each topic has knowledge.md, rules.md, examples.md)
3. Apply guidance to your work

## Contents

### References

| Category | Purpose |
|----------|---------|
| `mcp-protocol` | MCP message format, transports, OpenAI client init, MAS workflow |
| `agent-design` | Specialist agent template (Researcher, Writer), helper function pattern |
| `orchestration` | Orchestrator role, hub-and-spoke routing, goal decomposition |
| `robustness` | Robust LLM components, MCP validation, Validator agent, validation loop |

### Workflows

| Workflow | Purpose |
|----------|---------|
| `workflows/build-mas.md` | Build a multi-agent system from scratch (MCP → agents → orchestrator → first run) |
| `workflows/harden-mas.md` | Add validation loops, robust LLM components, Validator agent |

## Guidelines

See `guidelines.md` for task-based file selection.
