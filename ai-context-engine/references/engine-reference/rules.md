# Context Engine Reference Rules

Rules governing module responsibilities, pipeline ordering, execution conventions, and safeguards activation in the Context Engine.

## Core Rules

### 1. One Responsibility Per Commons File

Each module in `commons` has one and only one responsibility.

| File | Owns | Must NOT contain |
|------|------|-------------------|
| `helpers.py` | External-API utilities, MCP construction, sanitize/moderate primitives | Agent logic, orchestration |
| `agents.py` | Specialist agent functions | Registry, planning, retries |
| `registry.py` | `AgentRegistry` class + `AGENT_TOOLKIT` global | Agent implementations |
| `engine.py` | Tracer, Planner, Executor, dependency resolution | Agent or helper definitions |
| `utils.py` | Environment setup (install, init clients) | Runtime logic |

### 2. Pipeline Steps Must Run In Order

Phase 0 ingestion order (non-negotiable):

1. Load documents
2. Chunk via `chunk_text` (token-aware with overlap, e.g. 400/50)
3. Embed batches via `get_embeddings_batch`
4. Enrich metadata (raw text + source filename)
5. Upsert to Pinecone in correct namespace

Skipping or reordering breaks verifiable citations.

### 3. Runtime Workflow Order Is Fixed

Runtime sequence inside `context_engine()`:

1. Pre-flight moderation (gate)
2. Plan (Planner emits JSON plan)
3. Execute loop: resolve dependencies → invoke handler → store state → log step
4. Post-flight moderation (gate)
5. Final output

### 4. Engine Room vs Control Deck

- **Engine room** (`execute_and_display`) — orchestration, moderation, trace rendering. Reusable.
- **Control deck** — per-run cell. Defines `goal`, `config`, calls `execute_and_display`. Disposable.
- Never put orchestration logic in the control deck; never put per-run config in the engine room.

### 5. Moderation Activates Conditionally, Sanitization Always

| Safeguard | Activation |
|-----------|------------|
| `helper_sanitize_input` | ALWAYS — runs on every retrieved chunk inside `agent_researcher` |
| `helper_moderate_content` (pre-flight) | When `moderation_active=True` |
| `helper_moderate_content` (post-flight) | When `moderation_active=True` AND result exists |
| Moderation fail-safe | If API call errors, return `flagged=True` |

### 6. Sanitization Failure Skips Chunks, Does Not Crash

In `agent_researcher`: a chunk that fails `helper_sanitize_input` is skipped. The agent continues with remaining chunks. `ValueError` from sanitize is caught per-chunk.

### 7. Context Chaining Uses MCP + `$$STEP_N_OUTPUT$$`

- Inter-agent communication: every payload goes through `create_mcp_message`.
- Plan dependencies: reference prior step output with `$$STEP_N_OUTPUT$$`.
- Resolution: `resolve_dependencies()` recursively replaces references using `state` dict.

### 8. Dependency Injection at Handler Retrieval

`AgentRegistry.get_handler()` injects only the dependencies the agent needs (conditional logic). Returns a lambda taking only `mcp_message`. Agents never receive parameters they don't use.

### 9. Tracing Is Mandatory

Every run produces an `ExecutionTrace`. Log: goal, plan, each step (planned + resolved input, output), final status, duration. Returned even on failure (`Failed` status, output `None`).

### 10. Policy Beats Automation When Reality Bites

When pure code can't decide appropriateness (e.g. profanity in legal quotes vs email body), do NOT add complexity to the engine. Move the rule to a meta-controller above the engine that:

- Parses messy input
- Enforces deterministic business rules
- Assembles a clean control deck

This keeps non-deterministic AI separate from deterministic business logic.

## Guidelines

- Keep `tenacity` retry on every external API call (max 6 attempts, exponential backoff).
- Use `cl100k_base` as fallback encoding when a model's encoding is unknown.
- Default to a neutral blueprint when Librarian finds no match.
- Instruct the Researcher's LLM to answer "based ONLY on provided sources" — citations must be programmatically collected.
- Validate Planner JSON conforms to `{"plan": [...]}` before executing.

## Exceptions

- **Skipping post-flight moderation**: only when no result was produced (already short-circuited).
- **Bypassing sanitization**: never. Even trusted sources must pass.
- **Disabling moderation in dev**: pass `moderation_active=False`, but never default to it in production control decks.

## Quick Reference

| Rule | Summary |
|------|---------|
| File responsibility | One module, one concern |
| Pipeline order | Load → Chunk → Embed → Enrich → Upsert |
| Runtime order | Moderate → Plan → Execute → Moderate → Deliver |
| Sanitize scope | Every retrieved chunk, always |
| Moderate scope | Goal + final output, when enabled |
| Fail-safe | Moderation API error => flagged |
| Chaining | MCP + `$$STEP_N_OUTPUT$$` |
| Tracing | Mandatory, returned even on failure |
| Policy escape hatch | Meta-controller above the engine |
