# Writer Agent — Examples

Initial (Ch4) and hardened (Ch5) versions of `agent_writer`. The Writer's hardening is the most important — it had to absorb the data-contract changes made to the Librarian and Researcher.

## Initial Version (Ch4)

```python
def agent_writer(mcp_message):
    """
    Combines the factual research with the semantic blueprint to generate the final output.
    Crucially enhanced to handle either raw facts OR previous content for rewriting tasks.
    """
    print("\n[Writer] Activated. Applying blueprint to source material...")

    blueprint_json_string = mcp_message['content'].get('blueprint')
    facts = mcp_message['content'].get('facts')
    previous_content = mcp_message['content'].get('previous_content')

    if not blueprint_json_string:
         raise ValueError("Writer requires 'blueprint' in the input content.")

    if facts:
        source_material = facts
        source_label = "RESEARCH FINDINGS"
    elif previous_content:
        source_material = previous_content
        source_label = "PREVIOUS CONTENT (For Rewriting)"
    else:
        raise ValueError("Writer requires either 'facts' or 'previous_content'.")

    system_prompt = f"""You are an expert content generation AI.
    Your task is to generate content based on the provided SOURCE MATERIAL.
    Crucially, you MUST structure, style, and constrain your output according to the rules defined in the SEMANTIC BLUEPRINT provided below.

    --- SEMANTIC BLUEPRINT (JSON) ---
    {blueprint_json_string}
    --- END SEMANTIC BLUEPRINT ---

    Adhere strictly to the blueprint's instructions, style guides, and goals. The blueprint defines HOW you write; the source material defines WHAT you write about.
    """

    user_prompt = f"""
    --- SOURCE MATERIAL ({source_label}) ---
    {source_material}
    --- END SOURCE MATERIAL ---

    Generate the content now, following the blueprint precisely.
    """

    final_output = call_llm_robust(system_prompt, user_prompt)
    return create_mcp_message("Writer", final_output)
```

## Hardened Version (Ch5 — `agents.py`)

```python
def agent_writer(mcp_message, client, generation_model):
    """Combines research with a blueprint to generate the final output."""
    logging.info("[Writer] Activated. Applying blueprint to source material...")
    try:
        blueprint_data = mcp_message['content'].get('blueprint')
        facts_data = mcp_message['content'].get('facts')
        previous_content_data = mcp_message['content'].get(
            'previous_content'
        )

        # Extract the actual strings, handling both dict and raw string inputs
        blueprint_json_string = blueprint_data.get('blueprint_json') \
            if isinstance(blueprint_data, dict) else blueprint_data
        facts = facts_data.get('facts') \
            if isinstance(facts_data, dict) else facts_data
        previous_content = previous_content_data  # Assuming this is already a string if provided

        if not blueprint_json_string:
            raise ValueError("Writer requires 'blueprint' in the input content.")

        if facts:
            source_material = facts
            source_label = "RESEARCH FINDINGS"
        elif previous_content:
            source_material = previous_content
            source_label = "PREVIOUS CONTENT (For Rewriting)"
        else:
            raise ValueError("Writer requires either 'facts' or 'previous_content'.")

        # ... (System and User prompt construction remains the same as Ch4) ...

        final_output = call_llm_robust(
            system_prompt,
            user_prompt,
            client=client,
            generation_model=generation_model
        )
        return create_mcp_message("Writer", final_output)
    except Exception as e:
        logging.error(f"[Writer] An error occurred: {e}")
        raise e
```

## Conceptual Diff

1. **Signature**: adds `client, generation_model` (DI). Note: NO namespace argument — the Writer doesn't do retrieval.
2. **Logging**: `print()` → `logging.info`; explicit `logging.error` then re-raise on exception
3. **Error handling**: full `try...except` with explicit error log + re-raise
4. **Critical integration fix**: input unpacking handles BOTH dicts (from the new Librarian/Researcher) AND raw strings (backward compat) via the `isinstance(..., dict)` check. This is the closing piece of the data-contract upgrade.
5. **Helper call**: `call_llm_robust` invoked with explicit kwargs

## Notes

- The Writer is **terminal** — its output is a raw string, not a wrapped dict, because no downstream agent consumes it
- The two-prompt architecture (system = blueprint = HOW, user = source = WHAT) is preserved unchanged from Ch4 — the prompt structure was already correct
- The `isinstance` check makes the Writer robust to both old callers (passing raw strings) and new callers (passing the structured dicts) — useful during migration
- Without this Writer upgrade, the Librarian/Researcher data-contract changes would have broken the engine — a reminder that one component change forces updates to its consumers
