# Summarizer Agent Examples

Verbatim Python from Chapter 6 covering the foundation utility, the Summarizer agent itself, registry integration, and post-execution token analysis.

## Foundation: `count_tokens` Helper

```python
# FILE: commons/helpers.py (existing code)
# This function is our primary tool for proactive token management.

def count_tokens(text, model="gpt-4"):
    """Counts the number of tokens in a text string for a given model."""
    try:
        encoding = tiktoken.encoding_for_model(model)
    except KeyError:
        # Fallback for models that might not be in the tiktoken registry
        encoding = tiktoken.get_encoding("cl100k_base")
    return len(encoding.encode(text))
```

**Why it works**:
- Wraps `tiktoken` and degrades gracefully via `cl100k_base` fallback when the model is not in the registry.
- Returns an integer that any component can use to make pre-call decisions about context size.

## The Summarizer Agent (full function)

```python
# FILE: commons/ch6/agents.py
# This new function is added to our existing agent library.
# It follows the established dependency injection and structured logging patterns.

def agent_summarizer(mcp_message, client, generation_model):
    """
    Reduces a large text to a concise summary based on an objective.
    Acts as a gatekeeper to manage token counts and costs.
    """
    logging.info("[Summarizer] Activated. Reducing context...")
    try:
        # Unpack the inputs from the MCP message
        text_to_summarize = mcp_message['content'].get('text_to_summarize')
        summary_objective = mcp_message['content'].get('summary_objective')

        if not text_to_summarize or not summary_objective:
            raise ValueError("Summarizer requires 'text_to_summarize' and 'summary_objective' in the input content.")

        # Define the prompts for the LLM
        system_prompt = """You are an expert summarization AI. Your task is to reduce the provided text to its essential points, guided by the user's specific objective. The summary must be concise, accurate, and directly address the stated goal."""
        user_prompt = f"""--- OBJECTIVE ---\n{summary_objective}\n\n--- TEXT TO SUMMARIZE ---\n{text_to_summarize}\n--- END TEXT ---\n\nGenerate the summary now."""

        # Call the hardened LLM helper to perform the summarization
        summary = call_llm_robust(
            system_prompt,
            user_prompt,
            client=client,
            generation_model=generation_model
        )

        # Return the summary in the standard MCP format
        return create_mcp_message("Summarizer", {"summary": summary})
    except Exception as e:
        logging.error(f"[Summarizer] An error occurred: {e}")
        raise e
```

**Why it works**:
- Self-contained with dependency injection (`client`, `generation_model`).
- Validates both required inputs and raises `ValueError` early.
- Returns a predictable MCP message with the `"summary"` key.
- Catches and re-raises with structured logging.

## Registry Integration

### Add to the registry dictionary

```python
# FILE: commons/ch6/registry.py
# The entire file is updated to integrate the new agent.

# === Imports ===
import logging
import agents
from helpers import create_mcp_message

# === 5. The Agent Registry (Final Hardened Version) ===
class AgentRegistry:
    def __init__(self):
        self.registry = {
            "Librarian": agents.agent_context_librarian,
            "Researcher": agents.agent_researcher,
            "Writer": agents.agent_writer,
            # --- NEW: Add the Summarizer Agent ---
            "Summarizer": agents.agent_summarizer,
        }
```

### Wire dependencies in `get_handler`

```python
    def get_handler(
        self, agent_name, client, index, generation_model,
        embedding_model, namespace_context, namespace_knowledge
    ):
        handler_func = self.registry.get(agent_name)
        if not handler_func:
            logging.error(f"Agent '{agent_name}' not found in registry.")
            raise ValueError(f"Agent '{agent_name}' not found in registry.")

        # --- UPDATED: Add a condition for the Summarizer ---
        if agent_name == "Librarian":
            return lambda mcp_message: handler_func(
                mcp_message, client=client, index=index,
                embedding_model=embedding_model,
                namespace_context=namespace_context
            )
        elif agent_name == "Researcher":
            return lambda mcp_message: handler_func(
                mcp_message, client=client, index=index,
                generation_model=generation_model,
                embedding_model=embedding_model,
                namespace_knowledge=namespace_knowledge
            )
        elif agent_name == "Writer":
            return lambda mcp_message: handler_func(
                mcp_message, client=client,
                generation_model=generation_model
            )
        elif agent_name == "Summarizer":
            return lambda mcp_message: handler_func(
                mcp_message, client=client,
                generation_model=generation_model
            )
        else:
            return handler_func
```

