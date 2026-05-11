---
name: ai-rag-defense
description: |
  Token reduction, retrieval fidelity, and prompt-injection defense layers for the Context Engine. Covers a Summarizer agent for proactive context reduction, micro-context engineering (prompt design inside agents), high-fidelity RAG with source-metadata citations, input sanitization against prompt injection, and grounded-reasoning validation that prevents hallucination.

  Use this skill when:
  - Reducing token costs by adding a Summarizer agent
  - Designing system prompts inside specialist agents (micro-context)
  - Adding citations and source metadata to RAG outputs
  - Defending agents against prompt injection / data poisoning
  - Validating agent reliability across high-fidelity / summarization / grounded test cases
  - Preventing hallucination when retrieval returns no result
---

# AI RAG Defense

Knowledge from "Context Engineering for Multi-Agent Systems" (Chapters 6-7). The reduction, fidelity, and defense layers that turn a working engine into a trustworthy one.

## Quick Start

1. Check `guidelines.md` to find which files to load
2. Load only relevant files (each topic has knowledge.md, rules.md, examples.md)
3. Apply guidance to your work

## Contents

### References

| Category | Purpose |
|----------|---------|
| `summarizer-agent` | Cost-management agent for proactive context reduction |
| `micro-context-engineering` | Prompt design inside agents (macro vs micro) |
| `high-fidelity-rag` | Source-metadata-on-chunks pattern, citations-mandatory Researcher |
| `input-sanitization` | helper_sanitize_input, prompt-injection threat model + smells |
| `grounded-reasoning` | Report-negative-finding pattern, multi-case validation |

### Workflows

| Workflow | Purpose |
|----------|---------|
| `workflows/add-summarizer.md` | Integrate Summarizer agent for proactive context reduction |
| `workflows/add-citations.md` | Upgrade RAG to high-fidelity (source metadata + cite) |
| `workflows/defend-against-injection.md` | Sanitize input + run grounded-reasoning validation suite |

## Guidelines

See `guidelines.md` for task-based file selection.
