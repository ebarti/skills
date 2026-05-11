# Comparative Evaluation Rules

Guidelines for when to use comparative evaluation, how to handle its scaling and standardization issues, and how to translate its signals into actionable decisions.

## Core Rules

### 1. Use comparative eval only when preference is the right signal

Comparative evaluation works when the question is one of preference and the evaluator is qualified to have one.

- Use it for subjective qualities: tone, clarity, helpfulness, creative writing
- Do NOT use it for factual or correctness questions ("Is X linked to Y?")
- Do NOT use it when the user is asking the model because they don't know the answer (e.g., math help) — they cannot judge the better response

**Example**:
```python
# Bad - asking preference for a factual question
prompt = "Is there a link between cell phone radiation and brain tumors?"
# Showing two opposing answers and asking the user to pick teaches the wrong signal.

# Good - reserve comparative eval for preference-suitable tasks
prompt = "Rewrite this email to be more concise."
# Two rewrites side-by-side; user is qualified to judge which they prefer.
```

### 2. Allow ties

If both responses are equally good or equally bad, forcing a pick adds random noise to your ranking. Always include a tie option.

### 3. Do not confuse comparative evaluation with A/B testing

- A/B testing: one user sees one variant, you compare aggregate outcomes
- Comparative eval: one evaluator sees multiple variants at once and picks
- They serve different purposes; do not substitute one for the other

### 4. Pick a rating algorithm suited to your data

- **Bradley-Terry** — preferred default; insensitive to match order (Chatbot Arena's choice)
- **Elo** — sequential, sensitive to order of matches and evaluators; avoid if you batch-process matches
- **TrueSkill** — when you have multi-way comparisons, not just pairs

### 5. Treat ranking as a predictive problem

A ranking is "correct" only insofar as it predicts future match outcomes. Validate by holding out matches and checking predictive accuracy — there is no other ground truth.

### 6. Do not infer absolute capability from a ranking

A ranking tells you order, not quality. "B beats A 51% of the time" does not tell you how many of your customer support tickets B will resolve. Pair comparative eval with pointwise/task evaluation before swapping models in production.

## Guidelines

### Scalability

- Number of pairs grows quadratically — N models => N(N-1)/2 pairs. 57 models = 1,596 pairs
- LMSYS averaged ~153 comparisons per pair across 244K total matches; treat similar density as a floor for trustworthy signals
- Use **smart matching**: stop comparing pairs whose outcome is settled; allocate matches to pairs that reduce ranking uncertainty most
- Lean on transitivity to skip direct comparisons, but be skeptical — preference is not always transitive
- Adding a new model requires re-evaluating against existing models, which may shift the whole ranking
- Private models cannot use public leaderboards directly — you must run your own or pay for private evaluation

### Standardization & Quality Control

- Crowdsourced votes capture diversity but cannot enforce factual correctness — voters often prefer responses that *sound* better
- Filter prompts before ranking: remove trivial prompts ("hi", "hello") and brainteasers; LMSYS filters to "hard prompts" for its harder leaderboard
- Public leaderboards rarely simulate production setups (RAG, tools, system prompts) — their rankings may not match your application
- Trained evaluators (Scale-style) are higher quality but costly and produce far fewer matches
- In-product comparative eval (e.g., two code suggestions in the editor) gathers volume but adds noise from random clicks
- AI judges may beat random internet voters even if they trail trained experts

### Translating Comparative to Absolute

- A win-rate delta does not map linearly to task success — 1% win-rate change can be huge or trivial depending on the application
- Always measure absolute task metrics (resolution rate, accuracy, latency, cost) before swapping models
- For cost-benefit decisions (e.g., model B costs 2x model A), comparative eval alone is insufficient

## Exceptions

- **Models surpass human scoring ability**: When experts can't assign concrete scores, comparative may be the only viable human signal (per Llama 2 paper)
- **Training preference models**: Comparative data is the natural input format for RLHF reward models — use it even when correctness is mixed in, but curate carefully
- **Saturated benchmarks**: When pointwise benchmarks are pegged at 100%, comparative eval still discriminates between top models

## Quick Reference

| Rule | Summary |
|------|---------|
| Right signal | Use only when preference is appropriate and voter is qualified |
| Allow ties | Avoid forced random picks |
| Not A/B testing | Side-by-side, not aggregate variant comparison |
| Algorithm choice | Bradley-Terry for batch; Elo only if order matters |
| Predictive | Validate ranking on held-out matches |
| Not absolute | Pair with task metrics before production decisions |
| Scale smartly | Use uncertainty-reducing match selection |
| Filter prompts | Drop trivial/saturated prompts from ranking |
