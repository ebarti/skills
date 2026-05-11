# MCP Protocol Rules

Rules for structuring MCP messages, choosing transports, managing protocol state, setting up the LLM client, and designing message schemas in a multi-agent system.

## Core Rules

### 1. Structure Every Message as JSON-RPC 2.0

All official MCP messages must be clean JSON objects following JSON-RPC 2.0.

- Use a JSON object — not raw text, XML, or binary
- Conform to the JSON-RPC 2.0 specification
- Even when using a simplified Python-dict stand-in, mirror the same field discipline

### 2. Encode Messages as UTF-8

Universal compatibility across systems requires UTF-8.

- Always emit messages as UTF-8
- Do not rely on platform default encodings

### 3. Keep Each Message on a Single Line

Each MCP message must appear on a single line with no embedded newlines.

- No `\n` inside the serialized payload
- One message = one line — enables fast, reliable parsing
- Never pretty-print messages on the wire (only for display/debugging)

### 4. Use a Consistent Message Schema

Every message must carry the same fields in the same shape.

- Required fields in the book's simplified version: `protocol_version`, `sender`, `content`
- Optional field: `metadata` (default to `{}` when absent, never `None` on the wire)
- Build messages through a single helper (e.g., `create_mcp_message`) — never construct ad hoc

**Example**:
```python
# Bad — ad hoc shape, missing fields
msg = {"from": "Orch", "text": "do research"}

# Good — standardized helper, full schema
msg = create_mcp_message(
    sender="Orchestrator",
    content="Research the benefits of the Mediterranean diet.",
    metadata={"task_id": "T-123", "priority": "high"},
)
```

### 5. Choose Transport by Deployment Topology

Pick the transport layer based on where agents run.

- **Same machine** (e.g., Colab notebook, local process group) → **STDIO**
- **Different servers** (over a network) → **HTTP**
- Do not mix transports within a single agent hop without an explicit bridge

### 6. Send a Version Header Over HTTP

When using HTTP transport, include a version header.

- Required so client and server agree on the same rule set
- Mismatched versions must be rejected, not silently negotiated
- The simplified dict carries `protocol_version` inside the payload as the equivalent

### 7. Validate Connections for Security

Apply MCP's connection-validation rules to prevent common cyberattacks.

- Confirm you are communicating with the intended server (not an impostor)
- Reject connections that fail validation rather than degrade gracefully
- Treat MCP security rules as non-optional even in development

### 8. Initialize the LLM Client from Environment Secrets

Never hard-code API keys; rely on the environment.

- Load the API key from a secrets store (e.g., Colab Secrets) into an env var **before** notebook execution
- Construct the client with no arguments: `client = OpenAI()` — it reads `OPENAI_API_KEY` automatically
- Print a confirmation (e.g., `"OpenAI client initialized."`) so initialization failures are obvious
- Import `json` alongside the client to display structured messages cleanly

**Example**:
```python
# Bad — secret in code, no confirmation
client = OpenAI(api_key="sk-...")

# Good — env-driven, confirmed
import json
client = OpenAI()
print("OpenAI client initialized.")
```

### 9. Pass Information Only Through MCP Messages

No raw-text shortcuts between agents.

- Every inter-agent interaction is wrapped in an MCP message
- The Orchestrator passes one agent's results as the next agent's `content` (context chaining)
- Metadata (e.g., `task_id`, `priority`) travels with the message, not out-of-band

### 10. Treat Schema Consistency as a Reliability Guarantee

Consistency of structure is the foundation of system reliability.

- Do not introduce per-agent variants of the message shape
- Add new fields under `metadata` rather than at the top level when possible
- Changes to the schema warrant bumping `protocol_version`

## Guidelines

- For learning and prototyping, a Python dictionary is sufficient as a JSON-RPC stand-in
- Use `json.dumps(message, indent=2)` only for human-readable display — not for transport
- Keep `content` task-focused (one task or one result per message)
- Use `metadata` for routing/observability data such as `task_id`, `priority`

## Exceptions

- **Pedagogical / Colab context**: A Python dict may stand in for the formal JSON-RPC 2.0 object to focus on the spirit of MCP without protocol overhead.
- **Single-machine demos**: STDIO is acceptable even when HTTP would be required in production.

## Quick Reference

| Rule | Summary |
|------|---------|
| JSON-RPC 2.0 | Official message format |
| UTF-8 | Required encoding |
| Single line | No embedded newlines on the wire |
| Consistent schema | `protocol_version`, `sender`, `content`, `metadata` |
| Transport choice | STDIO same-machine, HTTP cross-server |
| Version header | Required over HTTP |
| Security | Validate connections, confirm peer |
| Client init | `OpenAI()` from env var, no hard-coded keys |
| MCP-only comms | All agent-to-agent traffic wrapped in messages |
| Schema stability | Treat as reliability contract, version on change |
