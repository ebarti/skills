# Meeting Analysis Rules

Rules for designing layered, context-chained analysis pipelines over meetings and long-form documents.

## Core Rules

### 1. One Purpose Per Prompt

Each cell (g2–g7) must have a single, clearly stated task. Never combine "isolate noise AND analyze dynamics AND draft an email" into one prompt.

- State the task as one verb (Analyze, Identify, Generate, Compile, Draft).
- If you need "and" between two verbs, split the prompt.

### 2. Pipe Outputs Verbatim

The output variable from step N becomes a literal f-string interpolation in step N+1's prompt.

- `substantive_content` from g2 feeds g3, g4, and g5.
- `new_developments` from g3 feeds g6.
- `final_summary_table` from g6 feeds g7.

**Example**:
```python
prompt_g6 = f"""
Task: Create a final, concise summary of the meeting in a markdown table.
Use the following information to construct the table.
- New Developments: {new_developments}
The table should have three columns: "Topic", "Decision/Outcome", and "Owner".
"""
```

### 3. Layer 1 = Scope: Extraction Only

Layer 1 prompts extract and filter — they never interpret or invent.

- g2: tell the model exactly what counts as substantive vs noise.
- g3: inject prior context (`previous_summary`) so output is differential, not absolute.
- Forbid speculation in the prompt language ("Return ONLY the substantive content").

### 4. Layer 2 = Investigation: Read Between the Lines

Layer 2 prompts explicitly ask for inference beyond the literal text.

- g4: "Go beyond the literal words" — ask about hesitation, tensions, mood.
- g5: combine **two distinct facts** from the transcript into a single new idea; name the facts in the prompt.

### 5. Layer 3 = Action: Force a Schema

Layer 3 prompts must specify the exact output format.

- g6: markdown table with named columns ("Topic", "Decision/Outcome", "Owner").
- g7: an email with subject, decisions block, and per-person action items.

### 6. Branch Where Independent, Chain Where Dependent

g3, g4, g5 all consume `substantive_content` and run in parallel — they share no state with each other.
g6 depends on g3; g7 depends on g6 — these must run sequentially.

## Guidelines

- Keep system role implicit and put the entire instruction in `{"role": "user", "content": prompt_gN}` for transparent debugging.
- Use the same model (`gpt-5`) across the chain unless you have a reason to swap.
- Always print intermediate results — every variable should be inspectable mid-chain.
- Wrap each call in `try/except` so a failure in one step is loud and localized.

## Output Schemas Per Layer

| Cell | Variable | Schema |
|------|----------|--------|
| g2 | `substantive_content` | Bulleted list of decisions/updates/issues |
| g3 | `new_developments` | Bulleted list of changes vs. `previous_summary` |
| g4 | `implicit_threads` | Themed prose sections (hesitation, tension, mood) |
| g5 | `novel_solution` | Named idea + plan + risks + owners |
| g6 | `final_summary_table` | Markdown table: Topic / Decision / Owner |
| g7 | `follow_up_email` | Subject, decisions, per-person action items |

## When to Chain vs Branch

| Situation | Approach |
|-----------|----------|
| Output of step A is required input for step B | Chain (sequential) |
| Multiple analyses share the same upstream input but produce independent artifacts | Branch (parallel) |
| Final artifact must aggregate multiple branches | Add a join step (e.g., a g8 that merges g4 + g6 + g5) |

## Exceptions

- **Short transcripts**: a single prompt may suffice for a 5-line transcript, but you lose the debugging benefit.
- **No prior context available**: skip g3 and feed g2 directly into g6.
- **No action artifact needed**: stop at Layer 2 if the goal is analysis only.

## Quick Reference

| Rule | Summary |
|------|---------|
| One purpose per prompt | Single verb per cell |
| Pipe outputs verbatim | f-string the previous variable |
| Layer 1 extracts | No interpretation |
| Layer 2 infers | Subtext + synthesis |
| Layer 3 schematizes | Specify exact format |
| Branch vs chain | Parallel for independent, sequential for dependent |
