# High-Fidelity Researcher Examples

Verbatim code for the upgraded Researcher agent and the NASA control deck. Pair with `examples.md` for the ingestion side.

## Example 3: High-Fidelity Researcher Agent

### Retrieval with metadata

```python
# FILE: commons/ch7/agents.py
from helpers import helper_sanitize_input

def agent_researcher(mcp_message, client, index, generation_model, embedding_model, namespace_knowledge):
    """
    Retrieves and synthesizes factual information, providing source citations.
    UPGRADE: Implements High-Fidelity RAG and input sanitization.
    """
    logging.info("[Researcher] Activated. Investigating topic with high fidelity...")
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
```

### Sanitize and collect unique sources

```python
        # Sanitize and Prepare Source Texts
        sanitized_texts = []
        sources = set()
        for match in results:
            try:
                clean_text = helper_sanitize_input(
                    match['metadata']['text'])
                sanitized_texts.append(clean_text)
                if 'source' in match['metadata']:
                    sources.add(match['metadata']['source'])
            except ValueError as e:
                logging.warning(f"[Researcher] A retrieved chunk failed sanitization and was skipped. Reason: {e}")
                continue
```

### Citation-aware synthesis

```python
    if not sanitized_texts:
            logging.error("[Researcher] All retrieved chunks failed sanitization. Aborting.")
            return create_mcp_message("Researcher", {"answer": "Could not generate a reliable answer as retrieved data was suspect.", "sources": []})

        # 3. Synthesize with a Citation-Aware Prompt
        logging.info(f"[Researcher] Found {len(sanitized_texts)} relevant chunks. Synthesizing answer with citations...")

        system_prompt = """You are an expert research synthesis AI. Your task is to provide a clear, factual answer to the user's topic based *only* on the provided source texts. After the answer, you MUST provide a "Sources" section listing the unique source document names you used."""

        source_material = "\n\n---\n\n".join(sanitized_texts)
        user_prompt = f"Topic: {topic}\n\nSources:\n{source_material}\n\n--- \nSynthesize your answer and list the source documents now."

        findings = call_llm_robust(
            system_prompt,
            user_prompt,
            client=client,
            generation_model=generation_model
        )

        # We can also append the sources we found programmatically for robustness
        final_output = f"{findings}\n\n**Sources:**\n" + "\n".join(
            [f"- {s}" for s in sorted(list(sources))])

        return create_mcp_message(
            "Researcher", {"answer_with_sources": final_output}
        )

    except Exception as e:
        logging.error(f"[Researcher] An error occurred: {e}")
        raise e
```

**Why it works**:
- Sources are deduplicated via a `set` and sorted for deterministic output.
- LLM is constrained to provided texts and required to emit a Sources section.
- Programmatic source appending guarantees attribution even if the LLM omits one.
- Aborts cleanly if every chunk fails sanitization rather than synthesizing without evidence.

## Example 4: NASA Control Deck

```python
# FILE: NASA_Research_Assistant.ipynb
# === CONTROL DECK: NASA Research Assistant ===

# 1. Define a research goal that requires verifiable, cited answers.
goal = "What are the primary scientific objectives of the Juno mission, and what makes its design unique? Please cite your sources."

# 2. Use the standard configuration
config = {
    "index_name": 'genai-mas-mcp-ch3',
    "generation_model": "gpt-5",
    "embedding_model": "text-embedding-3-small",
    "namespace_context": 'ContextLibrary',
    "namespace_knowledge": 'KnowledgeStore'
}

# 3. Call the execution function
execute_and_display(goal, config, client, pc)
```

### Sample trace output

```text
'output': { 'answer_with_sources': 'NASA Juno mission — primary scientific objectives...
        ...enabling unique coverage of the polar magnetosphere [1].
        **Sources:**
        - juno_mission_overview.txt
        - perseverance_rover_tools.txt'}
```

**Why it works**:
- The goal explicitly requests citations, giving the Planner a clear signal to use the high-fidelity Researcher.
- The trace proves the Researcher returned both an answer and verifiable source filenames.
- Demonstrates an emergent six-step plan: Librarian (steps 1, 4) -> Researcher (steps 2, 3) -> Writer (steps 5, 6).
