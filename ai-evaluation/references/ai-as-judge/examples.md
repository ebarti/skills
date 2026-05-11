# AI as a Judge Examples

Concrete prompts, code, and bias illustrations for AI judges.

## Bad Examples

### Vague Pointwise Prompt

```python
prompt = f"""Given the following question and answer, evaluate how good the answer is.
Use the score from 1 to 5.
- 1 means very bad.
- 5 means very good.
Question: {question}
Answer: {answer}
Score:"""
```

**Problems**:
- "Good" is undefined — accuracy? helpfulness? tone?
- No examples for what 1, 3, or 5 looks like
- 1–5 numerical scoring works worse than classification
- No constraint on output format — model may emit "4/5" or "Four"

### Pairwise Without Order Mitigation

```python
prompt = f"""Given the following question and two answers, evaluate which answer is
better. Output A or B.
Question: {question}
A: {answer_a}
B: {answer_b}
The better answer is:"""
```

**Problems**:
- First-position bias: A wins more often regardless of quality
- No criteria — "better" by what measure?
- No tie option — judge forced to pick even when equal
- Single run, no order swap

### Black-Box Tool Trust

```python
from some_eval_lib import faithfulness
score = faithfulness(context=ctx, output=resp)  # what scale? what definition?
```

**Problems**:
- MLflow scores 1–5, Ragas 0/1, LlamaIndex YES/NO — not comparable
- Underlying prompt may change between library versions
- Score drift misattributed to your app changes

## Good Examples

### Well-Structured Pointwise Judge

```python
JUDGE_PROMPT = """Score relevance between a generated answer and the question
based on the ground truth, 1 to 5, with a reason.

- 1-2: Generated answer contradicts the ground truth.
- 3:   Partially correct but missing key information.
- 4:   Correct but less complete than the ground truth.
- 5:   Fully matches the ground truth.

Example:
Question: "Is the sky blue?"
Ground truth: "Yes, the sky is blue."
Generated: "No, the sky is not blue."
Score: 1   Reason: Contradicts the ground truth.

Question: {question}
Ground truth: {ground_truth}
Generated: {generated}

Respond as JSON: {{"score": <1-5>, "reason": "<brief>"}}"""
```

**Why it works**: Explicit task + criteria + scoring rubric (the three required parts), each level defined, worked example included, constrained JSON output.

### Order-Swapped Pairwise

```python
def pairwise_judge(client, question, a, b, model, prompt_template):
    """Run pairwise twice with order swapped; return winner only if consistent."""
    def judge_once(first, second):
        prompt = prompt_template.format(question=question, A=first, B=second)
        resp = client.messages.create(
            model=model, messages=[{"role": "user", "content": prompt}],
            temperature=0.0, max_tokens=10,
        )
        return resp.content[0].text.strip().upper()  # "A" or "B"

    forward, reverse = judge_once(a, b), judge_once(b, a)
    if forward == "A" and reverse == "B": return "a"
    if forward == "B" and reverse == "A": return "b"
    return "tie"  # disagreement = order bias detected
```

**Why it works**: Detects position bias by swap, treats disagreement as ties, pinned model + temperature=0 for reproducibility.

### Classification with Rationale

```python
JUDGE_PROMPT = """Classify the response as RELEVANT, PARTIALLY_RELEVANT, or IRRELEVANT.

RELEVANT: directly answers the question with accurate information.
PARTIALLY_RELEVANT: addresses the question but is incomplete or partially incorrect.
IRRELEVANT: does not address the question or contradicts known facts.

Question: {question}
Response: {response}

Output JSON: {{"label": "<RELEVANT|PARTIALLY_RELEVANT|IRRELEVANT>", "rationale": "<one sentence>"}}"""
```

**Why it works**: Classification (LLMs do best at this), each label defined, rationale aids auditing.

## Bias Examples

### Verbosity Bias

```
Question: "What is the capital of Australia?"

Response A (~50 words, correct): "The capital of Australia is Canberra,
chosen as a compromise between Sydney and Melbourne at federation in 1901,
serving as capital since 1927."

Response B (~100 words, incorrect): "Australia's capital is Sydney, the
country's largest city, famous for the Opera House and Harbour Bridge.
Sydney has historically served as the political and economic heart of the
nation, with proximity to business centers, airports, and financial markets,
making it the natural seat of federal government."
```

GPT-4 and Claude-1 tend to prefer B despite the factual error. Mitigation: add to criteria *"length is not a quality signal — penalize unjustified length"*.

### Self-Bias

Claude-v1 evaluating Claude-v1 vs GPT-4 outputs has been shown to favor itself by +25% win rate. GPT-4 favors itself by +10%. Lesson: do NOT use a model to judge head-to-head competitions involving itself.

### Position Bias (Single Run)

```
Run 1 (A=GPT, B=Claude): Judge picks A
Run 2 (A=Claude, B=GPT): Judge picks A again
```
The judge is picking position A, not the better answer. Always swap and check for agreement.

## Refactoring Walkthrough

### Before

```python
def evaluate(question, answer):
    prompt = f"Rate this answer 1-10: Q: {question} A: {answer}"
    return float(llm(prompt))
```

### After

```python
JUDGE_MODEL = "claude-opus-4-20250514"
JUDGE_PROMPT_VERSION = "v2"

JUDGE_PROMPT = """Classify the answer as CORRECT, PARTIAL, or INCORRECT.
Provide a one-sentence rationale.

CORRECT: directly and accurately answers the question.
PARTIAL: addresses the question but is incomplete or contains minor errors.
INCORRECT: does not answer or contains major factual errors.

Examples:
Q: "What is 2+2?" A: "4"          -> CORRECT
Q: "What is 2+2?" A: "Around 4."  -> PARTIAL
Q: "What is 2+2?" A: "5"          -> INCORRECT

Question: {question}
Answer: {answer}

Output JSON: {{"label": "<CORRECT|PARTIAL|INCORRECT>", "rationale": "<text>"}}"""

def evaluate(client, question, answer):
    resp = client.messages.create(
        model=JUDGE_MODEL,
        messages=[{"role": "user", "content": JUDGE_PROMPT.format(
            question=question, answer=answer)}],
        temperature=0.0, max_tokens=200,
    )
    return json.loads(resp.content[0].text)
```

### Changes Made

1. 1–10 numeric → 3-class classification (LLMs do better at classification)
2. Added explicit per-class criteria and few-shot examples
3. Pinned model and prompt versions; temperature=0 for reproducibility
4. Structured JSON output with rationale for auditing
