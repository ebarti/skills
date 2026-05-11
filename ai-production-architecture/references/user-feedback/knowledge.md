# User Feedback Knowledge

Core concepts for collecting, extracting, and leveraging user feedback in AI applications.

## Overview

User feedback is proprietary data and a competitive advantage in AI applications. It powers the data flywheel: feedback informs evaluation, drives model improvement, and enables personalization. Conversational interfaces enable new genres of feedback that go beyond traditional thumbs up/down.

## Key Concepts

### Explicit vs Implicit Feedback

**Explicit feedback**: Information users actively provide in response to feedback requests (thumbs up/down, star ratings, "Did we solve your problem?").
- Standard across applications, well understood
- Demands extra effort from users → sparse
- Suffers from response bias (unhappy users complain more)

**Implicit feedback**: Information inferred from user actions (purchasing a recommendation, regenerating a response, editing output).
- Application-dependent and limited only by imagination
- More abundant but noisier
- Requires user studies to interpret intent

### Conversational Feedback

Feedback blended into natural language dialogue. Users encourage good behaviors and correct errors the same way they would in daily conversations. Conveys both application performance and user preference.

**Three uses**:
- **Evaluation**: derive metrics to monitor the application
- **Development**: train future models or guide development
- **Personalization**: tune the application per user

### Natural Language Feedback Signals

Inferred from message content:

- **Early termination**: User stops generation, exits app, or leaves agent hanging
- **Error correction**: Follow-ups starting with "No, …" or "I meant, …"
- **Rephrase attempts**: Users try different wordings of the same request
- **Action correction**: "You should also check XYZ GitHub" (common in agentic flows)
- **Confirmation requests**: "Are you sure?", "Check again", "Show me the sources"
- **User edits**: Direct edits to generated outputs (strong signal + preference data)
- **Complaints**: Bot is wrong, irrelevant, toxic, lengthy, lacking detail
- **Sentiment**: General negative expressions like "Uggh"
- **Refusal rate**: Model saying "Sorry, I don't know" indicates user dissatisfaction

### Other Conversational Feedback (Action-based)

- **Regeneration**: User asks for new response (may signal dissatisfaction OR exploration)
- **Conversation organization**: Delete (negative), rename (title bad), share, bookmark
- **Conversation length**: Context-dependent (good for companions, bad for support)
- **Dialogue diversity**: Distinct token/topic count; low diversity may indicate stuck loop

### Preference Data from Edits

User edits create (query, winning, losing) tuples for preference finetuning:
- Original generated response = losing response
- Edited response = winning response

## Feedback Design Principles

### When to Collect

- **In the beginning**: Calibration (face ID, voice wake words, skill assessment) — keep optional unless necessary
- **When something bad happens**: Always allow error reporting, downvoting, regeneration
- **When model has low confidence**: Comparative choices for preference finetuning
- **For positive feedback**: Debated; Apple advises against it, but reveals high-impact features

### How to Collect

- Seamlessly integrate into workflow (Midjourney upscale/variation/regenerate, Copilot Tab acceptance)
- Easy to ignore, nonintrusive
- Provide incentives and explain how feedback is used
- Don't ask the impossible (no "choose between two options I don't understand")
- Add icons and tooltips for clarity

## Limitations

### Biases

- **Leniency bias**: Users rate more positively to avoid conflict or extra work
- **Randomness**: Users click randomly when not motivated to think (especially side-by-side)
- **Position bias**: First option clicked more often regardless of quality
- **Preference bias**: Length over accuracy, recency bias in comparisons

### Degenerate Feedback Loops

When predictions influence feedback, which influences the next model iteration, amplifying initial biases:

- **Exposure bias / popularity bias / filter bubbles**: Top-ranked items get more clicks → ranked higher
- **Audience drift**: Initial cat-photo lovers attract more cat lovers; product becomes unrecognizable
- **Sycophancy**: Models trained on user feedback present views matching the user's

## Terminology

| Term | Definition |
|------|------------|
| Data flywheel | Self-reinforcing loop where users → data → better models → more users |
| Inpainting | Letting users select a region and re-prompt to fix part of a generated image |
| Refusal rate | Frequency model declines to answer ("As an AI, I can't…") |
| Sycophancy | Model tells users what they want to hear vs what's accurate |
| Wake word | Phrase that activates a voice assistant ("Hey Google") |

## How It Relates To

- **Monitoring & observability**: Feedback signals feed metrics and alerts
- **Dataset engineering**: Feedback becomes training data via the data flywheel
- **Preference finetuning (RLHF/DPO)**: User edits and comparative votes are preference data
- **Privacy**: Feedback is user data; consent and PII handling required

## Common Misconceptions

- **Myth**: Thumbs up/down is enough for evaluating an AI product.
  **Reality**: Explicit feedback is sparse and biased; implicit conversational signals are more abundant.

- **Myth**: A regeneration always means the previous response was bad.
  **Reality**: Users may regenerate to explore options or verify consistency.

- **Myth**: Sharing a conversation is positive feedback.
  **Reality**: Some users share embarrassing failures; intent must be studied.

- **Myth**: More user feedback always improves the model.
  **Reality**: Indiscriminate use creates degenerate loops, audience drift, and sycophancy.
