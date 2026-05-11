# Sampling Patterns

Reusable sampling configuration patterns by use case.

## Pattern: Factual Q&A / Extraction

### Intent
Maximize factual accuracy and reproducibility for tasks with one correct answer.

### When to Use
- Information extraction, RAG-based QA, classification, NER.
- Anything evaluated against a ground-truth set.

### Structure
```python
config = {
    "temperature": 0,
    "top_p": 1.0,        # T=0 makes top_p irrelevant
    "max_tokens": 256,   # tight, since answers are short
    "seed": 42,          # reproducibility where supported
}
```

### Benefits
- Reproducible during evaluation; lowest hallucination drift; cheapest.

### Considerations
- Outputs feel robotic. Even at T=0, provider hardware can introduce non-determinism.

---

## Pattern: Code Generation / SQL / Regex

### Intent
Generate syntactically valid code with minimal randomness; recover from rare failures via retry.

### When to Use
- Text-to-SQL, code completion, regex generation, function-call args.

### Structure
```python
def generate_code(prompt, validator, max_attempts=3):
    for _ in range(max_attempts):
        code = client.responses.create(
            model="gpt-x", input=prompt,
            temperature=0.2, max_tokens=1024,
        ).output_text
        if validator(code):
            return code
    return None
```

### Benefits
- Validator catches malformed output. Retry is cheap for short tasks.

### Considerations
- For strict schemas, prefer constrained sampling or provider native function-calling.

---

## Pattern: Creative Writing / Brainstorming

### Intent
Maximize diversity and surprise; coherence matters less than novelty.

### When to Use
- Marketing copy, story generation, ideation lists.

### Structure
```python
config = {
    "temperature": 1.0,    # 0.8-1.2 range
    "top_p": 0.95,         # avoid total nonsense from extreme tail
    "max_tokens": 1500,
    "presence_penalty": 0.6,
    "frequency_penalty": 0.3,
}
```

### Benefits
- More interesting, less predictable output.

### Considerations
- Higher hallucination risk; do not use for factual content. Higher cost.

---

## Pattern: Chat Assistant (Balanced)

### Intent
Conversational quality with a sane default for general assistant tasks.

### When to Use
- Customer-facing chat, general assistant, no strong reason to deviate from defaults.

### Structure
```python
config = {
    "temperature": 0.7,
    "top_p": 0.95,
    "max_tokens": 800,
}
```

### Benefits
- Vendor-recommended baseline; balances coherence and personality.

### Considerations
- Tune T down to 0.3-0.5 if users complain about inconsistency; up to 0.9 if too generic.

---

## Pattern: Math / Multiple Choice (Self-Consistency)

### Intent
Improve accuracy on tasks with a discrete answer via majority vote.

### When to Use
- Math word problems, MCQ benchmarks (MMLU, GSM8K), multi-step reasoning.

### Structure
```python
from collections import Counter

def self_consistent_answer(prompt, n=8, extract_fn=None):
    raws = [client.responses.create(model="gpt-x", input=prompt, temperature=0.7).output_text
            for _ in range(n)]
    answers = [extract_fn(a) for a in raws if extract_fn(a) is not None]
    return Counter(answers).most_common(1)[0][0] if answers else None
```

### Benefits
- Significant accuracy boost over single-sample (Google used N=32 on Gemini/MMLU).

### Considerations
- Cost scales linearly with N. Requires reliable answer-extraction.

---

## Pattern: Strict Structured Output (Constrained Sampling)

### Intent
Guarantee output format validity at the token level.

### When to Use
- Function-call args, must-parse DB queries, when even 0.1% format failure is unacceptable.

### Structure
```python
import outlines
from pydantic import BaseModel

class Output(BaseModel):
    intent: str
    entities: list[str]

model = outlines.models.transformers("Llama-3-8B")
generator = outlines.generate.json(model, Output)
result = generator(user_prompt)  # always parses to Output
```

### Benefits / Considerations
- 100% format validity; no retry needed. Requires self-host or provider with constrained decoding; adds per-token latency.

---

## Pattern: Best-of-N with Verifier

### Intent
Sample many candidates and rank with a verifier or reward model.

### When to Use
- Offline batch generation; high-stakes outputs; code with executable tests.

### Structure
```python
def best_of_n(prompt, n=10, scorer=None):
    candidates = [
        client.responses.create(model="gpt-x", input=prompt, temperature=0.8).output_text
        for _ in range(n)
    ]
    return max(candidates, key=scorer)
```

### Benefits / Considerations
- Verifier selection can match a 30x larger model. Linear cost; cap N (8-32 in production); scorer quality is the bottleneck.

---

## Pattern Selection Guide

| Use Case | Pattern |
|----------|---------|
| Extraction, classification, RAG QA | Factual Q&A |
| Code, SQL, regex | Code Generation |
| Story, copy, brainstorming | Creative Writing |
| General chat assistant | Chat Assistant |
| Math, MCQ, exact-answer reasoning | Self-Consistency |
| Function-call args, must-parse JSON | Constrained Sampling |
| High-stakes offline generation | Best-of-N with Verifier |
