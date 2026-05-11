# Moderation Rules

Rules for building, integrating, and operating a moderation gatekeeper around a Context Engine.

## Core Rules

### 1. Encapsulate Moderation in a Dedicated Helper

Build a single `helper_moderate_content` function in `commons/ch8/helpers.py` (or your equivalent commons module). All moderation API interaction lives there.

- One function, one responsibility
- Returns a structured report (not a boolean) so callers can inspect categories and scores
- Lives in a chapter-/version-scoped commons file so earlier code keeps working

**Example**:
```python
# Good — structured report
return {"flagged": ..., "categories": {...}, "scores": {...}}

# Bad — opaque boolean
return is_flagged
```

### 2. Apply the Two-Stage Protocol (Input + Output)

Moderation must run twice: once on the user's goal (pre-flight) and once on the AI's output (post-flight).

- Pre-flight halts execution before any LLM cost is incurred on harmful input
- Post-flight catches harmful generations even from benign prompts
- Skipping either stage leaves a hole in the safety wrapper

### 3. Fail Safe on API Errors

If the Moderation API call raises any exception, return a flagged report. Never let unvetted content through because the safety check itself broke.

**Example**:
```python
except Exception as e:
    logging.error(f"...: {e}")
    return {"flagged": True, "categories": {"error": str(e)}, "scores": {}}
```

### 4. Halt on Pre-Flight Flag, Redact on Post-Flight Flag

Different stages call for different responses:

- **Pre-flight flagged**: print a clear halt message and `return` immediately — do not call the engine
- **Post-flight flagged**: replace the result with a standardized redaction string before display

```python
# Pre-flight
if moderation_report["flagged"]:
    print("\nGoal failed pre-flight moderation. Execution halted.")
    return

# Post-flight
if moderation_report["flagged"]:
    result = "[Content flagged as potentially harmful by moderation policy and has been redacted.]"
```

### 5. Make Moderation Toggleable, Default On for Production

Expose `moderation_active` as a parameter on the orchestrator function so it can be turned off for trusted dev runs but defaults on for production.

- Production: `moderation_active=True` (always)
- Customer-facing demos: `moderation_active=True`
- Local debug with trusted goals: may be `False` to save cost/latency
- Compliance-regulated domains: `moderation_active=True`, no exceptions

### 6. Log Every Moderation Decision

Use `logging.info` for passes and `logging.warning` for flags. The report is your audit trail.

- Log the categories on every flag so reviewers can see why
- Log API errors at `error` level
- Print the full report during interactive runs for transparency

### 7. Treat Moderation as a Wrapper, Not a Modification

The moderation layer must not alter the engine's reasoning logic. It only wraps inputs and outputs.

- Do not edit Planner, Researcher, or Writer agents to "be safer"
- Keep agents focused on reasoning; let the wrapper enforce policy
- This preserves separation of concerns and makes the safety layer auditable

## Guidelines

- Print the moderation report (`pprint.pprint`) during development so engineers can see scores
- Keep redaction messages standardized and recognizable so users understand what happened
- Budget ~200 ms per moderation call when planning latency
- Use the structured report to feed dashboards/metrics, not just to gate execution
- When testing, use a known-safe goal first to verify the full pipeline runs end-to-end

## Exceptions

When these rules may be relaxed:

- **Trusted internal benchmarks**: Pre-/post-flight moderation may be disabled to measure raw engine latency
- **Domain with legitimate edge content (e.g., legal witness testimony with profanity)**: Combine moderation with a policy layer that whitelists specific contexts — do not just disable moderation
- **Local development**: Skip moderation only when working on engine internals unrelated to safety; never ship that config

## Cost vs Safety Trade-Off

- Each Moderation API call has a small token/compute cost and ~200 ms latency
- Two calls per goal => ~400 ms added latency
- Skipping moderation saves cost but exposes the business to harmful content liability
- Recommended: always pay the safety cost in production; measure and accept the latency

## Quick Reference

| Rule | Summary |
|------|---------|
| Encapsulate | One helper, structured report |
| Two stages | Pre-flight + post-flight, both required |
| Fail safe | API error => flagged |
| Halt vs redact | Halt pre-flight, redact post-flight |
| Toggleable | Parameter-driven, default on for prod |
| Log everything | Every decision is auditable |
| Wrap, don't modify | Keep reasoning logic untouched |
