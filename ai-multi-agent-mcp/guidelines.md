# AI Multi-Agent MCP Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use:** Find your situation below, then load ONLY the listed files. For multi-step tasks, use a workflow.

---

## Workflows

| Task | Workflow |
|------|----------|
| Build a multi-agent system from scratch | `workflows/build-mas.md` |
| Harden a working MAS with validation loops + Validator | `workflows/harden-mas.md` |

---

## By Task

### Designing Inter-Agent Communication

| What you're doing | Load these files |
|-------------------|------------------|
| Defining MCP message schema | `mcp-protocol/knowledge.md`, `mcp-protocol/rules.md` |
| Choosing transport (STDIO vs HTTP) | `mcp-protocol/knowledge.md` |
| Wiring up the OpenAI client + env vars | `mcp-protocol/examples.md` |

### Building Specialist Agents

| What you're doing | Load these files |
|-------------------|------------------|
| Designing a new specialist agent | `agent-design/knowledge.md`, `agent-design/rules.md`, `agent-design/patterns.md` |
| Writing the agent's system prompt | `agent-design/rules.md`, `agent-design/examples.md` |
| Adding a shared helper function | `agent-design/examples.md`, `agent-design/patterns.md` |
| Choosing: new agent vs extend existing | `agent-design/rules.md` |

### Building / Hardening the Orchestrator

| What you're doing | Load these files |
|-------------------|------------------|
| Initial orchestrator design | `orchestration/knowledge.md`, `orchestration/examples.md` |
| Adding goal decomposition | `orchestration/knowledge.md`, `orchestration/rules.md` |
| Adding a validation loop | `robustness/knowledge.md`, `robustness/examples.md` |
| Adding a Validator agent | `robustness/rules.md`, `robustness/examples.md` |

### Hardening for Production

| What you're doing | Load these files |
|-------------------|------------------|
| Building robust LLM call wrapper | `robustness/rules.md`, `robustness/examples.md` |
| Validating MCP message structure | `robustness/knowledge.md`, `robustness/examples.md` |
| Final pre-prod review | `robustness/checklist.md` |

---

## By Code Element

| Working with... | Primary | Secondary |
|-----------------|---------|-----------|
| MCP message dict | `mcp-protocol/examples.md` | `mcp-protocol/rules.md` |
| Specialist agent function | `agent-design/examples.md` | `agent-design/patterns.md` |
| Orchestrator function | `orchestration/examples.md` | `robustness/examples.md` (final loop) |
| Validator agent | `robustness/examples.md` | `robustness/rules.md` |

---

## By Problem / Symptom

| If you notice... | Load these files |
|------------------|------------------|
| Agent silently produces wrong output | `robustness/rules.md` (add validation), `robustness/examples.md` (Validator) |
| MCP messages have inconsistent fields | `mcp-protocol/rules.md`, `robustness/rules.md` (validate_mcp_message) |
| One agent doing too many jobs | `agent-design/rules.md` (one-job specialization) |
| Orchestrator code touching domain logic | `orchestration/rules.md` (no domain work in orchestrator) |
| Validation loop never terminates | `robustness/rules.md` (bounded loop with explicit exits) |

---

## File Index

### mcp-protocol
| File | Purpose |
|------|---------|
| `knowledge.md` | MCP definition, formats, transports, MAS workflow |
| `rules.md` | 10 rules covering schema, transport, security, env-init |
| `examples.md` | Verbatim Python: client init, create_mcp_message, JSON sample |

### agent-design
| File | Purpose |
|------|---------|
| `knowledge.md` | Specialist agent, system-prompt-as-identity, helper function |
| `rules.md` | 7 rules + new-vs-extend decision table |
| `examples.md` | Verbatim Python: call_llm, researcher, writer + full prompts |
| `patterns.md` | Specialist Agent + Helper Function patterns |

### orchestration
| File | Purpose |
|------|---------|
| `knowledge.md` | Orchestrator role, hub-and-spoke, goal decomposition |
| `rules.md` | 6 rules + state-ownership matrix |
| `examples.md` | Full Orchestrator function + sample console output |

### robustness
| File | Purpose |
|------|---------|
| `knowledge.md` | Resilience vs reliability, Validator, validation-loop pattern |
| `rules.md` | 7 rules covering retries, validation, Validator, bounded loops |
| `examples.md` | Verbatim Python: call_llm_robust, validate_mcp_message, Validator, final orchestrator |
| `checklist.md` | Pre-prod resilience/reliability gates |

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| Start a new MAS project | `mcp-protocol/knowledge.md` + `agent-design/knowledge.md` + `orchestration/knowledge.md` |
| Build first Researcher+Writer pair | `agent-design/examples.md` + `orchestration/examples.md` |
| Make the system production-ready | `robustness/knowledge.md` + `robustness/examples.md` + `robustness/checklist.md` |
| Add a new specialist agent | `agent-design/patterns.md` + `agent-design/examples.md` |
