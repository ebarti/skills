---
name: ai-context-engine-production
description: |
  Production deployment of the Context Engine: moderation gatekeepers (two-stage protocol), policy-driven meta-control (the 5 principles), reusable control-deck templates, domain adaptation (legal + marketing case studies), API + worker + Docker + observability deployment topology, and business-value framing for stakeholders.

  Use this skill when:
  - Adding moderation gatekeepers (input + output)
  - Encoding compliance policy outside the model
  - Building applications on top of the engine via control decks
  - Adapting the engine to a new vertical (legal, medical, marketing, etc.)
  - Deploying to production (FastAPI + worker + Docker + observability)
  - Presenting ROI / business value to non-technical stakeholders
---

# AI Context Engine Production

Knowledge from "Context Engineering for Multi-Agent Systems" (Chapters 8-10). The safeguards, applications, and deployment topology that take the engine to production.

## Quick Start

1. Check `guidelines.md` to find which files to load
2. Load only relevant files (each topic has knowledge.md, rules.md, examples.md)
3. Apply guidance to your work

## Contents

### References

| Category | Purpose |
|----------|---------|
| `moderation` | Two-stage moderation protocol, gatekeeper integration, fail-safe |
| `policy-driven-control` | The 5 principles, policy as outermost context layer |
| `control-decks` | Reusable templates: high-fidelity RAG / context reduction / grounded reasoning |
| `domain-applications` | Legal compliance + strategic marketing case studies |
| `production-deployment` | FastAPI orchestration, async workers, Docker, observability |
| `business-value` | 5 enterprise capabilities, ROI framing, stakeholder messaging |

### Workflows

| Workflow | Purpose |
|----------|---------|
| `workflows/add-moderation.md` | Wire two-stage moderation gatekeeper into the engine |
| `workflows/adapt-to-domain.md` | Adapt the engine to a new vertical (legal, medical, marketing, etc.) |
| `workflows/deploy-to-production.md` | Full go-live (env → API → workers → Docker → observability) |

## Guidelines

See `guidelines.md` for task-based file selection.
