# Comparative Evaluation Examples

Python examples showing how to set up matches, compute win rates, fit rating algorithms, and avoid common pitfalls.

## Match Data Structure

A match is a single comparison record. Build a list of these as your raw signal.

```python
from dataclasses import dataclass
from typing import Literal

@dataclass
class Match:
    prompt_id: str
    model_a: str
    model_b: str
    winner: Literal["a", "b", "tie"]   # always allow ties
    evaluator_id: str                  # human or AI judge
    timestamp: float
```

## Win Rate Computation

```python
from collections import defaultdict

def compute_win_rates(matches: list[Match]) -> dict[tuple[str, str], float]:
    """A's win rate vs B, ignoring ties (count ties as 0.5 each)."""
    wins = defaultdict(float)
    totals = defaultdict(int)
    for m in matches:
        pair = tuple(sorted([m.model_a, m.model_b]))
        totals[pair] += 1
        if m.winner == "tie":
            wins[(m.model_a, m.model_b)] += 0.5
            wins[(m.model_b, m.model_a)] += 0.5
        elif m.winner == "a":
            wins[(m.model_a, m.model_b)] += 1
        else:
            wins[(m.model_b, m.model_a)] += 1
    return {(a, b): wins[(a, b)] / totals[tuple(sorted([a, b]))]
            for (a, b) in wins}
```

## Bradley-Terry Rating (the Chatbot Arena choice)

Bradley-Terry assigns each model a strength score; P(A beats B) = strength_A / (strength_A + strength_B).

```python
import numpy as np
from scipy.optimize import minimize

def bradley_terry(matches: list[Match], models: list[str]) -> dict[str, float]:
    """Fit Bradley-Terry strengths via maximum likelihood."""
    idx = {m: i for i, m in enumerate(models)}
    n = len(models)

    def neg_log_lik(log_strengths):
        ll = 0.0
        for m in matches:
            if m.winner == "tie":
                continue
            i, j = idx[m.model_a], idx[m.model_b]
            si, sj = log_strengths[i], log_strengths[j]
            # P(a beats b) = sigmoid(si - sj)
            diff = si - sj if m.winner == "a" else sj - si
            ll += diff - np.logaddexp(0, diff)
        return -ll

    # Anchor model 0 at 0 to remove scale ambiguity
    x0 = np.zeros(n)
    res = minimize(neg_log_lik, x0, method="L-BFGS-B")
    scaled = 400 * (res.x - res.x[0]) + 1000   # Elo-like scaling
    return dict(zip(models, scaled))
```

## Bad Examples

### Forcing a winner with no tie option

```python
# Bad - forces a coin flip when responses are equally good
def vote(a_response, b_response):
    return "a" if random.random() < 0.5 else "b"   # noise contaminates ranking
```

**Problems**:
- Adds random noise to the rating algorithm
- Inflates apparent win rate variance
- Makes transitivity violations more likely

### Asking preference for a correctness question

```python
# Bad - factual question routed through preference voting
matches.append(Match(
    prompt_id="q_radiation",
    model_a="model_x",   # said "yes"
    model_b="model_y",   # said "no"
    winner="a",          # voter just guessed
    evaluator_id="user_42",
    timestamp=now(),
))
```

**Problems**:
- Voter cannot evaluate correctness — they are guessing
- Training a preference model on this signal teaches incorrect behavior
- Pollutes any downstream RLHF data

### Confusing comparative eval with A/B testing

```python
# Bad - calling A/B test results "comparative evaluation"
group_a_users = serve_model("model_a", users[:5000])
group_b_users = serve_model("model_b", users[5000:])
# These users never saw both outputs side-by-side; this is A/B, not comparative.
```

**Problems**:
- Different users, different prompts — not a controlled comparison
- Cannot fit Bradley-Terry / Elo on this data
- Conflating the two methods leads to wrong tooling choices

### Treating win rate as absolute capability

```python
# Bad - swapping models in production based on win rate alone
if win_rate("model_b", "model_a") > 0.51:
    deploy("model_b")
```

**Problems**:
- 51% win rate could mean huge or tiny improvement on actual tasks
- Ignores cost (model_b might be 2x more expensive)
- No measurement of resolution rate, accuracy, or latency

## Good Examples

### In-product comparison with tie + skip

```python
# Good - lets users abstain, allows ties, captures evaluator
def collect_vote(prompt_id, response_a, response_b, user_id):
    show_side_by_side(response_a, response_b)
    choice = ask("Which is better? [A / B / Tie / Skip]")
    if choice == "Skip":
        return None
    return Match(prompt_id, "model_a", "model_b", choice.lower(),
                 evaluator_id=user_id, timestamp=time.time())
```

**Why it works**:
- Skip option avoids forced random clicks
- Tie option avoids coin-flip noise
- Records evaluator for downstream noise filtering

### Smart match scheduling (uncertainty-reducing)

```python
# Good - sample matches that most reduce ranking uncertainty
def next_pair(strengths: dict[str, float], variances: dict[str, float]) -> tuple[str, str]:
    """Pick the pair with highest combined variance and closest strengths."""
    best, best_score = None, -1
    models = list(strengths)
    for i, a in enumerate(models):
        for b in models[i+1:]:
            closeness = 1 / (abs(strengths[a] - strengths[b]) + 1e-3)
            uncertainty = variances[a] + variances[b]
            score = closeness * uncertainty
            if score > best_score:
                best, best_score = (a, b), score
    return best
```

**Why it works**:
- Avoids burning matches on already-settled pairs (Arena's bottleneck)
- Concentrates evaluator effort where it shifts the ranking

### Pairing comparative with absolute task metrics

```python
# Good - ranks via Bradley-Terry but gates deployment on task success
ranking = bradley_terry(matches, models)
top = max(ranking, key=ranking.get)

resolution_rate = measure_on_holdout(top, customer_support_tickets)
cost_per_request = measure_cost(top)

if resolution_rate >= 0.70 and cost_per_request <= budget:
    deploy(top)
else:
    log_warning("Top of leaderboard fails absolute thresholds — keep current model")
```

**Why it works**:
- Uses comparative eval for ordering, absolute eval for the deployment decision
- Catches the "both models are bad" scenario the ranking cannot reveal
- Bakes cost into the swap decision

## Pitfall: Prompt Pollution

Among 33,000 LMSYS prompts, 180 were "hi"/"hello" (0.55%). Trivial prompts cannot discriminate models.

```python
# Good - filter trivial and saturated prompts before ranking
TRIVIAL_PATTERNS = {"hi", "hello", "hey", "hola", "test"}

def is_useful_prompt(prompt: str) -> bool:
    p = prompt.strip().lower().rstrip("!.?")
    return p not in TRIVIAL_PATTERNS and len(p.split()) > 3

filtered = [m for m in matches if is_useful_prompt(prompt_text[m.prompt_id])]
ranking = bradley_terry(filtered, models)
```

**Why it works**:
- Removes prompts every model handles equally
- Mirrors LMSYS's "hard prompts" leaderboard approach
- Improves discriminating power of the resulting ranking
