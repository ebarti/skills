# Agent Memory Knowledge

Core concepts for memory systems in AI agents and conversational applications.

## Overview

Memory refers to mechanisms that allow a model to retain and utilize information across queries, turns, and tasks. Memory is essential for knowledge-rich applications like RAG and multi-step agent workflows that must store instructions, examples, plans, tool outputs, and reflections. An AI model has three layered memory mechanisms (internal, short-term, long-term) and a memory system manages how data flows between them.

## Key Concepts

### Internal Knowledge

**Definition**: Knowledge baked into the model's weights from training data.

The model itself is a memory mechanism. Internal knowledge does not change unless the model is retrained or finetuned, and it is accessible in every query.

**Key points**:
- Always available, no retrieval needed
- Updated only by training/finetuning
- Use for information essential to all tasks

### Short-Term Memory

**Definition**: The model's context window — information present in the current prompt.

Short-term memory holds previous messages or task-specific data so the model can reference them in the current generation. It is fast to access but capacity-limited and does not persist across tasks.

**Key points**:
- Bound by context length
- Reserved for immediate, task-specific information
- Lost when the session/task ends unless persisted elsewhere

### Long-Term Memory

**Definition**: External data sources the model accesses via retrieval (the RAG-style backend).

Long-term memory persists across tasks and sessions. Unlike internal knowledge, entries can be added, updated, or deleted without retraining the model.

**Key points**:
- Persistent across sessions and tasks
- Storage is cheap and easily extensible
- Accessed via retrieval, similar to RAG

### Memory Management

**Definition**: The logic that decides what to add to and delete from memory.

Two operations: `add` and `delete`. Long-term memory may not need deletion (storage is cheap), but short-term memory always needs an eviction strategy due to context limits.

### Memory Retrieval

**Definition**: Fetching relevant entries from long-term memory for the current task.

Mechanically equivalent to RAG retrieval — the long-term store is just an external data source.

## Terminology

| Term | Definition |
|------|------------|
| Internal knowledge | Knowledge encoded in model weights |
| Short-term memory | Information in the current context window |
| Long-term memory | Persistent external store accessed via retrieval |
| Memory management | Logic for adding/deleting entries |
| Memory retrieval | Fetching entries relevant to the current task |
| FIFO eviction | First-in-first-out removal when context fills |
| Reflection memory | Agent reviews new info and decides insert/merge/replace |
| Overflow | Data spilled from short-term into long-term storage |

## How It Relates To

- **RAG**: Long-term memory uses the same retrieval machinery as RAG; RAG can be seen as a memory mechanism the agent reads from.
- **Agent planning**: Plans, tool inventories, and reflections all live in memory; the planner reads/writes them across steps.
- **Context engineering**: Short-term memory size = context budget minus retrieved long-term entries.

## Common Misconceptions

- **Myth**: Memory just means chat history.
  **Reality**: Memory also covers tool outputs, plans, reflections, structured records (queues, tables), and entity facts.

- **Myth**: Keeping the most recent N messages is always safe.
  **Reality**: FIFO can drop the original task statement, which often carries the most important context.

- **Myth**: Long-term memory needs aggressive deletion.
  **Reality**: External storage is cheap; deletion is mainly a short-term concern driven by context limits.

- **Myth**: Memory is unstructured by definition.
  **Reality**: Memory systems can store structured artifacts (sheets, queues, entity tables) to preserve data integrity.

## Quick Reference

| Memory Type | Where It Lives | Persistence | Use For |
|-------------|----------------|-------------|---------|
| Internal | Model weights | Until retrain | Universal facts/skills |
| Short-term | Context window | Within task | Immediate task data |
| Long-term | External store | Across sessions | Rarely-needed or large data |

| Benefit of Memory System | What It Solves |
|--------------------------|----------------|
| Manage information overflow | Context-length blowups during long tasks |
| Persist between sessions | Personalization, user preferences, history |
| Boost consistency | Repeated subjective questions get stable answers |
| Maintain structural integrity | Tables, queues, leads stay structured |
