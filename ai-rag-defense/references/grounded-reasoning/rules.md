# Grounded Reasoning Rules

Rules for ensuring agents stay grounded, validating across regression test cases, and preserving backward compatibility as capabilities grow.

## Core Rules

### 1. Report Negative Findings Instead of Inventing

When retrieval returns no relevant data, the agent MUST emit a structured negative result rather than fabricate facts.

- The output must say what was searched, what was found, and that nothing was applicable.
- The output must list the sources actually consulted.
- The downstream Writer must accept negative results as a valid `answer_with_sources` payload.

**Example**:
```json
// Bad - invented content
{ "step": 1, "agent": "Researcher",
  "output": { "answer_with_sources": "Apollo 11 landed on July 20, 1969..." } }

// Good - honest negative result
{ "step": 1, "agent": "Researcher",
  "output": { "answer_with_sources": "I can't produce an accurate account of Apollo 11 from the provided documents...\nSources: None (no relevant Apollo 11 information in the provided documents)" } }
```

### 2. Maintain a Complete Inventory Before Validating

You cannot validate what you cannot enumerate. Keep a canonical table of every function, grouped by tier (notebook, helpers, agents, registry, engine core).

- Update the inventory whenever a new function is added.
- Treat the inventory as code, not appendix prose.
- Include the contexts/prompts you designed alongside the functions.

### 3. Validate Across Multiple Test Cases on Every Upgrade

Run at least three regression scenarios before declaring a release ready:

- High-fidelity secure research (current chapter capability)
- Backward-compat workflow (prior chapter using new agents)
- Grounded reasoning (knowledge base intentionally missing the asked topic)

Successful execution of all three confirms stability and modular soundness.

### 4. Preserve Backward Compatibility via Flexible Data Contracts

When adding a new producer agent, upgrade shared consumers (e.g., Writer) to accept the new contract without breaking the old ones.

**Example** - the trilingual unpacking pattern:
```python
# Good - accepts facts, summary, or answer_with_sources
facts = None
if isinstance(facts_data, dict):
    facts = facts_data.get('facts')
    if facts is None:
        facts = facts_data.get('summary')
    if facts is None:
        facts = facts_data.get('answer_with_sources')
elif isinstance(facts_data, str):
    facts = facts_data
```

### 5. Trace Every Decision for Audit

Every step must be logged via `ExecutionTrace.log_step()` with goal, plan, inputs, resolved context, and output.

- Negative-result steps are still steps; log them.
- Finalize the trace with status and duration.
- A run without a complete trace is not a valid run.

### 6. Sanitize All External Input Before LLM Use

Use `helper_sanitize_input()` on any text that enters the LLM, especially in high-fidelity research workflows. Prompt injection and data poisoning are silent failure modes that bypass grounding.

### 7. Cite Sources Whenever Producing Factual Claims

The high-fidelity Researcher agent's contract is `answer_with_sources` - the citation field is non-optional. A factual answer without sources should be treated as a hallucination by reviewers.

## Guidelines

- Re-read the full inventory before adding any new agent or helper.
- Use mind maps (Figures 7.2-7.5 in the source) to confirm only the expected functions light up per scenario.
- For production, extend with a user-facing prompt on negative results: "The provided documents do not contain this information. Do you want me to confirm this response?"
- Take time. Validation is not a checklist to rush; the chapter explicitly tells the engineer to "take another deep breath."

## Exceptions

When these rules may be relaxed:

- **Exploratory prototyping**: Inventory and tracing can be lighter, but never skip the negative-result contract.
- **User-controlled fallbacks**: Once you offer the user a "answer from general knowledge?" prompt, the system may answer outside context only with explicit consent.

## Quick Reference

| Rule | Summary |
|------|---------|
| Report negative findings | Never invent when retrieval is empty |
| Maintain inventory | Enumerate every function by tier |
| Multi-case validation | Run Ch7, Ch6, Ch5 scenarios each release |
| Flexible contracts | Shared consumers accept all producer formats |
| Trace decisions | Every step logged via ExecutionTrace |
| Sanitize input | Run `helper_sanitize_input()` before LLM use |
| Cite sources | `answer_with_sources` is non-optional |
