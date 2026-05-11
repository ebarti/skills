# Harden the Context Engine Workflow

Take a working notebook prototype to production: dependency injection, structured logging, proactive context management, modularization, engine room / control deck split.

## When to Use

- Engine works end-to-end (from `build-context-engine`) but is a single notebook
- Globals everywhere, no logging, hard to test
- Approaching production deployment or team handoff

## Prerequisites

- Working engine from `build-context-engine` workflow
- Familiarity with the 4 hardening pillars

**Reference**: `references/hardening/knowledge.md`, `references/hardening/checklist.md`

---

## Workflow Steps

### Step 1: Apply dependency injection

**Goal**: No globals — all clients passed explicitly.

- [ ] Identify every global (OpenAI client, Pinecone client, namespace, etc.)
- [ ] Refactor functions to accept these as arguments
- [ ] Update agents to take a `dependencies` dict
- [ ] Update Agent Registry to inject deps via lambdas in `get_handler`

**Reference**: `references/hardening/rules.md` (DI rule), `references/hardening/examples.md` (hardened call_llm + get_embedding)

---

### Step 2: Add structured logging

**Goal**: Every step logs JSON-shaped events for debugging.

- [ ] Configure root logger with structured formatter
- [ ] Add log lines at every agent entry/exit
- [ ] Log retries, errors, token counts
- [ ] Log catch-then-raise (don't swallow)

**Reference**: `references/hardening/examples.md` (logging config), `references/hardening/rules.md` (catch-log-raise)

---

### Step 3: Add proactive context management

**Goal**: Count tokens before sending to LLM; alarm or truncate when too large.

- [ ] Add `count_tokens(text, model)` helper
- [ ] Call it before every LLM hop
- [ ] If over threshold → log warning (later: route to Summarizer)

**Reference**: `references/hardening/examples.md` (count_tokens), see also `ai-rag-defense/summarizer-agent` for routing

---

### Step 4: Centralize setup

**Goal**: One function to bootstrap the whole engine.

- [ ] Create `initialize_clients()` that returns `(openai_client, pinecone_index)`
- [ ] Move all bootstrap code from notebook cells into this function
- [ ] Consume in main entry point only

**Reference**: `references/hardening/rules.md` (centralized setup)

---

### Step 5: Split engine room from control deck

**Goal**: Separate "what config + what goal" from "how the engine runs".

- [ ] Create `execute_and_display(goal, config, deps)` — the engine room
- [ ] In the notebook (control deck), only define `goal` and `config` and call the function
- [ ] Notebook becomes a thin user interface

**Reference**: `references/hardening/examples.md` (engine room + control deck pattern)

---

### Step 6: Modularize into commons/

**Goal**: Single notebook → reusable Python modules.

- [ ] Move helpers → `commons/helpers.py`
- [ ] Move agents → `commons/agents.py`
- [ ] Move registry → `commons/registry.py`
- [ ] Move engine → `commons/engine.py`
- [ ] Notebook imports from `commons.*`
- [ ] Verify each module is importable independently

**Reference**: `references/hardening/examples.md` (local imports), `references/engine-reference/examples.md` (commons file map)

---

### Step 7: Verify with checklist

**Goal**: Confirm production-readiness.

- [ ] Run engine end-to-end on the same goal as before — should match output
- [ ] Inspect logs: structured JSON throughout
- [ ] Try removing one global (env var) — engine should fail loudly, not silently
- [ ] Run all items in `hardening/checklist.md`

---

## Quick Checklist

```
[ ] Step 1: DI applied (no globals)
[ ] Step 2: Structured logging
[ ] Step 3: count_tokens + threshold checks
[ ] Step 4: initialize_clients()
[ ] Step 5: Engine room / control deck split
[ ] Step 6: Modularized into commons/
[ ] Step 7: Checklist passes
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Refactor agents but keep globals in helpers | DI is half-done | All-or-nothing per layer |
| Plain string logging | Hard to search/filter in prod | Structured JSON |
| Catching exceptions silently | Hides errors | catch-log-raise |
| Notebook still has business logic | Can't run from CLI | Engine room is a function |
| `from commons import *` | Unclear import graph | Explicit `from commons.X import Y` |

---

## Exit Criteria

- [ ] No globals (all deps explicit)
- [ ] Structured logs from every layer
- [ ] Token counts logged before LLM hops
- [ ] `commons/` modules import cleanly
- [ ] Notebook is just config + one function call
- [ ] All items in `hardening/checklist.md` pass
