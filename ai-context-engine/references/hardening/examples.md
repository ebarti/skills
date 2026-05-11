# Hardening Examples

Verbatim Python code from Chapter 5 demonstrating the four hardening pillars.

## Production-Level Logging Configuration

Configure once at the top of your module so every helper emits timestamped, leveled output.

```python
# === Configure Production-Level Logging ===
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s')
```

## Context Management Utility (count_tokens)

The `tiktoken`-based "fuel gauge" — measure prompt cost before sending. Built with a fallback for models not in the registry.

```python
# === Context Management Utility (New) ===
def count_tokens(text, model="gpt-4"):
    """Counts the number of tokens in a text string for a given model."""
    try:
        encoding = tiktoken.encoding_for_model(model)
    except KeyError:
        # Fallback for models that might not be in the tiktoken registry
        encoding = tiktoken.get_encoding("cl100k_base")
    return len(encoding.encode(text))
```

## Hardened LLM Helper (Dependency Injection + Logging + Retry)

Notice the explicit `client` and `generation_model` arguments, the `@retry` decorator, structured logging, and catch-log-raise error handling.

```python
# === LLM Interaction (Hardened with Dependency Injection) ===
@retry(wait=wait_random_exponential(min=1, max=60), stop=stop_after_attempt(6))
def call_llm_robust(
    system_prompt, user_prompt, client, generation_model,
    json_mode=False
):
    """
    A centralized function to handle all LLM interactions with retries.
    UPGRADE: Now requires the 'client' and 'generation_model' objects to be passed in.
    """
    logging.info("Attempting to call LLM...")
    try:
        response_format = {"type": "json_object"} 
            if json_mode else {"type": "text"}
       # UPGRADE: Uses the passed-in client and model name for the API call.    
       response = client.chat.completions.create(
            model=generation_model,
            response_format=response_format,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
        )
        logging.info("LLM call successful.")
        return response.choices[0].message.content.strip()
    except APIError as e:
        logging.error(f"OpenAI API Error in call_llm_robust: {e}")
        raise e
    except Exception as e:
        logging.error(f"An unexpected error occurred in call_llm_robust: {e}")
        raise e
```

**Why it works**:
- Specific `APIError` is caught and logged before the generic `Exception` fallback.
- Both branches re-raise, so the orchestrator can halt cleanly.
- Caller chooses `client`/`generation_model` — same function works with any provider.

## Hardened Embedding Helper

Same DI pattern applied to embeddings.

```python
# === Embeddings (Hardened with Dependency Injection) ===
@retry(wait=wait_random_exponential(min=1, max=60),
    stop=stop_after_attempt(6)
)
def get_embedding(text, client, embedding_model):
    """
    Generates embeddings for a single text query with retries.
    UPGRADE: Now requires the 'client' and 'embedding_model' objects.
    """
    text = text.replace("\n", " ")
    try:
        # UPGRADE: Uses the passed-in client and model name.
        response = client.embeddings.create(input=[text], model=embedding_model)
        return response.data[0].embedding
    except APIError as e:
        logging.error(f"OpenAI API Error in get_embedding: {e}")
        raise e
    except Exception as e:
        logging.error(f"An unexpected error occurred in get_embedding: {e}")
        raise e
```

## Local Imports for a Flat Colab Directory

When all files live at the same level (Colab default), import each as a top-level module.

```python
# This works in a flat directory by importing each file directly.
import helpers
import agents
from registry import AGENT_TOOLKIT
from engine import context_engine
```

## Engine Room: The execute_and_display Function

The notebook's engine room — encapsulates the full run + presentation flow. Lives in the notebook, not in `engine.py`, to keep the library clean.

```python
# === ENGINE ROOM: The Main Execution Function ===
# This function contains all the logic to run the engine.
# We define it here so our final cell can be very simple.

import logging
import pprint
from IPython.display import display, Markdown

def execute_and_display(goal, config, client, pc):
    """
    Runs the context engine with a given goal and configuration,
    then displays the final output and the technical trace.
    """
    logging.info(f"******** Starting Engine for Goal: '{goal}' **********\n")

    # 1. Run the Context Engine using the provided configuration
    result, trace = context_engine(
        goal,
        client=client,
        pc=pc,
        **config  # Unpack the config dictionary into keyword arguments
    )

    # 2. Display the Final Result for the main reader
    print("--- FINAL OUTPUT ---")
    if result:
        display(Markdown(result))
    else:
        print(f"The engine failed to produce a result. Status: {trace.status}")

    # 3. Display the Technical Trace for the developer/technical reader
    print("\n\n--- TECHNICAL TRACE (for the tech reader) ---")
    if trace:
        print(f"Trace Status: {trace.status}")
        print(f"Total Duration: {trace.duration:.2f} seconds")
        print("Execution Steps:")
        # Use pprint for a clean, readable dictionary output
        pp = pprint.PrettyPrinter(indent=2)
        pp.pprint(trace.steps)
```

## Control Deck: Config + Goal Pattern

Two cells. The first defines the technical configuration; the second defines the goal and triggers the run. Nothing else.

```python
# 1. Define all configuration variables for this run in a dictionary
config = {
    "index_name": 'genai-mas-mcp-ch3',
    "generation_model": "gpt-5",
    "embedding_model": "text-embedding-3-small",
    "namespace_context": 'ContextLibrary',
    "namespace_knowledge": 'KnowledgeStore'
}
```

```python
#Example 1
# Define the high-level goal
goal = "[YOUR GOAL]"
# Call the execution function from the cell above
execute_and_display(goal, config, client, pc)
```

**Why it works**:
- The user only ever touches `goal` and `config` — pure separation of concerns.
- `**config` lets you extend technical parameters without changing the call signature.
- The same engine room handles every goal; only the control deck changes per task.
