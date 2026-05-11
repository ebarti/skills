# Orchestration Rules

Rules for designing and implementing the Orchestrator in a multi-agent system.

## Core Rules

### 1. Orchestrator Does Not Do Domain Work

The Orchestrator coordinates - it never researches, writes, calculates, or otherwise performs the agents' jobs.

- No domain logic inside the orchestrator function
- No LLM calls for content generation - only for planning, if at all
- If you find yourself adding "real work" to the orchestrator, extract a new agent

**Example**:
```python
# Bad - orchestrator doing the writing itself
def orchestrator(goal):
    research = researcher_agent(...)
    blog_post = llm.complete(f"Write a post about {research}")  # wrong!
    return blog_post

# Good - delegate to a specialized agent
def orchestrator(goal):
    research = researcher_agent(...)
    blog_post = writer_agent(create_mcp_message("Orchestrator", research['content']))
    return blog_post['content']
```

### 2. Orchestrator Owns Workflow State

The Orchestrator holds intermediate results between agent calls. Agents are stateless functions; state lives in the orchestrator's local variables.

- Store each agent's response in a clearly named variable (`mcp_from_researcher`, `mcp_from_writer`)
- Do not push intermediate state into agents
- Pass only what the next agent needs, not the full history

### 3. Route All Inter-Agent Communication Through the Orchestrator

Agents never call each other directly. All hand-offs go through the Orchestrator (hub-and-spoke topology).

- Researcher does not invoke Writer
- Writer does not invoke Researcher
- The Orchestrator unwraps one agent's MCP response and wraps a new MCP message for the next

### 4. Wrap Every Delegation in an MCP Message

Use `create_mcp_message(sender="Orchestrator", content=...)` for every outgoing task.

- `sender` is always `"Orchestrator"` on outgoing tasks
- `content` is the next agent's input (often the previous agent's `content`)
- Never pass raw strings to agents

### 5. Sequential by Default, Parallel Only on Independence

Default to sequential calls. Use parallel invocation only when two agents have no data dependency on each other.

- Sequential: Researcher -> Writer (Writer needs research)
- Parallel: Two independent researchers gathering different facets, then merged

### 6. Surface Progress Visibly

Print or log every transition: goal received, task delegated, response received, workflow complete.

- Helps debugging when an agent misbehaves
- Makes the conductor metaphor concrete to the user

## Guidelines

- Keep the orchestrator function flat - one step per phase, no deep nesting
- Use comment headers (`# --- Step 1: ...`) to mark each phase
- Hardcode the workflow first; add dynamic planning only when you need it
- Treat the orchestrator as the place where the user's goal lives - never push it down to agents

## Failure Handling (Basic Orchestrator)

The basic orchestrator has **no error handling**. The chapter explicitly notes:

> a network hiccup, a malformed message, or an unexpected LLM response could break the flow

For the basic version, accept this fragility. The next chapter section adds error handling, validation, and safeguards.

- Do not add try/except prematurely - get the happy path working first
- Do not add retries until you have a validation layer

## When to Involve the User

The basic orchestrator involves the user only at two points:

- **At the start**: receiving the high-level goal
- **At the end**: presenting the final assembled output

No mid-workflow user prompts in the basic version. Approval gates and clarification turns belong in a more advanced orchestrator.

## When the Orchestrator Owns State vs. Delegates

| Concern | Owner |
|---------|-------|
| Workflow sequence | Orchestrator |
| Intermediate results | Orchestrator (local variables) |
| Domain knowledge (research, writing) | Specialized agent |
| Final assembly | Orchestrator |
| Per-agent tool use | Specialized agent |

## Quick Reference

| Rule | Summary |
|------|---------|
| No domain work | Orchestrator only coordinates |
| Owns state | Intermediate results live in orchestrator variables |
| Hub-and-spoke | All hand-offs route through orchestrator |
| Wrap in MCP | Every delegation is an MCP message |
| Sequential default | Parallel only when truly independent |
| Visible progress | Log every transition |
| User at edges only | Goal in, final output out - no mid-flow prompts |
