# High-Fidelity RAG Examples

Verbatim code from the chapter. Split across files for readability:

- This file: source document preparation + metadata-aware ingestion.
- `examples-researcher.md`: the upgraded Researcher agent and NASA control deck.

## Example 1: Source Document Preparation

### Juno mission document

```python
#@title Preparing the NASA Source Documents
# Create a directory to store our source documents
import os
if not os.path.exists("nasa_documents"):
    os.makedirs("nasa_documents")

# --- Document 1: Juno Mission ---
juno_text = """
The Juno mission's primary goal is to understand the origin and evolution of Jupiter. Underneath its dense cloud cover, Jupiter safeguards secrets to the fundamental processes and conditions that governed our solar system during its formation. As our primary example of a giant planet, Jupiter can also provide critical knowledge for understanding the planetary systems being discovered around other stars. Juno's specific scientific objectives include:
1. Origin: Determine the abundance of water and constrain the planet's core mass to decide which theory of the planet's formation is correct.
2. Atmosphere: Understand the composition, temperature, cloud motions and other properties of Jupiter's atmosphere.
3. Magnetosphere: Map Jupiter's magnetic and gravity fields, revealing the planet's deep structure and exploring the polar magnetosphere.
Juno is the first space mission to orbit an outer-planet from pole to pole, and the first to fly below the planet's hazardous radiation belts.
"""
with open("nasa_documents/juno_mission_overview.txt", "w") as f:
    f.write(juno_text)
```

### Perseverance rover document

```python
# --- Document 2: Perseverance Rover ---
perseverance_text = """
The Perseverance rover's primary mission on Mars is to seek signs of ancient life and collect samples of rock and regolith (broken rock and soil) for possible return to Earth. The rover has a drill to collect core samples of the most promising rocks and soils, and sets them aside in a "cache" on the surface of Mars. The mission also provides opportunities to gather knowledge and demonstrate technologies that address the challenges of future human expeditions to Mars. These include testing a method for producing oxygen from the Martian atmosphere, identifying other resources (such as subsurface water), improving landing techniques, and characterizing weather, dust, and other potential environmental conditions that could affect future astronauts living and working on Mars. Perseverance carries the Ingenuity Helicopter, a technology demonstration to test the first powered flight on Mars.
"""
with open("nasa_documents/perseverance_rover_tools.txt", "w") as f:
    f.write(perseverance_text)

print("✅ Created 2 sample NASA document files in the 'nasa_documents' directory.")
```

**Why it works**:
- One topic per file means the filename is a meaningful citation.
- Files live in a dedicated directory the loader can iterate.

## Example 2: Metadata-Aware Knowledge Base Ingestion

### Dynamic document loading

```python
# Load all documents from our new directory
knowledge_base = {}
doc_dir = "nasa_documents"
for filename in os.listdir(doc_dir):
    if filename.endswith(".txt"):
        with open(os.path.join(doc_dir, filename), 'r') as f:
            knowledge_base[filename] = f.read()

print(f"∎ Loaded {len(knowledge_base)} documents into the knowledge base.")
```

### Upsert chunks with `source` metadata

```python
# --- 6.2. Knowledge Base (UPGRADED FOR HIGH-FIDELITY RAG) ---
print(f"\nProcessing and uploading Knowledge Base to namespace: {NAMESPACE_KNOWLEDGE}")
batch_size = 100
total_vectors_uploaded = 0

for doc_name, doc_content in knowledge_base.items():
    print(f"  - Processing document: {doc_name}")
    knowledge_chunks = chunk_text(doc_content)

    for i in tqdm(range(0, len(knowledge_chunks), batch_size),
        desc=f"  Uploading {doc_name}"
    ):
        batch_texts = knowledge_chunks[i:i+batch_size]
        batch_embeddings = get_embeddings_batch(batch_texts)
        batch_vectors = []
        for j, embedding in enumerate(batch_embeddings):
            chunk_id = f"{doc_name}_chunk_{total_vectors_uploaded + j}"

            batch_vectors.append({
                "id": chunk_id,
                "values": embedding,
                "metadata": {
                    "text": batch_texts[j],
                    "source": doc_name
                }
            })

        index.upsert(vectors=batch_vectors, namespace=NAMESPACE_KNOWLEDGE)
    total_vectors_uploaded += len(knowledge_chunks)
```

**Why it works**:
- Adds a single `"source": doc_name` field that becomes the foundation of verifiability.
- Per-document loop keeps each chunk attributed correctly.

### Verification probe

```python
#@title Verify Metadata Ingestion
import pprint
print("Querying a sample vector to verify metadata...")

query_embedding = get_embeddings_batch(["What is the Juno mission?"])[0]

results = index.query(
    vector=query_embedding,
    top_k=1,
    namespace=NAMESPACE_KNOWLEDGE,
    include_metadata=True
)

if results['matches']:
    top_match_metadata = results['matches'][0]['metadata']
    print("\n✅ Verification successful! Metadata of top match:")
    pprint.pprint(top_match_metadata)
else:
    print("❌ Verification failed. No results found.")
```

**Why it works**:
- Confirms the `source` field is actually queryable, not just written.
- Always run this cell at the end of the ingestion notebook.
