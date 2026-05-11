# Grounded Reasoning Examples

The three regression test cases used to validate the upgraded NASA-inspired research assistant. Each preserves the goal, the activated functions, and the key trace excerpt from the source chapter.

## Test Case 1 - Chapter 7: High-Fidelity, Secure Research Workflow

### Goal

Prove the full capabilities of the upgraded engine: deliver trustworthy, verifiable answers to a multifaceted research query. Output must be a polished, accurate, evidence-backed report credible in a professional research environment.

### Required Capabilities

- Autonomously deconstruct the user's goal
- Plan a multi-agent workflow
- Execute securely (input sanitization)
- Use high-fidelity RAG with citations

### Activated Functions

```text
Notebook : execute_and_display()
Engine   : context_engine(), planner(), resolve_dependencies(), ExecutionTrace
Registry : get_handler(), get_capabilities_description()
Agents   : agent_researcher(), agent_librarian(), agent_writer()
Helpers  : query_pinecone(), call_llm_robust(), helper_sanitize_input(), get_embedding()
```

### What Success Looks Like

The trace shows the planner producing a multi-step JSON plan; the researcher returns `answer_with_sources` with concrete citations; the writer composes the final report. Every step appears in the ExecutionTrace.

---

## Test Case 2 - Chapter 6: Backward-Compatibility Validation

### Goal

Re-run the Chapter 6 large-context summarization workflow on the Chapter 7 engine to prove that new upgrades did not regress prior functionality. Showcases cost efficiency and reasoning depth via the Summarizer-then-Writer pattern.

### The Linchpin: Trilingual Writer

The `agent_writer` was progressively reinforced to understand three data contracts:

```python
# FINAL ROBUST LOGIC for handling multiple data contracts
facts = None
if isinstance(facts_data, dict):
    # Check for 'facts' (from original Researcher)
    facts = facts_data.get('facts')
    # Check for 'summary' (from Summarizer)
    if facts is None:
        facts = facts_data.get('summary')
    # NEW: Check for 'answer_with_sources' (from Hi-Fi Researcher)
    if facts is None:
        facts = facts_data.get('answer_with_sources')
elif isinstance(facts_data, str):
    facts = facts_data
```

### Activated Functions

```text
Notebook : execute_and_display()
Engine   : context_engine(), planner(), resolve_dependencies(), ExecutionTrace
Registry : get_handler(), get_capabilities_description()
Agents   : agent_summarizer(), agent_librarian(), agent_writer()
Helpers  : query_pinecone(), call_llm_robust(), count_tokens(), get_embedding()
```

### What Success Looks Like

The Chapter 6 goal completes end-to-end on the Chapter 7 engine. The Writer accepts `summary` payloads from the Summarizer just as it accepts `answer_with_sources` from the new researcher. No regression in tone, length, or structure of the final output.

---

## Test Case 3 - Chapter 5: Grounded Reasoning, Preventing Hallucination

### Goal

> Write a story about the Apollo 11 moon landing.

### The Twist

The knowledge base contains only Juno and Perseverance mission documents - **nothing about Apollo 11**. A trustworthy system must recognize the gap and respond truthfully.

### Activated Functions

```text
Notebook : execute_and_display()
Engine   : context_engine(), planner(), resolve_dependencies(), ExecutionTrace
Registry : get_handler(), get_capabilities_description()
Agents   : agent_researcher(), agent_librarian(), agent_writer()
Helpers  : query_pinecone(), call_llm_robust(), helper_sanitize_input(), get_embedding()
```

### Trace Excerpt - The Negative Result

The Researcher correctly reported absence rather than fabricating Apollo 11 history:

```json
{
  "step": 1,
  "agent": "Researcher",
  "output": {
    "answer_with_sources": "I can't produce an accurate, child-friendly account of the Apollo 11 landing from the provided documents. The supplied sources (an NDA, a hostile witness testimony excerpt, a service agreement, and a privacy policy) don't contain any information about Apollo 11...\n\nSources:\nNone (no relevant Apollo 11 information in the provided documents)\n\n**Sources:**\n- NDA_Template_and_Testimony.txt\n- Privacy_Policy_v3.txt\n- Service_Agreement_v1.txt"
  }
}
```

### What Success Looks Like

- Researcher emits a structured negative result instead of inventing content.
- Writer transforms that negative result into a contextual narrative about the absence of information.
- ExecutionTrace records every step including the empty retrieval.

### Production Enhancement

A production-ready system can prompt the user upon detecting a negative result:

```text
The provided documents do not contain this information.
Do you want me to confirm this response. Yes or No?
```

This empowers the user to manage the trade-off between strict context-adherence and the model's general helpfulness.

---

## Cross-Case Comparison

| Aspect | Ch7 (Hi-Fi) | Ch6 (Backward Compat) | Ch5 (Grounded) |
|--------|-------------|------------------------|----------------|
| Producer agent | `agent_researcher` (hi-fi) | `agent_summarizer` | `agent_researcher` (hi-fi) |
| Writer contract used | `answer_with_sources` | `summary` | `answer_with_sources` (negative) |
| Citations | Present | N/A | "None" - explicitly listed |
| Pass criterion | Polished evidence-backed report | Same quality on new engine | Honest absence, no fabrication |
