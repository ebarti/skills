# Prompting Fundamentals Rules

Practical rules for choosing prompt strategies, structuring system/user prompts, and managing context.

## Core Rules

### 1. Try Prompting Before Finetuning

Prompt engineering is the cheapest, fastest adaptation technique. Exhaust it before reaching for resource-intensive options.

- Start zero-shot, then add few-shot examples if needed
- Move to RAG if domain knowledge is missing
- Only finetune when prompting hits a clear ceiling

### 2. Default to Zero-Shot on Strong Models, Reach for Few-Shot When Needed

For GPT-4+ class models on common tasks, zero-shot is often enough. Add few-shot when domain is unfamiliar to the model or output format must be exact.

**Use zero-shot when**:
- Task is common (summarization, classification, Q&A)
- Model is strong (GPT-4, Claude Sonnet/Opus, Llama 3.1+)
- You want to minimize tokens / cost / latency

**Use few-shot when**:
- Task involves domain-specific APIs (e.g., Ibis dataframes, internal DSL) the model rarely saw in training
- Output must follow a strict, non-obvious format
- Edge cases need to be calibrated
- You're using a smaller / weaker model

### 3. Put the Task Description in the System Prompt

Application-developer instructions go in the system prompt. End-user input goes in the user prompt.

- Role assignment ("You are an experienced real estate agent")
- Output format constraints
- Tone and persona
- Safety and refusal rules

End-user data (questions, uploaded documents) goes in the user prompt.

### 4. Place Critical Instructions at the Beginning or End

Models attend best to the start and end of the prompt. The middle is a dead zone.

- Put the most important instruction at the very start (works for most models, including GPT-4)
- Repeat critical constraints at the end if the prompt is long
- Never bury the actual ask in the middle of a long context

**Exception**: Some models (e.g., Llama 3) perform better with the task description at the end. Test per model.

### 5. Match the Model's Chat Template Exactly

Wrong templates cause silent failures — the model produces plausible-but-wrong output. Always verify.

- Look up the template in the model's official docs
- Print the final assembled prompt before sending it the first time
- Verify any third-party prompt-construction tool uses the right template
- Watch for extra newlines, missing tokens, or wrong tag casing
- Re-check templates when you upgrade model versions (e.g., Llama 2 → Llama 3 changed template entirely)

### 6. Treat Context Length as a Budget

Maximum context is a hard cap on examples + instructions + retrieved context + user input + room for the response.

- Subtract expected output tokens from the limit before budgeting input
- Trim few-shot examples that don't measurably improve outputs
- Compress retrieved chunks (summarize, dedupe) before injecting
- If a model's quality drops on long inputs, shorten the prompt — don't just rely on the advertised window

### 7. Test Robustness Before Shipping

Probe prompt sensitivity by running small perturbations. If outputs swing wildly, your prompt is brittle.

- Try `5` vs `five`, swapped capitalization, added/removed newlines
- Re-order the few-shot examples
- If results change a lot, either harden the prompt or pick a stronger model

### 8. Validate Long-Context Behavior with NIAH-Style Tests

Don't trust advertised context windows blindly. Run a needle-in-a-haystack test on your real prompts.

- Insert a known fact at varying depths (10%, 30%, 50%, 70%, 90%)
- Ask the model to retrieve it
- Use **private** facts so the model can't lean on training data
- If retrieval drops in the middle, restructure to put critical info at the ends

## Guidelines

Less strict recommendations:

- Experiment with more vs fewer examples — there is no universal optimal N
- For domain-specific use cases, few-shot often still beats zero-shot even on strong models
- Use stronger models when you can — robustness reduces the time you spend fiddling
- Treat prompt experiments with ML rigor: track, version, and evaluate them
- Start the prompt with the role/task description; end with the concrete ask

## Exceptions

When these rules may be relaxed:

- **Llama 3 and similar**: task description at the end may outperform task at the start. Always A/B test.
- **Single-turn classification**: system prompt is optional; you can put everything in the user prompt
- **Highly token-constrained calls**: drop few-shot first, then trim instructions before trimming context

## Quick Reference

| Rule | Summary |
|------|---------|
| Try prompting first | Cheaper than finetuning, often sufficient |
| Default zero-shot on strong models | Add shots only when needed |
| System = developer, user = end user | Split task description from task |
| Beginning/end placement | Avoid the middle for critical info |
| Match chat template | Wrong template fails silently |
| Budget context length | Subtract output tokens, compress aggressively |
| Test robustness | Perturb small things, check stability |
| NIAH-test long contexts | Use private facts, vary insertion depth |
