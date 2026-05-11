# MCP Protocol Examples

Code examples for initializing the LLM client and defining/using MCP messages, taken verbatim from the book.

## Client Initialization

### OpenAI Client Setup

```python
#@title 1. Initializing the Client
# -------------------------------------------------------------------------
# We'll need the `openai` library to communicate with the LLM.
# Note: This notebook assumes you have already run a setup cell in your Colab
# environment to load your API key from Colab Secrets into an environment
# variable, as you specified.
# -------------------------------------------------------------------------
import json

# --- Initialize the OpenAI Client ---
# The client will automatically read the OPENAI_API_KEY from your environment.
client = OpenAI()
print("OpenAI client initialized.")
```

**Why it works**:
- `OpenAI()` is constructed with no arguments — the SDK reads `OPENAI_API_KEY` from the environment, keeping the secret out of source
- `json` is imported up front so structured MCP messages can be displayed readably later
- The print statement provides immediate confirmation that initialization succeeded

**Expected output**:
```
OpenAI client initialized.
```

## MCP Message Definition

### Simplified MCP Message (Python Dict)

```python
#@title 2. Defining the Protocol: The MCP Standard
# -------------------------------------------------------------------------
# Before we build our agents, we must define the language they will speak.
# MCP provides a simple, structured way to pass context. For this example,
# our MCP message will be a Python dictionary with key fields.
# -------------------------------------------------------------------------
def create_mcp_message(sender, content, metadata=None):
    """Creates a standardized MCP message."""
    return {
        "protocol_version": "1.0",
        "sender": sender,
        "content": content,
        "metadata": metadata or {}
    }
print("--- Example MCP Message (Our Simplified Version) ---")
example_mcp = create_mcp_message(
    sender="Orchestrator",
    content="Research the benefits of the Mediterranean diet.",
    metadata={"task_id": "T-123", "priority": "high"}
)
print(json.dumps(example_mcp, indent=2))
```

**Why it works**:
- Single helper (`create_mcp_message`) guarantees every message has the same shape
- `metadata or {}` ensures the field is always a dict, never `None` — safe to read downstream
- `protocol_version` is embedded so receivers can detect mismatches
- Three explicit inputs (sender, content, optional metadata) keep call sites self-documenting

## Sample MCP Message Between Agents

### Orchestrator → Researcher Task Message

The output of `create_mcp_message` rendered as JSON — this is the exact structure passed between agents:

```json
--- Example MCP Message (Our Simplified Version) ---
{
  "protocol_version": "1.0",
  "sender": "Orchestrator",
  "content": "Research the benefits of the Mediterranean diet.",
  "metadata": {
    "task_id": "T-123",
    "priority": "high"
  }
}
```

**Reading this message**:
- `sender` identifies the originating agent (the Orchestrator delegating work)
- `content` is the task to perform — passed to the Researcher agent
- `metadata.task_id` allows the Orchestrator to track the request through the pipeline
- `metadata.priority` lets the receiver triage urgency
- `protocol_version` lets the receiver verify it can handle this message's schema

## MCP Message Field Reference

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `protocol_version` | string | yes | Schema version (e.g., `"1.0"`) for compatibility checks |
| `sender` | string | yes | Name of the agent emitting the message |
| `content` | string / structured | yes | The task to execute or the result being returned |
| `metadata` | dict | no (defaults to `{}`) | Auxiliary routing/observability data such as `task_id`, `priority` |

## Patterns of Use in the MAS Workflow

The same `create_mcp_message` helper is reused for every hop in the pipeline:

1. **Orchestrator → Researcher**: `sender="Orchestrator"`, `content="<research task>"`
2. **Researcher → Orchestrator**: `sender="Researcher"`, `content="<bullet-pointed summary>"`
3. **Orchestrator → Writer**: `sender="Orchestrator"`, `content="<summary as context for writing>"`
4. **Writer → Orchestrator**: `sender="Writer"`, `content="<final polished content>"`

Each message preserves full context — the Orchestrator chains outputs from one stage as input to the next, all wrapped in the same MCP envelope.
