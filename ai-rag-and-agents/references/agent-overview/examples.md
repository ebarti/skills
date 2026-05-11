# Agent Overview Examples

Concrete examples for defining an agent and its tools across the three categories.

## Agent Definition (Anthropic SDK)

```python
import anthropic

client = anthropic.Anthropic()

SYSTEM_PROMPT = """You are a sales-forecasting agent for Kitty Vogue.
You have access to SQL query generation and execution tools.
Reason step-by-step. Invoke tools when you need data, then reason
about the results before invoking the next tool. Stop when the
task is complete."""

tools = [
    {
        "name": "generate_sql",
        "description": "Generate a SQL query for the sales database from a natural-language request.",
        "input_schema": {
            "type": "object",
            "properties": {"request": {"type": "string"}},
            "required": ["request"],
        },
    },
    {
        "name": "execute_sql",
        "description": "Execute a read-only SQL query against the sales database. Returns rows as JSON.",
        "input_schema": {
            "type": "object",
            "properties": {"query": {"type": "string"}},
            "required": ["query"],
        },
    },
]

response = client.messages.create(
    model="claude-opus-4-7",
    max_tokens=4096,
    system=SYSTEM_PROMPT,
    tools=tools,
    messages=[{"role": "user", "content": "Project Fruity Fedora sales for the next 3 months."}],
)
```

**Why it works**: clear system prompt; each tool has an action-oriented description; read-only and write tools clearly separable.

## Knowledge Augmentation Tools

```python
# Text retriever (RAG)
{"name": "search_docs",
 "description": "Search the internal knowledge base. Returns top-k passages with source URLs.",
 "input_schema": {"type": "object",
                   "properties": {"query": {"type": "string"}, "k": {"type": "integer", "default": 5}},
                   "required": ["query"]}}

# SQL read executor — read-only by validation
{"name": "query_sales_db",
 "description": "Run a read-only SELECT against the sales database. Errors on any non-SELECT.",
 "input_schema": {"type": "object",
                   "properties": {"sql": {"type": "string"}}, "required": ["sql"]}}

# Web browsing — fights model staleness
{"name": "web_search",
 "description": "Search the web for current info (news, prices, events). Returns titles, snippets, URLs.",
 "input_schema": {"type": "object",
                   "properties": {"query": {"type": "string"},
                                  "freshness": {"type": "string", "enum": ["day", "week", "month"]}},
                   "required": ["query"]}}

# Internal people search
{"name": "people_search",
 "description": "Look up an employee by name, email, or team. Returns role, manager, contact info.",
 "input_schema": {"type": "object",
                   "properties": {"query": {"type": "string"}}, "required": ["query"]}}
```

## Capability Extension Tools

```python
# Calculator — fixes model math weakness
{"name": "calculator",
 "description": "Evaluate an arithmetic expression. Supports +, -, *, /, **, parentheses.",
 "input_schema": {"type": "object",
                   "properties": {"expression": {"type": "string"}}, "required": ["expression"]}}

# Unit converter
{"name": "convert_units",
 "description": "Convert a value between units (lbs to kg, F to C, miles to km).",
 "input_schema": {"type": "object",
                   "properties": {"value": {"type": "number"},
                                  "from_unit": {"type": "string"},
                                  "to_unit": {"type": "string"}},
                   "required": ["value", "from_unit", "to_unit"]}}

# Code interpreter — sandboxed
{"name": "run_python",
 "description": "Execute Python in a sandbox. Returns stdout, stderr, files. No network access.",
 "input_schema": {"type": "object",
                   "properties": {"code": {"type": "string"}}, "required": ["code"]}}

# Image generator — multimodal extension for text-only model
{"name": "generate_image",
 "description": "Generate an image from a text prompt via DALL-E. Returns image URL.",
 "input_schema": {"type": "object",
                   "properties": {"prompt": {"type": "string"},
                                  "size": {"type": "string", "enum": ["1024x1024", "1792x1024"]}},
                   "required": ["prompt"]}}
```

## Write Action Tools

```python
# Email send — approval-gated
{"name": "send_email",
 "description": "Send an email. WRITE ACTION. Requires approval_token from user approval flow.",
 "input_schema": {"type": "object",
                   "properties": {"to": {"type": "array", "items": {"type": "string"}},
                                  "subject": {"type": "string"},
                                  "body": {"type": "string"},
                                  "approval_token": {"type": "string"}},
                   "required": ["to", "subject", "body", "approval_token"]}}

# Bank transfer — propose-only, never auto-execute
{"name": "propose_wire_transfer",
 "description": "Create a PENDING transfer. WRITE ACTION. Does NOT execute — human approves in dashboard.",
 "input_schema": {"type": "object",
                   "properties": {"amount_usd": {"type": "number"},
                                  "to_account": {"type": "string"},
                                  "memo": {"type": "string"}},
                   "required": ["amount_usd", "to_account"]}}

# CRM update — audited
{"name": "update_crm_contact",
 "description": "Update a CRM contact. WRITE ACTION. Logged with full audit trail.",
 "input_schema": {"type": "object",
                   "properties": {"contact_id": {"type": "string"},
                                  "fields": {"type": "object"}},
                   "required": ["contact_id", "fields"]}}
```

## Bad Examples

### Vague tool description
```python
# Bad
{"name": "do_thing", "description": "Does a thing."}
# Good
{"name": "fetch_order_status", "description": "Fetch the current status of an order by order_id. Returns shipped|pending|cancelled with timestamp."}
```
**Problem**: Model can't pick the right tool without clear, action-oriented descriptions.

### Write action with no approval gate
```python
# Bad
{"name": "delete_user", "description": "Delete a user account."}
# Good
{"name": "request_user_deletion", "description": "Create a pending deletion request requiring admin approval."}
```
**Problem**: One bad prompt can destroy production data.

### Too many overlapping tools
```python
# Bad
tools = [search_docs_v1, search_docs_v2, search_internal, search_wiki, search_handbook]
# Good
tools = [search_knowledge_base]  # one tool, source as a parameter
```
**Problem**: Model wastes tokens choosing among near-duplicates and may pick wrong.

### Wrapping a one-shot task as an agent
```python
# Bad: agent overhead for a single completion
agent.run("Translate this sentence to French.")
# Good: direct LLM call
client.messages.create(model="...", messages=[{"role":"user","content":"Translate..."}])
```
**Problem**: Adds latency, cost, and extra failure modes for no benefit.
