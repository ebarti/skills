# Evaluation Pipeline Rules

Rules for building, operating, and iterating an AI evaluation pipeline (3 steps).

## Step 1 Rules: Evaluate All Components

### 1. Score every intermediate output independently

If a system has N steps, you need N+1 scores (one per step plus end-to-end). You cannot localize failures otherwise.

- Pick a method appropriate to each step (similarity for extraction, accuracy for classification).
- For the resume example: text-similarity for PDF->text, accuracy for text->employer.

### 2. Evaluate per turn AND per task when applicable

Turn-based scores quality of one output; task-based scores whether the user goal was achieved and in how many turns.

- Two turns vs twenty turns to fix a bug is a major UX difference.
- Task-based is more important but requires defining task boundaries explicitly.

### 3. A turn can include multiple internal steps

Do not collapse multi-step internal reasoning into multiple turns; a turn is one user-visible exchange.

## Step 2 Rules: Create Evaluation Guidelines

### 4. Define what the app should NOT do

Out-of-scope inputs need detection logic and a defined response (e.g., support chatbot refusing election questions).

### 5. Derive criteria from real user queries

Generate multiple responses per test query (manual or AI), label them good/bad, then extract the dimensions that mattered.

- Average application uses ~2.3 criteria (LangChain State of AI 2023).
- Common criteria: relevance, factual consistency, safety.

### 6. Build a scoring rubric with worked examples

For each criterion choose a scale (binary, 1-5, 0-1, ternary -1/0/1) and show what each score looks like.

- Validate the rubric with multiple humans.
- If humans disagree or cannot follow it, refine until unambiguous.
- Reuse the rubric for training data annotation later.

### 7. Tie eval metrics to business metrics

Map score ranges to business outcomes (automation %, revenue, stickiness). Define a usefulness threshold.

- Understand business metrics BEFORE choosing eval metrics.
- Be aware: stickiness/engagement focus can incentivize addictive or extreme behavior.

## Step 3 Rules: Methods and Data

### 8. Match the method to the criterion

Different criteria need different tools: toxicity classifier for safety, semantic similarity for relevance, AI judge for factual consistency.

### 9. Mix cheap and expensive methods

Layer a cheap classifier on 100% of data with an expensive AI judge on 1% to balance cost and confidence.

### 10. Use logprobs when available

Logprobs reveal model confidence (uniform 30-40% across classes = uncertain; 95% on one = confident). Also enables perplexity for fluency/factuality.

### 11. Keep humans in the loop

Automate as much as possible but use human experts as the North Star, even in production. LinkedIn manually evaluates up to 500 daily conversations.

### 12. Plan for production, not just experimentation

Reference data is unavailable in production; design for user feedback collection and correlation with offline metrics.

### 13. Use real production data for annotation

If natural labels exist, use them. Otherwise label with humans or AI. The annotation guide doubles as finetuning instruction data.

### 14. Slice your data

Always report per-slice metrics to avoid Simpson's paradox and uncover bias. Slice by tier, traffic source, length, topic, format, error patterns.

### 15. Maintain multiple evaluation sets

At minimum: production-distribution set, known-failure set, common-user-error set (e.g., typos), out-of-scope set.

### 16. Size evaluation sets via bootstrap

Resample with replacement; if results swing wildly, you need more data.

- 30% difference detection: ~10 samples
- 10%: ~100; 3%: ~1,000; 1%: ~10,000
- Every 3x decrease in difference -> 10x more samples
- Inverse Scaling prize minimum: 300; preferred: 1,000+

### 17. Evaluate the evaluation pipeline

Ask: Are signals correct? Is it reproducible? Are metrics correlated? What latency/cost does it add?

- AI judge temperature MUST be 0 for reproducibility.
- Two perfectly-correlated metrics: drop one. Two uncorrelated metrics: insight or untrustworthy.

### 18. Iterate, but track everything

Log every variable that can change: eval data, rubric, AI judge prompt, sampling config. Without experiment tracking you cannot trust trend lines.

## Guidelines

- "If you care about something, put a test set on it."
- A correct response is not always a good response.
- Do not skip evaluation in production to save latency.
- Reuse evaluation annotation guidelines as finetuning instruction guides.

## Exceptions

- **Closed-ended tasks**: Can use a simpler pipeline; this chapter targets open-ended.
- **Rapid prototypes**: Lightweight rubric is acceptable; harden before production.
- **No reference data in production**: Substitute user feedback + sampled human eval.

## Quick Reference

| Rule | Summary |
|------|---------|
| Component eval | Score every step independently |
| Turn vs task | Both when conversation spans turns |
| Criteria | Derived from labeled real user queries |
| Rubric | Scale + worked examples + human validation |
| Business tie | Map scores to automation/revenue/stickiness |
| Methods | Match to criterion; mix cheap + expensive |
| Logprobs | Use them for confidence and perplexity |
| Slicing | Always; prevents Simpson's paradox |
| Bootstrap | Sizing test for eval set adequacy |
| AI judge T | Temperature = 0 always |
| Tracking | Log eval data, rubric, prompt, sampling |
