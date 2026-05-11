# Prompting Best Practices Examples

Concrete before/after prompt examples demonstrating each best practice.

## Bad Examples

### Ambiguous Scoring

```python
prompt = "Score this essay."
```

**Problems**:
- No scale specified (1-5? 1-10?)
- No guidance for uncertain cases
- May produce fractional or text scores

### No Persona for Subjective Task

```python
prompt = "Score this essay: 'I like chickens. Chickens are fluffy and they give tasty eggs.'"
# Model returns: 2/5
```

**Problems**:
- Without a persona, the model defaults to harsh adult standards
- A first-grade essay scored against a college rubric is unfair

### Edge Case Without Examples

```python
prompt = "Will Santa bring me presents on Christmas?"
# Model returns: "Santa Claus is a fictional character..."
```

**Problems**:
- The model breaks the magic for a child user
- No examples teach the bot how to handle fictional characters

### Missing End-of-Prompt Marker

```python
prompt = """Label the following item as edible or inedible.
pineapple pizza --> edible
cardboard --> inedible
chicken"""
# Model returns: "tacos --> edible"  (continues the input pattern!)
```

**Problems**:
- Without `-->`, model treats `chicken` as an incomplete input
- Output starts a new line of input rather than labeling

### Giant Monolithic Prompt

```python
prompt = """You are a customer support bot. Classify the request,
then if it's billing handle X, if it's tech support handle Y, if it's
account management handle Z, and respond appropriately. Also check for
abuse, spam, off-topic, and... [1500+ tokens]"""
```

**Problems**:
- Hard to debug which step failed
- Cannot parallelize or monitor intermediate outputs
- Model performance degrades as prompt grows

## Good Examples

### Clear Scoring Instructions

```python
prompt = """Score this essay from 1 to 5 (integers only, no decimals).
If uncertain, pick the closest integer score.
Output only the number, no explanation."""
```

**Why it works**:
- Scale is explicit
- Edge case (uncertainty) is handled
- Output format suppresses preamble

### Persona-Driven Scoring

```python
prompt = """You are a first-grade teacher grading essays.
Score this essay from 1 to 5 based on age-appropriate criteria:
'I like chickens. Chickens are fluffy and they give tasty eggs.'"""
# Model returns: 4/5
```

**Why it works**:
- Persona aligns scoring rubric with the audience
- Same essay receives a fair grade for the writer's level

### Few-Shot for Edge Cases

```python
prompt = """Q: Is the tooth fairy real?
A: Of course! Put your tooth under your pillow tonight. The tooth fairy might visit and leave you something.

Q: Will Santa bring me presents on Christmas?
A:"""
# Model returns: "Yes, absolutely! Santa loves to bring presents to kids who believe..."
```

**Why it works**:
- Example demonstrates desired tone for fictional characters
- The trailing `A:` marks where the model should write

### Token-Efficient Example Format

```python
# Verbose format: 38 tokens
prompt_v1 = """Label the following item as edible or inedible.
Input: chickpea
Output: edible
Input: box
Output: inedible
Input: pizza
Output:"""

# Compact format: 27 tokens (29% fewer)
prompt_v2 = """Label the following item as edible or inedible.
chickpea --> edible
box --> inedible
pizza -->"""
```

**Why it works**:
- Same task, fewer tokens
- `-->` is unlikely to appear in input data, so it makes a clean marker

### Decomposed Customer Support

```python
# Step 1: Intent classification
intent_prompt = """You will be provided with customer service queries.
Classify each query into a primary category and secondary category.
Output JSON with keys: primary, secondary.

Primary categories: Billing, Technical Support, Account Management, General Inquiry.
Billing secondary: Unsubscribe, Upgrade, ...
Technical Support secondary: Troubleshooting, ..."""

# Step 2: Response (one prompt per intent)
troubleshoot_prompt = """You are responding to a troubleshooting request.
Help the user by:
- Asking them to check all router cables are connected
- If issue persists, ask which router model
- After 5 minutes with no fix, output {"IT support requested"}
- If user goes off-topic, confirm and reclassify"""
```

**Why it works**:
- Each prompt has a single, focused job
- Cheaper model can handle classification; stronger model handles response
- Intermediate output (intent) can be monitored and debugged

### Zero-Shot Chain-of-Thought

```python
# Without CoT
prompt = "Which animal is faster: cats or dogs?"

# With zero-shot CoT
prompt = "Which animal is faster: cats or dogs? Think step by step before arriving at an answer."
```

**Why it works**:
- Single phrase ("think step by step") triggers more systematic reasoning
- Reduces hallucination on factual claims

### Scripted CoT

```python
prompt = """Which animal is faster: cats or dogs? Follow these steps:
1. Determine the speed of the fastest dog breed.
2. Determine the speed of the fastest cat breed.
3. Determine which one is faster."""
```

**Why it works**:
- Explicit steps remove ambiguity about what "thinking" means
- Each step is verifiable

### One-Shot CoT

```python
prompt = """Which animal is faster: sharks or dolphins?
1. The fastest shark breed is the shortfin mako shark, ~74 km/h.
2. The fastest dolphin breed is the common dolphin, ~60 km/h.
3. Conclusion: sharks are faster.

Which animal is faster: cats or dogs?"""
```

**Why it works**:
- The example shows the exact reasoning format expected
- Useful when zero-shot CoT produces inconsistent step structure

## Refactoring Walkthrough

### Before

```python
def grade_essay(essay):
    prompt = f"Grade this: {essay}"
    return llm(prompt)
```

### After

```python
# prompts.py — separated from code
GRADE_ESSAY_PROMPT = """You are a first-grade teacher grading student essays.
Score the following essay from 1 to 5 (integers only).

Criteria:
- 5: Clear ideas, complete sentences, age-appropriate vocabulary
- 1: Hard to understand, incomplete

Think step by step:
1. Identify the main idea.
2. Check sentence completeness.
3. Assess vocabulary level.
4. Output only the integer score, no preamble.

Essay: {essay}
Score:"""

# app.py
from prompts import GRADE_ESSAY_PROMPT

def grade_essay(essay):
    return llm(GRADE_ESSAY_PROMPT.format(essay=essay))
```

### Changes Made

1. **Persona added** ("first-grade teacher") — aligns scoring with audience
2. **Scale specified** (1-5 integers) — removes ambiguity
3. **Criteria included** — gives the model a rubric
4. **CoT steps added** — improves reasoning quality
5. **Output format constrained** ("integer only, no preamble") — clean for downstream
6. **End marker** (`Score:`) — tells model where to start
7. **Prompt extracted to `prompts.py`** — reusable, testable, versionable
