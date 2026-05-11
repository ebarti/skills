# Policy-Driven Control Patterns

Architectural patterns for wrapping a Context Engine inside an organizational policy boundary.

## Pattern: Policy-as-Outermost-Context

### Intent

Treat workshop-agreed organizational policy as the authoritative outermost context layer. Every engine call executes inside policy that the meta-controller deterministically enforces, so the engine never has to debate or infer organizational rules.

### When to Use

- The engine sits inside a regulated organization (Legal, HR, Compliance, finance, healthcare).
- Inputs blend legitimate and illegitimate content that the LLM cannot disambiguate from text alone.
- Policy must be explicit, auditable, and changeable without retraining or re-prompting the engine.
- Multiple business processes (email, chat, document review) must share one engine but enforce different policies.

### Structure

```
+---------------------------------------------------------+
|  Organizational Policy (Legal / HR / Compliance / IT)   |  <-- workshop-agreed
+---------------------------------------------------------+
|  Meta-Controller                                        |
|   - Input parsing                                       |
|   - Policy enforcement (deterministic)                  |
|   - Control deck assembly                               |
|   - Business logic execution (notifications, routing)   |
+---------------------------------------------------------+
|  Control Deck  (goal, config, moderation_active, ...)   |  <-- clean API
+---------------------------------------------------------+
|  Context Engine                                         |
|   - Non-deterministic reasoning only                    |
+---------------------------------------------------------+
```

### Example

A legal-assistant pipeline processing inbound emails:

1. Email arrives at the meta-controller (not the engine).
2. Meta-controller parses body, attachments, quoted regions.
3. Policy enforcement applies workshop rules: e.g., quoted legal evidence is exempt from profanity moderation; surrounding prose is not.
4. Meta-controller assembles a control deck — `{goal: "summarize_for_counsel", moderation_active: True, quoted_regions: [...]}` — and calls the engine.
5. Engine produces reasoning output.
6. Meta-controller runs post-checks, then either delivers the result or sends a rejection notification.

### Benefits

- **Auditable**: Every policy decision lives in code traceable to a workshop record.
- **Changeable**: Policy updates are deterministic edits to the meta-controller, not prompt re-engineering.
- **Reusable engine**: One Context Engine serves many business processes, each with its own meta-controller.
- **Clear separation of concerns**: Deterministic business rules outside; non-deterministic reasoning inside.
- **Aligned accountability**: Compliance/Legal own policy authorship; engineering owns enforcement code.

### Considerations

- Building a full meta-controller is itself a major project (the chapter notes it is beyond its own scope).
- Requires ongoing investment in workshops; policy is never "done."
- Ambiguous cases still need an explicit escalation path (human review).
- Avoid letting the meta-controller drift into doing reasoning — it must stay deterministic. Reasoning belongs in the engine.

---

## Pattern: Control Deck as the Engine's Only API

### Intent

Force every interaction with the Context Engine to go through a single, well-formed control deck assembled by the meta-controller, so the engine has no other surface area to be policy-violated through.

### When to Use

- The engine is shared across multiple business processes.
- You need a single chokepoint for policy enforcement and observability.

### Structure

```
business input -> meta-controller -> control deck -> Context Engine -> output
                                          ^
                                          |
                          (the only way in to the engine)
```

### Benefits

- One enforcement chokepoint.
- One observable surface for logging, tracing, evals.
- Engine stays reusable — its contract is the control deck shape, not any specific business process.

### Considerations

- The control-deck schema becomes a critical API; version it deliberately.
- Resist adding "back doors" for special cases — they erode the policy boundary.

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|---------------------|
| Need to enforce organizational rules around an LLM | Policy-as-Outermost-Context |
| Sharing one engine across many business processes | Control Deck as the Engine's Only API |
| Ambiguous content (legitimate + illegitimate blended) | Policy-as-Outermost-Context with explicit escalation path |
| Regulatory environment with auditing requirements | Policy-as-Outermost-Context (auditable code-level rules) |
