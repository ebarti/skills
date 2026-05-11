# Build a Multi-Agent System Workflow

Build an MCP-based multi-agent system from scratch: protocol → agents → orchestrator → first run.

## When to Use

- Starting a new multi-agent project
- Replacing a single-agent monolith with specialist agents
- Need multiple LLM "roles" (researcher / writer / critic / etc.) to collaborate

## Prerequisites

- OpenAI (or compatible) API key in env
- Decided what specialist roles you need
- Defined the high-level goal you want the MAS to achieve

**Reference**: `references/mcp-protocol/knowledge.md`, `references/agent-design/knowledge.md`

---

## Workflow Steps

### Step 1: Define the MCP message schema

**Goal**: Lock the inter-agent message format before writing any agent.

- [ ] Decide the required fields (sender, recipient, message_type, payload, etc.)
- [ ] Pick a transport (STDIO for local, HTTP for distributed)
- [ ] Write `create_mcp_message` helper

**Reference**: `references/mcp-protocol/examples.md`, `references/mcp-protocol/rules.md`

---

### Step 2: Initialize the LLM client

**Goal**: Set up a single, env-driven OpenAI client.

- [ ] Load `OPENAI_API_KEY` from env (never hardcode)
- [ ] Initialize the OpenAI client once
- [ ] Verify connectivity with a small probe call

**Reference**: `references/mcp-protocol/examples.md` (client init)

---

### Step 3: Build the shared helper function

**Goal**: One canonical LLM call wrapper used by all agents.

- [ ] Implement `call_llm(system_prompt, user_message)` returning text
- [ ] Centralize logging here (not in each agent)
- [ ] Defer retries/validation — those come in `harden-mas`

**Reference**: `references/agent-design/examples.md`

---

### Step 4: Build specialist agents

**Goal**: One function per role, system prompt = identity.

For each specialist (e.g. Researcher, Writer):
- [ ] Write a focused system prompt (role + task + output)
- [ ] Wrap as a function that takes an MCP message and returns an MCP message
- [ ] Use `call_llm` for the LLM hop
- [ ] Confirm: function does ONE job

**Reference**: `references/agent-design/rules.md`, `references/agent-design/examples.md`, `references/agent-design/patterns.md`

---

### Step 5: Build the Orchestrator

**Goal**: Hub-and-spoke coordinator with no domain logic.

- [ ] Take a high-level goal as input
- [ ] Decompose into agent-sized sub-goals (sequential at first)
- [ ] Route via MCP to each specialist in turn
- [ ] Pass each agent's output as next agent's input
- [ ] No domain logic in orchestrator

**Reference**: `references/orchestration/knowledge.md`, `references/orchestration/examples.md`, `references/orchestration/rules.md`

---

### Step 6: Run the system end-to-end

**Goal**: Verify the full MAS produces a coherent result.

- [ ] Pick a representative high-level goal
- [ ] Call the Orchestrator
- [ ] Watch the console output: each MCP hop visible
- [ ] Verify each agent's output is well-formed
- [ ] Verify final output answers the goal

---

## Quick Checklist

```
[ ] Step 1: MCP schema + helper
[ ] Step 2: OpenAI client init
[ ] Step 3: call_llm helper
[ ] Step 4: Specialist agents (one per role)
[ ] Step 5: Orchestrator
[ ] Step 6: End-to-end run
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Agent does 2+ jobs | Hard to debug, drift | One specialist per role |
| Orchestrator inspects payload contents | Couples orchestrator to domain | Route MCP envelopes only |
| Each agent re-implements LLM call | Inconsistent retries / logging | Shared `call_llm` helper |
| Hardcoded API key | Security risk | Env var only |
| Skipping MCP envelope between agents | Loses provenance | Always wrap in MCP |

---

## Exit Criteria

- [ ] System runs end-to-end on a real goal
- [ ] Each agent visible in console / logs
- [ ] No domain logic in Orchestrator
- [ ] No globals between agents (everything via MCP)
- [ ] Ready for `harden-mas` workflow next
