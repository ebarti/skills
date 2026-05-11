# Harden a Multi-Agent System Workflow

Add validation loops, robust LLM components, and a Validator agent to a working MAS prototype.

## When to Use

- The basic MAS (from `build-mas`) works on happy paths but breaks under noise
- Agents occasionally produce malformed or incorrect output
- Production deployment is approaching

## Prerequisites

- Working MAS from `build-mas` workflow
- Understanding of validation-loop pattern

**Reference**: `references/robustness/knowledge.md`

---

## Workflow Steps

### Step 1: Wrap the LLM call with retry + structural validation

**Goal**: Replace `call_llm` with `call_llm_robust` to handle transient failures.

- [ ] Add bounded retries with exponential backoff
- [ ] Validate non-empty response
- [ ] Log every failure
- [ ] Swap-out: every agent now uses `call_llm_robust`

**Reference**: `references/robustness/examples.md`, `references/robustness/rules.md`

---

### Step 2: Validate every MCP message

**Goal**: Catch malformed messages at the protocol boundary.

- [ ] Implement `validate_mcp_message(msg)` checking required fields
- [ ] Call it at every Orchestrator hop (before & after agent calls)
- [ ] Raise (don't return None) on validation failure

**Reference**: `references/robustness/examples.md` (validate_mcp_message), `references/mcp-protocol/rules.md`

---

### Step 3: Add a Validator agent

**Goal**: A 3rd agent whose only job is to critique the Writer's output.

- [ ] Define the Validator's role (constraints to check)
- [ ] System prompt: "Return APPROVED or list issues"
- [ ] Wrap as a specialist agent

**Reference**: `references/robustness/examples.md` (Validator agent), `references/agent-design/rules.md`

---

### Step 4: Wrap Writer + Validator in a validation loop

**Goal**: Iteratively improve output until approved or max-retries hit.

- [ ] In the Orchestrator, after Writer returns, invoke Validator
- [ ] If APPROVED → done
- [ ] If issues → feed issues back to Writer with a "revise" prompt
- [ ] Cap at N iterations (typically 3) — never unbounded
- [ ] Log every iteration

**Reference**: `references/robustness/examples.md` (final orchestrator with validation loop), `references/robustness/rules.md`

---

### Step 5: Add agent specialization controls

**Goal**: Prevent one agent from doing another's job.

- [ ] In each agent, add input checks (right MCP message_type? right fields?)
- [ ] Reject (don't process) messages outside the agent's specialty
- [ ] Log specialization rejects

**Reference**: `references/robustness/rules.md`

---

### Step 6: Run the hardened system

**Goal**: Verify the loop converges and degrades gracefully.

- [ ] Run on the same goal as `build-mas` step 6 — should produce same/better output
- [ ] Inject a deliberately bad input — should fail validation cleanly
- [ ] Inject a transient error — should retry & recover
- [ ] Run validation-loop checklist

**Reference**: `references/robustness/checklist.md`

---

## Quick Checklist

```
[ ] Step 1: call_llm_robust (retry + structural validation)
[ ] Step 2: validate_mcp_message at every hop
[ ] Step 3: Validator agent
[ ] Step 4: Validation loop (Writer ↔ Validator, bounded)
[ ] Step 5: Specialization controls
[ ] Step 6: End-to-end resilience test
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Unbounded validation loop | Infinite retry, runaway costs | Cap at N iterations |
| Validator wrapped in Writer | Conflict of interest, no separation | Separate agent |
| Silent retries | Hides flaky behavior | Log every retry |
| Returning None on validation fail | Caller loses info on what failed | Raise with details |
| Skipping specialization checks | Agents drift into each other's roles | Check message_type at entry |

---

## Exit Criteria

- [ ] All agents use `call_llm_robust`
- [ ] All MCP messages validated at orchestrator hops
- [ ] Validator agent in place + wired into loop
- [ ] Loop bounded (max iterations defined)
- [ ] Specialization controls reject off-role messages
- [ ] All items in `robustness/checklist.md` pass
