# Agent Overview Rules

Guidelines for deciding when to use an agent and how to design its tool inventory.

## Core Rules

### 1. Use an agent only when multi-step reasoning + tools are required

Single LLM calls are cheaper and more reliable. Use an agent when the task needs the model to reason, invoke a tool, observe the result, and decide the next step.

- Suitable: research, data analysis pipelines, customer outreach automation
- Not suitable: a single classification, a one-shot completion, formatting

**Example**:
```python
# Bad: Wrapping a one-shot task as an agent adds latency and failure modes
agent.run("Translate this sentence to French.")

# Good: Direct call
client.messages.create(model="...", messages=[{"role":"user","content":"Translate..."}])
```

### 2. Use the most powerful model you can afford for agents

Compound mistakes destroy long workflows. At 95% per-step accuracy, a 10-step task is only 60% reliable; a 100-step task is 0.6%.

- Prefer top-tier models (e.g., Claude Opus, GPT-4-class) for multi-step agents
- Reserve smaller models for single tool calls or sub-routines

### 3. Match the tool inventory to the environment

The environment determines what tools are *possible*. Don't add tools the agent can't use.

- Code agent: terminal, filesystem, code interpreter
- Customer-support agent: CRM read, knowledge base search, ticket write
- Research agent: web search, document retrieval, summarizer

### 4. Right-size the tool inventory

More tools = more capability, but harder selection.

- Start with the minimum tools needed
- Add only when measurably better
- Audit unused tools periodically — remove them

### 5. Separate read-only from write actions

Read-only tools are safe to invoke liberally. Write actions need guardrails.

- Mark each tool clearly as read or write
- Apply different permission/approval policies to each class

### 6. Require explicit permission gates for write actions

Write actions can move money, send messages, delete data. Treat them like a junior employee with no authority by default.

- Require human approval for high-impact writes (transfers, deletions, mass emails)
- Use dry-run / preview modes when possible
- Log every write action with full provenance
- Rate-limit and scope by user/account

**Example**:
```python
# Bad: Agent can transfer money with no checks
tools = [send_wire_transfer]  # one bad prompt = real damage

# Good: Wrap with approval gate
tools = [propose_wire_transfer]  # creates a pending request requiring human approval
```

### 7. Knowledge augmentation tools should be the first thing you add

Most agent tasks fail because of missing context, not missing capability.

- Start with a retriever (text/SQL/internal search)
- Add web browsing only if up-to-date public info is needed
- Vet internet APIs carefully — they expose the agent to adversarial content

### 8. Use capability extension tools for known model weaknesses

Don't try to train math, code execution, or unit conversion into the prompt. Hand it to a tool.

- Math → calculator
- Computation, plotting, data analysis → code interpreter
- Time/date math → calendar + timezone tool
- Translation to weak languages → translation API
- Image/audio/PDF → captioner / transcriber / OCR

### 9. Secure code interpreters

Code execution tools enable powerful agents but open code injection risks.

- Run in a sandboxed environment (containers, gVisor, Firecracker)
- No network or limited egress
- Drop privileges, set resource limits (CPU, memory, time)
- Never execute untrusted code on production systems

### 10. Use function calling APIs when available

Most providers (Anthropic, OpenAI, Google) support native function calling.

- Prefer native tool/function calling over custom prompt parsing
- Define clear JSON schemas for each tool's inputs and outputs
- Validate tool arguments before execution

## Guidelines

- Treat the agent as the brain, tools as the limbs — keep responsibilities separated
- Prefer well-described tool names and docstrings; the model picks tools based on these
- Group related tools into a single tool with parameters, rather than many near-duplicates
- Keep tool outputs structured (JSON) so the model can reason over them reliably

## Exceptions

- **Toy/demo agent**: A throwaway prototype can skip approval gates — but never ship it
- **Internal-only, low-impact write**: A write that only updates the agent's own scratchpad doesn't need full approval

## Quick Reference

| Rule | Summary |
|------|---------|
| When to use agent | Multi-step + tools required |
| Model strength | Use the best you can afford |
| Tool count | Start small, add only if measurable gain |
| Read vs write | Different permission classes |
| Write actions | Require approval / sandbox / audit |
| Knowledge tools | Add first — context is the bottleneck |
| Capability tools | Use for math, code, time, multimodal |
| Code interpreter | Always sandbox |
| Function calling | Use native APIs over custom parsing |
