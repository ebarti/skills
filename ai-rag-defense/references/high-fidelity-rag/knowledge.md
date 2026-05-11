# High-Fidelity RAG Knowledge

Core concepts for building a trustworthy research assistant whose every claim can be independently verified.

## Overview

High-fidelity RAG transforms a context engine from a black-box answer generator into a glass-box research assistant by attaching source metadata to every chunk and requiring agents to cite their sources. The pattern is essential for enterprise AI in legal, medical, and scientific domains where auditability matters.

## Key Concepts

### Trustworthy Research Assistant Architecture

**Definition**: A modular, multi-stage system that separates a data-management department (ingestion notebook) from an application layer (context engine), so that data preparation and runtime synthesis evolve independently.

**Key points**:
- Phase 0 (Data Ingestion) is run as a separate notebook (`High_Fidelity_Data_Ingestion.ipynb`) before any agent runs.
- Phases 1-4 (Initiation, Planning, Execution Loop, Finalization) remain unchanged in the engine core.
- The Researcher agent's internal workflow zooms in to Retrieve -> Sanitize -> Synthesize -> Format.

### What "High-Fidelity" Means

**Definition**: Every retrieved chunk carries a permanent, queryable record of the document it came from, and the synthesizing agent surfaces those origins as verifiable citations in its output.

**Key points**:
- Verifiability = source metadata on chunks + citation-aware synthesis prompt.
- Shifts the system from providing *answers* to providing *evidence*.
- Independently verifiable claims are the difference between a black-box and a glass-box system.

### Source-Metadata-on-Chunks Pattern

**Definition**: When chunks are upserted into the vector store, the metadata dictionary includes a `source` key holding the originating document name (e.g., `juno_mission_overview.txt`).

**Key points**:
- Adding a single `"source": doc_name` field at upsert time is the foundation of the entire system.
- Enables programmatic deduplication of sources via a Python `set`.
- Required during retrieval via `include_metadata=True`.

### Upgraded Ingestion Pipeline

**Definition**: A multi-document ingestion flow that loads each `.txt` file from a directory, chunks it, embeds it, and upserts it with source metadata in batches.

**Key points**:
- Replaces the old monolithic `knowledge_data_raw` variable.
- Iterates through a directory, building a `{filename: content}` dictionary.
- Chunks per document so source attribution remains correct.
- Always followed by a verification probe that queries the index and prints metadata.

### Upgraded Researcher Agent

**Definition**: The `agent_researcher` function that retrieves chunks with metadata, sanitizes each chunk, then synthesizes an answer with a citation-aware system prompt.

**Key points**:
- Collects unique sources into a Python `set` while iterating retrieved matches.
- Synthesizes with a system prompt that mandates a `Sources` section.
- Programmatically appends the unique source list to the LLM output for robustness, in case the model omits one.
- Returns an MCP message with key `answer_with_sources`.

### NASA Research Assistant Application

**Definition**: The end-to-end demo (`NASA_Research_Assistant_and_Retrocompatibility.ipynb`) that drives the upgraded engine with a research goal that explicitly asks "Please cite your sources."

**Key points**:
- Goal: scientific objectives + unique design features of the Juno mission.
- Standard config selects `gpt-5` generation and `text-embedding-3-small`.
- Planner emits a six-step plan that calls the Researcher twice, decomposing the multi-part query.

## Terminology

| Term | Definition |
|------|------------|
| High-fidelity RAG | Retrieval system where every chunk carries source metadata and every answer carries citations. |
| Source metadata | The `source` key (filename) attached to a chunk's metadata in the vector index. |
| Citation-aware prompt | A system prompt that instructs the LLM to ground answers in provided sources and emit a `Sources` section. |
| Control deck | The notebook cell that defines the research goal and runs `execute_and_display`. |
| Glass-box system | A system that shows its reasoning and evidence, opposite of a black-box generator. |
| Programmatic citation appending | Appending the deduplicated source list to the LLM output as a reliability safeguard. |

## How It Relates To

- **Input sanitization**: Sanitization happens between Retrieve and Synthesize in the same Researcher upgrade; both work on the metadata-rich chunks.
- **Glass-box context engine**: High-fidelity RAG is the next evolution of the Chapter 5 design philosophy.
- **Defense in depth**: Source metadata enables auditability; sanitization adds the security layer.

## Common Misconceptions

- **Myth**: Citations require a heavyweight RAG framework.
  **Reality**: A single metadata field at upsert time plus a citation-aware prompt is enough.

- **Myth**: The LLM alone can be trusted to list every source it used.
  **Reality**: Always append the unique source list programmatically as a safety net.

- **Myth**: Ingestion and the application layer can share the same notebook.
  **Reality**: Enterprise practice separates the data management department (ingestion) from the application (engine).

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Source metadata | One `source` key per chunk unlocks all verifiability. |
| Citation-aware prompt | Mandates a `Sources` section grounded only in provided texts. |
| Programmatic appending | Backstop the LLM by attaching unique sources after synthesis. |
| Phase 0 | Ingestion runs in its own notebook, before the engine. |
| Researcher zoom-in | Retrieve -> Sanitize -> Synthesize -> Format. |
