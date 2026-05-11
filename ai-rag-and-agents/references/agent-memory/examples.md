# Agent Memory Examples

Concrete Python implementations for short-term and long-term memory in AI agents.

## Bad Examples

### Naive FIFO That Drops the Task Statement

```python
class FIFOMemory:
    def __init__(self, max_messages: int = 10):
        self.messages: list[dict] = []
        self.max_messages = max_messages

    def add(self, msg: dict) -> None:
        self.messages.append(msg)
        if len(self.messages) > self.max_messages:
            self.messages.pop(0)  # drops oldest, including system/task
```

**Problems**:
- Evicts the original task description once the window fills.
- No distinction between system, task, and chit-chat.
- Token-blind — `max_messages` says nothing about real context use.

### Unbounded Context With Everything Inlined

```python
def build_prompt(user_msg, profile, full_history, all_tool_outputs):
    return (
        f"{profile}\n"
        f"{full_history}\n"
        f"{all_tool_outputs}\n"
        f"User: {user_msg}"
    )
```

**Problems**:
- Will overflow the context window on long sessions.
- Sends rarely-used data on every turn (cost + latency).
- Tool outputs that should live in long-term memory are pinned in short-term.

## Good Examples

### Short-Term Memory With Pinned Task and Token Budget

```python
from dataclasses import dataclass, field

@dataclass
class ShortTermMemory:
    max_tokens: int
    pinned: list[dict] = field(default_factory=list)   # system + task
    rolling: list[dict] = field(default_factory=list)  # recent turns
    count_tokens: callable = len  # plug in a real tokenizer

    def pin(self, msg: dict) -> None:
        self.pinned.append(msg)

    def add(self, msg: dict) -> list[dict]:
        """Append a turn; return any messages evicted to long-term."""
        self.rolling.append(msg)
        evicted: list[dict] = []
        while self._total_tokens() > self.max_tokens and self.rolling:
            evicted.append(self.rolling.pop(0))
        return evicted

    def render(self) -> list[dict]:
        return self.pinned + self.rolling

    def _total_tokens(self) -> int:
        all_msgs = self.pinned + self.rolling
        return sum(self.count_tokens(m["content"]) for m in all_msgs)
```

**Why it works**:
- Pins system + original task so FIFO cannot drop them.
- Token-aware eviction respects the real context limit.
- Returns evicted messages so the caller can spill them to long-term storage.

### Long-Term Memory Backed by an Embedding Store

```python
class LongTermMemory:
    def __init__(self, embedder, vector_store):
        self.embedder = embedder
        self.store = vector_store

    def add(self, text: str, metadata: dict | None = None) -> str:
        vec = self.embedder.embed(text)
        return self.store.upsert(vec, text=text, metadata=metadata or {})

    def retrieve(self, query: str, k: int = 5) -> list[dict]:
        vec = self.embedder.embed(query)
        return self.store.search(vec, k=k)  # [{text, metadata, score}, ...]

    def delete(self, entry_id: str) -> None:
        self.store.delete(entry_id)
```

**Why it works**:
- Mirrors RAG infrastructure — same embeddings, same index.
- Supports add/delete; deletion is optional given cheap storage.
- Returns scored hits so the caller can budget how many to inject.

### Reflection-Based Memory Update (Liu et al. 2023 style)

```python
REFLECT_PROMPT = """You manage an agent's long-term memory.
New observation: {obs}
Closest existing entries:
{neighbors}

Decide ONE action: INSERT, MERGE, or REPLACE.
Return JSON: {{"action": "...", "target_id": "...|null", "text": "..."}}."""

def reflect_and_update(llm, ltm: LongTermMemory, observation: str) -> None:
    neighbors = ltm.retrieve(observation, k=3)
    rendered = "\n".join(f"[{n['metadata']['id']}] {n['text']}" for n in neighbors)
    decision = llm.json(REFLECT_PROMPT.format(obs=observation, neighbors=rendered))

    if decision["action"] == "INSERT":
        ltm.add(decision["text"])
    elif decision["action"] == "MERGE":
        ltm.delete(decision["target_id"])
        ltm.add(decision["text"])
    elif decision["action"] == "REPLACE":
        ltm.delete(decision["target_id"])
        ltm.add(decision["text"])
```

**Why it works**:
- Keeps memory coherent: contradictions get replaced, related facts get merged.
- Bounded LLM cost — only reflects on neighbors, not the whole store.
- Easy to audit because each decision is a JSON record.

## Refactoring Walkthrough

### Before

```python
# Single global list, FIFO, no budget split, no long-term store.
HISTORY: list[dict] = []

def chat(user_msg: str, llm) -> str:
    HISTORY.append({"role": "user", "content": user_msg})
    if len(HISTORY) > 20:
        HISTORY.pop(0)
    reply = llm.complete(HISTORY)
    HISTORY.append({"role": "assistant", "content": reply})
    return reply
```

### After

```python
class Agent:
    def __init__(self, llm, embedder, vector_store, max_short_tokens: int):
        self.llm = llm
        self.short = ShortTermMemory(max_tokens=max_short_tokens)
        self.long = LongTermMemory(embedder, vector_store)

    def set_task(self, system: str, task: str) -> None:
        self.short.pin({"role": "system", "content": system})
        self.short.pin({"role": "user",   "content": task})

    def chat(self, user_msg: str) -> str:
        # 1. Retrieve relevant long-term entries (budget: top-k).
        hits = self.long.retrieve(user_msg, k=3)
        retrieved = "\n".join(h["text"] for h in hits)

        # 2. Add the user turn; spill overflow into long-term.
        evicted = self.short.add({"role": "user", "content": user_msg})
        for m in evicted:
            self.long.add(m["content"], metadata={"role": m["role"]})

        # 3. Build the prompt and generate.
        prompt = [{"role": "system", "content": f"Context:\n{retrieved}"}]
        prompt += self.short.render()
        reply = self.llm.complete(prompt)

        # 4. Add the assistant turn; reflect into long-term.
        self.short.add({"role": "assistant", "content": reply})
        reflect_and_update(self.llm, self.long, reply)
        return reply
```

### Changes Made

1. **Pinned the system + task** so FIFO can no longer drop them.
2. **Token-aware short-term memory** instead of a fixed message count.
3. **Long-term memory via embeddings** for cross-session persistence and retrieval.
4. **Overflow spillover** — evicted short-term turns are saved to long-term, not lost.
5. **Reflection step** keeps long-term memory coherent (insert/merge/replace).
6. **Explicit retrieval budget** (`k=3`) keeps retrieved context bounded.
