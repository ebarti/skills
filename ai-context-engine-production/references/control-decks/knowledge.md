# Control Decks Knowledge

Core concepts and foundational understanding for control decks, the user-facing API of the Context Engine.

## Overview

Control decks are reusable, generic templates that let engineers drive the Context Engine across domains without rewriting workflows. Each deck packages a goal definition, a standard configuration dictionary, and a single `execute_and_display` call into a small block of Python that any application layer can adapt.

## Key Concepts

### What a Control Deck Is

**Definition**: A control deck is the smallest reusable unit of "task intent" for the Context Engine. It is composed of three parts:

1. **Goal** — A natural-language statement describing what the engine must accomplish.
2. **Configuration** — A `config` dict pinning the index, generation model, embedding model, and namespaces.
3. **Execute call** — A single invocation of `execute_and_display(goal, config, client, pc, moderation_active=...)`.

**Key points**:
- Decks are domain-independent: the same template works across legal, medical, financial, scientific, or corporate text.
- Decks are the user-facing API of the engine — application code calls into them, not into the underlying agents.
- The `moderation_active` flag is an explicit control surface that toggles the moderation layer per execution.

### Template 1: High-Fidelity RAG

**Definition**: A control deck for knowledge-intensive queries that require a verifiable, cited answer.

**Tests**: The Planner (decomposes the query), the Researcher (retrieves text with `source` metadata), and the Writer (assembles the cited report).

**Domain applicability**: Any knowledge-intensive field (legal contracts, medical literature, financial filings, scientific papers).

### Template 2: Context Reduction

**Definition**: A control deck for the *reduce-then-create* workflow — summarize a long document first, then use the summary for a downstream task.

**Tests**: The Summarizer agent and the engine's Context Chaining between Summarizer and Writer.

**Domain applicability**: Any field with large, information-dense documents (legal contracts, scientific papers, corporate reports, privacy policies).

### Template 3: Grounded Reasoning

**Definition**: A control deck that issues a deliberately out-of-scope task to verify the engine refuses to hallucinate.

**Tests**: The Researcher's ability to report a negative finding and the Writer's ability to handle that gracefully — a successful run is an honest "I don't have that context" rather than a fabricated answer.

**Domain applicability**: Universal — applicable to any curated knowledge base as an integrity check.

## Terminology

| Term | Definition |
|------|------------|
| Control deck | A goal + config + execute call that drives one engine run. |
| Goal | Natural-language task description used as input to the engine. |
| Configuration | Dict pinning index, models, and namespaces for an execution. |
| `execute_and_display` | The single entry point that runs the deck and renders output. |
| `moderation_active` | Boolean flag on the execute call toggling moderation per run. |
| Context Chaining | Passing one agent's output (e.g. summary) as input to the next. |
| Glass-box architecture | Domain-independent agents whose reasoning steps are observable. |

## How It Relates To

- **Underlying agents (Planner, Researcher, Summarizer, Writer)**: Decks invoke them indirectly through `execute_and_display` — engineers never wire agents by hand.
- **Moderation layer**: Each deck chooses whether to run with `moderation_active=True` or `False`.
- **Domain ingestion (e.g. `High_Fidelity_Data_Ingestion.ipynb`)**: Decks operate on whatever has been ingested into the configured index/namespaces; switching domains is an ingestion concern, not a deck concern.

## Common Misconceptions

- **Myth**: Control decks are domain-specific scripts.
  **Reality**: They are generic templates — the only domain-specific part is the `goal` string and (optionally) the index name.

- **Myth**: A successful Template 3 run produces a polished answer.
  **Reality**: A successful run is an honest negative finding; producing a polished answer to an out-of-scope query is a failure (hallucination).

- **Myth**: You need a different `execute_and_display` per template.
  **Reality**: All three templates use the same execute call signature; only the goal changes.

## Quick Reference

| Template | One-Line Summary |
|----------|-----------------|
| 1: High-Fidelity RAG | Cited answers for knowledge-intensive queries. |
| 2: Context Reduction | Summarize a large document, then act on the summary. |
| 3: Grounded Reasoning | Confirm the engine refuses out-of-scope tasks instead of hallucinating. |
