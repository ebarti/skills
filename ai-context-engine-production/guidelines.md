# AI Context Engine Production Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use:** Find your situation below, then load ONLY the listed files. For multi-step tasks, use a workflow.

---

## Workflows

| Task | Workflow |
|------|----------|
| Wire the two-stage moderation gatekeeper | `workflows/add-moderation.md` |
| Adapt the engine to a new vertical | `workflows/adapt-to-domain.md` |
| Full production deployment (env → API → workers → Docker) | `workflows/deploy-to-production.md` |

---

## By Task

### Adding Safety / Compliance Layers

| What you're doing | Load these files |
|-------------------|------------------|
| Adding a moderation gatekeeper | `moderation/knowledge.md`, `moderation/examples.md` |
| Designing the two-stage protocol | `moderation/knowledge.md`, `moderation/rules.md` |
| Encoding compliance policy | `policy-driven-control/knowledge.md`, `policy-driven-control/rules.md` |
| Pre-release moderation audit | `moderation/checklist.md` |

### Architectural Decisions

| What you're doing | Load these files |
|-------------------|------------------|
| Justifying policy as outermost context | `policy-driven-control/knowledge.md`, `policy-driven-control/patterns.md` |
| Choosing between control-deck templates | `control-decks/knowledge.md`, `control-decks/patterns.md` |
| Composing multiple templates | `control-decks/rules.md`, `control-decks/patterns.md` |

### Building / Adapting Applications

| What you're doing | Load these files |
|-------------------|------------------|
| Writing a control deck for a new use case | `control-decks/examples.md`, `control-decks/rules.md` |
| Adapting the engine to a new vertical | `domain-applications/knowledge.md`, `domain-applications/patterns.md` |
| Building a legal compliance assistant | `domain-applications/examples.md` (Legal section) |
| Building a marketing engine | `domain-applications/examples.md` (Marketing section) |
| Defining domain-specific limit tests | `domain-applications/rules.md`, `domain-applications/examples.md` |

### Production Deployment

| What you're doing | Load these files |
|-------------------|------------------|
| Setting up env config + secrets | `production-deployment/examples.md`, `production-deployment/rules.md` |
| Building the FastAPI orchestration layer | `production-deployment/examples.md`, `production-deployment/rules.md` |
| Adding async / task queues | `production-deployment/knowledge.md`, `production-deployment/examples.md` |
| Adding observability (logs / metrics / traces) | `production-deployment/rules.md`, `production-deployment/examples.md` |
| Writing the Dockerfile | `production-deployment/examples.md` |
| Pre-go-live audit | `production-deployment/checklist.md` |

### Stakeholder Communication

| What you're doing | Load these files |
|-------------------|------------------|
| Pitching the engine to executives | `business-value/knowledge.md`, `business-value/examples.md` |
| Justifying investment | `business-value/rules.md`, `business-value/examples.md` |
| Mapping capabilities to outcomes | `business-value/examples.md` |

---

## By Code Element

| Working with... | Primary | Secondary |
|-----------------|---------|-----------|
| helper_moderate_content | `moderation/examples.md` | `moderation/rules.md` |
| Engine room execute_and_display fn | `moderation/examples.md` | `ai-context-engine/hardening/examples.md` |
| Control deck (config + goal + execute) | `control-decks/examples.md` | `control-decks/patterns.md` |
| FastAPI endpoint | `production-deployment/examples.md` | `production-deployment/rules.md` |
| Dockerfile / Uvicorn / Celery | `production-deployment/examples.md` | `production-deployment/checklist.md` |
| Domain knowledge base | `domain-applications/examples.md` | `domain-applications/rules.md` |

---

## By Problem / Symptom

| If you notice... | Load these files |
|------------------|------------------|
| Engine processes unsafe input | `moderation/examples.md` (gatekeeper integration), `moderation/rules.md` |
| Edge cases cause unexpected agent behavior | `policy-driven-control/knowledge.md` (Principle 2), `policy-driven-control/patterns.md` |
| Same code reused across domains diverges | `domain-applications/patterns.md` (adaptation pattern) |
| Secrets hardcoded in source | `production-deployment/rules.md`, `production-deployment/checklist.md` |
| API blocks while engine runs (slow) | `production-deployment/knowledge.md` (async + queue) |
| Stakeholders don't understand value | `business-value/examples.md` |

---

## File Index

### moderation
| File | Purpose |
|------|---------|
| `knowledge.md` | Enterprise architecture, deliberate-pace, two-stage protocol |
| `rules.md` | 7 rules: encapsulate, two-stage, fail-safe, halt-vs-redact |
| `examples.md` | Verbatim helper_moderate_content + integration + control deck |
| `checklist.md` | Moderation-completeness audit |

### policy-driven-control
| File | Purpose |
|------|---------|
| `knowledge.md` | Meta-controller, all 5 principles verbatim |
| `rules.md` | 7 rules: external policy, override, escalation, role separation |
| `examples.md` | Principle quotes, mixed-profanity case, meta-controller pseudocode |
| `patterns.md` | Policy-as-Outermost-Context, Control Deck as Engine's API |

### control-decks
| File | Purpose |
|------|---------|
| `knowledge.md` | Control deck definition, 3 templates, domain applicability |
| `rules.md` | Template selection, parametrization, composition |
| `examples.md` | All 3 templates verbatim + execute_and_display |
| `patterns.md` | Each template formalized + selection guide |

### domain-applications
| File | Purpose |
|------|---------|
| `knowledge.md` | Domain independence, what stays/changes, KB curation |
| `rules.md` | 8 rules covering pipeline reuse, deck selection, namespaces |
| `examples.md` | Legal + Marketing case studies (verbatim Python) |
| `patterns.md` | Domain Adaptation, Organizational Fix Over Code Patch |

### production-deployment
| File | Purpose |
|------|---------|
| `knowledge.md` | 12-Factor config, FastAPI orch, async, observability, K8s |
| `rules.md` | 10 rules covering secrets, FastAPI, queues, logs, Docker |
| `examples.md` | Verbatim env config, FastAPI, JSON logger, Dockerfile |
| `checklist.md` | Go-live gates + smoke tests |

### business-value
| File | Purpose |
|------|---------|
| `knowledge.md` | 5 enterprise capabilities, 3 value lenses |
| `rules.md` | 8 rules for stakeholder presentations + audience pitch table |
| `examples.md` | Capability→outcome mapping, verbatim metrics, blueprints |

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| First go-live | `moderation/checklist.md` + `production-deployment/checklist.md` + `policy-driven-control/knowledge.md` |
| Adapt engine to a new vertical | `domain-applications/patterns.md` + `domain-applications/examples.md` + `control-decks/examples.md` |
| Add safety guardrails | `moderation/examples.md` + `moderation/rules.md` + `ai-rag-defense/input-sanitization/examples.md` |
| Build investor / exec deck | `business-value/examples.md` + `business-value/rules.md` |
| Write a new control deck for a use case | `control-decks/examples.md` + `control-decks/patterns.md` + `control-decks/rules.md` |
