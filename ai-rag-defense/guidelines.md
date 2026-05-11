# AI RAG Defense Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use:** Find your situation below, then load ONLY the listed files. For multi-step tasks, use a workflow.

---

## Workflows

| Task | Workflow |
|------|----------|
| Add a Summarizer agent for token reduction | `workflows/add-summarizer.md` |
| Add citations / upgrade RAG to high-fidelity | `workflows/add-citations.md` |
| Defend the engine against prompt injection | `workflows/defend-against-injection.md` |

---

## By Task

### Reducing Token Costs

| What you're doing | Load these files |
|-------------------|------------------|
| Adding a Summarizer agent | `summarizer-agent/knowledge.md`, `summarizer-agent/examples.md` |
| Measuring before/after token count | `summarizer-agent/examples.md` (post-execution analysis) |
| Wiring Summarizer into the registry | `summarizer-agent/examples.md`, `summarizer-agent/rules.md` |

### Designing Agent Internal Prompts

| What you're doing | Load these files |
|-------------------|------------------|
| Writing or refining a Summarizer / Writer prompt | `micro-context-engineering/rules.md`, `micro-context-engineering/examples.md` |
| Reinforcing an agent's instructions | `micro-context-engineering/examples.md` (Writer before/after) |
| Distinguishing macro vs micro context | `micro-context-engineering/knowledge.md` |

### High-Fidelity RAG / Citations

| What you're doing | Load these files |
|-------------------|------------------|
| Adding source metadata to chunks | `high-fidelity-rag/knowledge.md`, `high-fidelity-rag/examples.md` |
| Building the citations-mandatory Researcher | `high-fidelity-rag/examples-researcher.md`, `high-fidelity-rag/rules.md` |
| Verifying chunk metadata after ingestion | `high-fidelity-rag/examples.md` (verification probe) |
| Designing for legal / medical / scientific use | `high-fidelity-rag/patterns.md`, `high-fidelity-rag/rules.md` |

### Defending Against Prompt Injection

| What you're doing | Load these files |
|-------------------|------------------|
| Adding helper_sanitize_input | `input-sanitization/examples.md`, `input-sanitization/rules.md` |
| Threat modeling for retrieval-driven agents | `input-sanitization/knowledge.md`, `input-sanitization/smells.md` |
| Identifying injection patterns in retrieved text | `input-sanitization/smells.md` (PI1-PI5) |

### Validating Agent Reliability

| What you're doing | Load these files |
|-------------------|------------------|
| Preventing hallucination on out-of-scope | `grounded-reasoning/knowledge.md`, `grounded-reasoning/rules.md` |
| Running multi-case validation | `grounded-reasoning/examples.md` (Ch5/6/7 cases) |
| Pre-release reliability check | `grounded-reasoning/checklist.md` |

---

## By Code Element

| Working with... | Primary | Secondary |
|-----------------|---------|-----------|
| count_tokens helper | `summarizer-agent/examples.md` | `ai-context-engine/hardening/examples.md` |
| Summarizer agent function | `summarizer-agent/examples.md` | `summarizer-agent/rules.md` |
| Researcher with citations | `high-fidelity-rag/examples-researcher.md` | `high-fidelity-rag/rules.md` |
| Chunk metadata schema | `high-fidelity-rag/examples.md` | `high-fidelity-rag/patterns.md` |
| helper_sanitize_input | `input-sanitization/examples.md` | `input-sanitization/rules.md` |
| Test cases / regression tests | `grounded-reasoning/examples.md` | `grounded-reasoning/checklist.md` |

---

## By Problem / Symptom

| If you notice... | Load these files |
|------------------|------------------|
| Token costs spiking | `summarizer-agent/knowledge.md` (add Summarizer) |
| Agents make up information | `grounded-reasoning/rules.md` (report negative findings) |
| Researcher returns unverifiable claims | `high-fidelity-rag/rules.md` (require citations) |
| User input contains "ignore previous instructions" | `input-sanitization/smells.md` (PI1) |
| Adding a capability breaks existing tests | `grounded-reasoning/rules.md` (multi-case validation) |
| Summarizer output is generic / loses key info | `micro-context-engineering/rules.md`, `micro-context-engineering/examples.md` |

---

## File Index

### summarizer-agent
| File | Purpose |
|------|---------|
| `knowledge.md` | Glass-box, Summarizer's gatekeeper role, post-exec analysis |
| `rules.md` | Invocation triggers, registry update locations, measurement |
| `examples.md` | Verbatim Python: count_tokens, agent_summarizer, registry, analysis |
| `patterns.md` | Summarizer-as-Context-Reducer, Post-Execution Measurement |

### micro-context-engineering
| File | Purpose |
|------|---------|
| `knowledge.md` | Macro vs micro distinction, agent-as-mini-context-engine |
| `rules.md` | 7 rules: role/task/constraints/output, reinforcement triggers |
| `examples.md` | Summarizer prompts (poor vs strong), Writer before/after |

### high-fidelity-rag
| File | Purpose |
|------|---------|
| `knowledge.md` | Architecture, source-metadata pattern, NASA app |
| `rules.md` | 6 rules: doc structure, chunk metadata, citation requirements |
| `examples.md` | Source doc prep, metadata-aware ingestion, verification |
| `examples-researcher.md` | Upgraded Researcher code, NASA control deck, sample trace |
| `patterns.md` | Source-Metadata-on-Chunks, Citations-Mandatory Agent |

### input-sanitization
| File | Purpose |
|------|---------|
| `knowledge.md` | Threat model, two-stage RAG attack, pipeline placement |
| `rules.md` | Sanitize-before-LLM, fail-closed, log events, escalation |
| `examples.md` | Verbatim helper_sanitize_input + usage patterns |
| `smells.md` | PI1-PI5 injection patterns |

### grounded-reasoning
| File | Purpose |
|------|---------|
| `knowledge.md` | Inventory tiers, how engine thinks, ExecutionTrace |
| `rules.md` | Report negative findings, multi-case validation, tracing |
| `examples.md` | Ch7 high-fidelity, Ch6 backward-compat, Ch5 grounded test cases |
| `checklist.md` | "Is my system grounded?" + red flags |

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| First time adding RAG defenses | `input-sanitization/examples.md` + `high-fidelity-rag/examples.md` + `grounded-reasoning/rules.md` |
| Cost-optimization sprint | `summarizer-agent/knowledge.md` + `summarizer-agent/examples.md` + `micro-context-engineering/rules.md` |
| Building a citation-aware research assistant | `high-fidelity-rag/examples.md` + `high-fidelity-rag/examples-researcher.md` + `high-fidelity-rag/patterns.md` |
| Pre-release reliability sweep | `grounded-reasoning/checklist.md` + `grounded-reasoning/examples.md` + `input-sanitization/smells.md` |
