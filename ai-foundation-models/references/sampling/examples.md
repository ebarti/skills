# Sampling Examples

Concrete examples of sampling parameters, structured-output approaches, and hallucination mitigation.

## Temperature Examples

### Two-Token Toy Example

Logits for tokens [A, B] = [1, 2].

| Temperature | P(A) | P(B) | Behavior |
|-------------|------|------|----------|
| 1.0 (default) | 0.27 | 0.73 | Picks B 73% of the time |
| 0.5 | 0.12 | 0.88 | Picks B 88% — distribution sharpened |
| 0.1 | ~0.00 | ~1.00 | Almost always picks B |
| 0 (argmax) | 0 | 1 | Always picks B |
| 2.0 | 0.38 | 0.62 | Distribution flattened — A more likely |

### Effect on a Real Prompt

Prompt: `My favorite color is`

```python
# T=0 -> "My favorite color is blue."
# T=0.7 -> "My favorite color is teal — calm and alive."
# T=1.5 -> "My favorite color is the hush of pre-dawn mist on still water."
```

## Top-k vs Top-p

```python
# Prompt: "Do you like music? Answer yes or no."
# top_k=50: 50 candidates considered; only 2 are sensible.
# top_p=0.9: dynamically narrows to {yes, no}.

# Prompt: "What's the meaning of life?"
# top_p=0.9: candidate set expands because probabilities are spread.
```

## Structured Outputs

### Approach 1: Prompting Only

```python
prompt = """Extract name and age. Return JSON with keys "name", "age" only.
Text: "Alice is 30 years old." """
client.responses.create(model="gpt-x", input=prompt, temperature=0)
# -> '{"name": "Alice", "age": 30}' — risk of invalid JSON, prose preamble.
```

### Approach 2: Prompting + Post-Processing

```python
import json, re

raw = client.responses.create(model="gpt-x", input=prompt, temperature=0).output_text
raw = re.sub(r"^```json|```$", "", raw.strip()).strip()
if not raw.endswith("}"):
    raw = raw + "}"  # close truncated JSON
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    data = None
```

LinkedIn raised valid YAML rate from 90% to 99.99% with similar small fixes.

### Approach 3: Test Time Compute (Retry Until Valid)

```python
def get_valid_json(prompt, max_attempts=5):
    for _ in range(max_attempts):
        out = client.responses.create(model="gpt-x", input=prompt, temperature=0.7).output_text
        try:
            return json.loads(out)
        except json.JSONDecodeError:
            continue
    return None
```

### Approach 4: Constrained Sampling (with `outlines`)

```python
import outlines
from pydantic import BaseModel

class Person(BaseModel):
    name: str
    age: int

model = outlines.models.transformers("meta-llama/Llama-3-8B")
generator = outlines.generate.json(model, Person)
person = generator("Alice is 30 years old.")  # always parses to Person
```

### Approach 5: Finetuning (Classifier Head)

```python
import torch.nn as nn

class ClassifierModel(nn.Module):
    def __init__(self, base, num_classes):
        super().__init__()
        self.encoder = base
        self.head = nn.Linear(base.hidden_size, num_classes)

    def forward(self, input_ids):
        h = self.encoder(input_ids).last_hidden_state[:, -1, :]
        return self.head(h)  # only valid classes possible
```

## Test Time Compute Examples

### Self-Consistency for Math

```python
from collections import Counter

def solve_math(problem, n_samples=8):
    answers = []
    for _ in range(n_samples):
        out = client.responses.create(
            model="gpt-x",
            input=f"Solve step-by-step. End with 'Answer: <number>'.\n{problem}",
            temperature=0.7,
        ).output_text
        match = re.search(r"Answer:\s*(-?\d+(?:\.\d+)?)", out)
        if match:
            answers.append(match.group(1))
    return Counter(answers).most_common(1)[0][0] if answers else None
```

Google used N=32 on Gemini/MMLU.

### Best-of-N via Avg Logprob

```python
response = client.completions.create(
    model="gpt-x", prompt=prompt, n=10, best_of=10,
)
```

### Latency Trick: First Valid Wins

```python
import asyncio

async def first_valid(prompt, n=3):
    tasks = [client.responses.create(model="gpt-x", input=prompt) for _ in range(n)]
    for coro in asyncio.as_completed(tasks):
        r = await coro
        if is_valid(r.output_text):
            return r.output_text
```

## Hallucination Examples

### Snowballing Hallucination

Prompt: image of a shampoo bottle + "List the ingredients on this product's label."

LLaVA-v1.5-7B response: "This is a bottle of milk. The ingredients are: milk, ..."

Misidentifies the object, then hallucinates ingredients consistent with the wrong assumption.

### Mitigation 1: Allow "I Don't Know"

```python
prompt = """Answer the question. If unsure, respond exactly: "Sorry, I don't know."
Question: Who founded the company Nimbletide in 2019?"""
```

### Mitigation 2: Cite Sources (RAG)

```python
prompt = """Answer using only the provided context. After each claim cite the
source like [source: doc_3]. If the context lacks the answer, say "Not found
in sources."

Context: {retrieved_chunks}
Question: {user_question}"""
```

### Mitigation 3: Self-Verification

```python
answer = generate_answer(question)
verify = f"""Question: {question}
Proposed answer: {answer}
Is this factually correct? Reply YES or NO with a brief reason."""
verdict = client.responses.create(model="gpt-x", input=verify, temperature=0).output_text
```

### Mitigation 4: Concise Responses

```python
# Verbose: "Tell me everything about Marie Curie." -> more room to fabricate.
# Concise: "In one sentence, what is Marie Curie best known for?" -> less surface.
```
