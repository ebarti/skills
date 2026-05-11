# Prompting Fundamentals Examples

Concrete prompt examples for zero-shot vs few-shot, system vs user split, and context efficiency.

## Zero-Shot vs Few-Shot

### Zero-Shot (no examples)

```python
from anthropic import Anthropic

client = Anthropic()
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=200,
    messages=[{
        "role": "user",
        "content": (
            "Classify the sentiment of this review as POSITIVE, NEGATIVE, or NEUTRAL.\n\n"
            "Review: The shipping was slow but the product is great."
        ),
    }],
)
```

**Use when**: Common task, strong model, minimum tokens.

### Few-Shot (3 examples)

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=200,
    messages=[{
        "role": "user",
        "content": (
            "Classify the sentiment as POSITIVE, NEGATIVE, or MIXED.\n\n"
            "Review: I love the design but the battery dies fast.\nSentiment: MIXED\n\n"
            "Review: Best purchase of the year.\nSentiment: POSITIVE\n\n"
            "Review: Broke after one use, do not buy.\nSentiment: NEGATIVE\n\n"
            "Review: The shipping was slow but the product is great.\nSentiment:"
        ),
    }],
)
```

**Use when**: You need a non-obvious label (MIXED), strict format, or are working with a niche domain.

### Trade-offs

| Aspect | Zero-Shot | Few-Shot |
|--------|-----------|----------|
| Tokens / cost | Low | High (grows with N) |
| Format precision | Variable | Tight |
| Domain fit | Poor on niche APIs | Strong |
| Best for | Common tasks, strong models | Custom labels, niche domains, weak models |

## System Prompt vs User Prompt

### Bad: Everything in the User Prompt

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=500,
    messages=[{
        "role": "user",
        "content": (
            "You are an experienced real estate agent. Read disclosures carefully, "
            "answer succinctly and professionally.\n\n"
            f"Context: {disclosure_text}\n"
            "Question: Summarize the noise complaints, if any."
        ),
    }],
)
```

**Problems**:
- Role mixed with user data; hard to swap user input
- Misses post-training boost models give to system prompts
- Easier for users to hijack the role via injection

### Good: Role in System, Task in User

```python
SYSTEM_PROMPT = (
    "You are an experienced real estate agent. Your job is to read each disclosure "
    "carefully, fairly assess the condition of the property, and help your buyer "
    "understand the risks and opportunities. Answer succinctly and professionally."
)

response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=500,
    system=SYSTEM_PROMPT,
    messages=[{
        "role": "user",
        "content": (
            f"Context: {disclosure_text}\n"
            "Question: Summarize the noise complaints, if any."
        ),
    }],
)
```

**Why it works**:
- Role survives across user turns
- Model attends to system prompt with priority (instruction hierarchy)
- Dev-controlled rules vs user-controlled input is explicit; easier to defend

## Context Efficiency

### Bad: Critical Question Buried in the Middle

```python
prompt = (
    f"Here is the document:\n\n{long_document}\n\n"   # 80K tokens
    "What is the patient's blood type?\n\n"           # buried mid-prompt
    f"{more_filler}\n\nPlease answer accurately."     # 30K more tokens
)
```

**Problems**: Question sits in the model's worst attention zone (middle); the final "Please answer accurately" is too vague to anchor the model.

### Good: Critical Instruction at Start AND End

```python
QUESTION = "What is the patient's blood type?"

prompt = (
    f"Task: Answer using only the document below. If absent, reply 'Not found.'\n"
    f"Question: {QUESTION}\n\n"
    f"Document:\n{long_document}\n\n"
    f"Reminder: {QUESTION} Answer with just the blood type."
)
```

**Why it works**:
- Question at the start hits the strongest attention zone
- Repeated at the end to defeat the "lost in the middle" effect
- Document is sandwiched between two clear instruction blocks

### Bad vs Good: Few-Shot Sizing

```python
# Bad: 50 examples for a task GPT-4 handles zero-shot
examples = load_examples(n=50)

# Good: 3 diverse, calibrated examples covering edge cases
examples = load_examples(n=3)

block = "\n\n".join(f"Input: {ex['in']}\nOutput: {ex['out']}" for ex in examples)
prompt = f"{block}\n\nInput: {user_input}\nOutput:"
```

**Why minimum-effective wins**: 94% fewer prompt tokens; cheaper, faster, and easier to evaluate which example moves the needle. Long prompts can also degrade quality on long-context-weak models.

## Refactoring Walkthrough

### Before

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=300,
    messages=[{
        "role": "user",
        "content": (
            "Translate the following to French and act as a polite translator. "
            "Here are some texts I've gotten from various users today. Some are "
            "questions, some are statements. Be careful with idioms.\n\n"
            f"{user_text}\n\n"
            "Make sure your translation is accurate."
        ),
    }],
)
```

### After

```python
SYSTEM_PROMPT = (
    "You are a professional French translator. Translate the user's text to French. "
    "Preserve idiomatic meaning over literal wording. Output only the translation."
)

response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=300,
    system=SYSTEM_PROMPT,
    messages=[{"role": "user", "content": user_text}],
)
```

### Changes Made

1. Moved role and task description to system prompt — survives turns, model prioritizes it
2. Removed filler ("here are some texts...", "make sure...accurate") — wasted tokens, no behavior change
3. Added explicit output constraint ("Output only the translation") — narrows format, eases parsing
4. User prompt contains only user data — clean separation, easier to defend against injection
