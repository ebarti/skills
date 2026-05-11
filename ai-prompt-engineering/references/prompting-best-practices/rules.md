# Prompting Best Practices Rules

Actionable rules for writing effective prompts that work across model providers.

## Core Rules

### 1. Write Clear and Explicit Instructions

Remove ambiguity about what you want the model to do.

- Specify scoring scales (1-5 vs 1-10) and output ranges
- Tell the model what to do when uncertain (pick best answer vs "I don't know")
- If you observe unwanted behavior (e.g., fractional scores), update the prompt to forbid it
- Avoid model-specific hacks like "Q:" formatting or tip promises — they become outdated

**Example**:
```python
# Bad
prompt = "Score this essay."

# Good
prompt = """Score this essay on a scale of 1 to 5 (integers only).
If uncertain, pick the score closest to your best assessment.
Do not output fractional scores like 4.5."""
```

### 2. Ask the Model to Adopt a Persona

Use a persona when the perspective changes the answer.

- Useful for scoring, roleplay, simulations, audience-specific writing
- The persona should match the evaluation context (first-grade teacher for child essays)

### 3. Provide Examples

Show the model what good output looks like with input/output pairs.

- Especially useful for edge cases (fictional characters, sensitive topics)
- Choose token-efficient example formats when length matters
- Use `Input/Output:` only if needed; `chickpea --> edible` is shorter

### 4. Specify the Output Format

Tell the model exactly how to structure its response.

- Request concise output to reduce cost and latency
- Forbid preambles like "Based on the content..."
- For JSON, specify the keys and give examples
- Use end-of-prompt markers (e.g., `-->`) for structured tasks
- Choose markers unlikely to appear in inputs

**Example**:
```python
# Bad — no marker, model continues input pattern
prompt = "Label as edible or inedible.\npineapple pizza --> edible\nchicken"

# Good — marker tells model where output begins
prompt = "Label as edible or inedible.\npineapple pizza --> edible\nchicken -->"
```

### 5. Provide Sufficient Context

Include reference material the model needs to answer accurately.

- Inline context (paste the document) or use tools (RAG, web search)
- Context reduces hallucinations driven by gaps in internal knowledge
- For closed-context tasks, instruct: "answer using only the provided context"
- Ask the model to quote the supporting passage to nudge faithfulness

### 6. Break Complex Tasks Into Subtasks

Decompose multi-step tasks into chained prompts.

- Each subtask gets its own prompt (e.g., intent classification → response generation)
- Use cheaper models for simple steps, stronger models for hard ones
- Decomposition enables monitoring, debugging, parallelization
- Trade-off: more queries can increase user-perceived latency

### 7. Give the Model Time to Think (CoT)

Encourage step-by-step reasoning before the answer.

- Add "think step by step" or "explain your rationale" to the prompt
- Or specify the steps explicitly
- Or include a one-shot worked example
- Use self-critique to have the model check its own work
- Trade-off: increases latency and cost

### 8. Iterate on Your Prompts

Treat prompt engineering as an experimental loop.

- Each model has quirks — test the same prompt across models
- Read the model provider's prompting guide
- Use the model's playground to explore behavior
- Test systematically: version prompts, use experiment tracking, evaluate on held-out data
- A prompt that improves a subtask may worsen the whole system — evaluate end-to-end

### 9. Organize and Version Prompts

Separate prompts from code; treat them as versioned artifacts.

- Store prompts in a dedicated file (e.g., `prompts.py`) or `.prompt` files
- Wrap each prompt with metadata: model, endpoint, sampling params, schemas
- Use a prompt catalog so apps can pin different versions of the same prompt
- Avoid coupling prompt versions to code commits when reuse is needed

### 10. Be Cautious With Prompt Engineering Tools

Inspect what tools do under the hood before adopting them.

- Tools generate hidden API calls (e.g., 30 examples × 10 variants = 300 calls)
- Tool developers make mistakes (wrong templates, typos, token concatenation bugs)
- Tools can change behavior without warning
- Start by writing your own prompts; adopt tools only when justified

## Guidelines

- Prefer techniques proven across providers over model-specific tricks
- Default to CoT for reasoning tasks; default to plain prompts for simple lookups
- When prompts grow past ~500 tokens, consider decomposition
- Match marker style and example format to your token budget

## Exceptions

When these rules may be relaxed:

- **Trivial tasks**: A single sentence prompt is often enough; don't over-engineer
- **High-latency budgets**: Skip decomposition and CoT if user-perceived latency is critical and no intermediate UI exists
- **Single-app prompts**: Versioning via git is fine when no other application reuses the prompt

## Quick Reference

| Rule | Summary |
|------|---------|
| Clear instructions | Remove ambiguity; specify scales, formats, edge cases |
| Persona | Match the role to the evaluation context |
| Examples | Show input/output pairs for edge cases |
| Output format | Specify structure, kill preambles, use end markers |
| Sufficient context | Provide references; use RAG when needed |
| Decompose | Many small prompts beat one giant prompt |
| Time to think | Use CoT and self-critique for reasoning tasks |
| Iterate | Version prompts; test systematically |
| Organize | Separate prompts from code; use a catalog |
| Tools cautiously | Inspect generated prompts; track API calls |
