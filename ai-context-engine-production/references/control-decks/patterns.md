# Control Decks Patterns

Each generic control deck formalized as a reusable pattern engineers can apply when wrapping the Context Engine in an application.

## Pattern: High-Fidelity RAG Deck

### Intent

Answer a knowledge-intensive query against a curated corpus with verifiable citations, using the Planner -> Researcher -> Writer pipeline.

### When to Use

- The user needs a factual answer backed by source references.
- The corpus has been ingested with `source` metadata.
- The domain is knowledge-intensive (legal, medical, financial, scientific).
- You need to validate the high-fidelity Researcher path end to end.

### Structure

```python
goal = "<domain question that explicitly requests citations>"

config = {
    "index_name": '<your-index>',
    "generation_model": "<model>",
    "embedding_model": "<embedding-model>",
    "namespace_context": '<context-namespace>',
    "namespace_knowledge": '<knowledge-namespace>',
}

execute_and_display(goal, config, client, pc, moderation_active=<bool>)
```

### Benefits

- Single template covers any knowledge-intensive domain.
- Forces source-backed output, reducing fabrication risk.
- Same shape as Templates 2 and 3 — engineers learn the API once.

### Considerations

- The corpus must already contain `source` metadata; otherwise citations will be empty.
- Setting `moderation_active=False` is appropriate during capability tests, not in production.

---

## Pattern: Context Reduction Deck

### Intent

Compress a long, information-dense document with the Summarizer, then chain the summary into a downstream creative or analytical task handled by the Writer.

### When to Use

- The source document is too large to feed directly to a generation step.
- The downstream task should operate strictly on the summary, not the original.
- The domain involves long contracts, papers, policies, or reports.
- You need to validate Context Chaining between Summarizer and Writer.

### Structure

```python
goal = (
    "First, summarize <document>. "
    "Then, using ONLY the information in that summary, <downstream task>."
)

config = { ... }  # same shape as Template 1

execute_and_display(goal, config, client, pc, moderation_active=<bool>)
```

### Benefits

- Captures the *reduce-then-create* pattern in one self-contained goal string.
- The "ONLY the information in that summary" clause enforces the chaining boundary.
- Reuses the same config and execute call as the other templates.

### Considerations

- The Writer's quality depends on summary fidelity; tune the Summarizer first.
- For very long documents, you may need multiple reduction passes before the Writer step.

---

## Pattern: Grounded Reasoning Deck

### Intent

Probe the engine with a deliberately out-of-scope task to verify it reports a negative finding instead of hallucinating an answer.

### When to Use

- Smoke-testing a freshly ingested corpus to confirm scope boundaries.
- Regression-testing after model upgrades or retrieval changes.
- Building confidence before exposing the engine to end users.
- Validating that the Researcher returns honest negative findings and the Writer handles them gracefully.

### Structure

```python
# Primary: an obviously absurd or off-topic goal
goal = "<task that has no support in the ingested corpus>"

# Optional limit test: an ambiguous request that mixes in-scope and out-of-scope work
# goal = "<request that is partially supported, partially fabricated>"

config = { ... }  # same shape as Templates 1 and 2

execute_and_display(goal, config, client, pc, moderation_active=<bool>)
```

### Benefits

- Universal — works against any curated knowledge base regardless of domain.
- A single failing run surfaces hallucination risk early.
- Doubles as an integrity test after every ingestion change.

### Considerations

- Success is an honest "I lack the context" — do not grade outputs by their fluency.
- Keep the limit-test variant commented out except during evaluation, so default runs stay deterministic.

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|--------------------|
| User asks a factual question over a corpus | High-Fidelity RAG Deck |
| User asks for citations | High-Fidelity RAG Deck |
| Document is too large to process directly | Context Reduction Deck |
| Output needs simplification of dense source text | Context Reduction Deck |
| Smoke test after corpus ingestion | Grounded Reasoning Deck |
| Validating hallucination guardrails | Grounded Reasoning Deck |
| Need both citations and simplification | Compose RAG Deck -> Context Reduction Deck at app layer |
| Need fresh-document analysis cross-checked against corpus | Compose Context Reduction Deck -> RAG Deck at app layer |
