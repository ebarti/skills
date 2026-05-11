# Robustness Examples

Verbatim Python from Chapter 2.

## Robust LLM Component

```python
import time
```
```python
#@title 3.Building Robust Components
--- Hardening the call_llm Function ---
def call_llm_robust(system_prompt, user_content, retries=3, delay=5):
    """A more robust helper function to call the OpenAI API with retries."""
    for i in range(retries):
        try:
            response = client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_content}
                ]
            )
            return response.choices[0].message.content
        except Exception as e:
            print(f"API call failed on attempt {i+1}/{retries}. Error: {e}")
            if i < retries - 1:
                print(f"Retrying in {delay} seconds...")
                time.sleep(delay)
            else:
                print("All retries failed.")
                return None
```

Retry loop survives transient API outages; `time.sleep(delay)` backs off between attempts; returns `None` so the Orchestrator can branch on failure.

## MCP Validation Logic

```python
--- The MCP Validator ---
def validate_mcp_message(message):
    """A simple validator to check the structure of an MCP message."""
    required_keys = ["protocol_version", "sender", "content", "metadata"]

    if not isinstance(message, dict):
        print(f"MCP Validation Failed: Message is not a dictionary.")
        return False

    for key in required_keys:
        if key not in message:
            print(f"MCP Validation Failed: Missing key '{key}'")
            return False

    print(f"MCP message from {message['sender']} validated successfully.")
    return True
```

Type check catches non-dict garbage; required-keys check prevents downstream `KeyError`s; logs the sender on success.

## Specialists Upgraded to the Robust Caller

```python
#@title 4.Building the Agents: The Specialists
--- Agent 1: The Researcher ---
def researcher_agent(mcp_input):
    ... (code omitted for brevity) ...
    system_prompt = "You are a research analyst. Synthesize the provided information into 3-4 concise bullet points."
    # Now using the robust caller
    summary = call_llm_robust(system_prompt, research_result)
    ... (code omitted for brevity) ...

--- Agent 2: The Writer ---
def writer_agent(mcp_input):
    ... (code omitted for brevity) ...
    system_prompt = "You are a content writer. Take the following research points and write a short, appealing blog post (approx. 150 words) with a catchy title."
    # Now using the robust caller
    blog_post = call_llm_robust(system_prompt, research_summary)
    ... (code omitted for brevity) ...
```

## The Validator Agent (Agent 3)

```python
# --- Agent 3: The Validator ---
def validator_agent(mcp_input):
    """This agent fact-checks a draft against a source summary."""
    print("\n[Validator Agent Activated]")

    # Extracting the two required pieces of information
    source_summary = mcp_input['content']['summary']
    draft_post = mcp_input['content']['draft']

    system_prompt = """
    You are a meticulous fact-checker. Determine if the 'DRAFT' is factually consistent with the 'SOURCE SUMMARY'.
    - If all claims in the DRAFT are supported by the SOURCE, respond with only the word \"pass\".
    - If the DRAFT contains any information not in the SOURCE, respond with \"fail\" and a one-sentence explanation.
    """

    validation_context = f"SOURCE SUMMARY:\n{source_summary}\n\nDRAFT:\n{draft_post}"
    validation_result = call_llm_robust(system_prompt, validation_context)

    print(f"Validation complete. Result: {validation_result}")

    return create_mcp_message(
        sender="ValidatorAgent",
        content=validation_result
    )
```

Constrained prompt forces a deterministic `pass` / `fail` token; two-input contract (`summary`, `draft`) is its semantic blueprint; returns a standard MCP message.

## Final Orchestrator with Validation Loop

### Step 1: Research and Immediate Validation

```python
#@title 5.The Final Orchestrator with Validation Loop
def final_orchestrator(initial_goal):
    ... (Initialization code omitted) ...

    # Step 1 Research and Immediate Validation
    # --- Step 1: Research ---
    print("\n[Orchestrator] Task 1: Research. Delegating to Researcher Agent.")
    # ... (Call to researcher_agent) ...
    mcp_from_researcher = researcher_agent(mcp_to_researcher)

    # New: Validate the message structure immediately
    if not validate_mcp_message(mcp_from_researcher) or not mcp_from_researcher['content']:
        print("Workflow failed due to invalid or empty message from Researcher.")
        return

    research_summary = mcp_from_researcher['content']
    print("\n[Orchestrator] Research complete.")
```

### Steps 2 & 3: Iterative Writing and Validation Loop

```python
Step 2 and 3 The Iterative Loop
# --- Step 2 & 3: Iterative Writing and Validation Loop ---
final_output = "Could not produce a validated article."
max_revisions = 2
for i in range(max_revisions):
    print(f"\n[Orchestrator] Writing Attempt {i+1}/{max_revisions}")

    # Prepare context for the writer
    writer_context = research_summary
    if i > 0:
        # If this is a revision, add the validator's feedback
        writer_context += f"\n\nPlease revise the previous draft based on this feedback: {validation_result}"

    # Call the Writer Agent and Validate
    mcp_to_writer = create_mcp_message(sender="Orchestrator", content=writer_context)
    mcp_from_writer = writer_agent(mcp_to_writer)

    if not validate_mcp_message(mcp_from_writer) or not mcp_from_writer['content']:
        print("Aborting revision loop due to invalid message from Writer.")
        break
    draft_post = mcp_from_writer['content']
```

### Validation Step and Decision Point

```python
    # --- Validation Step ---
    print("\n[Orchestrator] Draft received. Delegating to Validator Agent.")

    # Prepare context for the Validator (needs both summary and draft)
    validation_content = {"summary": research_summary, "draft": draft_post}
    mcp_to_validator = create_mcp_message(sender="Orchestrator", content=validation_content)
    mcp_from_validator = validator_agent(mcp_to_validator)

    # Validate Validator output
    if not validate_mcp_message(mcp_from_validator) or not mcp_from_validator['content']:
        print("Aborting revision loop due to invalid message from Validator.")
        break
    validation_result = mcp_from_validator['content']

    # Decision Point
    if "pass" in validation_result.lower():
        print("\n[Orchestrator] Validation PASSED. Finalizing content.")
        final_output = draft_post
        break
    else:
        print(f"\n[Orchestrator] Validation FAILED. Feedback: {validation_result}")
        if i < max_revisions - 1:
            print("Requesting revision.")
        else:
            print("Max revisions reached. Workflow failed.")
```

## Running the Final Robust System

```python
#@title 6.Run the Final, Robust System
user_goal = "Create a blog post about the benefits of the Mediterranean diet."
final_orchestrator(user_goal)
```

Sample log (truncated): the Orchestrator prints the goal, delegates Task 1 to the Researcher, the Researcher logs `[Researcher Agent Activated]` and `Research summary created for: 'Mediterranean Diet'`, validation prints `MCP message from ResearcherAgent validated successfully`, and the loop continues through Writer and Validator before producing the final blog post.
