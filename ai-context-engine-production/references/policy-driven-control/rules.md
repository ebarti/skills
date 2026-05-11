# Policy-Driven Control Rules

Rules for encoding, enforcing, and governing organizational policy around a Context Engine via a meta-controller.

## Core Rules

### 1. Encode policy as machine-readable rules outside the engine

Workshop-agreed policy must be translated into deterministic code that lives in the meta-controller, not as prompt instructions or in-engine heuristics.

- Policy lives in the meta-controller's policy-enforcement module.
- Rules must be explicit and unambiguous (no LLM judgment required to apply them).
- The engine receives the resulting decision via the control deck (e.g., `moderation_active=True`), not the raw policy.

### 2. Policy always overrides agent decisions

When organizational policy and the engine's reasoning disagree, policy wins. The engine's role is to enforce policy with perfect fidelity, not to debate it.

- Meta-controller decisions execute before, around, and after the engine call.
- The engine never bypasses policy by reasoning around it.
- If the engine produces output that violates policy, the meta-controller blocks, redacts, or reroutes before downstream business actions.

### 3. Define an explicit escalation path when policy is ambiguous

Real inputs (e.g., legitimate profanity quoted inside otherwise-violating text) reveal gaps. The meta-controller must know what to do when no rule clearly applies.

- Default to the safer outcome (block / redact / escalate) rather than guessing.
- Route ambiguous cases to a human reviewer, not back to the engine.
- Log the ambiguous case as input for the next policy workshop.

### 4. Separate policy authors from policy implementers

The people who *decide* policy and the people who *encode* it are different roles with different accountability.

- **Policy authors**: Compliance, Legal, HR, and business stakeholders. They define rules in workshops.
- **Policy implementers**: Context engineers. They translate workshop output into meta-controller code.
- Engineers must not silently invent policy by adding "smart" filters; that creates rules nobody agreed to.
- Authors must not write ambiguous policy and expect engineering to resolve the ambiguity in code.

### 5. Drive policy from real-world workshops, not from code

> *Only business practices agreed upon in real-world workshops will solve the issue.*

- Convene Legal, HR, IT, and affected business owners.
- Produce explicit, deterministic rules — no "use judgment" clauses.
- Re-run workshops on a cadence to catch evolving regulations and user behavior.

### 6. Keep business-process logic out of the engine

Email parsing, attachment handling, bypass-phrase detection, notification sending — all belong in the meta-controller.

- The Context Engine is reserved for non-deterministic reasoning.
- The control deck is the only API the engine consumes.

### 7. Treat the engine as a continuously adapted artifact

Per Principle 1, the system is only as good as the engineers maintaining it.

- Schedule periodic alignment reviews against current business needs, regulations, and observed user behavior.
- Track reality-factor drift as a first-class operational concern.

## Guidelines

- Prefer fewer, sharper policy rules over many fuzzy ones.
- When a rule requires LLM judgment to apply, the rule is not yet ready for the meta-controller.
- Document every policy rule with the workshop decision that produced it.
- Design hybrid solutions: human judgment for ambiguous cases, automated enforcement for clear ones.

## Exceptions

- **Internal experimentation**: Prototype workflows may stub policy enforcement, but must not ship to production without meta-controller wrapping.
- **Read-only exploratory tools**: Tools with no business actions may relax full policy enforcement, but must still respect access controls.

## Quick Reference

| Rule | Summary |
|------|---------|
| Encode externally | Policy lives in meta-controller code, not prompts |
| Policy overrides | Policy beats engine reasoning, always |
| Escalate ambiguity | Default safer + route to human; never guess |
| Separate roles | Authors (Legal/HR/Compliance) vs implementers (Engineering) |
| Workshop-driven | No engineer-invented policy |
| Business logic out | Parsing, notifications, bypass checks belong outside the engine |
| Continuous adaptation | Treat the engine as an artifact under constant maintenance |
