# Orchestration Examples

Code examples demonstrating the basic Orchestrator pattern from Chapter 2.

## The Complete Orchestrator Function

The single function below manages the entire multi-agent workflow from start to finish. Its role is to call the Researcher, then the Writer, and finally assemble the output into a completed artifact.

### Step 0: Function Signature and Goal Logging

```python
def orchestrator(initial_goal):
    """
    Manages the multi-agent workflow to achieve a high-level goal.
    """
    print("=" * 50)
    print(f"[Orchestrator] Goal Received: '{initial_goal}'")
    print("=" * 50)
```

`initial_goal` is the high-level task we want the system to complete. The function confirms receipt before doing any work.

### Step 1: Delegate to the Researcher Agent

```python
    # --- Step 1: Orchestrator plans and calls the Researcher Agent ---
    print("\n[Orchestrator] Task 1: Research. Delegating to Researcher Agent.")
    research_topic = "Mediterranean Diet"
```

The research topic is hardcoded here; in practice it could be derived dynamically from `initial_goal`.

Wrap the topic in an MCP message:

```python
    mcp_to_researcher = create_mcp_message(
        sender="Orchestrator",
        content=research_topic
    )
```

Call the Researcher and unwrap its response:

```python
    mcp_from_researcher = researcher_agent(mcp_to_researcher)
    print("\n[Orchestrator] Research complete. Received summary:")
    print("-" * 20)
    print(mcp_from_researcher['content'])
    print("-" * 20)
```

### Step 2: Hand the Research Off to the Writer Agent

```python
    # --- Step 2: Orchestrator calls the Writer Agent ---
    print("\n[Orchestrator] Task 2: Write Content. Delegating to Writer Agent.")
    mcp_to_writer = create_mcp_message(
        sender="Orchestrator",
        content=mcp_from_researcher['content']
    )
    mcp_from_writer = writer_agent(mcp_to_writer)
    print("\n[Orchestrator] Writing complete.")
```

Note how the Writer's `content` is the Researcher's `content` - direct hand-off mediated by the Orchestrator.

### Step 3: Present the Final Result

```python
    # --- Step 3: Orchestrator presents the final result ---
    final_output = mcp_from_writer['content']
    print("\n" + "="*50)
    print("[Orchestrator] Workflow Complete. Final Output:")
    print("="*50)
    print(final_output)
```

## Running the System

The block below defines a high-level user goal, passes it to the Orchestrator, and triggers the full workflow. With a single function call, the Orchestrator delegates to the Researcher, collects the summary, hands it off to the Writer, and assembles the final blog post.

```python
#@title 5. Run the System
# ------------------------------------------------------------------------
# Let's give our Orchestrator a high-level goal and watch the agent team work.
# ------------------------------------------------------------------------
user_goal = "Create a blog post about the benefits of the Mediterranean diet."
orchestrator(user_goal)
```

## Sample Console Output

The console log shows how each agent contributes to the final blog post.

### 1. Goal Received

```
==================================================
[Orchestrator] Goal Received: 'Create a blog post about the benefits of the Mediterranean diet.'
==================================================
Orchestrator Delegates to the Researcher
```

### 2. Researcher Activated and Returns Summary

```
[Orchestrator] Task 1: Research. Delegating to Researcher Agent.
[Researcher Agent Activated]
Research summary created for: 'Mediterranean Diet'
```

```
[Orchestrator] Research complete. Received summary:
--------------------
- Emphasizes fruits, vegetables, whole grains, olive oil, and fish as core foods.
- Associated with lower risk of heart disease, improved brain health, and increased longevity.
- Benefits are linked to high intake of monounsaturated fats (especially from olive oil) and antioxidants.
--------------------
```

### 3. Writer Activated and Drafts Post

```
[Orchestrator] Task 2: Write Content. Delegating to Writer Agent.
[Writer Agent Activated]
Blog post drafted.
Writer Agent Completes the Draft
```

```
[Orchestrator] Writing complete.
```

### 4. Workflow Complete with Final Output

```
==================================================
[Orchestrator] Workflow Complete. Final Output:
==================================================
Mediterranean Magic: A Delicious Way to Boost Heart, Brain, and Longevity
The Mediterranean-style plate celebrates colorful fruits and vegetables, hearty whole grains, silky olive oil, and plenty of fish. Research links this pattern with a lower risk of heart disease, sharper brain health, and a longer life. The secret sauce? Monounsaturated fats - especially from extra-virgin olive oil - help improve cholesterol balance and keep blood vessels supple, while antioxidant-rich plants and seafood fight oxidative stress and inflammation....
```

## Why This Example Works

- **Single entry point**: One function call (`orchestrator(user_goal)`) runs the whole pipeline
- **Clean hand-off**: `mcp_from_researcher['content']` becomes the Writer's input directly
- **Visible flow**: Every transition is printed - goal received, task delegated, response received, workflow complete
- **No domain work in the orchestrator**: It only routes messages and assembles the final output

## Known Limitation (Addressed Later)

This basic orchestrator has no error handling. A network hiccup, a malformed message, or an unexpected LLM response would break the flow. Validation, retries, and safeguards are added in the robustness section of the chapter.
