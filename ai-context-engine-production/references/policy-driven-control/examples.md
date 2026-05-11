# Policy-Driven Control Examples

Concrete illustrations from the chapter, with the exact wording of each principle preserved as verbatim quotes.

## Verbatim Principles

### Principle 1 (verbatim)

> *A stochastic non-deterministic AI system is only as good as the engineers who can continually adapt it to the reality factors of the real world.*

### Principle 3 (verbatim)

> *A new era context engineer takes not only the context of the Context Engine into account, but also the context of the environment and organization it is integrated in.*

### Principle 4 (verbatim)

> *Only business practices agreed upon in real-world workshops will solve the issue.*

### Principle 5 (verbatim, on the AI's role)

> The AI's role isn't to debate the nuances of that policy: it's to **enforce it with perfect fidelity.**

## The Mixed-Profanity Email Case

### The input that breaks naive moderation

```
"Hey John, read this [profanity] by this [profanity] that says [profanity] this [profanity] racist stuff: On June 7, 2024, Mr Jones called his boss a [profanity] and a [profanity] and [profanity][profanity][profanity][profanity] …"
```

This single email contains both:
- A legitimate quote from witness testimony (acceptable evidence).
- Illegitimate profanity in the surrounding text (a policy violation).

### Why naive solutions fail

- A simple moderation filter blocks the whole email, losing legitimate testimony.
- A dynamic redaction function over-redacts the quoted evidence.
- Disabling moderation lets policy-violating prose through.
- Enabling moderation only for emails breaks important messages.

> The knowledge required to make the right judgment isn't in the text itself. It is an external, organizational rule.

### What actually fixes it

A workshop-agreed corporate regulation that defines, deterministically:
- What counts as a "quoted legal source" (e.g., delimited by specific markers).
- What moderation applies inside vs. outside that quoted region.
- What the meta-controller does on bypass-phrase detection.

The meta-controller then encodes the rule and assembles a control deck the engine can consume.

## Real-World Symptoms That Triggered the Rethink

From the chapter's "unpleasant surprises" list:

- Moderation blocked witness testimony because it contained profanity.
- Moderation blocked an internal meeting transcript after someone lost their temper for a minute.
- Setting `moderation=False` let profanity slip through in emails.
- Enabling moderation only for emails caused important messages to stop getting through.

Each of these is a *reality factor* that pure technical solutions cannot resolve — only policy can.

## Meta-Controller Responsibilities (from the chapter)

The chapter does not provide pseudocode, but enumerates the meta-controller's distinct responsibilities. Treat this as the conceptual structure to implement:

```
meta_controller(raw_input):
    # 1. Input parsing
    parsed = separate_email_body_and_attachments(raw_input)

    # 2. Policy enforcement
    #    - workshop-agreed rules from Legal / HR / IT
    #    - bypass-phrase checks, quoted-section handling, etc.
    policy_decision = enforce_policy(parsed)

    if policy_decision.rejected:
        # 4. Business logic execution
        send_rejection_notification(parsed.sender, policy_decision.reason)
        return

    # 3. Control deck assembly
    control_deck = {
        "goal": policy_decision.goal,
        "config": policy_decision.config,
        "moderation_active": policy_decision.moderation_active,
        # ... other hyperparameters
    }

    # Hand off to the Context Engine
    engine_output = context_engine.run(control_deck, parsed.payload)

    # 4. Business logic execution (post-engine)
    deliver_or_route(engine_output)
```

Note: this is a conceptual sketch derived from the chapter's bulleted responsibilities (input parsing, policy enforcement, control deck assembly, business logic execution). The book states a full meta-controller implementation is beyond its scope.

## Architectural Boundary (the chapter's conclusion)

> The meta-controller handles the deterministic, business-specific rules, while our Context Engine is reserved for the complex, non-deterministic reasoning tasks it was designed for. The control deck becomes the clean API that connects the two layers.

## Key Takeaway Quote

> A well-defined corporate regulation is, in many ways, the most powerful form of context we can create. It's explicit, unambiguous, and directly reflects the organization's intent.
