# Input Sanitization Rules

Rules for applying input sanitization as the first line of defense against prompt injection in RAG pipelines.

## Core Rules

### 1. Sanitize Before Every LLM Call

Run the sanitizer on any text that will be inserted into a prompt and sent to an LLM — especially text retrieved from the vector store.

- Place the check between retrieval and synthesis
- Apply to each retrieved chunk individually
- Do not skip sanitization for "trusted" sources — trust assumptions break

**Example**:
```python
# Bad — retrieved text flows directly into the LLM prompt
chunks = retriever.search(query)
response = llm.generate(build_prompt(query, chunks))

# Good — sanitize each chunk before it reaches the prompt
chunks = retriever.search(query)
clean_chunks = [helper_sanitize_input(c) for c in chunks]
response = llm.generate(build_prompt(query, clean_chunks))
```

### 2. Fail Closed on Detection

When a known injection pattern matches, raise an exception (`ValueError`). Do not silently strip, redact, or "clean up" the offending text.

- Surfacing the failure forces explicit handling upstream
- Silent mutation can mask attacks and create inconsistent behavior
- Let the caller decide retry, fallback, or user-facing error

### 3. Filter Known Injection Patterns

At minimum, detect these prompt-injection signatures (case-insensitive):

- `ignore previous instructions`
- `ignore all prior commands`
- `you are now in.*mode`
- `act as`
- `print your instructions`
- `sudo|apt-get|yum|pip install` (shell / package-manager command exfil)

### 4. Log Every Sanitization Event

Both threat hits and clean passes must be logged. Without telemetry, you cannot tune patterns, detect new attack waves, or perform incident response.

- Log a `warning` with the matched pattern when a threat is detected
- Log an `info` line when input passes the check
- Include enough context (request id, source) downstream to correlate

### 5. Treat the Pattern List as Living Code

The injection pattern list must be augmented continuously. Treat it like a security signature database, not a fixed configuration.

- Review new attack reports and add patterns
- Version-control the pattern list and review changes like security policy
- Do not rely on the published list as sufficient

## Guidelines

- Apply sanitization at a single, well-known choke point in the pipeline so it cannot be bypassed
- Keep regex case-insensitive — attackers frequently mix case
- Prefer raising clear exception types so callers can distinguish sanitization failures from other errors
- Do not echo the matched pattern back to end users (avoids hint-leakage to attackers)
- Augment regex with semantic checks (LLM-based classifiers, allowlists, role enforcement) over time

## Integration Points

| Location | When to use |
|----------|-------------|
| Per-agent retrieval call | Default — every agent that touches retrieved text sanitizes its own inputs |
| Shared retrieval gateway | Centralize when many agents share the same retriever; reduces drift |
| Tool input boundary | Apply on any text consumed from external tools, not just RAG |

A gateway approach is preferred when feasible — it makes the checkpoint impossible to forget. Per-agent sanitization is acceptable for heterogeneous pipelines but requires discipline.

## Escalation When Sanitization Triggers

When a `ValueError` is raised by the sanitizer:

1. **Discard** the tainted chunk — never forward it to the LLM
2. **Log** the warning with the matched pattern
3. **Decide** whether to:
   - Retry retrieval excluding the tainted source
   - Return a degraded answer with remaining clean chunks
   - Surface a user-facing error if no clean context remains
4. **Investigate** repeated hits from the same source — likely a poisoned document needing removal from the vector store

## Exceptions

- **None for production RAG paths**: Always sanitize retrieved text before LLM consumption
- **Offline batch ingestion**: You may sanitize at ingestion time *in addition to* query time, but this does not replace query-time checks (patterns evolve)

## Quick Reference

| Rule | Summary |
|------|---------|
| Sanitize before LLM | Every prompt-bound text passes the checkpoint |
| Fail closed | Raise on detection, never silently strip |
| Filter known patterns | Maintain a regex list of injection signatures |
| Log all events | Warnings on hit, info on pass |
| Living pattern list | Continuously augment as attacks evolve |
| Single choke point | Centralize the checkpoint to prevent bypass |
