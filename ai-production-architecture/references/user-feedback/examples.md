# User Feedback Examples

Concrete patterns for extracting, collecting, and analyzing AI user feedback.

## Extracting Conversational Feedback

### Detecting Error-Correction Signals

```python
import re

ERROR_CORRECTION_PATTERNS = [
    r"^\s*no[,.]", r"^\s*i\s*meant", r"^\s*actually[,.]",
    r"^\s*that'?s\s*not", r"^\s*wrong[,.]",
]
CONFIRMATION_REQUESTS = [
    r"are\s*you\s*sure", r"check\s*again",
    r"show\s*me\s*the\s*sources?", r"is\s*that\s*right",
]

def classify_followup(message: str) -> dict:
    """Extract implicit feedback from a follow-up user message."""
    text = message.lower().strip()
    return {
        "is_error_correction": any(re.search(p, text) for p in ERROR_CORRECTION_PATTERNS),
        "is_confirmation_request": any(re.search(p, text) for p in CONFIRMATION_REQUESTS),
        "starts_with_negation": text.startswith(("no,", "no.", "not ", "wrong")),
    }
```

### Conversation-Level Signals

```python
from dataclasses import dataclass

@dataclass
class ConversationSignals:
    early_terminated: bool
    edit_count: int
    regeneration_count: int
    turn_count: int
    distinct_token_ratio: float
    refusal_count: int
    deleted: bool

def detect_stuck_in_loop(s: ConversationSignals) -> bool:
    return s.turn_count > 10 and s.distinct_token_ratio < 0.2

def overall_sentiment_score(s: ConversationSignals) -> float:
    score = 1.0
    if s.early_terminated: score -= 0.4
    if s.deleted:          score -= 0.5
    score -= 0.1 * (s.edit_count + s.regeneration_count)
    score -= 0.05 * s.refusal_count
    return max(0.0, min(1.0, score))
```

### Preference Data from User Edits

```python
@dataclass
class PreferenceExample:
    query: str
    winning_response: str  # what user kept
    losing_response: str   # what model produced

def edit_to_preference(query, generated, user_edited):
    """User edits → preference finetuning data."""
    if generated.strip() == user_edited.strip():
        return None
    return PreferenceExample(query, user_edited, generated)
```

## UI Patterns

### Thumbs Up/Down with Context Capture

```python
from datetime import datetime

@dataclass
class FeedbackEvent:
    user_id: str
    response_id: str
    rating: int                       # +1 / -1
    context_consent: bool
    dialog_window: list[dict] | None  # only if consent
    timestamp: datetime

def submit_feedback(user_id, response_id, rating, dialog, consent):
    return FeedbackEvent(
        user_id, response_id, rating, consent,
        dialog[-10:] if consent else None, datetime.utcnow(),
    )
```

### Comparative Choice with Position Randomization

```python
import random

def render_comparison(response_a: str, response_b: str) -> dict:
    """Randomize position to mitigate position bias."""
    flip = random.random() < 0.5
    left, right = (response_a, response_b) if flip else (response_b, response_a)
    mapping = {"left": "A", "right": "B"} if flip else {"left": "B", "right": "A"}
    return {
        "left": left, "right": right, "mapping": mapping,
        "options": ["left", "right", "both_same", "dont_know"],
    }
```

### Midjourney-Style Multi-Signal Feedback

```python
# Upscale = strongest positive, variation = weak positive, regenerate = negative
def feedback_to_score(action: str) -> float:
    return {"upscale": 1.0, "variation": 0.5, "regenerate": -0.3}.get(action, 0.0)
```

## Bias Examples and Mitigations

### Detecting Leniency Bias

```python
def detect_leniency_bias(ratings: list[int]) -> dict:
    """Skewed-positive distribution flags leniency bias (Uber: avg 4.8/5)."""
    n = len(ratings)
    if n == 0: return {"biased": False}
    high_share = sum(1 for r in ratings if r >= 4) / n
    return {"biased": high_share > 0.85, "high_share": high_share}
```

### Reframed Rating Options (No Numbers)

```python
RATING_OPTIONS = [
    "Great experience.",
    "Pretty good.",
    "Nothing to complain about, nothing stellar.",
    "Could've been better.",
    "Don't show me this again.",
]  # Removes the "5-star or you fail" pressure that causes leniency bias.
```

### Position Bias Correction

```python
def adjust_for_position(click_rate, position, position_priors):
    """Discount clicks based on display position."""
    expected = position_priors.get(position, 1.0)
    return click_rate / expected if expected else click_rate
```

## Degenerate Feedback Loop Examples

### Bad: Pure Top-K (Filter Bubble)

```python
def recommend_bad(items, scores, k=10):
    # Top items get all clicks → ranked higher → more clicks. Loop.
    ranked = sorted(zip(items, scores), key=lambda x: -x[1])
    return [item for item, _ in ranked[:k]]
```

### Good: Inject Exploration

```python
import random

def recommend_with_exploration(items, scores, k=10, exploration_rate=0.1):
    """Reserve a slot for sampled items to break filter bubbles."""
    ranked = sorted(zip(items, scores), key=lambda x: -x[1])
    top = [item for item, _ in ranked[:k - 1]]
    explore_pool = [item for item, _ in ranked[k:]]  # below the fold
    if explore_pool and random.random() < exploration_rate:
        top.append(random.choice(explore_pool))
    else:
        top.append(ranked[k - 1][0])
    return top
```

### Sycophancy Test

```python
def test_sycophancy(model_call, prompts_with_user_view) -> float:
    """Same factual question, different stated user views.
    Non-sycophantic model gives the same answer regardless."""
    responses = [model_call(p) for p in prompts_with_user_view]
    agreement = sum(1 for r, p in zip(responses, prompts_with_user_view) if p["user_view"] in r)
    return agreement / len(responses)  # high = sycophantic
```

### Detecting Audience Drift

```python
def detect_audience_drift(t0_demo, t1_demo, threshold=0.2) -> bool:
    """Flag if user-base composition shifted beyond threshold."""
    return any(abs(t1_demo.get(c, 0.0) - s) > threshold for c, s in t0_demo.items())
```
