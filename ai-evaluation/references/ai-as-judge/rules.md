# AI as a Judge Rules

Guidelines for setting up, prompting, and operating AI judges reliably.

## Core Rules

### 1. Treat the judge as a system, not a model

A judge = model + prompt + sampling parameters. Changing any of them produces a different judge. Version everything together.

- Pin the model version (no "gpt-4-latest" aliases)
- Store the prompt in source control
- Pin sampling parameters (temperature, top_p, seed if available)

**Example**:
```python
# Bad - implicit dependencies, judge changes silently
score = client.messages.create(model="claude-opus", messages=[{"role": "user", "content": prompt}])

# Good - pinned, versioned, reproducible
JUDGE = {
    "model": "claude-opus-4-20250514",
    "prompt_version": "relevance-v3",
    "temperature": 0.0,
}
score = client.messages.create(
    model=JUDGE["model"],
    messages=[{"role": "user", "content": render_prompt(JUDGE["prompt_version"], ...)}],
    temperature=JUDGE["temperature"],
)
```

### 2. Prefer classification over numerical scoring

Language models handle text better than numbers.

- First choice: classification labels (relevant/irrelevant, good/bad)
- Second choice: discrete numerical, narrow range (1–5 typical)
- Avoid: continuous scores (0.0–1.0) unless you genuinely need a degree
- Avoid: wide discrete ranges (1–10, 1–100) — accuracy degrades

### 3. A judge prompt must specify three things

1. **Task** — what the model is evaluating (e.g., "evaluate relevance of generated answer to the question")
2. **Criteria** — detailed definition of what counts as good/bad. The more detailed, the better.
3. **Scoring system** — exact labels or numeric range, with the meaning of each value

### 4. Include scored examples in the prompt

Few-shot examples improve consistency. Show what a 1, 3, and 5 look like (and ideally why each got that score). Zheng et al. found this raises GPT-4 consistency from 65% to 77.5%.

Trade-off: more examples → longer prompts → higher cost (Zheng's prompt cost quadrupled).

### 5. Never trust a judge whose model and prompt you cannot see

Black-box judges from third-party tools may change underneath you. Score drift will be misattributed to your application.

- Read the underlying prompt before adopting any built-in criterion
- Forked tools' criteria (faithfulness in MLflow vs Ragas vs LlamaIndex) are not interchangeable

### 6. Mitigate position bias in pairwise comparison

AI judges have first-position bias. Mitigate by:

- Running each pair twice with order swapped, average or require agreement
- Or carefully crafted prompts that de-emphasize order

```python
def pairwise_judge(question, a, b):
    score_ab = judge(question, a, b)  # A first
    score_ba = judge(question, b, a)  # B first
    if score_ab == "A" and score_ba == "B":
        return "A"  # consistent across orderings
    if score_ab == "B" and score_ba == "A":
        return "B"
    return "tie"  # disagreed when swapped
```

### 7. Watch for verbosity and self-bias

- **Verbosity bias**: GPT-4 and Claude-1 prefer ~100-word incorrect answers over ~50-word correct ones. Normalize length or penalize unjustified length in the criteria.
- **Self-bias**: GPT-4 favored itself by +10% win rate; Claude-v1 by +25%. Do not use a model to evaluate itself in head-to-head benchmarks.

### 8. Use spot-checking to control cost in production

- Evaluating every response with a strong judge ~doubles API cost (or more with multiple criteria)
- Spot-check a subset (e.g., 1–10%) for quality monitoring
- Use full coverage only for safety-critical guardrails

## Guidelines

- Use stronger models for important judgments; cheaper models for high-volume monitoring
- Use a fast model in the request path, a stronger model async in the background
- For repeatable scoring, set temperature=0 and a fixed seed if the API supports it
- Have the judge produce a rationale alongside the score — useful for audits and debugging drift
- Specialized small judges (reward, preference, reference-based) often beat general-purpose for narrow criteria
- Always combine AI judges with at least one exact metric or human spot-check

## Exceptions

- **Sanity checks via self-evaluation**: self-bias is fine when the goal is "does the model itself think this is wrong?"
- **Latency-critical paths**: skip in-line judge evaluation; run async or sample offline
- **No reference data available**: AI judge may be the only automatic option — accept the noise and supplement with humans

## Quick Reference

| Rule | Summary |
|------|---------|
| Pin everything | Model + prompt + params are one unit; version together |
| Prefer classification | Labels > discrete numbers > continuous scores |
| Three-part prompt | Task + criteria + scoring system, all explicit |
| Add examples | Few-shot scored examples raise consistency |
| Black-box ban | If you can't see model and prompt, don't trust the score |
| Swap order | Run pairwise twice with order flipped |
| Mind verbosity | Long-but-wrong often beats short-but-right |
| Avoid self-judge | Self-bias inflates scores 10–25% |
| Spot-check | Sample responses to balance cost and confidence |
