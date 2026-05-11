# Agent Design Rules

Rules for writing specialist agents, their system prompts, helper functions, and deciding when to add a new agent.

## Core Rules

### 1. One Agent, One Job

Each agent function should have a single, well-defined responsibility.

- The Researcher researches; the Writer writes — never both.
- If an agent's docstring needs "and" to describe its job, split it into two agents.
- Specialization makes prompts shorter, outputs more predictable, and the workflow easier to debug.

**Example**:
```python
# Bad — one agent doing two jobs
def research_and_write_agent(mcp_input): ...

# Good — two specialist agents
def researcher_agent(mcp_input): ...
def writer_agent(mcp_input): ...
```

### 2. Agent I/O Is Always MCP

Every agent must accept an MCP message and return an MCP message built via `create_mcp_message`.

- Read input via `mcp_input['content']`.
- Wrap output with `create_mcp_message(sender=..., content=..., metadata=...)`.
- Never pass raw strings between agents — keep the envelope intact for traceability.

**Example**:
```python
# Bad — returning a bare string
def writer_agent(mcp_input):
    return call_llm(prompt, mcp_input['content'])

# Good — returning an MCP message
def writer_agent(mcp_input):
    blog_post = call_llm(prompt, mcp_input['content'])
    return create_mcp_message(
        sender="WriterAgent",
        content=blog_post,
        metadata={"word_count": len(blog_post.split())},
    )
```

### 3. Behavior Lives in the System Prompt

Differentiate agents by their `system_prompt`, not by branching logic.

- State the role ("You are a research analyst").
- State the format ("3–4 concise bullet points").
- State the tone or audience when relevant ("engaging, informative, encouraging").
- Add length constraints when output size matters ("approx. 150 words").

**Example**:
```python
# Bad — vague prompt, will produce inconsistent output
system_prompt = "Summarize this."

# Good — role, format, focus
system_prompt = (
    "You are a research analyst. Your task is to synthesize the "
    "provided information into 3-4 concise bullet points. "
    "Focus on the key findings."
)
```

### 4. Centralize LLM Calls in `call_llm`

All API calls go through one shared helper.

- Helper takes `system_prompt` and `user_content`.
- Helper builds the `messages` list with explicit `system` and `user` roles.
- Helper returns `response.choices[0].message.content`.
- Helper wraps the call in `try`/`except` so agents never crash on API failure.

### 5. Log Agent Activation

Print a clear log line when each agent starts.

- Use a recognizable tag like `[Researcher Agent Activated]` or `[Writer Agent Activated]`.
- Print a confirmation when the agent finishes its core work (summary created, blog drafted).
- Logs make the multi-agent workflow traceable end-to-end.

### 6. Set Meaningful Metadata

Metadata is per-agent context that helps downstream consumers understand the payload.

- Researcher: `{"source": "Simulated Internal DB"}` indicates provenance.
- Writer: `{"word_count": len(blog_post.split())}` indicates an output property.
- Always include `sender` so messages are attributable in logs and chains.

### 7. Handle Missing Inputs Gracefully

If the agent looks up data, provide a default for the missing case.

- Researcher uses `dict.get(topic.lower(), "No information found on this topic.")`.
- Avoid `KeyError` propagation; let the LLM stage handle the explicit "no info" message.
- Normalize keys (e.g., `.lower()`) to avoid lookup misses.

## Guidelines

- Keep agent functions small and linear: extract → process → wrap.
- Treat the simulated database as a placeholder; expect to swap it for a vector store later.
- Prefer adding a new agent when the prompt would otherwise need conditionals like "if this then write else summarize."
- Keep the helper function generic — do not bake one agent's defaults into `call_llm`.

## When to Add a New Agent vs. Extend an Existing One

| Situation | Choice |
|-----------|--------|
| New role needs a different tone, format, or audience | New agent |
| Slight prompt tweak for the same output type | Extend existing agent |
| Output requires different metadata or downstream routing | New agent |
| Logic change that does not affect prompt or output shape | Extend existing agent |
| You find yourself branching on input type inside one agent | Split into multiple agents |

## Exceptions

- **Prototyping**: A single combined agent is acceptable while exploring; refactor before adding orchestration.
- **Cost constraints**: If two agents would always run sequentially with identical context, consider merging — but only if the system prompts can be cleanly unified.

## Quick Reference

| Rule | Summary |
|------|---------|
| One job | One agent, one responsibility |
| MCP I/O | Always input and output MCP messages |
| Prompt = identity | Differentiate via `system_prompt` |
| Shared `call_llm` | All LLM calls go through the helper |
| Log activation | Print start and completion messages |
| Meaningful metadata | Include `sender` plus per-agent context |
| Graceful lookups | Default values for missing keys |
