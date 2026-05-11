# Micro-Context Engineering Rules

Rules for designing prompts and objectives WITHIN individual agents in a multi-agent system.

## Core Rules

### 1. Treat Every Agent Prompt as a Mini Context Engine

Each agent's system prompt + dynamic objective is a self-contained context engine. Design it with the same rigor you apply to the macro engine.

- Define role, task, constraints, and output shape every time.
- Do not rely on the LLM to infer what "good" looks like.

### 2. Never Ship a Vague Objective

An instruction must not be an old-fashioned prompt. Replace generic asks with precise, constrained objectives.

**Example**:

```text
# Bad
"Summarize this text."

# Good
"Extract the names of all involved parties, the key financial figures
discussed, and the final resolution date from the following legal
document. Exclude all procedural boilerplate and present the output
as a JSON object."
```

### 3. Structure Every Objective with Role / Task / Constraints / Output

A strong objective is a miniature semantic blueprint. It must contain:

- **Role / task**: What is being extracted or produced.
- **Constraints**: What to exclude or how to scope it.
- **Output shape**: Format (JSON, bullet list, single paragraph, etc.).

### 4. Reinforce Consuming Agents When New Producers Are Added

Whenever a new agent is introduced upstream, audit each consumer for data-contract compatibility and reinforce its unpacking logic.

- Detect new schemas (e.g., `'summary'` vs `'facts'`).
- Make the consumer "bilingual" by trying multiple keys before failing.
- Validate that required inputs exist before invoking the LLM.

### 5. Keep the System Prompt Stable; Vary the Objective

The system prompt defines the agent's identity (role, tone, hard rules). The dynamic objective tailors a single invocation. Do not mutate the system prompt per call to express task-level changes.

- System prompt = "who you are."
- Objective = "what you must do this time."

### 6. Avoid Prompt Drift Across Agents

Specialist agents should share consistent vocabulary and output conventions wherever they overlap, so that downstream consumers do not need to learn N dialects.

- Pick canonical key names where possible (or document each one).
- Document each agent's output schema in the registry's capabilities description.
- When two agents must differ (e.g., `facts` vs `summary`), make the difference explicit and reinforce consumers accordingly.

### 7. Validate Required Inputs Before Calling the LLM

A reinforced agent fails fast on missing inputs rather than emitting a degraded result.

```python
if not blueprint_json_string or (not facts and not previous_content):
    raise ValueError("Writer requires a blueprint and either 'facts' or 'previous_content'.")
```

## Guidelines

- Treat the objective string as part of the planner's output design, not an afterthought.
- When repurposing a generic agent, always supply a fresh, task-specific objective.
- Prefer structured outputs (JSON, dict) when the result feeds another agent.
- Write the objective so that a human reader could predict the output without seeing it.

## Exceptions

- **One-shot prototyping**: A vague objective is acceptable while exploring an idea, but never in production.
- **Free-form creative tasks**: Some constraints can be loosened, but role and output format should still be specified.

## Quick Reference

| Rule | Summary |
|------|---------|
| Mini context engine | Design every agent prompt with macro-level rigor |
| No vague objectives | Replace "summarize this" with specific, constrained tasks |
| Role/Task/Constraints/Output | Required structure for every objective |
| Reinforce consumers | Update downstream agents when new producers appear |
| Stable system / variable objective | Identity is fixed; per-call task varies |
| No prompt drift | Keep vocabulary and output shapes consistent |
| Validate inputs | Fail fast on missing required keys |
