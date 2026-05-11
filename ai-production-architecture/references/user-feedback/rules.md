# User Feedback Rules

Guidelines for collecting, extracting, and acting on user feedback in AI applications.

## Core Rules

### 1. Always Allow Error Reporting

Users must be able to flag bad outputs (hallucinations, blocked legitimate requests, slow responses) at any time.

- Provide downvote, regenerate, or model-switch options
- Let users still complete their task even when AI fails (edit, fall back to human)
- For agentic flows, accept conversational corrections like "You should also check X"

### 2. Make Feedback Nonintrusive

Feedback collection should integrate into workflow, not interrupt it.

- Easy to ignore, easy to give
- No blocking modals
- Tab-to-accept (Copilot pattern) over explicit prompts when possible

### 3. Don't Ask Users for Impossible Judgments

Never force users to compare options they cannot evaluate.

- Add an "I don't know" option for comparative evaluation
- Use icons/tooltips to clarify ambiguous choices
- Test feedback UIs with real users before shipping

**Example**:
```python
# Bad: forces a decision the user can't make
options = ["Response A (technical)", "Response B (technical)"]

# Good: let user opt out
options = ["Response A is better", "Response B is better", "Both look the same / I don't know"]
```

### 4. Track Implicit Conversational Signals

Don't rely solely on explicit feedback — extract signals from natural conversation.

- Early termination, error-correction phrases ("No, ...", "I meant, ...")
- User edits to generated content (strong negative + preference data)
- Regeneration count, conversation length, dialogue diversity
- Sentiment and refusal-rate trends

### 5. Study Why Users Take Each Action

Don't assume the meaning of an implicit signal — validate with user studies.

- Sharing can be positive (useful) or negative (embarrassing)
- Long conversations are good for companions, bad for support
- Combine multiple signals to disambiguate intent

### 6. Avoid Mixing Positive and Negative Feedback Prompts

Per Apple's HIG, don't ask for both — implies good results are exceptional.

- If you must collect positive signals, sample (e.g., show prompt to 1% of users)
- Prefer passive positive signals (favoriting, sharing, repeated use)

### 7. Get Explicit Consent for Context Capture

Thumbs up/down alone is product analytics — deeper analysis needs the surrounding dialogue.

- Service agreements should cover analytics and improvement use
- For sensitive contexts, use a "donate this conversation" flow
- Reassure users about model-training opt-outs (only if true)

### 8. Inspect Feedback for Biases

Always analyze the distribution of ratings before acting on them.

- Check for leniency bias (everyone rates 5/5)
- Randomize position to detect position bias
- Compare feedback distribution against ground truth periodically

### 9. Guard Against Degenerate Feedback Loops

Don't blindly retrain on user feedback — it can amplify initial biases.

- Inject exploration (don't only show top-ranked items)
- Monitor for audience drift (user base demographic changes)
- Test for sycophancy (does the model agree with everything?)
- Hold out a portion of recommendations for randomized testing

### 10. Treat Feedback as User Data

User feedback is subject to all data-handling rules.

- Respect privacy laws (GDPR, CCPA)
- Allow users to view, export, and delete their feedback
- Be explicit about how feedback is used (analytics, personalization, training)

## Guidelines

- Use lighter colors for AI suggestions (Copilot pattern) so accept/reject is implicit
- Show partial responses for side-by-side comparison to reduce cognitive load (Gemini pattern)
- Prefer multiple weak signals combined over a single strong signal
- For low-confidence outputs, ask the user — don't guess

## Exceptions

- **Calibration applications** (face ID, voice biometric setup): explicit feedback IS required upfront
- **Creative regeneration** (Midjourney): regeneration may be exploration, not dissatisfaction
- **High-stakes domains** (medical, legal): always require explicit confirmation, accept latency cost

## Quick Reference

| Rule | Summary |
|------|---------|
| Error reporting | Always available, never blocked |
| Nonintrusive | Integrate; easy to ignore |
| Implicit signals | Track edits, terminations, rephrasing |
| Position bias | Randomize positions of suggestions |
| Degenerate loops | Inject exploration; monitor drift |
| Consent | Explicit terms for context capture |
| Side-by-side | Provide "I don't know" escape hatch |
