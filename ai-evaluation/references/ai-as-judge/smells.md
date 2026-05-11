# AI as a Judge Smells

Anti-patterns to watch for when designing or operating AI judges.

---

## J1: Criteria Ambiguity

**What it is**: Judge prompt asks for a quality (e.g., "good", "relevant", "faithful") without defining what those mean.

**How to detect**:
- Prompt contains undefined adjectives ("good", "high quality", "accurate")
- No scoring rubric tied to specific criteria
- Cannot answer "why did this get a 3 instead of a 4?"
- Different reviewers reading the prompt would score the same response differently

**Why it's bad**:
- Scores are not reproducible across runs or judges
- "Faithfulness" in MLflow, Ragas, and LlamaIndex are all different — never comparable
- Drift over time cannot be distinguished from genuine application change

**How to fix**:
- Define each criterion with a precise statement
- Anchor every score level (1, 2, 3, 4, 5) with a description
- Include a worked example for each level

---

## J2: Position Bias (First-Position Bias)

**What it is**: In pairwise comparison, judge favors whichever answer appears first regardless of quality.

**How to detect**:
- Single-shot pairwise verdicts
- Verdict flips when you swap A and B
- Aggregate win rate of "first option" significantly above 50%

**Why it's bad**:
- Inflates win rate of whichever model you list first
- Corrupts preference data used for alignment training
- Skews leaderboards

**How to fix**:
- Run each comparison twice with A/B swapped
- Treat disagreement after swap as a tie
- Use prompt structures that de-emphasize order (e.g., shuffle and present as "Option X" / "Option Y")

**Example**:
```python
# Smell - single direction
result = judge(q, candidate_a, candidate_b)

# Fixed - swap and require agreement
forward = judge(q, candidate_a, candidate_b)
reverse = judge(q, candidate_b, candidate_a)
winner = candidate_a if (forward == "A" and reverse == "B") else \
         candidate_b if (forward == "B" and reverse == "A") else "tie"
```

---

## J3: Verbosity Bias

**What it is**: Judge prefers longer answers regardless of correctness.

**How to detect**:
- Empirical: longer responses win even when factually wrong
- GPT-4 and Claude-1 documented to prefer ~100-word wrong answers over ~50-word correct ones
- Win rate correlates with response length

**Why it's bad**:
- Encourages model training/selection toward verbose generation
- Hides factual errors behind verbosity

**How to fix**:
- Add to criteria: "length is not a quality signal; penalize unjustified length"
- Normalize answer lengths before comparison (truncate to similar length)
- Use a stronger judge — bias decreases with model strength (GPT-4 less prone than GPT-3.5)

---

## J4: Self-Bias (Self-Preference)

**What it is**: A model rating its own outputs higher than equivalent outputs from other models.

**How to detect**:
- Same model used for generation and head-to-head judging
- Win rate of self vs equivalent competitor > 50% by a margin
- GPT-4 self-bias: +10% win rate; Claude-v1: +25%

**Why it's bad**:
- Inflated benchmark scores
- Invalid model selection / leaderboard rankings
- Reinforces own biases when used for self-improvement

**How to fix**:
- Use a different model family for judging than for generation
- For self-evaluation as a sanity check (not benchmarking), accept the bias as inherent to the use case
- Cross-validate with at least one external judge or human spot-check

---

## J5: Inconsistency

**What it is**: Same judge, same input, different scores across runs.

**How to detect**:
- Run the judge twice on the same input — scores differ
- temperature > 0 with no seed
- Reproducibility tests fail

**Why it's bad**:
- Cannot trust evaluation results
- Cannot detect application changes vs noise
- Aggregated metrics become statistically muddy

**How to fix**:
- Set temperature=0
- Set a fixed seed when the API supports it
- Add few-shot scored examples (Zheng et al.: GPT-4 consistency rose from 65% to 77.5%)
- Beware: high consistency does not imply high accuracy — the judge may consistently make the same mistake

---

## J6: Black-Box Judge

**What it is**: Using a hosted criterion or library function without seeing its prompt and model.

**How to detect**:
- Using `faithfulness()`, `relevance()`, etc. from a library without reading source
- Cannot answer "what model was queried?" or "what did the prompt look like?"
- Library upgrade silently changes scores

**Why it's bad**:
- Scores can drift between library versions
- Misattributing drift to your application
- Cannot reproduce evaluation conditions

**How to fix**:
- Read the prompt before adopting any built-in criterion
- Pin library versions in addition to model versions
- Prefer judges where you control the prompt

---

## J7: Wide Numerical Scoring

**What it is**: Asking the judge for fine-grained numbers (1–10, 1–100, or continuous 0.0–1.0).

**How to detect**:
- Prompt asks for "score from 1 to 10" or "between 0 and 1"
- Score histogram clusters around few values (e.g., judge always returns 7 or 8)

**Why it's bad**:
- LLMs are worse with numbers than text
- Wider ranges produce noisier, less discriminative scores
- Different runs sometimes hit different "magnet" numbers

**How to fix**:
- Switch to classification (good/bad, relevant/partial/irrelevant)
- If numerical needed, use 1–5 with anchored level definitions
- Reserve continuous scoring for genuine degree measurements (e.g., similarity)

---

## J8: Untracked Judge Versions

**What it is**: Treating the judge as a static utility while the model alias, prompt, or sampling params change underneath.

**How to detect**:
- Using model aliases like "gpt-4" or "claude-latest"
- Prompts edited without commit history
- "Improved coherence by 2%" with no record of the judge being unchanged

**Why it's bad**:
- Application metric changes are confounded with judge changes
- Different teams managing app and judge can each blame the other
- "Did we improve, or did the grader get more lenient?" becomes unanswerable

**How to fix**:
- Pin model version explicitly (no `-latest` aliases)
- Version the prompt template and store in source control
- Bump a `judge_version` field whenever model or prompt changes
- Alert downstream consumers on judge version changes

---

## Quick Detection Table

| ID | Smell | Key Indicator |
|----|-------|---------------|
| J1 | Criteria ambiguity | Vague criteria, no per-score definitions |
| J2 | Position bias | Verdict flips when A and B are swapped |
| J3 | Verbosity bias | Longer answers win regardless of correctness |
| J4 | Self-bias | Model judges its own output highly |
| J5 | Inconsistency | Same input → different scores across runs |
| J6 | Black-box judge | Cannot see model + prompt being used |
| J7 | Wide scoring | 1–10 / 0.0–1.0 ranges with sparse usage |
| J8 | Untracked versions | Model alias or unversioned prompt |
