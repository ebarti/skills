# Micro-Context Engineering Examples

Concrete examples of micro-context design and instruction reinforcement. All prompts preserved verbatim from the source.

## Bad Examples

### Vague, Open-Ended Objective

```text
"Summarize this text."
```

**Problems**:
- Forces the LLM to guess what the user deems important.
- Produces a generic, bland paragraph.
- May completely miss the critical information the user actually needed.
- Wastes both the API call and the user's time.

### Rigid Consumer Agent (Pre-Reinforcement Writer)

The original `agent_writer` only understood the Researcher's schema:

```python
# Researcher output: {'facts': '...'}
# Summarizer output: {'summary': '...'}

# Original Writer assumed only 'facts' existed.
facts = facts_data.get('facts')
# When the Planner chained Summarizer -> Writer, this returned None
# and the Writer failed: a data contract violation.
```

**Problems**:
- Single hardcoded schema assumption.
- Breaks the moment a new producer agent (Summarizer) is introduced.
- Failure surfaces only during integration testing.

## Good Examples

### Strong, Semantic-Blueprint Objective

```text
"Extract the names of all involved parties, the key financial figures
discussed, and the final resolution date from the following legal
document. Exclude all procedural boilerplate and present the output
as a JSON object."
```

**Why it works**:
- Specific about what to extract (parties, figures, date).
- Provides a constraint (exclude procedural boilerplate).
- Defines the output shape (JSON object).
- Transforms the generic Summarizer into a precision entity-extraction tool for this one task.
- Leaves no room for ambiguity and guarantees a useful, structured output.

### Bilingual Consumer Agent (Reinforced Writer)

```python
facts = None
if isinstance(facts_data, dict):
    # First, try to get 'facts' (from Researcher)
    facts = facts_data.get('facts')
    # If that fails, try to get 'summary' (from Summarizer)
    if facts is None:
        facts = facts_data.get('summary')
elif isinstance(facts_data, str):
    facts = facts_data

if not blueprint_json_string or (not facts and not previous_content):
    raise ValueError("Writer requires a blueprint and either 'facts' or 'previous_content'.")
```

**Why it works**:
- Speaks both upstream schemas (`facts` and `summary`).
- Falls back gracefully instead of crashing.
- Validates required inputs before invoking the LLM.
- Resolves the data contract violation with no change to the system prompt.

## Refactoring Walkthrough: Reinforcing the Writer Agent

### Before

```python
# FILE: commons/ch6/agents.py (ORIGINAL agent_writer)

def agent_writer(mcp_message, client, generation_model):
    """Combines research with a blueprint to generate the final output."""
    blueprint_data = mcp_message['content'].get('blueprint')
    facts_data = mcp_message['content'].get('facts')
    previous_content = mcp_message['content'].get('previous_content')

    blueprint_json_string = blueprint_data.get('blueprint_json') \
        if isinstance(blueprint_data, dict) else blueprint_data

    # Only understood the Researcher's 'facts' schema.
    facts = facts_data.get('facts') if isinstance(facts_data, dict) else facts_data

    # ... constructs prompt and calls the LLM ...
```

### After

```python
# FILE: commons/ch6/agents.py (UPGRADED agent_writer)

def agent_writer(mcp_message, client, generation_model):
    """Combines research with a blueprint to generate the final output."""
    logging.info("[Writer] Activated. Applying blueprint to source material...")
    try:
        blueprint_data = mcp_message['content'].get('blueprint')
        facts_data = mcp_message['content'].get('facts')
        previous_content = mcp_message['content'].get('previous_content')

        # UPGRADE: Robust logic for handling multiple data contracts
        blueprint_json_string = blueprint_data.get('blueprint_json') \
            if isinstance(blueprint_data, dict) else blueprint_data

        facts = None
        if isinstance(facts_data, dict):
            # First, try to get 'facts' (from Researcher)
            facts = facts_data.get('facts')
            # If that fails, try to get 'summary' (from Summarizer)
            if facts is None:
                facts = facts_data.get('summary')
        elif isinstance(facts_data, str):
            facts = facts_data

        if not blueprint_json_string or (not facts and not previous_content):
            raise ValueError("Writer requires a blueprint and either 'facts' or 'previous_content'.")

        # Determine the source material and label for the prompt
        if facts:
            source_material = facts
            source_label = "SOURCE FACTS"
        else:
            source_material = previous_content
            source_label = "PREVIOUS CONTENT (For Rewriting)"

        # Construct the prompts and call the LLM...
        system_prompt = f"""You are an expert content generation AI..."""  # (prompt remains the same)
        user_prompt = f"""--- SOURCE MATERIAL ({source_label}) ---\n{source_material}\n--- END SOURCE MATERIAL ---\n\nGenerate the content now..."""  # (prompt remains the same)

        final_output = call_ll_robust(
            system_prompt, user_prompt, client=client,
            generation_model=generation_model
        )
        return create_mcp_message("Writer", final_output)

    except Exception as e:
        logging.error(f"[Writer] An error occurred: {e}")
        raise e
```

### Changes Made

1. **Bilingual unpacking**: Try `'facts'` first, then fall back to `'summary'` so the Writer accepts input from both Researcher and Summarizer.
2. **String fallback**: If `facts_data` is a plain string, use it directly.
3. **Input validation**: Raise a clear `ValueError` when required inputs are missing, instead of silently failing inside the LLM call.
4. **Identity preserved**: The `system_prompt` is intentionally unchanged — reinforcement happens at the data-contract layer, not in the agent's identity.
