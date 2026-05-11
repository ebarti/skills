# Context Librarian Agent — Examples

Initial (Ch4) and hardened (Ch5) versions of `agent_context_librarian`.

## Initial Version (Ch4 — uses globals, `print`, returns raw string)

```python
def agent_context_librarian(mcp_message):
    """
    Retrieves the appropriate Semantic Blueprint from the Context Library.
    """
    print("\n[Librarian] Activated. Analyzing intent...")
    requested_intent = mcp_message['content'].get('intent_query')

    if not requested_intent:
        raise ValueError("Librarian requires 'intent_query' in the input content.")

    results = query_pinecone(requested_intent, NAMESPACE_CONTEXT, top_k=1)

    if results:
        match = results[0]
        print(f"[Librarian] Found blueprint '{match['id']}' (Score: {match['score']:.2f})")
        blueprint_json = match['metadata']['blueprint_json']
        content = blueprint_json
    else:
        print("[Librarian] No specific blueprint found. Returning default.")
        content = json.dumps({"instruction": "Generate the content neutrally."})

    return create_mcp_message("Librarian", content)
```

## Hardened Version (Ch5 — `agents.py`)

```python
def agent_context_librarian(
    mcp_message, client, index, embedding_model, namespace_context
):
    """Retrieves the appropriate Semantic Blueprint from the Context Library."""
    logging.info("[Librarian] Activated. Analyzing intent...")
    try:
        requested_intent = mcp_message['content'].get('intent_query')
        if not requested_intent:
            raise ValueError("Librarian requires 'intent_query' in the input content.")

        results = query_pinecone(
            query_text=requested_intent,
            namespace=namespace_context,
            top_k=1,
            index=index,
            client=client,
            embedding_model=embedding_model
        )

        if results:
            match = results[0]
            logging.info(
                f"[Librarian] Found blueprint '{match['id']}' (Score: {match['score']:.2f})"
            )
            blueprint_json = match['metadata']['blueprint_json']
            content = {"blueprint_json": blueprint_json}
        else:
            logging.warning("[Librarian] No specific blueprint found. Returning default.")
            content = {"blueprint_json": json.dumps(
                    {"instruction": "Generate the content neutrally."}
                )
            }
        return create_mcp_message("Librarian", content)
```

## Conceptual Diff

1. **Signature**: now takes `client, index, embedding_model, namespace_context` (DI)
2. **Logging**: `print()` → `logging.info`/`logging.warning`
3. **Error handling**: body wrapped in `try` block
4. **Helper call**: `query_pinecone` called with explicit kwargs
5. **Critical fix — data contract**: output content wrapped as `{"blueprint_json": ...}` dict — the Writer can now reliably look up the blueprint by key

## Notes

- The default-blueprint branch still ensures the agent always returns a valid MCP message — the system never fails because no blueprint exists
- The `intent_query` field is required upfront; missing → `ValueError`
- Logging tag `[Librarian]` lets you filter multi-agent traces
