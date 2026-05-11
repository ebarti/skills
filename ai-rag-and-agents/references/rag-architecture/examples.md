# RAG Architecture Examples

Architecture diagrams and a basic RAG implementation in Python.

## High-Level RAG Architecture

```
                +--------------------+
                |    User Query      |
                +---------+----------+
                          |
                          v
            +-------------+--------------+
            |          Retriever         |
            |  (indexing + querying)     |
            +-------------+--------------+
                          |
                          v  top-k relevant chunks
            +-------------+--------------+
            |       Post-processing      |
            |  (join chunks + prompt)    |
            +-------------+--------------+
                          |
                          v  final prompt
            +-------------+--------------+
            |          Generator         |
            |        (LLM model)         |
            +-------------+--------------+
                          |
                          v
                    +-----+------+
                    |   Answer   |
                    +------------+

              ^ External memory feeds the retriever:
              | internal DB, user chat history, internet
```

## Indexing vs Querying (the two retriever phases)

```
INDEXING (offline, runs when data changes)
    Documents -> chunk -> embed/tokenize -> store in index

QUERYING (online, runs per user query)
    Query -> embed/tokenize -> rank against index -> top-k chunks
```

## Bad Example: Stuff Everything Into the Prompt

```python
# Anti-pattern: dump the entire knowledge base in the prompt every call.
from anthropic import Anthropic

client = Anthropic()

with open("entire_company_handbook.txt") as f:
    handbook = f.read()  # 800K tokens

def answer(question: str) -> str:
    return client.messages.create(
        model="claude-opus-4-5",
        max_tokens=1024,
        messages=[{
            "role": "user",
            "content": f"{handbook}\n\nQuestion: {question}",
        }],
    ).content[0].text
```

**Problems**:
- Exceeds (or strains) the context window.
- Pays for ~800K input tokens on every query.
- Model "loses" the relevant section in the noise.
- Can't scope to per-user data.

## Good Example: Basic RAG in Python

```python
# Minimal RAG: retriever (embedding-based) + generator (Claude).
from anthropic import Anthropic
from sentence_transformers import SentenceTransformer
import numpy as np

client = Anthropic()
embedder = SentenceTransformer("all-MiniLM-L6-v2")

# ---- 1. Indexing (offline) ----
def chunk(text: str, size: int = 500) -> list[str]:
    return [text[i:i + size] for i in range(0, len(text), size)]

documents = chunk(open("entire_company_handbook.txt").read())
doc_embeddings = embedder.encode(documents, normalize_embeddings=True)

# ---- 2. Querying (online) ----
def retrieve(query: str, k: int = 5) -> list[str]:
    q_emb = embedder.encode([query], normalize_embeddings=True)[0]
    scores = doc_embeddings @ q_emb           # cosine sim (normalized)
    top_k = np.argsort(scores)[-k:][::-1]
    return [documents[i] for i in top_k]

# ---- 3. Generation ----
def answer(question: str) -> str:
    chunks = retrieve(question, k=5)
    context = "\n\n---\n\n".join(chunks)
    prompt = (
        f"Use the context below to answer the question.\n\n"
        f"Context:\n{context}\n\n"
        f"Question: {question}"
    )
    resp = client.messages.create(
        model="claude-opus-4-5",
        max_tokens=1024,
        messages=[{"role": "user", "content": prompt}],
    )
    return resp.content[0].text
```

**Why it works**:
- Clean separation of retriever (`retrieve`) and generator (`answer`).
- Indexes once, queries cheaply per request.
- Sends only the top-k relevant chunks, not the whole corpus.
- Easy to swap the embedder, the vector store, or the LLM independently.

## Refactoring Walkthrough: Long-Context to RAG

### Before

```python
# Single 800K-token call per question.
def answer(question: str) -> str:
    return llm(f"{whole_handbook}\n\nQ: {question}")
```

### After

```python
# Retrieve, then generate with only the relevant slice.
def answer(question: str) -> str:
    relevant = retrieve(question, k=5)          # ~2.5K tokens
    return llm(f"{join(relevant)}\n\nQ: {question}")
```

### Changes Made

1. Split the handbook into chunks and built an embedding index once, offline.
2. Replaced the static giant prompt with a per-query top-k retrieval.
3. Kept the generator interface the same — only the context construction changed.
4. Result: lower cost per query, lower latency, and the model focuses on the relevant section instead of scanning 800K tokens.
