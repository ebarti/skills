# Specialist Agents Examples

Both initial (Ch4 prototype) and hardened (Ch5 production) versions of each agent. The hardened versions in `agents.py` are the canonical reference.

This file is split per-agent for readability:

- `examples-librarian.md` — Context Librarian agent (initial + hardened + diff)
- `examples-researcher.md` — Researcher agent (initial + hardened + diff)
- `examples-writer.md` — Writer agent (initial + hardened + diff)

## Cross-Agent Hardening Summary

All three agents underwent the same three structural upgrades from Ch4 → Ch5:

1. **Dependency injection**: Function signatures now explicitly require `client`, `index`, model identifiers, and namespaces — no globals.
2. **Structured logging**: All `print()` calls replaced with `logging.info`/`logging.warning`/`logging.error`, prefixed with `[AgentName]`.
3. **`try...except` wrapping**: Whole agent body lives inside `try`; exceptions are logged and re-raised.

### Plus a Critical Bug Found During Hardening

The Librarian and Researcher originally returned **raw strings**. The Writer expected dict keys. This mismatch was discovered when integrating the modules and fixed by establishing a **data contract**:

| Agent | Output Shape Before | Output Shape After |
|-------|---------------------|--------------------|
| Librarian | `"<json string>"` | `{"blueprint_json": "<json string>"}` |
| Researcher | `"<text>"` | `{"facts": "<text>"}` |
| Writer (consumer) | unpacked raw strings | `isinstance(..., dict)` to support both |

The Writer's input-unpacking logic was upgraded to handle both dicts (from new agents) and raw strings (backward compatibility) — the integration fix that actually closed the loop.

## Quick Comparison Table

| Aspect | Ch4 (Prototype) | Ch5 (Hardened) |
|--------|-----------------|-----------------|
| Dependencies | Global variables | Function arguments |
| Logging | `print(...)` | `logging.info(...)` |
| Errors | Unhandled | `try...except` + log + raise |
| Output (Lib/Res) | Raw string | `{"key": value}` dict |
| Helper calls | Positional args | Explicit kwargs |
| Namespace | Hardcoded constant | Injected argument |
