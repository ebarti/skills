# Data Synthesis Patterns

Reusable pipeline patterns for synthesizing and verifying training data.

## Pattern: Topic-Expansion Pipeline

### Intent
Generate large, diverse instruction datasets from a small seed of topics by hierarchical expansion.

### When to Use
- Need broad coverage; small seed of topics; used by UltraChat and Alpaca

### Structure

```python
def topic_expansion(seed_topics, n_subs=40, n_examples=10):
    dataset = []
    for topic in seed_topics:
        for sub in ask_llm(f"Generate {n_subs} subtopics for {topic}."):
            for _ in range(n_examples):
                instr = ask_llm(f"Write a user question about: {sub}")
                resp = ask_llm(f"Answer: {instr}")
                if passes_quality_filters(instr, resp):
                    dataset.append({"instruction": instr, "response": resp})
    return dataset
```

### Benefits
- Scales linearly with seed; forces diversity via topic structure

### Considerations
- Topic-level bias propagates downward; deduplicate via embeddings

---

## Pattern: Generate-Verify-Revise Loop

### Intent
Improve synthetic data quality by iteratively fixing failed examples instead of discarding them.

### When to Use
- Code generation where failures are catchable (lint, tests)
- Math/reasoning tasks with verifiable answers
- Used in Llama 3 coding pipeline

### Structure

```python
def generate_verify_revise(prompt, max_attempts=3):
    candidate = generate(prompt)
    for _ in range(max_attempts):
        errors = verify(candidate)
        if not errors:
            return candidate
        candidate = revise(prompt, candidate, errors)
    return None  # Discard if still failing
```

### Benefits
- Recovers borderline examples
- Final dataset is high-precision

### Considerations
- Multiple LLM calls per example
- Cap attempts to avoid runaway loops

---

## Pattern: Reverse Instruction (Anchored Quality)

### Intent
Avoid AI hallucination on long outputs by using human-authored content as the response and synthesizing only the prompt.

### When to Use
- Long-form tasks; abundant high-quality content; Köksal/Li/Chen (2023)

### Structure

```python
def reverse_instruction_pipeline(long_documents):
    return [
        {"instruction": ask_llm(f"Write a prompt that would elicit:\n{doc}"),
         "response": doc}  # Human-authored, guaranteed quality
        for doc in long_documents
    ]
```

### Benefits
- No hallucination in responses; leverages existing libraries

### Considerations
- Limited to content-rich domains; instructions may not match natural phrasing

---

## Pattern: Iterative Bootstrapping

### Intent
Improve a weak model by recursively training on its own verified outputs.

### When to Use
- Small seed dataset; you have a verifier; want growth without more annotation

### Structure

```python
def bootstrap_loop(seed_data, corpus, max_iter=5):
    model = train(base_model, seed_data)
    dataset = list(seed_data)
    for _ in range(max_iter):
        new = []
        for content in corpus:
            instr = model.generate(f"What instruction would elicit this?\n{content}")
            if verify_quality(instr, content):
                new.append({"instruction": instr, "response": content})
        dataset.extend(new)
        next_model = train(base_model, dataset)
        if not improves(next_model, model):
            break
        model = next_model
    return model
```

### Benefits
- Compounds capability per iteration; anchored to real corpus avoids collapse

### Considerations
- Stop when validation plateaus; always include real data

---

## Pattern: Long-Context Finetuning Synthesis

### Intent
Extend a model's context window using synthetic Q&A pairs anchored in long documents.

### When to Use
- Current model handles 8K, target is 128K; long documents available

### Structure

```python
def long_context_dataset(long_docs, chunk_size=8000):
    dataset = []
    for doc in long_docs:
        for chunk in split_into_chunks(doc, max_tokens=chunk_size):
            for qa in ask_llm(f"Generate (question, answer) pairs for:\n{chunk}"):
                # Use full long doc as context, not just chunk
                dataset.append({"context": doc, **qa})
    return dataset
```

### Benefits
- Trains model to use extended context anchored in real content

---

## Pattern: Self-Play Data Generation

### Intent
Generate trajectories by having models play against themselves or other roles.

### When to Use
- Game agents (chess, Go, Dota); multi-turn negotiation/support; tool-use agents

### Structure

```python
def self_play_episode(model_a, model_b, env):
    trajectory, state = [], env.reset()
    while not env.done:
        action_a = model_a.act(state, role="player_1")
        state, _ = env.step(action_a)
        action_b = model_b.act(state, role="player_2")
        state, _ = env.step(action_b)
        trajectory.append((state, action_a, action_b))
    return trajectory
```

### Benefits
- Massive data volume (OpenAI: 180 years/day for Dota 2); discovers non-human strategies

### Considerations
- Risk of degenerate strategies; requires reward signal or simulator

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|--------------------|
| Need broad instruction coverage | Topic-Expansion Pipeline |
| Code or verifiable outputs | Generate-Verify-Revise Loop |
| Long-form, high-quality responses | Reverse Instruction |
| No more annotation budget | Iterative Bootstrapping |
| Extending context window | Long-Context Finetuning |
| Game/agent/multi-turn data | Self-Play Data Generation |
| Cross-language data | Translation + Back-Translation |
| Preference data | AI Judge with Order Swap |
