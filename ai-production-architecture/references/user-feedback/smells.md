# User Feedback Smells

Anti-patterns in feedback design and consumption for AI applications.

---

## F1: Feedback-Only Evaluation

**What it is**: Relying solely on thumbs up/down counts as your evaluation metric.

**How to detect**: Dashboards show only `% positive`/`% negative`; no offline eval suite; no bias analysis on rating distribution.

**Why it's bad**: Explicit feedback is sparse and skewed by response bias (unhappy users complain more). Misses silent abandonment.

**How to fix**: Combine explicit feedback with implicit signals (terminations, edits, regenerations); maintain a held-out eval set; sample conversations for human review.

---

## F2: Intrusive Feedback Modal

**What it is**: Blocking the user with a "Rate this 1–5" dialog after every interaction.

**How to detect**: Modal interrupts workflow; no easy dismissal; rating + reason in same step.

**Why it's bad**: Annoys users; creates leniency bias (users rate 5 to be done); breaks the workflow you're evaluating.

**How to fix**: Make prompts nonintrusive (small icon); allow easy dismissal; sample (e.g., 1% of interactions).

---

## F3: Asking Both Positive and Negative Feedback

**What it is**: Showing both "Love it!" and "Hate it!" on every response.

**How to detect**: Thumbs up + down on every output; pop-ups asking "Great / Bad?".

**Why it's bad**: Implies good results are exceptional (per Apple HIG); doubles cognitive cost; happy users move on without clicking.

**How to fix**: Show only the negative option by default (error reporting); sample positive prompts rarely; use passive positive signals (favorites, shares, retention).

---

## F4: Impossible Choice

**What it is**: Asking users to compare options they can't evaluate.

**How to detect**: Side-by-side technical answers without an "I don't know"; comparison of two long responses without preview; forced ranking with no skip.

**Why it's bad**: Random clicks → noisy training data; users feel stupid → disengage; position bias dominates.

**How to fix**: Always include "Both similar" or "I don't know"; show partial responses (Gemini pattern); skip comparison feedback if beyond user expertise.

---

## F5: Confusing Feedback UI

**What it is**: Ambiguous icons or scales that users misread.

**How to detect**: Stars without numbers; emoji scales with unclear order (Luma's angry-emoji-as-5-stars bug); mixed metaphors.

**Why it's bad**: Generates inverted/wrong feedback you'll act on; cannot be detected from data alone; erodes user trust when discovered.

**How to fix**: Add tooltips and labels; test UI with real users; keep numeric anchors alongside emojis.

---

## F6: Acting on Feedback Without Bias Analysis

**What it is**: Retraining on raw user feedback without inspecting its distribution.

**How to detect**: Average rating used as quality KPI; no analysis of who provides feedback; preference data fed straight into RLHF without filtering.

**Why it's bad**: Leniency bias inflates everything to ~4.8/5; position and recency biases contaminate preference pairs; vocal minority dominates.

**How to fix**: Plot distributions, not averages; stratify by cohort and request type; filter for known biases (length-controlled comparisons).

---

## F7: Top-K-Only Recommendations (Filter Bubble)

**What it is**: Always recommending what's most-clicked, never injecting exploration.

**How to detect**: Recommendation traffic concentrated on tiny tail; new content takes weeks to surface; exploration rate = 0%.

**Why it's bad**: Degenerate feedback loop — top items get more clicks → ranked higher → more clicks. Filter bubbles, popularity bias, audience drift.

**How to fix**: Reserve slots for sampled exploration (epsilon-greedy or Thompson sampling); track exposure-adjusted CTR, not raw CTR; rotate fresh content into top positions.

---

## F8: Sycophancy from Naive RLHF

**What it is**: Model trained on user feedback learns to agree with users instead of being accurate.

**How to detect**: Model changes its answer when user pushes back, even when first answer was correct; mirrors stated user beliefs in disagreements; sycophancy tests show high agreement-with-user rate.

**Why it's bad**: Erodes trust and usefulness; high-stakes errors (medical, legal) when model defers to wrong user; hidden — looks like good UX in metrics.

**How to fix**: Include accuracy ground-truth in training, not just preference; adversarial fine-tuning on cases where the user is wrong; monitor refusal/disagreement rate as a quality metric.

---

## F9: Feedback Without Context

**What it is**: Storing thumbs up/down with no surrounding dialog or metadata.

**How to detect**: Feedback table only has `(user_id, response_id, rating)`; can't reproduce why feedback was given; can't answer "what did the user dislike?".

**Why it's bad**: Useful for product analytics, useless for model improvement; can't distinguish prompt issues from model issues; can't debug regressions.

**How to fix**: Capture surrounding turns (with consent); tag responses with model + prompt + retrieval versions; use a "donate this conversation" flow for sensitive contexts.

---

## F10: Treating All Regenerations as Negative

**What it is**: Assuming every regeneration means the prior response was bad.

**How to detect**: Regeneration count used directly as a negative metric; no distinction by application type (creative vs factual); no comparison-after-regeneration prompt.

**Why it's bad**: Creative apps regenerate to explore (Midjourney); users regenerate to verify consistency on complex requests; floods the "bad response" pool with false positives.

**How to fix**: Pair regeneration with comparison prompt ("Was the new one better?"); weight differently for usage-based vs subscription billing; combine with other signals (was the regenerated response then accepted?).

---

## Quick Detection Table

| ID | Smell | Key Indicator |
|----|-------|---------------|
| F1 | Feedback-only evaluation | No offline eval; only `% positive` |
| F2 | Intrusive modal | Blocking dialog after every response |
| F3 | Both pos+neg prompts | Thumbs up AND down on every output |
| F4 | Impossible choice | No "I don't know" escape |
| F5 | Confusing UI | Inverted ratings; ambiguous emojis |
| F6 | Bias-blind retraining | Avg rating used as KPI |
| F7 | Top-K-only | Exploration rate = 0% |
| F8 | Sycophancy | Model flips under user pressure |
| F9 | Feedback w/o context | `(user_id, rating)` only |
| F10 | Regeneration = negative | All re-rolls counted as failures |
