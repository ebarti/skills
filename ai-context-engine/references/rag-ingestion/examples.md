# RAG Ingestion Examples — Setup and Helpers

Verbatim Python from `RAG_Pipeline.ipynb` covering install, init, and helper functions. See `examples-upload.md` for blueprints, knowledge data, and upsert code.

## Install and Imports

```
!pip install tqdm==4.67.1 --upgrade
!pip install openai==1.104.2
!pip install pinecone==7.0.0 tqdm==4.67.1 tenacity==8.3.0
```

```python
# Imports for this notebook
import json
import time
from tqdm.auto import tqdm
import tiktoken
from pinecone import Pinecone, ServerlessSpec
from tenacity import retry, stop_after_attempt, wait_random_exponential
# general imports required in the notebooks of this book
import re
import textwrap
from IPython.display import display, Markdown
import copy
```

## Configuration and Secrets

```python
import os
from openai import OpenAI
from google.colab import userdata

# Load the API key from Colab secrets, set the env var, then init the client
...
# Configuration
EMBEDDING_MODEL = "text-embedding-3-small"
EMBEDDING_DIM = 1536 # Dimension for text-embedding-3-small
GENERATION_MODEL = "gpt-5"
```

Note: Falls back to environment variables when running outside Colab. Required env vars: `OPENAI_API_KEY`, `PINECONE_API_KEY`.

## Pinecone Init: Clients, Index, Namespaces

```python
try:
    # Standard way to access secrets securely in Google Colab
    from google.colab import userdata
    PINECONE_API_KEY = userdata.get('PINECONE_API_KEY')
...
```

```python
# --- Initialize Clients ---
client = OpenAI(api_key=OPENAI_API_KEY)
pc = Pinecone(api_key=PINECONE_API_KEY)

# --- Define Index and Namespaces ---
INDEX_NAME = 'genai-mas-mcp-ch3'
NAMESPACE_KNOWLEDGE = "KnowledgeStore"
NAMESPACE_CONTEXT = "ContextLibrary"

# Define Serverless Specification
spec = ServerlessSpec(cloud='aws', region='us-east-1')
```

## Create Index If Missing

```python
# Check if index exists
if INDEX_NAME not in pc.list_indexes().names():
    print(f"Index '{INDEX_NAME}' not found. Creating new serverless index...")
    pc.create_index(
        name=INDEX_NAME,
        dimension=EMBEDDING_DIM,
        metric='cosine',
        spec=spec
    )
    # Wait for index to be ready
    while not pc.describe_index(INDEX_NAME).status['ready']:
        print("Waiting for index to be ready...")
        time.sleep(1)
    print("Index created successfully. It is new and empty.")
```

## Clear Namespaces (Demo Only)

```python
else:
    print(f"Index '{INDEX_NAME}' already exists. Clearing namespaces for a fresh start...")
    index = pc.Index(INDEX_NAME)
    namespaces_to_clear = [NAMESPACE_KNOWLEDGE, NAMESPACE_CONTEXT]
```

```python
    for namespace in namespaces_to_clear:
        # Check if namespace exists and has vectors before deleting
        stats = index.describe_index_stats()
        if namespace in stats.namespaces
        AND stats.namespaces[namespace].vector_count > 0:
            print(f"Clearing namespace '{namespace}'...")
            index.delete(delete_all=True, namespace=namespace)
```

```python
    # **CRITICAL FUNCTTION: Wait for deletion to complete**
            while True:
                stats = index.describe_index_stats()
                if namespace not in stats.namespaces or
                stats.namespaces[namespace].vector_count == 0:
                    print(f"Namespace '{namespace}' cleared successfully.")
                    break
                print(f"Waiting for namespace '{namespace}' to clear...")
                time.sleep(5) # Poll every 5 seconds
        else:
            print(f"Namespace '{namespace}' is already empty or does not exist. Skipping.")
```

```python
# Connect to the index for subsequent operations
index = pc.Index(INDEX_NAME)
```

## Helpers: Tokenizer, Chunking, Embedding

```python
# Initialize tokenizer for robust, token-aware chunking
tokenizer = tiktoken.get_encoding("cl100k_base")
```

```python
def chunk_text(text, chunk_size=400, overlap=50):
    """Chunks text based on token count with overlap (Best practice for RAG)."""
    tokens = tokenizer.encode(text)
    chunks = []
    for i in range(0, len(tokens), chunk_size - overlap):
        chunk_tokens = tokens[i:i + chunk_size]
        chunk_text = tokenizer.decode(chunk_tokens)
        # Basic cleanup
        chunk_text = chunk_text.replace("\n", " ").strip()
        if chunk_text:
            chunks.append(chunk_text)
    return chunks
```

```python
@retry(
    wait=wait_random_exponential(min=1, max=60),
    stop=stop_after_attempt(6)
)
def get_embeddings_batch(texts, model=EMBEDDING_MODEL):
    """Generates embeddings for a batch of texts using OpenAI, with retries."""
    # OpenAI expects the input texts to have newlines replaced by spaces
    texts = [t.replace("\n", " ") for t in texts]
    response = client.embeddings.create(input=texts, model=model)
    return [item.embedding for item in response.data]
```
