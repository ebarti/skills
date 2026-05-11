# Retrieval Optimization Examples

Concrete Python code for chunking, reranking, query rewriting, contextual retrieval, multimodal RAG, and tabular RAG.

## Chunking Strategies Side-by-Side

### Fixed-Length Character Chunking

```python
def chunk_by_chars(text: str, size: int = 2048, overlap: int = 20) -> list[str]:
    chunks = []
    start = 0
    while start < len(text):
        end = min(start + size, len(text))
        chunks.append(text[start:end])
        start = end - overlap  # slide back to overlap
    return chunks
```

### Recursive Splitting

```python
def recursive_split(text: str, max_size: int = 2048) -> list[str]:
    if len(text) <= max_size:
        return [text]
    # Try section → paragraph → sentence
    for sep in ("\n\n\n", "\n\n", "\n", ". "):
        if sep in text:
            parts = text.split(sep)
            chunks = []
            for p in parts:
                chunks.extend(recursive_split(p, max_size))
            return chunks
    # Fallback: hard character split
    return chunk_by_chars(text, size=max_size, overlap=20)
```

### Token-Based Chunking

```python
import tiktoken

def chunk_by_tokens(text: str, model: str = "gpt-4o", max_tokens: int = 512,
                    overlap: int = 20) -> list[str]:
    enc = tiktoken.encoding_for_model(model)
    tokens = enc.encode(text)
    chunks = []
    start = 0
    while start < len(tokens):
        end = min(start + max_tokens, len(tokens))
        chunks.append(enc.decode(tokens[start:end]))
        start = end - overlap
    return chunks
```

**Trade-off**: aligns with generator tokenizer but requires reindexing if you switch models.

### Domain-Specific: Q&A Pair Chunking

```python
def chunk_qa(qa_doc: list[dict]) -> list[str]:
    # Each pair is one chunk: keeps question and answer together
    return [f"Q: {pair['question']}\nA: {pair['answer']}" for pair in qa_doc]
```

## Reranker Integration

### Cheap Retriever → Cross-Encoder Reranker

```python
from sentence_transformers import CrossEncoder

reranker = CrossEncoder("cross-encoder/ms-marco-MiniLM-L-6-v2")

def retrieve_and_rerank(query: str, retriever, top_k: int = 50,
                        keep: int = 5) -> list[str]:
    candidates = retriever.search(query, top_k=top_k)            # cheap recall
    pairs = [(query, doc) for doc in candidates]
    scores = reranker.predict(pairs)                              # precise scoring
    ranked = sorted(zip(candidates, scores), key=lambda x: -x[1])
    return [doc for doc, _ in ranked[:keep]]
```

### Time-Decayed Reranking

```python
import math
from datetime import datetime

def time_decay_rerank(candidates: list[dict], half_life_days: float = 30):
    now = datetime.utcnow()
    for c in candidates:
        age_days = (now - c["timestamp"]).days
        decay = math.exp(-math.log(2) * age_days / half_life_days)
        c["final_score"] = c["relevance"] * decay
    return sorted(candidates, key=lambda c: -c["final_score"])
```

## Query Rewriting

### Multi-Turn Rewrite with an LLM

```python
import anthropic

client = anthropic.Anthropic()

REWRITE_PROMPT = (
    "Given the following conversation, rewrite the last user input to "
    "reflect what the user is actually asking. The rewritten query must "
    "stand on its own without prior context. If you cannot resolve a "
    "reference (e.g., 'his wife') from the conversation, respond with "
    "UNRESOLVABLE and explain what's missing."
)

def rewrite_query(history: list[dict]) -> str:
    msg = client.messages.create(
        model="claude-opus-4-7",
        max_tokens=200,
        system=REWRITE_PROMPT,
        messages=history,
    )
    return msg.content[0].text

# Example
history = [
    {"role": "user", "content": "When was the last time John Doe bought from us?"},
    {"role": "assistant", "content": "John last bought a Fruity Fedora on Jan 3, 2030."},
    {"role": "user", "content": "How about Emily Doe?"},
]
# → "When was the last time Emily Doe bought something from us?"
```

