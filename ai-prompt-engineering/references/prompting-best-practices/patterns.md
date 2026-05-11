# Prompting Best Practices Patterns

Reusable prompt patterns for common tasks.

## Pattern: Zero-Shot Chain-of-Thought

### Intent

Improve reasoning quality without providing worked examples.

### When to Use

- Math, logic, multi-step reasoning tasks
- Tasks where hallucination needs to be reduced
- When token budget doesn't allow few-shot examples

### Structure

```python
prompt = f"""{question}

Think step by step before arriving at an answer."""
```

### Example

```python
prompt = """Which animal is faster: cats or dogs?

Think step by step before arriving at an answer."""
```

### Benefits

- Single-phrase intervention with measurable accuracy gains
- Works across model sizes (LaMDA, GPT-3, PaLM and beyond)
- Reduces hallucinations

### Considerations

- Increases output length, latency, and cost
- Quality of reasoning depends on the model — small models may produce shallow steps

---

## Pattern: Scripted Chain-of-Thought

### Intent

Force the model to follow a specific reasoning sequence.

### When to Use

- The reasoning steps are known and consistent
- You need each intermediate step to be verifiable
- Zero-shot CoT produces inconsistent step structure

### Structure

```python
prompt = f"""{question}

Follow these steps to find an answer:
1. {step_1}
2. {step_2}
3. {step_3}"""
```

### Example

```python
prompt = """Which animal is faster: cats or dogs?
Follow these steps to find an answer:
1. Determine the speed of the fastest dog breed.
2. Determine the speed of the fastest cat breed.
3. Determine which one is faster."""
```

### Benefits

- Predictable output structure
- Each step can be evaluated independently
- Useful for compliance and auditing

### Considerations

- Less flexible than zero-shot CoT
- Requires you to know the right steps in advance

---

## Pattern: One-Shot CoT

### Intent

Demonstrate the exact reasoning format with a single worked example.

### When to Use

- Format consistency matters (e.g., for downstream parsing)
- Zero-shot CoT produces inconsistent structure
- Token budget allows one example

### Structure

```python
prompt = f"""{example_question}
{example_step_1}
{example_step_2}
{example_conclusion}

{actual_question}"""
```

### Benefits

- Strong format conformance
- Less verbose than full few-shot

### Considerations

- Adds tokens compared to zero-shot
- The example must be representative of the actual task

---

## Pattern: Self-Critique

### Intent

Have the model evaluate and improve its own response.

### When to Use

- Tasks where quality matters more than speed
- When you need an extra check on factual claims
- As a poor-man's evaluator before adding human review

### Structure

```python
# Two-pass implementation
draft = llm(f"Answer: {question}")
final = llm(f"""Original answer: {draft}

Critique this answer for accuracy, clarity, and completeness.
Then provide an improved final answer.""")
```

### Benefits

- Catches errors the model would otherwise commit
- Pairs well with CoT for reasoning tasks

### Considerations

- Doubles (or more) the API calls and latency
- The model may critique cosmetically without finding real issues

---

## Pattern: Task Decomposition / Prompt Chaining

### Intent

Replace one large prompt with a chain of smaller, focused prompts.

### When to Use

- Tasks with multiple distinct steps (e.g., classify → respond)
- Prompts growing past 500-1500 tokens
- You need to monitor or debug intermediate outputs
- Different steps benefit from different model tiers

### Structure

```python
def chain(input_data):
    intermediate = llm_cheap(prompt_step_1.format(input=input_data))
    final = llm_strong(prompt_step_2.format(input=input_data, hint=intermediate))
    return final
```

### Example: Customer Support

```python
# Step 1 — cheap model classifies intent
intent = llm_haiku(INTENT_PROMPT.format(query=query))

# Step 2 — strong model uses intent-specific prompt
response_prompt = INTENT_PROMPTS[intent["primary"]]
return llm_sonnet(response_prompt.format(query=query))
```

### Benefits

- Each step is simple, easier to write and debug
- Mix cheap and strong models per step
- Monitor and parallelize independent steps

### Considerations

- More API calls (though smaller prompts often cost less per call)
- Increased user-perceived latency for sequential chains
- More moving parts means more places for bugs

---

## Pattern: Few-Shot With End Marker

### Intent

Teach the model the desired output format using examples and a clear marker for where to begin.

### When to Use

- Classification, labeling, structured output tasks
- When output should match a specific format

### Structure

```python
prompt = f"""{instruction}
{example_input_1} {marker} {example_output_1}
{example_input_2} {marker} {example_output_2}
{actual_input} {marker}"""
```

### Example

```python
prompt = """Label the following item as edible or inedible.
chickpea --> edible
box --> inedible
pizza -->"""
```

### Benefits

- Token-efficient compared to verbose `Input/Output:` format
- End marker prevents the model from continuing the input pattern

### Considerations

- Marker must not appear in inputs (avoid common symbols)
- Few-shot examples consume input tokens

---

## Pattern: Restrict to Provided Context

### Intent

Force the model to answer only from a given corpus, not from internal knowledge.

### When to Use

- Roleplay simulations (e.g., a Skyrim character shouldn't know Starbucks)
- Faithful question answering against a document
- Reducing hallucinations in RAG pipelines

### Structure

```python
prompt = f"""You may only use information from the provided context.
If the answer is not in the context, respond "I don't know."
Quote the supporting passage in your answer.

Context:
{context}

Question: {question}"""
```

### Benefits

- Reduces hallucination
- Quoting nudges faithfulness

### Considerations

- Prompting alone doesn't guarantee restriction
- Pretraining knowledge can still leak; for hard guarantees, finetune or train from scratch

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|-------------------|
| Math or multi-step reasoning | Zero-Shot CoT or Scripted CoT |
| Need format consistency | One-Shot CoT or Few-Shot With End Marker |
| Quality > speed | Self-Critique |
| Long monolithic prompt | Task Decomposition |
| Mixed hard/easy steps | Decomposition with mixed model tiers |
| Document QA | Restrict to Provided Context |
| Classification | Few-Shot With End Marker |
