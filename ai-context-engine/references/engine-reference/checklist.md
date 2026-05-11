# Context Engine Completeness Checklist

Use when building, reviewing, or auditing a Context Engine deployment to verify all required pieces are in place.

## Before You Start

- [ ] OpenAI + Pinecone API keys available via secret manager
- [ ] Python environment supports `tenacity`, `openai`, `pinecone`, `tiktoken`, `re`
- [ ] Source documents identified and accessible
- [ ] Pinecone index provisioned (correct dimensions for embedding model)

## Required Files (commons library)

- [ ] `helpers.py` — exposes `call_llm_robust`, `get_embedding`, `create_mcp_message`, `query_pinecone`, `count_tokens`, `helper_sanitize_input`, `helper_moderate_content`
- [ ] `agents.py` — exposes `agent_context_librarian`, `agent_researcher`, `agent_writer`, `agent_summarizer`
- [ ] `registry.py` — defines `AgentRegistry` with `get_handler` + `get_capabilities_description`, instantiates `AGENT_TOOLKIT`
- [ ] `engine.py` — defines `ExecutionTrace`, `planner`, `resolve_dependencies`, `context_engine`
- [ ] `utils.py` — defines `install_dependencies`, `initialize_clients`

## Required Ingestion Steps (Phase 0)

- [ ] Load raw documents from a directory
- [ ] Chunk with `tiktoken`-aware sizing (e.g. 400 tokens) AND overlap (e.g. 50 tokens)
- [ ] Batch-embed chunks with retry-protected `get_embeddings_batch`
- [ ] Enrich metadata with `text` + `source` filename
- [ ] Upsert to `KnowledgeStore` namespace
- [ ] Separately ingest semantic blueprints into `ContextLibrary` namespace (embed description, store `blueprint_json` as metadata)

## Required Safeguards

- [ ] `helper_sanitize_input` invoked on every retrieved chunk inside `agent_researcher`
- [ ] Sanitization failures skip the chunk, do NOT crash the agent
- [ ] `helper_moderate_content` available for pre-flight (goal) check
- [ ] `helper_moderate_content` available for post-flight (output) check
- [ ] Moderation has fail-safe — API exception returns `flagged=True`
- [ ] `moderation_active` flag plumbed through `execute_and_display`
- [ ] Redaction message defined for flagged outputs
- [ ] Meta-controller (or documented placeholder) for organizational policy

## Required Engine Behaviors

- [ ] `ExecutionTrace` records goal, plan, every step's planned + resolved input + output
- [ ] Trace finalized with `Success` or `Failed` status and duration
- [ ] Failure path returns `(None, trace)` — never raises to caller
- [ ] Planner output validated against `{"plan": [...]}` schema
- [ ] `resolve_dependencies` recurses into dicts and lists
- [ ] `resolve_dependencies` raises `ValueError` on missing `$$STEP_N_OUTPUT$$`
- [ ] `AgentRegistry.get_handler` injects only the dependencies each agent needs

## Operational Interface

- [ ] Engine room (`execute_and_display`) handles moderation + display + trace render
- [ ] Control deck cell defines `goal`, `config`, calls `execute_and_display`
- [ ] At least one workflow template documented (RAG, context reduction, or grounded reasoning)

## Red Flags

Stop and address if you find:

- Sanitization skipped for "trusted" sources
- Moderation disabled by default in production control deck
- Agent functions with hard-coded clients (no dependency injection)
- Custom code inside engine deciding business policy (move to meta-controller)
- Plans executed without validating Planner JSON shape
- `ExecutionTrace` missing resolved inputs (only planned inputs logged)
- No retry decorator on external API calls
- Single-namespace Pinecone index conflating knowledge + blueprints

## Quick Reference

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| Sanitization coverage | Every chunk | Every chunk | Selective |
| Moderation | Pre + post + fail-safe | Pre + post | Off in prod |
| Tracing | Plan + resolved inputs + outputs | Plan + outputs | Outputs only |
| Retry on API | tenacity, 6 attempts, exp backoff | tenacity, fewer attempts | None |
| Chunking | Token-aware + overlap | Token-aware | Char-based, no overlap |
| Namespaces | `KnowledgeStore` + `ContextLibrary` | Two namespaces | Single namespace |
| Policy | External meta-controller | Documented gap | Code inside engine |