### Update the capabilities description (Planner-facing manual)

```python
    def get_capabilities_description(self):
        """Returns a structured description of the agents for the Planner LLM."""
        # --- UPDATED: Add the Summarizer's capabilities ---
        return """
Available Agents and their required inputs.
CRITICAL: You MUST use the exact input key names provided for each agent.

1. AGENT: Librarian
   ROLE: Retrieves Semantic Blueprints (style/structure instructions).
   INPUTS:
     - "intent_query": (String) A descriptive phrase of the desired style.
   OUTPUT: The blueprint structure (JSON string).

2. AGENT: Researcher
   ROLE: Retrieves and synthesizes factual information on a topic.
   INPUTS:
     - "topic_query": (String) The subject matter to research.
   OUTPUT: Synthesized facts (String).

3. AGENT: Summarizer
   ROLE: Reduces large text to a concise summary based on a specific objective. Ideal for managing token counts before a generation step.
   INPUTS:
     - "text_to_summarize": (String/Reference) The long text to be summarized.
     - "summary_objective": (String) A clear goal for the summary (e.g., "Extract key technical specifications").
   OUTPUT: A dictionary containing the summary: {"summary": "..."}.

4. AGENT: Writer
   ROLE: Generates or rewrites content by applying a Blueprint to source material.
   INPUTS:
     - "blueprint": (String/Reference) The style instructions (usually from Librarian).
     - "facts": (String/Reference) Factual information (usually from Researcher or Summarizer).
     - "previous_content": (String/Reference) Existing text for rewriting.
   OUTPUT: The final generated text (String).
"""
```

## Post-Execution Token Analysis

```python
# === Post-Execution Analysis: Quantifying Context Reduction ===

# Make sure to import the count_tokens utility
from helpers import count_tokens

# 1. Get the original text that was sent to the Summarizer
#    (This is the same variable we defined in the control deck)
original_text = large_text_from_researcher

# 2. Get the summarized text from the trace object
#    The trace object 'trace_1' was returned by the execute_and_display function.
#    We look inside the first step (index 0) of the execution trace.
summarized_text = trace_1.steps[0]['output']['summary']

# 3. Use the 'count_tokens' utility to measure both
original_tokens = count_tokens(original_text)
summarized_tokens = count_tokens(summarized_text)
reduction_percentage = (1 - (summarized_tokens / original_tokens)) * 100

# 4. Print the results
print("--- Context Reduction Analysis ---")
print(f"Original Text Tokens: {original_tokens}")
print(f"Summarized Text Tokens: {summarized_tokens}")
print(f"Token Reduction: {reduction_percentage:.1f}%")
```

**Outcome from the chapter's run**:
- Original text (`text_to_summarize`): 253 tokens.
- Final summary (`output`): 110 tokens.
- Token reduction: ~56.5%.

## Observed Trace Output (proof artifacts)

The Planner extracted a precise objective:

```python
'summary_objective': 'Extract only the key facts about '
                     "Juno's scientific mission and its "
                     'instruments/power system...'
```

The Summarizer returned a bullet-pointed summary in MCP form:

```python
'output': { 'summary': '- Operates in a polar orbit around Jupiter...'
                       '- Measures Jupiter’s composition, gravitational field...'
                       '- Investigates formation by probing the interior...'
                       '- Determines the amount of water in the deep atmosphere...'
                       '- Maps mass distribution and characterizes deep winds...'
                       '- Powered and stabilized by three very large solar-array wings...'
          }
```

The Writer received the lean summary via context chaining (not the original 253 tokens):

```python
'resolved_context': {
    'blueprint': { 'blueprint_json': '{"scene_goal": "Increase tension..."}'},
    'facts': { 'summary': '- Operates in a polar orbit...'},
    ...
}
```
