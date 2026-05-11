# Robustness Checklist

Use when reviewing whether a multi-agent system is hardened enough for production. Derived from the rules in `rules.md`.

## Before You Start

- [ ] You have a working prototype that succeeds on the happy path.
- [ ] You can identify every place the system calls the LLM.
- [ ] You can identify every inter-agent message handoff.

## Resilience (LLM Call Hardening)

- [ ] Every LLM call goes through `call_llm_robust` (or equivalent retrying caller).
- [ ] No naked `call_llm` remains in any agent (Researcher, Writer, Validator, or new ones).
- [ ] Retries are bounded (`retries=3` or similar) and use a delay between attempts.
- [ ] The robust caller returns `None` on exhaustion rather than raising.
- [ ] Every retry attempt and the final exhaustion are logged.

## Reliability (MCP Message Validation)

- [ ] `validate_mcp_message` exists and checks the message is a `dict`.
- [ ] Validation enforces all required keys: `protocol_version`, `sender`, `content`, `metadata`.
- [ ] The Orchestrator calls `validate_mcp_message` immediately after every agent return.
- [ ] Every validation site also checks for empty content (`not message['content']`).
- [ ] Validation failures are logged with the reason.

## Agent Specialization Controls

- [ ] A dedicated Validator agent exists whose sole job is fact-checking.
- [ ] The Validator takes two named inputs (`summary`, `draft`) packaged in `content`.
- [ ] The Validator's system prompt forces a deterministic token: `pass` or `fail` + explanation.
- [ ] The Validator returns a standard MCP message via `create_mcp_message`.
- [ ] No specialist makes orchestration decisions; control flow lives in the Orchestrator.

## Validation Loop Design

- [ ] The loop is bounded by `max_revisions` (no unbounded `while True`).
- [ ] `final_output` is initialized with a safe fallback string.
- [ ] On `pass`: `final_output` is set to the draft and the loop `break`s.
- [ ] On invalid MCP message from Writer or Validator: the loop `break`s.
- [ ] On `fail` with revisions remaining: a "Requesting revision" log is emitted.
- [ ] On `fail` at the last iteration: a "Max revisions reached" log is emitted.
- [ ] On revision (`i > 0`): the Validator's feedback is appended to the Writer's context.
- [ ] The decision check is case-insensitive (`"pass" in result.lower()`).

## Step 1 (Research) Hardening

- [ ] The Researcher's MCP output is validated before entering the writing loop.
- [ ] If validation fails or content is empty, the Orchestrator `return`s with a clear log.
- [ ] The writing loop never starts with bad or missing context.

## Observability

- [ ] Each agent logs its activation (e.g., `[Validator Agent Activated]`).
- [ ] The Orchestrator logs each task, each writing attempt, and each decision outcome.
- [ ] Validation success messages name the sender.

## Red Flags

Stop and address if you find:

- A single naked `call_llm(...)` call anywhere in the agent code.
- Any code path that reads `message['content']` without prior `validate_mcp_message`.
- A loop that can iterate forever (no `max_revisions`, no `break` conditions).
- The Writer's output flowing to the user without passing through the Validator.
- The Validator returning prose instead of a constrained `pass` / `fail` token.
- The Orchestrator silently swallowing `None` returns from `call_llm_robust`.

## Quick Reference

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| LLM caller | `call_llm_robust` everywhere | Robust caller in critical paths | Naked `call_llm` |
| MCP validation | Every handoff + empty check | Every handoff | Skipped on "trusted" agents |
| Validator | Dedicated Agent 3 | LLM self-check inside Writer | No fact-check at all |
| Loop bound | `max_revisions=2` | `max_revisions<=3` | Unbounded loop |
| Revision feedback | Validator's text appended | Generic "try again" message | No feedback fed back |
| Decision logic | Case-insensitive `pass` check | Exact `pass` match | Substring of free-form prose |
| Failure exit | Logged + safe fallback | Logged | Silent crash |
