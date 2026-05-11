# RAG Ingestion Examples — Data and Upload

Verbatim Python for blueprints, knowledge data, and upsert code. See `examples.md` for setup and helper functions.

## Context Blueprints (Procedural RAG)

```python
context_blueprints = [
    {
        "id": "blueprint_suspense_narrative",
        "description": "A precise Semantic Blueprint designed to generate suspenseful and tense narratives, suitable for children's stories. Focuses on atmosphere, perceived threats, and emotional impact. Ideal for creative writing.",
        "blueprint": json.dumps({
              "scene_goal": "Increase tension and create suspense.",
              "style_guide": "Use short, sharp sentences. Focus on sensory details (sounds, shadows). Maintain a slightly eerie but age-appropriate tone.",
              "participants": [
                { "role": "Agent", "description": "The protagonist experiencing the events." },
                { "role": "Source_of_Threat", "description": "The underlying danger or mystery." }
              ],
            "instruction": "Rewrite the provided facts into a narrative adhering strictly to the scene_goal and style_guide."
            })
    },
    {
        "id": "blueprint_technical_explanation",
        "description": "A Semantic Blueprint designed for technical explanation or analysis. This blueprint focuses on clarity, objectivity, and structure. Ideal for breaking down complex processes, explaining mechanisms, or summarizing scientific findings.",
        "blueprint": json.dumps({
              "scene_goal": "Explain the mechanism or findings clearly and concisely.",
              "style_guide": "Maintain an objective and formal tone. Use precise terminology. Prioritize factual accuracy and clarity over narrative flair.",
              "structure": ["Definition", "Function/Operation", "Key Findings/Impact"],
              "instruction": "Organize the provided facts into the defined structure, adhering to the style_guide."
            })
    },
    {
        "id": "blueprint_casual_summary",
        "description": "A goal-oriented context for creating a casual, easy-to-read summary. Focuses on brevity and accessibility, explaining concepts simply.",
        "blueprint": json.dumps({
              "scene_goal": "Summarize information quickly and casually.",
              "style_guide": "Use informal language. Keep it brief and engaging. Imagine explaining it to a friend.",
              "instruction": "Summarize the provided facts using the casual style guide."
            })
    }
]
```

```python
print(f"\nPrepared {len(context_blueprints)} context blueprints.")
```

## Knowledge Data (Factual RAG)

```python
knowledge_data_raw = """
Space exploration is the use of astronomy and space technology to explore outer space. The early era of space exploration was driven by a "Space Race" between the Soviet Union and the United States. The launch of the Soviet Union's Sputnik 1 in 1957, and the first Moon landing by the American Apollo 11 mission in 1969 are key landmarks.
...
Juno is a NASA space probe orbiting the planet Jupiter. It was launched on August 5, 2011, and entered a polar orbit of Jupiter on July 5, 2016.
...
A Mars rover is a remote-controlled motor vehicle designed to travel on the surface of Mars. NASA JPL managed several successful rovers including: Sojourner, Spirit, Opportunity, Curiosity, and Perseverance. The search for evidence of habitability and organic carbon on Mars is now a primary NASA objective. Perseverance also carried the Ingenuity helicopter.
"""
```

## Upload: Context Library

```python
# --- 6.1. Context Library ---
print(f"\nProcessing and uploading Context Library to namespace: {NAMESPACE_CONTEXT}")
vectors_context = []
for item in tqdm(context_blueprints):
    # We embed the DESCRIPTION (the intent)
    embedding = get_embeddings_batch([item['description']])[0]
    vectors_context.append({
        "id": item['id'],
        "values": embedding,
        "metadata": {
            "description": item['description'],
            # The blueprint itself (JSON string) is stored as metadata
            "blueprint_json": item['blueprint']
        }
    })
```

```python
# Upsert data
if vectors_context:
    index.upsert(vectors=vectors_context, namespace=NAMESPACE_CONTEXT)
    print(f"Successfully uploaded {len(vectors_context)} context vectors.")
```

## Upload: Knowledge Base (Chunk + Batch + Upsert)

```python
# --- 6.2. Knowledge Base ---
print(f"\nProcessing and uploading Knowledge Base to namespace: {NAMESPACE_KNOWLEDGE}")
# Chunk the knowledge data
knowledge_chunks = chunk_text(knowledge_data_raw)
print(f"Created {len(knowledge_chunks)} knowledge chunks.")
vectors_knowledge = []
batch_size = 100 # Process in batches
for i in tqdm(range(0, len(knowledge_chunks), batch_size)):
    batch_texts = knowledge_chunks[i:i+batch_size]
    batch_embeddings = get_embeddings_batch(batch_texts)

    batch_vectors = []
    for j, embedding in enumerate(batch_embeddings):
        chunk_id = f"knowledge_chunk_{i+j}"
        batch_vectors.append({
            "id": chunk_id,
            "values": embedding,
            "metadata": {
                "text": batch_texts[j]
            }
        })
    # Upsert the batch
    index.upsert(vectors=batch_vectors, namespace=NAMESPACE_KNOWLEDGE)
print(f"Successfully uploaded {len(knowledge_chunks)} knowledge vectors.")
```

## Expected Output

```
Processing and uploading Context Library to namespace: ContextLibrary
[Tqdm output for 3/3 iterations]
Successfully uploaded 3 context vectors.
Processing and uploading Knowledge Base to namespace: KnowledgeStore
Created 2 knowledge chunks.
[Tqdm output for 1/1 iterations]
Successfully uploaded 2 knowledge vectors.
```
