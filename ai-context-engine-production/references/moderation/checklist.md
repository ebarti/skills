# Moderation Completeness Checklist

Use when reviewing or shipping a Context Engine to verify the moderation safety layer is complete and production-ready.

## Before You Start

- [ ] OpenAI client (or equivalent moderation provider) is initialized
- [ ] Logging is configured at `info` and `warning` levels
- [ ] You know which environment this is (dev / staging / prod)

## Gatekeeper Helper

- [ ] A dedicated `helper_moderate_content` function exists in `commons/.../helpers.py`
- [ ] The function returns a structured report with `flagged`, `categories`, and `scores`
- [ ] The function logs `warning` on flag and `info` on pass
- [ ] The function has a `try...except` that fails safe (returns `flagged: True` on API error)
- [ ] The function does not contain any business logic beyond moderation

## Input Check (Pre-Flight)

- [ ] Pre-flight moderation runs on the user's goal before any planning begins
- [ ] If flagged, execution halts immediately with a clear message
- [ ] No LLM/embedding/Pinecone calls happen after a pre-flight flag
- [ ] The pre-flight report is logged or printed for audit

## Output Check (Post-Flight)

- [ ] Post-flight moderation runs on the AI's generated output before display
- [ ] If flagged, the output is replaced with a standardized redaction message
- [ ] The user is notified that content was redacted (the message is recognizable)
- [ ] The post-flight report is logged or printed for audit

## Fail-Safe Behavior

- [ ] API exceptions are caught and treated as flagged content
- [ ] Network timeouts do not allow content to bypass moderation
- [ ] No code path exists where unvetted content can reach the user
- [ ] `error`-level logs capture the underlying exception for diagnosis

## Toggle and Activation

- [ ] `moderation_active` parameter is exposed on the orchestrator function
- [ ] Production calls pass `moderation_active=True`
- [ ] Customer-facing flows pass `moderation_active=True` unconditionally
- [ ] Any caller that disables moderation has documented justification

## Logging and Observability

- [ ] Every moderation pass is logged at `info` level
- [ ] Every moderation flag is logged at `warning` level with categories
- [ ] Every moderation API error is logged at `error` level
- [ ] Reports can be aggregated for dashboards / compliance reporting

## Architectural Integrity

- [ ] Moderation is a wrapper — agents and reasoning logic are unchanged
- [ ] The two-stage protocol is implemented (input AND output, not one or the other)
- [ ] Latency budget includes ~200 ms per moderation call (~400 ms total)
- [ ] Cost of moderation API calls is included in the operating budget

## Testing

- [ ] A known-safe goal end-to-end test exists and passes
- [ ] A known-flagged input test exists and verifies pre-flight halt
- [ ] A test for API error path verifies fail-safe behavior
- [ ] Reports are inspected during dev runs (e.g., `pprint.pprint(report)`)

## Red Flags

Stop and address if you find:

- Moderation only on input OR only on output (not both)
- API exceptions allowing content to pass (fail-open instead of fail-safe)
- Hardcoded `moderation_active=False` in a production path
- Reasoning agents modified to "be safer" instead of using the wrapper
- Missing logs for flagged content (no audit trail)
- No standardized redaction message (users don't know content was blocked)
- Moderation skipped to "save latency" in customer-facing flows

## Quick Reference

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| Stages covered | Input + Output | Input + Output | One or none |
| API error behavior | Fail safe (flagged) | Fail safe + alert | Fail open |
| Production toggle | Always on | Always on | Conditional/off |
| Audit logs | Every decision | Flags only | None |
| Reasoning logic | Untouched | Untouched | Modified for safety |
| Latency budget | Includes ~400 ms | Includes ~400 ms | Not budgeted |
