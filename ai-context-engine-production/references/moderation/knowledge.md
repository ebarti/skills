# Moderation Knowledge

Core concepts and foundational understanding for the moderation gatekeeper in an enterprise-ready Context Engine.

## Overview

In generative AI, capability must always be paired with responsibility. The moderation layer is an automated content moderation shield that vets both user inputs (before execution) and AI outputs (before display) using a two-stage safety protocol. It wraps the Context Engine's reasoning core without altering it.

## Key Concepts

### Enterprise-Ready Context Engine

**Definition**: A Context Engine elevated for production by adding a critical safety layer that wraps the existing reasoning loop with pre- and post-moderation steps.

**Phases**:
- **Phase 0**: Data ingestion pipeline (unchanged)
- **Phase 1**: Pre-flight moderation and planning
- **Phase 2**: Execution with embedded moderation
- **Phase 3**: Post-flight moderation and finalization

**Key points**:
- Moderation does not modify the agents' core reasoning logic
- It functions as a protective wrapper around the engine
- Transforms a powerful prototype into a trustworthy enterprise asset

### The Deliberate Pace of a Reasoning Engine

**Definition**: Latency is a deliberate, transparent feature of multi-step reasoning, not a defect — "the slowness is the sound of the engine thinking."

**Why it matters**:
- A typical three-step plan triggers at least eight sequential API calls
- Total latency commonly exceeds 10 seconds (illustrative budget: ~10,700 ms)
- Pre- and post-flight moderation each add ~200 ms to the budget
- Predictability and security matter more than raw speed for enterprise use

### The Moderation Gatekeeper

**Definition**: A standalone helper function (`helper_moderate_content`) that encapsulates all interaction with the OpenAI Moderation API and returns a detailed report rather than a binary safe/unsafe flag.

**Returns three fields**:
- `flagged`: Boolean — `True` if any policy was violated
- `categories`: Per-harm-category Booleans (e.g., `hate`, `violence`)
- `scores`: Raw confidence scores per category (lower = safer)

### Two-Stage Moderation Protocol

**Definition**: The canonical pattern of running moderation twice — once on user input, once on AI output.

**Stages**:
1. **Pre-flight check**: User goal vetted before execution. If flagged, halt immediately.
2. **Post-flight check**: AI output screened before display. If flagged, redact and replace with safe message.

**Why both**:
- Pre-flight prevents harmful prompts from entering the engine
- Post-flight catches harmful generations even from benign inputs
- Together they create an end-to-end safety wrapper

### Integration into the Engine

**Definition**: The two-stage protocol is embedded in the central `execute_and_display` function via a toggleable `moderation_active` parameter, making the function the engine's central safety orchestrator.

**Behavior**:
- When `moderation_active=True`: both stages run, reports are printed
- When flagged at pre-flight: execution halts before any LLM cost
- When flagged at post-flight: output is replaced with a redaction notice

### When Moderation Should Activate

**Definition**: Moderation is a toggleable safeguard applied based on environment, audience, and risk tolerance.

**Defaults**:
- Production: always on for both stages
- Customer-facing flows: always on
- Internal dev/debug runs on trusted prompts: may be skipped to reduce cost/latency
- Compliance-regulated domains (legal, medical, finance): always on

## Terminology

| Term | Definition |
|------|------------|
| Gatekeeper | The `helper_moderate_content` function wrapping the Moderation API |
| Pre-flight check | Moderation applied to the user goal before planning |
| Post-flight check | Moderation applied to the AI output before display |
| Fail-safe | When the moderation API errors, treat the content as flagged |
| Redaction | Replacing flagged output with a standardized safe message |
| Moderation report | Dictionary of `flagged`, `categories`, and `scores` |
| Safety orchestrator | The upgraded `execute_and_display` function coordinating both checks |

## Harm Categories (OpenAI Moderation API)

| Category | Description |
|----------|-------------|
| `hate` | Pejorative or discriminatory views toward an identity group |
| `hate/threatening` | Direct threats of violence against a protected group |
| `harassment` | Abusive or threatening language targeting an individual |
| `harassment/threatening` | Direct threats of violence against an individual |
| `self-harm` | Encourages or instructs self-harm or suicide |
| `self-harm/intent` | User expresses clear intent to self-harm |
| `self-harm/instructions` | Provides instructions on how to self-harm |
| `sexual` | Content meant to arouse sexual excitement |
| `sexual/minors` | Sexual content involving a minor |
| `violence` | Glorifies or promotes violence or suffering |
| `violence/graphic` | Depicts death, violence, or severe injury graphically |

## How It Relates To

- **Sanitization (`helper_sanitize_input`)**: Sanitization filters injected instructions from retrieved text; moderation filters harmful content from user input and AI output. Both are needed.
- **Policy-driven control**: Moderation enforces a baseline; policy layers add domain-specific rules (e.g., legal profanity allowances).
- **Latency budget**: Each moderation call adds ~200 ms; budget for two calls per goal.

## Common Misconceptions

- **Myth**: Moderation is binary — content is either safe or unsafe.
  **Reality**: The API returns categories and confidence scores, enabling nuanced policy decisions.

- **Myth**: Moderating only user input is sufficient.
  **Reality**: AI models can generate harmful content even from benign prompts; output moderation is equally important.

- **Myth**: If the moderation API fails, default to allowing the content.
  **Reality**: Always fail safe — treat API errors as flagged content.

- **Myth**: Latency from moderation is wasted time.
  **Reality**: It is the cost of a trustworthy, auditable safety layer.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Gatekeeper | Helper that wraps the Moderation API and returns a structured report |
| Two-stage protocol | Run moderation on input AND output |
| Fail-safe | API error => treat as flagged |
| Redaction | Replace flagged output with a safe placeholder |
| Latency cost | ~200 ms per call, ~400 ms total per goal |
