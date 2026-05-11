# Hardening Rules

Rules for transforming a prototype Context Engine into a pre-production system across the four pillars: dependency injection, logging, context management, and modularization.

## Core Rules

### 1. No Globals — Use Dependency Injection

Every helper, agent, and orchestrator must receive its dependencies (`client`, `generation_model`, `embedding_model`, `index`, namespace configs) as arguments.

- Function signatures explicitly declare every external need.
- Functions become self-contained, testable units.
- You can run two engine tasks in parallel with different LLM providers just by passing different `client` objects.

**Example**:
```python
# Bad — implicit global dependency
def call_llm_robust(system_prompt, user_prompt, json_mode=False):
    response = client.chat.completions.create(model=GENERATION_MODEL, ...)

# Good — explicit injection
def call_llm_robust(system_prompt, user_prompt, client, generation_model, json_mode=False):
    response = client.chat.completions.create(model=generation_model, ...)
```

### 2. Replace All `print()` with Structured Logging

Use Python's `logging` module exclusively. Configure once at the top of the module.

- Use `logging.info` for routine events, `logging.warning` for soft failures, `logging.error` for caught exceptions.
- Logs are timestamped, leveled, and machine-readable for monitoring.

**Example**:
```python
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
```

### 3. Catch, Log, Re-raise

Wrap helper logic in `try...except`. Catch specific errors first (e.g., `APIError`), log them with context, then re-raise so the orchestrator can halt the plan.

- Specific errors first, generic `Exception` last.
- Always `raise e` after logging — never silently swallow.
- This lets the engine make the strategic decision to abort cleanly.

### 4. Measure Tokens Before Sending

Use `count_tokens(text, model)` to gauge prompt cost before any LLM call where context size is a concern.

- Built on `tiktoken.encoding_for_model(model)` with a `cl100k_base` fallback.
- Foundation for budget-aware summarization later.

### 5. Centralize Setup in `utils.py`

Move package installation and client initialization out of the notebook into reusable functions.

- `install_dependencies()` pins library versions for reproducibility.
- `initialize_clients()` fetches secrets and constructs OpenAI/Pinecone clients.
- The notebook becomes a single import + two function calls.

### 6. Modularize Into a `commons/` Package

Split the monolithic notebook into separate `.py` files: `helpers.py`, `agents.py`, `registry.py`, `engine.py`.

- Each file is an island — explicitly `import` every dependency.
- For Colab flat directories, use top-level imports: `import helpers`, `import agents`, `from registry import AGENT_TOOLKIT`, `from engine import context_engine`.
- For structured packages, use `from commons import helpers`.

### 7. Separate Engine Room From Control Deck

The final notebook has two distinct parts:

- **Engine Room** (`execute_and_display`): Holds all logic for running the engine and formatting output (plain result + technical trace).
- **Control Deck**: User-facing cell with only `goal` and a `config` dictionary.

This separation is the hallmark of a well-designed application.

### 8. Define a `config` Dictionary

Hold all technical parameters (`index_name`, `generation_model`, `embedding_model`, `namespace_context`, `namespace_knowledge`) in one dictionary, then unpack with `**config` into the engine call.

## Guidelines

- Prefer keyword arguments when calling hardened helpers — it documents intent at the call site.
- Use `pprint.PrettyPrinter(indent=2)` to display trace steps for human readability.
- Keep `engine.py` free of presentation code; presentation belongs in the notebook's engine room cell.
- After modularizing, expect `NameError` until every cross-module dependency is imported — this is normal debugging.

## Exceptions

- **Single-script demos**: A single-file demo may use module-level constants instead of full DI, but only if it will never be imported elsewhere.
- **Backward compatibility**: An agent may accept both raw strings and dicts (using `isinstance`) when interfacing with legacy callers.

## Quick Reference

| Rule | Summary |
|------|---------|
| DI | Pass `client`, models, configs as arguments |
| Logging | Replace `print()` with `logging` at INFO/WARNING/ERROR |
| Catch + raise | Log specific errors then `raise e` |
| Token counting | Call `count_tokens` before large prompts |
| Centralized setup | `install_dependencies()` + `initialize_clients()` in `utils.py` |
| Modularize | Split into `helpers.py`, `agents.py`, `registry.py`, `engine.py` |
| Engine room vs control deck | Function holds logic; user cell holds goal + config |
| Config dict | One dict; unpack with `**config` |
