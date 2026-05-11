# Production-Readiness Checklist

Use when promoting a Context Engine prototype to a pre-production deployment.

## Before You Start

- [ ] Prototype works end-to-end on at least one representative goal
- [ ] You can identify all globals the prototype reads (clients, model names, namespaces)
- [ ] You have a `utils.py` (or equivalent) target for centralized setup

## Dependency Injection

- [ ] No helper or agent reads global `client`, `index`, or model name
- [ ] Every helper signature explicitly lists `client`, `generation_model`, and/or `embedding_model`
- [ ] Every agent signature explicitly lists its required `client`, `index`, models, and namespaces
- [ ] `query_pinecone` is called with explicit keyword arguments
- [ ] You can swap LLM providers by passing a different `client` object

## Logging

- [ ] `logging.basicConfig` is called once with timestamp + level format
- [ ] Zero `print()` statements remain in helpers, agents, registry, or engine
- [ ] `logging.info` for routine events (activation, success)
- [ ] `logging.warning` for soft failures (no results found)
- [ ] `logging.error` for caught exceptions before re-raise

## Error Handling

- [ ] All helpers wrap logic in `try...except`
- [ ] Specific errors (`APIError`) caught before generic `Exception`
- [ ] All caught exceptions are re-raised with `raise e`
- [ ] No exception is silently swallowed

## Context Management

- [ ] `count_tokens(text, model)` utility is available in `helpers`
- [ ] `tiktoken.encoding_for_model` is wrapped in try/except with `cl100k_base` fallback
- [ ] Token counts are checked before sending large prompts (where applicable)

## Centralized Setup

- [ ] `install_dependencies()` exists in `utils.py` with pinned versions
- [ ] `initialize_clients()` exists in `utils.py` and fetches secrets securely
- [ ] The notebook setup is one import + two function calls

## Modularization

- [ ] Code is split into `helpers.py`, `agents.py`, `registry.py`, `engine.py`
- [ ] `registry.py` does `import agents` and references `agents.agent_*`
- [ ] `engine.py` imports from `helpers` and `registry`
- [ ] `agents.py` imports needed functions from `helpers`
- [ ] Notebook imports use the flat-directory pattern (Colab) or `from commons import ...` (structured)
- [ ] Running the import cell raises no `NameError`

## Engine Room vs Control Deck

- [ ] `execute_and_display(goal, config, client, pc)` is defined in the notebook (not in `engine.py`)
- [ ] It runs the engine, displays final output, and prints the technical trace
- [ ] `config` is a single dict holding `index_name`, `generation_model`, `embedding_model`, `namespace_context`, `namespace_knowledge`
- [ ] The user-facing cell defines only `goal` and calls `execute_and_display`

## Validation Run

- [ ] Standard goal (Librarian -> Researcher -> Writer) completes successfully
- [ ] Complex goal (chained writers, two-stage rewrite) completes successfully
- [ ] Trace shows `Status: Success` and reasonable `Total Duration`
- [ ] Each agent's output is a structured dict (not a raw string) with documented keys

## Red Flags

Stop and address if you find:

- Any `print()` left in a library file (`helpers.py`, `agents.py`, `registry.py`, `engine.py`)
- Any function reading a module-level `client` or `MODEL` constant instead of an argument
- Any agent returning a raw string when downstream agents expect a dict
- An exception caught and not re-raised (silent failure)
- The notebook control deck containing more than `goal` + `execute_and_display(...)`

## Quick Reference

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| Globals in helpers | None | Read-only constants for retries | Mutable `client`/model |
| `print()` count in libs | 0 | 0 | >0 |
| Try/except coverage | All helpers + agents | Helpers only | None |
| Exception re-raise | Always | Always | Silent swallow |
| Notebook setup cells | 1 | 2-3 | >3 |
| Library files | 4 (`helpers/agents/registry/engine`) | 3 if registry inlined | 1 monolith |
| Control deck content | `goal` + call | `goal` + call + comment | Mixed logic |
| Agent output shape | Dict with named keys | Dict | Raw string |
