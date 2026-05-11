# Agent Memory Rules

Guidelines for adding memory, choosing memory types, and managing storage and retrieval.

## Core Rules

### 1. Match Memory Type to Frequency of Use

Pick the storage layer based on how often the information is needed.

- **Always needed across all tasks**: bake into the model via training or finetuning (internal knowledge).
- **Needed for the current task only**: keep in short-term memory (context).
- **Rarely or selectively needed**: store in long-term memory and retrieve on demand.

**Example**:
```python
# Bad — stuffing every user fact into the prompt every turn
prompt = f"{full_user_profile}\n{full_history}\n{user_msg}"

# Good — keep current turn in short-term, retrieve relevant facts from long-term
relevant_facts = long_term_memory.retrieve(user_msg, k=3)
prompt = f"{relevant_facts}\n{recent_turns}\n{user_msg}"
```

### 2. Add Memory When Context Will Overflow or Must Persist

Introduce a memory system once any of these are true:

- Conversation/task exceeds the model's context limit
- Information must survive across sessions (user preferences, history)
- The agent needs consistency across repeated subjective queries
- You need to preserve structured data (tables, queues, lead lists)

If none of those apply, raw context may be enough — do not over-engineer.

### 3. Budget Short-Term vs Retrieved Context Explicitly

A model's short-term capacity = context limit minus the budget reserved for long-term retrieval.

- Decide a fixed split (e.g. 30% retrieval / 70% short-term).
- When short-term exceeds its budget, move overflow to long-term storage.
- Track token counts per turn; do not assume the model will compact for you.

### 4. Avoid Naive FIFO for Conversation Memory

FIFO is easy but discards the start of the conversation, which often contains the task statement.

- Pin the system message and original task to short-term memory.
- Use FIFO only for clearly low-value recent chatter (e.g. pleasantries).
- Prefer summarization or reflection-based eviction for substantive content.

### 5. Compress with Summaries Plus Entity Tracking

Reduce redundancy without losing facts.

- Summarize older turns with the same or a smaller model.
- Track named entities separately so they survive summarization.
- Optionally use a classifier (per Bae et al. 2022) to decide which sentences from memory and summary to keep.

### 6. Use Reflection to Update Long-Term Memory

After each agent action, run a reflection step that decides one of:

- **Insert** the new information as a new entry
- **Merge** with an existing related entry
- **Replace** an outdated/contradictory entry

This is the Liu et al. (2023) approach. It keeps long-term memory coherent and avoids stale facts.

### 7. Decide a Contradiction Policy Up Front

When new info contradicts old, pick a deterministic resolution:

- **Newer wins**: simplest, good for facts that change (preferences, status).
- **Model adjudicates**: ask the model which to keep, with rationale.
- **Keep both**: useful when multiple perspectives matter.

Document the choice — silent contradictions confuse the agent.

### 8. Match Storage Shape to Data Shape

Text-based context cannot guarantee structural integrity.

- Use tables/sheets for tabular data (e.g. sales leads).
- Use queues for action sequences.
- Use key-value stores for entity facts and preferences.
- Reserve free-text memory for genuinely unstructured content.

## Guidelines

- Default to "no deletion" for long-term memory unless storage cost is real.
- Store tool outputs in long-term memory if they may be reused; do not re-call expensive tools.
- Reuse RAG infrastructure for long-term memory retrieval — same embeddings, same index.
- Make every memory write idempotent and timestamped so reflection can reason about recency.

## Exceptions

When these rules may be relaxed:

- **Short, single-turn apps**: skip the memory system entirely; raw prompt is fine.
- **Strict privacy contexts**: deletion in long-term memory becomes mandatory regardless of cost.
- **Demos/prototypes**: FIFO with last-N messages is acceptable for fast iteration.
- **Heavy pleasantries**: dropping early messages with FIFO can be safe if they carry no task signal.

## Quick Reference

| Rule | Summary |
|------|---------|
| Frequency-based tier | Always-needed → internal; task-only → short-term; rare → long-term |
| Add memory when | Overflow, cross-session need, consistency, structured data |
| Budget split | Fix retrieval vs short-term ratio; spill overflow to long-term |
| FIFO caution | Pin task statement; avoid dropping early high-signal content |
| Compress | Summary + named-entity tracking |
| Reflection update | Insert / merge / replace per new observation |
| Contradiction policy | Pick newer-wins, model-judges, or keep-both — document it |
| Storage shape | Tables for rows, queues for sequences, KV for facts |