## Contextual Retrieval (Anthropic's Technique)

```python
CONTEXTUALIZE_PROMPT = """<document>
{whole_document}
</document>

Here is the chunk we want to situate within the whole document:

<chunk>
{chunk_content}
</chunk>

Please give a short succinct context to situate this chunk within the overall
document for the purposes of improving search retrieval of the chunk. Answer
only with the succinct context and nothing else."""

def contextualize_chunk(whole_document: str, chunk: str) -> str:
    msg = client.messages.create(
        model="claude-opus-4-7",
        max_tokens=120,
        messages=[{
            "role": "user",
            "content": CONTEXTUALIZE_PROMPT.format(
                whole_document=whole_document, chunk_content=chunk),
        }],
    )
    context = msg.content[0].text.strip()
    return f"{context}\n\n{chunk}"  # prepend, then index

# Index the augmented chunks instead of raw chunks
augmented = [contextualize_chunk(doc, c) for c in recursive_split(doc)]
```

## Question Augmentation for FAQ

```python
def augment_with_questions(article: str, questions: list[str]) -> str:
    q_block = "\n".join(f"- {q}" for q in questions)
    return f"Related questions:\n{q_block}\n\nArticle:\n{article}"

article = augment_with_questions(
    reset_password_doc,
    ["How to reset password?", "I forgot my password",
     "I can't log in", "Help, I can't find my account"],
)
```

## Multimodal RAG with CLIP

```python
import torch
from PIL import Image
from transformers import CLIPModel, CLIPProcessor

model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")

def embed_image(path: str) -> torch.Tensor:
    inputs = processor(images=Image.open(path), return_tensors="pt")
    with torch.no_grad():
        return model.get_image_features(**inputs)[0]

def embed_text(text: str) -> torch.Tensor:
    inputs = processor(text=[text], return_tensors="pt", padding=True)
    with torch.no_grad():
        return model.get_text_features(**inputs)[0]

# Index: embed all images and texts; store in any vector DB.
# Query: embed query text and search nearest neighbors across both modalities.
```

## RAG with Tabular Data (Text-to-SQL)

```python
import sqlite3

SCHEMA = """
Table: Sales
Columns: order_id INT, timestamp DATETIME, product_id INT,
         product TEXT, unit_price REAL, units INT, total REAL
"""

TEXT_TO_SQL_PROMPT = (
    "You are a SQL generator. Given the schema and a user question, "
    "output ONLY the SQL query.\n\nSchema:\n{schema}\n\nQuestion: {q}"
)

def text_to_sql(question: str, schema: str = SCHEMA) -> str:
    msg = client.messages.create(
        model="claude-opus-4-7",
        max_tokens=300,
        messages=[{"role": "user",
                   "content": TEXT_TO_SQL_PROMPT.format(schema=schema, q=question)}],
    )
    return msg.content[0].text.strip()

def answer_with_table(conn: sqlite3.Connection, question: str) -> str:
    sql = text_to_sql(question)
    rows = conn.execute(sql).fetchall()
    final = client.messages.create(
        model="claude-opus-4-7",
        max_tokens=400,
        messages=[{
            "role": "user",
            "content": f"Question: {question}\nSQL result: {rows}\nWrite the answer.",
        }],
    )
    return final.content[0].text

# Example: "How many units of Fruity Fedora were sold in the last 7 days?"
# → SELECT SUM(units) FROM Sales WHERE product = 'Fruity Fedora'
#     AND timestamp >= datetime('now', '-7 days');
```

### Adding Table Selection (When Many Tables Exist)

```python
def select_tables(question: str, table_summaries: dict[str, str]) -> list[str]:
    summary = "\n".join(f"{name}: {desc}" for name, desc in table_summaries.items())
    msg = client.messages.create(
        model="claude-opus-4-7",
        max_tokens=200,
        messages=[{"role": "user",
                   "content": f"Tables:\n{summary}\n\nQuestion: {question}\n"
                              "Return JSON list of table names needed."}],
    )
    return eval(msg.content[0].text)  # parse safely in production
```
