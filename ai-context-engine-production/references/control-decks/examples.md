# Control Decks Examples

The three reusable control deck templates verbatim, with goal definitions, configuration dicts, and execute calls preserved exactly as they appear in the book.

## Template 1: High-Fidelity RAG

A research query that requires a verifiable, cited answer.

```python
#@title CONTROL DECK TEMPLATE 1: High-Fidelity RAG

# 1. Define the Goal: A research query that requires a verifiable, cited answer.
#    - DOMAIN: Any knowledge-intensive field (e.g., legal, medical, financial).
#    - KEY CAPABILITY: Tests the high-fidelity `Researcher` agent and its ability
#      to retrieve text with `source` metadata and generate citations.
#goal = "[INSERT YOUR HIGH-FIDELITY RESEARCH GOAL HERE]"

# === CONTROL DECK 1: High-Fidelity RAG in a Legal Context ===
goal = "What are the key confidentiality obligations in the Service Agreement v1, and what is the termination notice period? Please cite your sources."
```

Standard configuration (shared across all three templates):

```python
# 2. Define the standard configuration
config = {
    "index_name": 'genai-mas-mcp-ch3',
    "generation_model": "gpt-5",
    "embedding_model": "text-embedding-3-small",
    "namespace_context": 'ContextLibrary',
    "namespace_knowledge": 'KnowledgeStore'
}

# 3. Call the execution function.
#    - moderation_active is set to False to focus on the core RAG capability.
execute_and_display(goal, config, client, pc, moderation_active=False)
```

**Why it works**:
- Goal explicitly asks for citations, exercising the Researcher's `source` metadata path.
- `moderation_active=False` isolates the RAG capability under test.
- The same `config` dict will be reused by Templates 2 and 3 unchanged.

## Template 2: Context Reduction

A multi-step task that involves summarizing a large document and then using that summary for a different purpose.

```python
#@title CONTROL DECK TEMPLATE 2: Context Reduction

# 1. Define the Goal: A multi-step task that involves summarizing a large
#    document and then using that summary for a different purpose.
#    - DOMAIN: Any field with large documents (legal, scientific, corporate).
#    - KEY CAPABILITY: Tests the `Summarizer` agent and the engine's ability
#      to perform Context Chaining between the `Summarizer` and the `Writer`.
# goal = "[INSERT YOUR CONTEXT REDUCTION GOAL HERE]"

# === CONTROL DECK 2: Context Reduction for Client Communication ===
goal = "First, summarize the Provider Inc. Privacy Policy. Then, using ONLY the information in that summary, draft a short, client-facing paragraph for a website FAQ that explains our data retention policy in simple, non-legalistic terms."
```

The rest of the control deck (config dict and `execute_and_display` call) is identical to Template 1.

**Why it works**:
- "First, summarize ... Then, using ONLY the information in that summary ..." is the canonical phrasing that triggers Context Chaining between Summarizer and Writer.
- Restricting the Writer to the summary forces the engine to honor the reduce-then-create boundary.

## Template 3: Grounded Reasoning

A creative or factual task that is deliberately outside the scope of the documents in the knowledge base.

```python
#@title CONTROL DECK TEMPLATE 3: Grounded Reasoning & Hallucination Prevention

# 1. Define the Goal: A creative or factual task that is deliberately
#    outside the scope of the documents in the knowledge base.
#    - DOMAIN: Universal test applicable to any curated knowledge base.
#    - KEY CAPABILITY: Tests the `Researcher` agent's ability to report a
#      negative finding and the `Writer` agent's ability to handle it gracefully,
#      preventing hallucination.
# goal = "[INSERT YOUR OUT-OF-SCOPE GOAL HERE]"

# === CONTROL DECK 3: Grounded Reasoning and Hallucination Prevention ===
goal = "Write a persuasive opening statement for a trial involving a monkey that can fly a rocket."

# === CONTROL DECK 3 (LIMIT TEST): The Ambiguous Request ===
#goal = "Analyze the attached NDA and draft a pleading based on its terms."

# 2. Use the same configuration dictionary
config = {…}

# 3. Call the execution function.
execute_and_display(goal, config, client, pc, moderation_active=False)…
```

**Why it works**:
- The primary goal is intentionally absurd, so any non-empty answer is a hallucination.
- The commented-out "limit test" variant is preserved verbatim for ambiguity stress tests — uncomment only during evaluation.
- `config = {…}` indicates the same dict from Templates 1-2 is reused unchanged.

## Refactoring Walkthrough

### Before (per-domain, ad-hoc deck from Chapter 7)

```python
# NASA-specific research call wired by hand
goal = "What did the Mars rover discover about water ice?"
nasa_config = {"index_name": "nasa-research", "generation_model": "gpt-5", ...}
execute_and_display(goal, nasa_config, client, pc, moderation_active=False)
```

### After (generic Template 1, retargeted to legal)

```python
goal = "What are the key confidentiality obligations in the Service Agreement v1, and what is the termination notice period? Please cite your sources."
config = {
    "index_name": 'genai-mas-mcp-ch3',
    "generation_model": "gpt-5",
    "embedding_model": "text-embedding-3-small",
    "namespace_context": 'ContextLibrary',
    "namespace_knowledge": 'KnowledgeStore'
}
execute_and_display(goal, config, client, pc, moderation_active=False)
```

### Changes Made

1. Replaced domain-specific goal with a goal that names the document and asks for citations.
2. Promoted the per-domain config dict into a single shared `config` reused across all three templates.
3. Kept the `execute_and_display` call shape identical, so the deck is a drop-in template — only `goal` (and optionally `moderation_active`) varies between executions.
