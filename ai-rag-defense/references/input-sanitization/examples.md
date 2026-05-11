# Input Sanitization Examples

Code examples for the `helper_sanitize_input` function and its use in a RAG pipeline.

## The `helper_sanitize_input` Function

Verbatim from `commons/ch7/helpers.py`:

```python
# FILE: commons/ch7/helpers.py
# === Security Utility (New for Chapter 7) ===
def helper_sanitize_input(text):
    """
    A simple sanitization function to detect and flag potential prompt injection patterns.
    Returns the text if clean, or raises a ValueError if a threat is detected.
    """
    injection_patterns = [
        r"ignore previous instructions",
        r"ignore all prior commands",
        r"you are now in.*mode",
        r"act as",
        r"print your instructions",
        r"sudo|apt-get|yum|pip install"
    ]

    for pattern in injection_patterns:
        if re.search(pattern, text, re.IGNORECASE):
            logging.warning(f"[Sanitizer] Potential threat detected with pattern: '{pattern}'")
            raise ValueError(f"Input sanitization failed. Potential threat detected.")

    logging.info("[Sanitizer] Input passed sanitization check.")
    return text
```

**How it works**:
- Maintains a list of regex patterns matching common prompt-injection phrases
- Iterates through patterns; on match, logs a warning and raises `ValueError`
- On clean pass, logs an info line and returns the text unmodified
- Provides a basic security checkpoint within the engine

## Usage Examples

### Sanitizing a Single Retrieved Chunk

```python
from commons.ch7.helpers import helper_sanitize_input

retrieved_text = vector_store.get_chunk(chunk_id)

try:
    clean_text = helper_sanitize_input(retrieved_text)
except ValueError:
    # Tainted chunk — discard and do NOT forward to the LLM
    clean_text = None
```

### Sanitizing All Retrieved Context Before LLM Synthesis

```python
def synthesize_with_rag(user_query, retriever, llm):
    chunks = retriever.search(user_query)

    clean_chunks = []
    for chunk in chunks:
        try:
            clean_chunks.append(helper_sanitize_input(chunk))
        except ValueError:
            # Skip tainted chunks; logging already happened inside the helper
            continue

    if not clean_chunks:
        raise RuntimeError("No clean context available after sanitization.")

    prompt = build_prompt(user_query, clean_chunks)
    return llm.generate(prompt)
```

**Why it works**:
- Sanitization runs *before* the LLM call — the only path to synthesis goes through the checkpoint
- Tainted chunks are discarded, not silently rewritten
- A complete failure (all chunks tainted) raises rather than producing a degraded answer with no context

## Bad Examples

### Forwarding Retrieved Text Directly to the LLM

```python
# Bad
chunks = retriever.search(user_query)
prompt = f"Context:\n{chunks}\n\nQuestion: {user_query}"
response = llm.generate(prompt)
```

**Problems**:
- No checkpoint between retrieval and LLM
- Any poisoned chunk hijacks the model
- No telemetry to detect attacks in flight

### Silently Stripping Suspicious Substrings

```python
# Bad
def naive_sanitize(text):
    return text.replace("ignore previous instructions", "")
```

**Problems**:
- Trivially bypassed (`Ignore Previous Instructions`, encoded variants, paraphrases)
- Hides the attack rather than surfacing it
- Caller has no signal that something was detected

### Sanitizing Only User Input

```python
# Bad
clean_query = helper_sanitize_input(user_query)
chunks = retriever.search(clean_query)
prompt = build_prompt(clean_query, chunks)  # chunks not sanitized
```

**Problems**:
- The primary RAG attack surface is *retrieved* text, not the user query
- A poisoned document still flows untouched into the LLM

## Refactoring Walkthrough

### Before

```python
def answer(query):
    chunks = vector_store.search(query)
    prompt = build_prompt(query, chunks)
    return llm.generate(prompt)
```

### After

```python
def answer(query):
    chunks = vector_store.search(query)
    clean_chunks = []
    for chunk in chunks:
        try:
            clean_chunks.append(helper_sanitize_input(chunk))
        except ValueError:
            continue  # warning already logged by the helper
    if not clean_chunks:
        raise RuntimeError("All retrieved context failed sanitization.")
    prompt = build_prompt(query, clean_chunks)
    return llm.generate(prompt)
```

### Changes Made

1. Inserted the sanitization checkpoint between retrieval and prompt construction
2. Per-chunk handling so one tainted document does not poison the entire batch
3. Hard failure when no clean context remains — never run the LLM on zero context silently
