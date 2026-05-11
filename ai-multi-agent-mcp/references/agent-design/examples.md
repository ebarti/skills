# Agent Design Examples

Verbatim Python code for the shared helper function and the two specialist agents (Researcher and Writer), including their full system prompts.

## Shared Helper: `call_llm`

A single helper that wraps every OpenAI chat completion call. It takes a system prompt and user content, builds the `messages` list with explicit roles, and returns the model's text response. The `try`/`except` keeps individual agent functions safe from API failures.

```python
def call_llm(system_prompt, user_content):
    """A helper function to call the OpenAI API using the new client syntax."""
    try:
    # Using the updated client.chat.completions.create method
        response = client.chat.completions.create(
            model="gpt-5",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_content}
            ]
        )
        return response.choices[0].message.content…
```

**Why it works**:
- Two clear inputs: `system_prompt` (behavior) and `user_content` (the specific question or data).
- The `messages` list explicitly sets the `system` role (frames the agent) and the `user` role (delivers the input).
- All agents share this entry point, so swapping models or adding logging happens in one place.
- Basic error handling means an API failure does not crash the agent.

## Researcher Agent

Takes a research topic, looks up matching information in a simulated database, summarizes it via the LLM, and returns an MCP message.

```python
def researcher_agent(mcp_input):
    """
    This agent takes a research topic, finds information, and returns a summary.
    """
    print("\n[Researcher Agent Activated]")
```

The simulated database stands in for a future vector database (RAG):

```python
    simulated_database = {
        "mediterranean diet": "The Mediterranean diet is rich in fruits, vegetables, whole grains, olive oil, and fish. Studies show it is associated with a lower risk of heart disease, improved brain health, and a longer lifespan. Key components include monounsaturated fats and antioxidants."
    }
```

Extract the topic from the MCP input and look it up safely:

```python
    research_topic = mcp_input['content']
    research_result = simulated_database.get(research_topic.lower(), 
        "No information found on this topic.")
```

The system prompt frames the LLM as a research analyst with a strict output format:

```python
    system_prompt = "You are a research analyst. Your task is to synthesize the provided information into 3-4 concise bullet points. Focus on the key findings."
```

Call the shared helper and log completion:

```python
    summary = call_llm(system_prompt, research_result)
    print(f"Research summary created for: '{research_topic}'")
```

Return the result as an MCP message with provenance metadata:

```python
    return create_mcp_message(
        sender="ResearcherAgent",
        content=summary,
        metadata={"source": "Simulated Internal DB"}
    )
```

**Why it works**:
- Single responsibility: retrieve and summarize.
- Stateless and trace-friendly thanks to the activation log.
- Default value for missing topics avoids `KeyError` and lets the LLM stage handle the message gracefully.
- Output envelope keeps downstream agents (Writer) decoupled from the data source.

## Writer Agent

Takes the Researcher's summary, drafts a short blog post via the LLM, and returns an MCP message that includes a word count.

```python
def writer_agent(mcp_input):
    """
    This agent takes research findings and writes a short blog post.
    """
    print("\n[Writer Agent Activated]")
```

Read the summary from the MCP input:

```python
    research_summary = mcp_input['content']
```

The system prompt sets a different role, tone, length, and a request for a catchy title:

```python
    system_prompt = "You are a skilled content writer for a health and wellness blog. Your tone is engaging, informative, and encouraging. Your task is to take the following research points and write a short, appealing blog post (approx. 150 words) with a catchy title."
```

Call the same shared helper, log completion:

```python
    blog_post = call_llm(system_prompt, research_summary)
    print("Blog post drafted.")
```

Wrap the output as an MCP message with metadata describing the draft:

```python
    return create_mcp_message(
        sender="WriterAgent",
        content=blog_post,
        metadata={"word_count": len(blog_post.split())}
    )
```

**Why it works**:
- Mirrors the Researcher's structure exactly: extract → `call_llm` → wrap.
- Differentiation lives entirely in the system prompt, not in branching code.
- Metadata (`word_count`) is meaningful for this agent's specific output.
- Demonstrates how a new specialist agent is just "swap the prompt and the metadata."

## Side-by-Side: Researcher vs. Writer

The two agents share an identical skeleton — only the prompt and metadata differ.

| Aspect | Researcher | Writer |
|--------|-----------|--------|
| Input field used | `mcp_input['content']` (topic) | `mcp_input['content']` (summary) |
| Pre-LLM step | Lookup in `simulated_database` | None |
| Persona | Research analyst | Health and wellness content writer |
| Output format | 3–4 concise bullet points | ~150-word blog post with catchy title |
| `sender` | `"ResearcherAgent"` | `"WriterAgent"` |
| `metadata` | `{"source": "Simulated Internal DB"}` | `{"word_count": len(blog_post.split())}` |

## Refactoring Note

If you started with a single combined function:

### Before

```python
def research_and_write_agent(mcp_input):
    topic = mcp_input['content']
    facts = simulated_database.get(topic.lower(), "No information found.")
    summary = call_llm("Summarize.", facts)
    blog = call_llm("Write a blog post.", summary)
    return create_mcp_message(sender="Combined", content=blog, metadata={})
```

### After

Split into `researcher_agent` and `writer_agent` (above), each with its own focused system prompt, sender, and metadata. The orchestrator wires them together.

### Changes Made

1. Separated retrieval/summary from drafting so each agent has one job.
2. Replaced vague prompts with role-, format-, and tone-specific prompts.
3. Added meaningful per-agent metadata to keep MCP messages informative.
4. Added activation logs to trace the workflow.
