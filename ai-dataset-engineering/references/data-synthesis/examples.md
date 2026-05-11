# Data Synthesis Examples

Concrete Python examples for rule-based, AI-powered, and distillation-style synthesis.

## Rule-Based Synthesis

### Faker-Based Transaction Generation

```python
from faker import Faker
import random, uuid

fake = Faker()

def synthesize_transaction():
    return {
        "txn_id": str(uuid.uuid4()),
        "card_number": fake.credit_card_number(),
        "merchant": fake.company(),
        "amount": round(random.uniform(1.0, 5000.0), 2),
        "currency": random.choice(["USD", "EUR", "GBP"]),
        "timestamp": fake.date_time_this_year().isoformat(),
        "country": fake.country_code(),
    }

dataset = [synthesize_transaction() for _ in range(10_000)]
```

**Why it works**: No PII exposed, broad coverage via randomization, lets fraud pipelines bootstrap before real data access.

### Bias Mitigation and Perturbation

```python
SWAPS = {"she": "he", "her": "him", "he": "she", "nurse": "doctor", "mom": "dad"}

def gender_swap(sentence: str) -> str:
    return " ".join(SWAPS.get(t.lower(), t) for t in sentence.split())

def perturb_tokens(text: str, vocab: list[str], rate: float = 0.015) -> str:
    """Replace ~1.5% of tokens with random words (BERT-style)."""
    tokens = text.split()
    for i in random.sample(range(len(tokens)), max(1, int(len(tokens) * rate))):
        tokens[i] = random.choice(vocab)
    return " ".join(tokens)
```

## AI-Powered Instruction Synthesis

### Self-Instruct (Alpaca Pattern)

```python
from anthropic import Anthropic
client = Anthropic()

PROMPT_TEMPLATE = """Come up with a diverse task instruction.
Example tasks:
{seeds}

Generate a NEW task as JSON with keys: instruction, input, output."""

def self_instruct_round(seeds: list[dict], n: int = 20) -> list[dict]:
    seed_text = "\n\n".join(
        f"Instruction: {s['instruction']}\nInput: {s['input']}\nOutput: {s['output']}"
        for s in random.sample(seeds, k=8)
    )
    out = []
    for _ in range(n):
        resp = client.messages.create(
            model="claude-opus-4-7", max_tokens=1024,
            messages=[{"role": "user", "content": PROMPT_TEMPLATE.format(seeds=seed_text)}],
        )
        out.append(parse_json(resp.content[0].text))
    return out
```

### Topic Expansion (UltraChat Pattern)

```python
def synthesize_dialogue_dataset():
    topics = ask_llm("Generate 30 diverse topics about daily life.")
    dataset = []
    for topic in topics:
        for sub in ask_llm(f"Generate 30-50 subtopics for '{topic}'."):
            instr = ask_llm(f"Write a user question about: {sub}")
            resp = ask_llm(f"Answer: {instr}")
            dataset.append({"topic": topic, "instruction": instr, "response": resp})
    return dataset
```

### Reverse Instruction (Long Outputs)

```python
def reverse_instruction(long_content: str) -> dict:
    """Generate the instruction that would elicit existing high-quality content."""
    instruction = ask_llm(
        f"Given this high-quality response, write the instruction that would "
        f"elicit it.\n\nResponse:\n{long_content}\n\nInstruction:"
    )
    return {"instruction": instruction, "response": long_content}

training_data = [reverse_instruction(article) for article in load_wikipedia_articles()]
```

### Llama 3 Code Synthesis Pipeline

```python
def synthesize_code_examples():
    problems = ask_llm("Generate 100 diverse programming problems.")
    verified = []
    for problem in problems:
        for lang in ["python", "javascript", "rust"]:
            solution = ask_llm(
                f"Solve in {lang}. Apply good programming rules and CoT.\n{problem}"
            )
            tests = ask_llm(f"Write unit tests for this {lang} code:\n{solution}")
            for _ in range(3):
                lint_errs = run_linter(solution, lang)
                test_errs = run_tests(solution, tests, lang)
                if not lint_errs and not test_errs:
                    verified.append({"problem": problem, "lang": lang, "code": solution})
                    break
                solution = ask_llm(
                    f"Fix this code.\nProblem: {problem}\nCode: {solution}\n"
                    f"Lint: {lint_errs}\nTests: {test_errs}"
                )
    return verified
```

### Back-Translation Verification

```python
def verify_translation(src_en: str, tgt_lao: str) -> bool:
    back = translate(tgt_lao, source="lao", target="english")
    return embedding_similarity(src_en, back) > 0.85

def verify_code_explanation(code: str, explanation: str) -> bool:
    """Llama 3 pattern: regenerate code from explanation, compare."""
    regenerated = ask_llm(f"Write code for: {explanation}")
    return code_equivalent(code, regenerated)
```

### AI Judge with Order Swap (NVIDIA Pattern)

```python
def pick_winner(prompt: str, response_a: str, response_b: str) -> str | None:
    """Only accept a winner if AI judge agrees with order swapped."""
    judge = "Which is better? Reply 'A' or 'B'.\nPrompt: {p}\nA: {a}\nB: {b}"
    first = ask_llm(judge.format(p=prompt, a=response_a, b=response_b))
    swap = ask_llm(judge.format(p=prompt, a=response_b, b=response_a))
    if first == "A" and swap == "B":
        return response_a
    if first == "B" and swap == "A":
        return response_b
    return None  # Inconsistent - discard
```

## Distillation Examples

### Alpaca-Style Distillation

```python
# 1. Generate 52K instruction-response pairs from a large teacher
seed = load_self_instruct_seeds()  # 175 examples
synthetic = []
while len(synthetic) < 52_000:
    new = self_instruct_round(seed, n=100)
    synthetic.extend(filter_valid(new))

# 2. Finetune small student (Llama-7B) on teacher outputs
finetune(base_model="llama-7b", dataset=synthetic, method="full_finetune")
# Result: Alpaca - 4% the size of teacher with similar capability
```

### LoRA Adapter Distillation (BuzzFeed Pattern)

```python
synthetic = generate_with_teacher(model="text-davinci-003", prompts=production_prompts)
finetune(base_model="flan-t5-base", dataset=synthetic, method="lora", rank=16)
# Result: 80% inference cost reduction
```

## Self-Instruct Heuristic Filters

```python
def self_instruct_filters(example: dict, existing: list[dict]) -> bool:
    """Filters from Wang et al. (2022) Self-Instruct."""
    if any(rouge_l(example["instruction"], e["instruction"]) > 0.7 for e in existing):
        return False  # Repetitive
    if not 5 <= len(example["instruction"].split()) <= 150:
        return False  # Too short or long
    if example["output"] == example["input"]:
        return False  # Output is repetition of input
    return True
```
