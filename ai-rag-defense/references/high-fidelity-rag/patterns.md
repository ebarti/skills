# High-Fidelity RAG Patterns

Reusable patterns for verifiable retrieval and citation-mandatory synthesis.

## Pattern: Source-Metadata-on-Chunks

### Intent

Make every retrieved chunk independently auditable by attaching the originating document name as metadata at upsert time.

### When to Use

- The application demands citation accuracy (legal, medical, scientific).
- Downstream agents need to deduplicate or filter results by source.
- You expect the corpus to grow into multiple documents over time.

### Structure

```python
batch_vectors.append({
    "id": chunk_id,
    "values": embedding,
    "metadata": {
        "text": chunk_text,
        "source": doc_name,   # the citation key
    },
})
index.upsert(vectors=batch_vectors, namespace=NAMESPACE)
```

### Example

```python
for doc_name, doc_content in knowledge_base.items():
    chunks = chunk_text(doc_content)
    for i, chunk in enumerate(chunks):
        embedding = embed(chunk)
        index.upsert(vectors=[{
            "id": f"{doc_name}_chunk_{i}",
            "values": embedding,
            "metadata": {"text": chunk, "source": doc_name},
        }], namespace=NAMESPACE)
```

### Benefits

- Single low-cost field unlocks full auditability.
- Sources can be deduplicated programmatically with a `set`.
- Filenames become the canonical citation tokens.

### Considerations

- Filenames must be human-readable; avoid hashes or random IDs.
- Always retrieve with `include_metadata=True`.
- Run a verification probe after ingestion to confirm metadata persistence.

---

## Pattern: Citations-Mandatory Agent

### Intent

Force a synthesis agent to ground its answer in retrieved sources and emit those sources, with a programmatic safety net so attribution is never lost.

### When to Use

- Building a Researcher / synthesis agent on top of a metadata-aware vector store.
- Outputs will be consumed by humans who need to verify claims.
- You cannot trust the LLM alone to remember every source it used.

### Structure

```python
# 1. Retrieve with metadata
results = query_pinecone(query_text=topic, top_k=3, include_metadata=True, ...)

# 2. Collect unique sources while preparing texts
sources = set()
texts = []
for match in results:
    texts.append(match["metadata"]["text"])
    if "source" in match["metadata"]:
        sources.add(match["metadata"]["source"])

# 3. Cite-aware system prompt
system_prompt = (
    "You are an expert research synthesis AI. Answer based *only* on the "
    "provided source texts. You MUST include a 'Sources' section listing "
    "the unique source document names you used."
)

# 4. Synthesize
findings = call_llm_robust(system_prompt, user_prompt, ...)

# 5. Programmatic safety net
final_output = f"{findings}\n\n**Sources:**\n" + "\n".join(
    f"- {s}" for s in sorted(sources)
)
```

### Example

See the `agent_researcher` implementation in `examples.md` (Example 3).

### Benefits

- Two-layer guarantee: prompt instruction + post-hoc append.
- Output payload (`answer_with_sources`) is a single auditable string.
- Sorted source list keeps outputs deterministic across runs.

### Considerations

- The system prompt must explicitly say "based *only* on the provided source texts."
- Synthesis must abort if no chunks survive sanitization, returning a clear "could not generate" message rather than hallucinating.
- The programmatic append is what makes the pattern robust against LLM stochasticity.

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|--------------------|
| Multi-document corpus needing audit trails | Source-Metadata-on-Chunks |
| Synthesis agent that must cite sources | Citations-Mandatory Agent |
| Both ingestion and synthesis under your control | Combine both patterns end-to-end |
