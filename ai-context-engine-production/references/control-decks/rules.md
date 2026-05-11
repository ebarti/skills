# Control Decks Rules

Rules for choosing, parametrizing, and composing control decks when building applications on top of the Context Engine.

## Core Rules

### 1. Match the Template to the Goal Type

Pick the deck whose key capability matches what the user actually needs.

- **Cited factual answer over a corpus** -> Template 1 (High-Fidelity RAG).
- **Long document that must be condensed before a downstream task** -> Template 2 (Context Reduction).
- **Validate that the engine refuses to invent answers outside its corpus** -> Template 3 (Grounded Reasoning).

**Heuristic**: If the goal contains "summarize ... then ..." it is Template 2. If it asks for citations, it is Template 1. If it is deliberately out-of-scope, it is Template 3.

### 2. Parametrize the Three Inputs Explicitly

Every deck has exactly three things you can change. Treat them as the public API.

- **`goal`** — the only domain-specific text in the template.
- **`config`** — pin `index_name`, `generation_model`, `embedding_model`, `namespace_context`, `namespace_knowledge`.
- **`moderation_active`** — set per execution; do not hide it behind defaults inside application code.

**Example**:
```python
# Bad: hard-codes the goal and hides the moderation flag
def run_legal_query():
    execute_and_display("What are the confidentiality obligations?", LEGAL_CONFIG, client, pc)

# Good: keeps the deck shape intact and exposes the moderation control
def run_legal_query(goal: str, moderation_active: bool = False):
    execute_and_display(goal, LEGAL_CONFIG, client, pc, moderation_active=moderation_active)
```

### 3. Keep `config` Stable Across Decks in the Same Domain

Within one domain, the configuration dictionary should not change between decks. Only the `goal` and `moderation_active` flag vary.

- One `config` per (index, models, namespaces) tuple.
- Switching domains means swapping `config`, not editing each deck.

### 4. Set `moderation_active` Deliberately

The flag is explicit on every `execute_and_display` call for a reason.

- For RAG capability checks (Template 1), the book sets `moderation_active=False` to focus on core RAG.
- For production user-facing runs, set it to `True`.
- Never silently default it; surface it in your application configuration.

### 5. Verify Before Generalizing to a New Domain

When introducing a new domain (e.g. legal documents on top of an existing scientific index), first confirm the existing decks still work against the previously-ingested data before swapping `config` or ingesting new data.

- Run all three templates against the existing corpus.
- Only then ingest the new domain and update `config`.

## Guidelines

- Treat the three templates as a starter library; add new decks only when an existing one cannot express the goal.
- Keep a one-line comment above each `goal =` line stating the deck number and intent — it makes notebook output far easier to scan.
- When composing decks (e.g. RAG followed by reduction), wire them at the application layer rather than inventing a new fused template.
- Run Template 3 periodically as a regression test against any new ingestion — it catches corpus drift that introduces accidental in-scope answers.

## When to Compose Templates

Composition belongs in the application layer, not inside a deck.

- **RAG + Reduction**: Use Template 1 to retrieve cited evidence, then feed the result into Template 2 to produce a client-friendly summary.
- **Reduction + RAG**: Use Template 2 to summarize a fresh document, then use Template 1 to cross-reference the summary against the existing knowledge base.
- **Any deck + Template 3**: Run Template 3 first as a smoke test that the corpus boundary still holds, then run the real deck.

## Exceptions

- **Capability tests**: It is acceptable (and recommended) to run with `moderation_active=False` when isolating a single agent's behavior.
- **Limit tests**: Template 3 has an explicit "ambiguous request" variant intended for stress-testing — keep it commented out except during evaluation runs.

## Quick Reference

| Rule | Summary |
|------|---------|
| Match template to goal | Cited -> T1, summarize-then-act -> T2, out-of-scope -> T3. |
| Parametrize three inputs | `goal`, `config`, `moderation_active` are the public API. |
| Stable config per domain | Only `goal` varies inside a domain. |
| Explicit moderation flag | Never hide `moderation_active` defaults from callers. |
| Verify before generalizing | Re-run existing decks before ingesting new domain data. |
| Compose at app layer | Chain templates outside the deck, do not fuse them. |
