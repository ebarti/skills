# Agent Registry Examples

Verbatim Python from Chapter 4 (initial registry) and Chapter 5 (hardened, modular registry with dependency injection).

## Chapter 4: Initial Agent Registry

### Registry initialization

```python
class AgentRegistry:
    def __init__(self):
        self.registry = {
            "Librarian": agent_context_librarian,
            "Researcher": agent_researcher,
            "Writer": agent_writer,
        }
```

**What it shows**: A simple name-to-function dictionary. Adding a new agent (e.g., "Critic", "Editor") only requires a new entry here.

### `get_handler` (initial form)

```python
    def get_handler(self, agent_name):
                    """Retrieves the function associated with an agent name."""
        handler = self.registry.get(agent_name)
        if not handler:
            raise ValueError(f"Agent '{agent_name}' not found in registry.")
        return handler
```

**What it shows**: Plain lookup with a `ValueError` on missing names. No dependency injection yet; agents are returned as-is.

### `get_capabilities_description` (LLM-facing context)

```python
    def get_capabilities_description(self):
    """
Returns a structured description of the agents for the Planner LLM.
This is crucial for the Planner to understand how to use the agents.
        """

        return """
Available Agents and their required inputs:
1. AGENT: Librarian
   ROLE: Retrieves Semantic Blueprints (style/structure instructions).
     INPUTS:
     - "intent_query": (String) A descriptive phrase of the desired style or format.
     OUTPUT: The blueprint structure (JSON string).

2. AGENT: Researcher
   ROLE: Retrieves and synthesizes factual information on a topic.
     INPUTS:
     - "topic_query": (String) The subject matter to research.
     OUTPUT: Synthesized facts (String).

3. AGENT: Writer
     ROLE: Generates or rewrites content by applying a Blueprint to source material.
     INPUTS:
- "blueprint": (String/Reference) The style instructions (usually from Librarian).
- "facts": (String/Reference) Factual information (usually from Researcher). Use this for new content generation.
- "previous_content": (String/Reference) Existing text (usually from a prior Writer step). Use this for rewriting/adapting content.
   OUTPUT: The final generated text (String).
""": Final generated text
        """
```

**What it shows**: The Planner LLM consumes this text to discover available agents, their inputs (named and typed), and outputs. Clarity here drives plan quality.

### Singleton instantiation

```python
AGENT_TOOLKIT = AgentRegistry()
```

**What it shows**: A single module-level instance activates the registry across the engine.

---

## Chapter 5: Hardened Agent Registry (`registry.py`)

The registry is moved into its own module. Agent functions are now imported explicitly and dependencies are injected through `get_handler`.

### Module imports

```python
import logging
import agents
```

**Why**: Splitting the registry into its own file exposed the implicit notebook-global namespace. Bare references caused `NameError`. The fix is explicit `import agents` plus qualified function names.

### Registry initialization with `agents.` prefix

```python
class AgentRegistry:
    def __init__(self):
        self.registry = {
            # Add the "agents." prefix to each function name
            "Librarian": agents.agent_context_librarian,
            "Researcher": agents.agent_researcher,
            "Writer": agents.agent_writer,
        }
```

**What changed**: Same agents, but each value is now `agents.<func>` so the registry is self-contained and modular.

### `get_handler` as dependency injector

```python
    def get_handler(
        self, agent_name, client, index, generation_model,
        embedding_model, namespace_context, namespace_knowledge
    ):
        handler_func = self.registry.get(agent_name)
        if not handler_func:
            logging.error(f"Agent '{agent_name}' not found in registry.")
            raise ValueError(f"Agent '{agent_name}' not found in registry.")

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
        else:
            return handler_func
```

**What changed**:
- Signature accepts shared infrastructure (`client`, `index`, `generation_model`, `embedding_model`, `namespace_context`, `namespace_knowledge`)
- Logs and raises on unknown agent names
- Returns a `lambda mcp_message: ...` per agent, binding only the dependencies that agent needs
- Librarian gets RAG context-side dependencies; Researcher gets generation + knowledge namespace; Writer only needs the generation model

---

## Refactoring Walkthrough

### Before (Chapter 4, notebook)

```python
class AgentRegistry:
    def __init__(self):
        self.registry = {
            "Librarian": agent_context_librarian,
            "Researcher": agent_researcher,
            "Writer": agent_writer,
        }

    def get_handler(self, agent_name):
        handler = self.registry.get(agent_name)
        if not handler:
            raise ValueError(f"Agent '{agent_name}' not found in registry.")
        return handler
```

### After (Chapter 5, `registry.py`)

```python
import logging
import agents

class AgentRegistry:
    def __init__(self):
        self.registry = {
            "Librarian": agents.agent_context_librarian,
            "Researcher": agents.agent_researcher,
            "Writer": agents.agent_writer,
        }

    def get_handler(
        self, agent_name, client, index, generation_model,
        embedding_model, namespace_context, namespace_knowledge
    ):
        handler_func = self.registry.get(agent_name)
        if not handler_func:
            logging.error(f"Agent '{agent_name}' not found in registry.")
            raise ValueError(f"Agent '{agent_name}' not found in registry.")

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
        else:
            return handler_func
```

### Changes Made

1. **`import agents`** added so `registry.py` is self-contained outside the notebook namespace.
2. **`agents.` prefix** on every registered function to resolve `NameError` from cross-module references.
3. **`logging`** added and an explicit log call before the `ValueError` for observability.
4. **`get_handler` signature** expanded to accept all shared infrastructure (`client`, `index`, `generation_model`, `embedding_model`, `namespace_context`, `namespace_knowledge`).
5. **Per-agent lambdas** inject only the dependencies each agent needs, returning a uniform `lambda mcp_message: ...` to the Executor.
6. **Default `else` branch** returns the bare handler for agents without injected dependencies.
