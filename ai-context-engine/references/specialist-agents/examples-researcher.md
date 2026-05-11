# Researcher Agent — Examples

Initial (Ch4) and hardened (Ch5) versions of `agent_researcher`.

## Initial Version (Ch4)

```python
def agent_researcher(mcp_message):
    """
    Retrieves and synthesizes factual information from the Knowledge Base.
    """
    print("\n[Researcher] Activated. Investigating topic...")
    topic = mcp_message['content'].get('topic_query')

    if not topic:
        raise ValueError("Researcher requires 'topic_query' in the input content.")

    results = query_pinecone(topic, NAMESPACE_KNOWLEDGE, top_k=3)

    if not results:
        print("[Researcher] No relevant information found.")
        return create_mcp_message("Researcher", "No data found on the topic.")

    print(f"[Researcher] Found {len(results)} relevant chunks. Synthesizing...")
    source_texts = [match['metadata']['text'] for match in results]

    system_prompt = """You are an expert research synthesis AI.
    Synthesize the provided source texts into a concise, bullet-pointed summary relevant to the user's topic. Focus strictly on the facts provided in the sources. Do not add outside information."""

    user_prompt = f"Topic: {topic}\n\nSources:\n" + "\n\n---\n\n".join(source_texts)

    findings = call_llm_robust(system_prompt, user_prompt)

    return create_mcp_message("Researcher", findings)
```

## Hardened Version (Ch5 — `agents.py`)

```python
def agent_researcher(
    mcp_message, client, index, generation_model, embedding_model,
    namespace_knowledge
):
    """Retrieves and synthesizes factual information from the Knowledge Base."""
    logging.info("[Researcher] Activated. Investigating topic...")
    try:
        topic = mcp_message['content'].get('topic_query')
        if not topic:
            raise ValueError("Researcher requires 'topic_query' in the input content.")

        results = query_pinecone(
            query_text=topic,
            namespace=namespace_knowledge,
            top_k=3,
            index=index,
            client=client,
            embedding_model=embedding_model
        )

        if not results:
            logging.warning("[Researcher] No relevant information found.")
            return create_mcp_message("Researcher", {"facts": "No data found on the topic."})

        logging.info(f"[Researcher] Found {len(results)} relevant chunks. Synthesizing...")
        source_texts = [match['metadata']['text'] for match in results]
        system_prompt = """You are an expert research synthesis AI.
Synthesize the provided source texts into a concise, bullet-pointed summary answering the user's topic."""
        user_prompt = f"Topic: {topic}\n\nSources:\n" + "\n\n---\n\n".join(source_texts)

        findings = call_llm_robust(
            system_prompt,
            user_prompt,
            client=client,
            generation_model=generation_model
        )
        return create_mcp_message("Researcher", {"facts": findings})
```

## Conceptual Diff

1. **Signature**: gains `client, index, generation_model, embedding_model, namespace_knowledge`
2. **Logging**: `print()` → `logging.info`/`logging.warning`; entire body wrapped in `try`
3. **Helper calls**: `query_pinecone` and `call_llm_robust` use explicit kwargs
4. **Critical fix — data contract**: returns `{"facts": ...}` dict in BOTH the success and the no-results paths

## Notes

- The Researcher does **not** simply pass through retrieved chunks. It uses an LLM with a strict synthesis prompt — this is the value-add and a primary hallucination defense.
- The system prompt subtly changed: Ch4 explicitly says "Do not add outside information." The Ch5 version trims this — but the discipline remains: the user prompt only ever contains retrieved sources
- `top_k=3` is intentional: more sources → more nuanced synthesis than a single-result retrieval
