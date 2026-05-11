# High-Fidelity RAG Rules

Rules for ingesting, retrieving, and synthesizing data so every claim is traceable to its source.

## Core Rules

### 1. Structure Source Documents for Citation

Each source document must be a separate file with a stable, human-readable name. The filename becomes the citation, so it has to make sense to a human auditor.

- Place documents in a dedicated directory (e.g., `nasa_documents/`).
- Use one document per topic; avoid monolithic dump files.
- Prefer descriptive filenames like `juno_mission_overview.txt` over generic names.

**Example**:
```python
# Bad: monolithic, untraceable
knowledge_data_raw = "Juno is... Perseverance is..."

# Good: separate files, citable filenames
with open("nasa_documents/juno_mission_overview.txt", "w") as f:
    f.write(juno_text)
with open("nasa_documents/perseverance_rover_tools.txt", "w") as f:
    f.write(perseverance_text)
```

### 2. Attach Source Metadata at Chunk Time

Every chunk uploaded to the vector store must include a `source` field in its metadata. This is the single most important rule of high-fidelity RAG.

- Set `"source": doc_name` inside the chunk's `metadata` dictionary.
- Apply per chunk, not per batch, so attribution survives reordering.
- Include the chunk's `text` alongside `source` so retrieval returns both.

**Example**:
```python
# Bad: no source field
batch_vectors.append({"id": chunk_id, "values": embedding,
                      "metadata": {"text": batch_texts[j]}})

# Good: source attached to every chunk
batch_vectors.append({"id": chunk_id, "values": embedding,
                      "metadata": {"text": batch_texts[j], "source": doc_name}})
```

### 3. Require Citations in Researcher Outputs

The Researcher agent must return an `answer_with_sources` payload containing both the synthesized answer and a `Sources` section.

- Collect unique sources into a Python `set` during retrieval.
- Programmatically append the sorted source list to the LLM output.
- Never trust the LLM alone to remember every source it consulted.

### 4. Design the System Prompt for Citation

The Researcher's system prompt must (a) restrict the model to the provided source texts and (b) mandate a `Sources` section listing the document names used.

**Example prompt**:
```text
You are an expert research synthesis AI. Your task is to provide a clear,
factual answer to the user's topic based *only* on the provided source texts.
After the answer, you MUST provide a "Sources" section listing the unique
source document names you used.
```

### 5. Verify Citation Correctness After Ingestion

A professional workflow always includes a verification probe. Do not assume metadata was stored correctly.

- After ingestion, query the index with `include_metadata=True`.
- Pretty-print the metadata of the top match.
- Confirm the `source` field is present and matches an expected filename.

### 6. Separate Ingestion from the Application Layer

Run ingestion in its own notebook (`High_Fidelity_Data_Ingestion.ipynb`). The context engine consumes the prepared knowledge base; it never re-ingests.

- Treat ingestion as a simulated data management department.
- The engine starts in Phase 1 assuming Phase 0 completed successfully.

## Guidelines

- Use `top_k=3` retrieval for the Researcher unless you measure otherwise.
- Chunk inside the per-document loop so each chunk inherits the right `source`.
- Use a batch size around 100 vectors per upsert for throughput.
- Sort the unique sources list before appending so output is deterministic.

## Exceptions

- **Single-source corpora**: A `source` field is still required so future expansion stays compatible.
- **Streaming ingestion**: Source metadata must still be derivable from the stream's identity (URL, document ID).

## Quick Reference

| Rule | Summary |
|------|---------|
| Per-file documents | One topic per file with citable filename. |
| `source` on chunks | Add `"source": doc_name` to every metadata dict. |
| `answer_with_sources` | Researcher returns answer + Sources section. |
| Citation system prompt | Restrict to provided texts; mandate Sources list. |
| Verify ingestion | Query and print metadata after upserting. |
| Ingestion isolation | Ingestion notebook runs separately from the engine. |
