# AI Production Architecture Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use**: Find your situation below, then load ONLY the listed files.

---

## By Task

### Designing System Architecture

| What you're doing | Load these files |
|-------------------|------------------|
| Designing a new AI system architecture | `references/architecture-patterns/rules.md`, `references/architecture-patterns/patterns.md` |
| Adding context enhancement (RAG, tools) | `references/architecture-patterns/rules.md`, `references/architecture-patterns/examples.md` |
| Adding input guardrails | `references/architecture-patterns/rules.md`, `references/architecture-patterns/examples.md` |
| Adding output guardrails | `references/architecture-patterns/rules.md`, `references/architecture-patterns/examples.md` |
| Setting up a model router | `references/architecture-patterns/rules.md`, `references/architecture-patterns/examples.md` |
| Setting up a model gateway | `references/architecture-patterns/rules.md`, `references/architecture-patterns/examples.md` |
| Implementing exact caching | `references/architecture-patterns/rules.md`, `references/architecture-patterns/examples.md` |
| Implementing semantic caching | `references/architecture-patterns/rules.md`, `references/architecture-patterns/examples.md` |
| Adding agent patterns | `references/architecture-patterns/patterns.md` |

### Setting Up Observability

| What you're doing | Load these files |
|-------------------|------------------|
| Designing metrics for an AI system | `references/monitoring-observability/rules.md`, `references/monitoring-observability/examples.md` |
| Setting up logging and tracing | `references/monitoring-observability/rules.md`, `references/monitoring-observability/examples.md` |
| Detecting drift (prompt/user/model) | `references/monitoring-observability/rules.md`, `references/monitoring-observability/examples.md` |
| Pre-launch observability check | `references/monitoring-observability/checklist.md` |
| Pipeline orchestration | `references/monitoring-observability/rules.md` |

### Building Feedback Systems

| What you're doing | Load these files |
|-------------------|------------------|
| Designing a user feedback collection system | `references/user-feedback/rules.md`, `references/user-feedback/examples.md` |
| Extracting feedback from conversations | `references/user-feedback/rules.md`, `references/user-feedback/examples.md` |
| Choosing UI patterns for feedback | `references/user-feedback/rules.md`, `references/user-feedback/examples.md` |
| Avoiding biased feedback | `references/user-feedback/rules.md`, `references/user-feedback/smells.md` |
| Preventing degenerate feedback loops | `references/user-feedback/rules.md`, `references/user-feedback/smells.md` |

---

## By Symptom/Problem

| If you notice... | Load these files |
|------------------|------------------|
| Users get unsafe/PII-leaking outputs | `references/architecture-patterns/rules.md` (output guardrails) |
| Cost explosion from repeated similar queries | `references/architecture-patterns/rules.md` (caching) |
| Hard to swap LLM providers | `references/architecture-patterns/rules.md` (gateway) |
| Same model over-used for everything | `references/architecture-patterns/rules.md` (router) |
| No visibility into what users sent | `references/monitoring-observability/rules.md` (logging) |
| Quality degraded after model version change | `references/monitoring-observability/rules.md` (drift detection), `references/monitoring-observability/examples.md` |
| Quality degraded after prompt change | `references/monitoring-observability/rules.md` (prompt-hash drift) |
| Feedback skewed toward angry users | `references/user-feedback/rules.md` (bias guarding), `references/user-feedback/smells.md` |
| Filter bubbles / sycophancy in outputs | `references/user-feedback/smells.md` (degenerate loops) |
| Can't reproduce production failures | `references/monitoring-observability/rules.md` (logs/traces) |

---

## By Topic (Direct Index)

### Architecture Patterns
- `references/architecture-patterns/knowledge.md` — 5-step architecture (context, guardrails, router/gateway, caches, agents)
- `references/architecture-patterns/rules.md` — 10 design rules
- `references/architecture-patterns/examples.md` — Python implementations of every step
- `references/architecture-patterns/patterns.md` — 8 reusable patterns

### Monitoring & Observability
- `references/monitoring-observability/knowledge.md` — Metrics, logs, traces, drift
- `references/monitoring-observability/rules.md` — 10 rules
- `references/monitoring-observability/examples.md` — Bad/good code, drift detection
- `references/monitoring-observability/checklist.md` — Production observability checklist

### User Feedback
- `references/user-feedback/knowledge.md` — Explicit/implicit, conversational signals, biases
- `references/user-feedback/rules.md` — 10 rules
- `references/user-feedback/examples.md` — Detection/UI/bias mitigation code
- `references/user-feedback/smells.md` — 10 anti-patterns

---

## Decision Tree

```
What stage are you at?
│
├─► Designing the system
│   ├─► Start simple → architecture-patterns/rules.md
│   ├─► Add complexity → architecture-patterns/patterns.md
│   └─► See examples → architecture-patterns/examples.md
│
├─► Operating the system
│   ├─► Setting up observability → monitoring-observability/rules.md + checklist.md
│   ├─► Diagnosing drift → monitoring-observability/examples.md
│   └─► User feedback collection → user-feedback/rules.md
│
└─► Auditing for problems
    ├─► Architecture audit → architecture-patterns/rules.md
    ├─► Observability audit → monitoring-observability/checklist.md
    └─► Feedback audit → user-feedback/smells.md
```

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| Building first production AI architecture | `architecture-patterns/rules.md` + `architecture-patterns/patterns.md` + `monitoring-observability/checklist.md` |
| Multi-tenant LLM service | `architecture-patterns/rules.md` (router/gateway) + `architecture-patterns/examples.md` |
| Customer-facing chatbot | `architecture-patterns/rules.md` (guardrails) + `monitoring-observability/rules.md` + `user-feedback/rules.md` |
| Pre-launch readiness check | `architecture-patterns/rules.md` + `monitoring-observability/checklist.md` |
| Improving model with user signals | `user-feedback/rules.md` + `user-feedback/examples.md` + `user-feedback/smells.md` |
