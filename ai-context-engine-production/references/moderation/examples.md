# Moderation Examples

Code examples for the moderation gatekeeper, its integration into the engine, and the two-stage guardrail in action. All Python is preserved verbatim from the source.

## Example 1: The Moderation Helper (`helper_moderate_content`)

A standalone function in `commons/ch8/helpers.py` that wraps the OpenAI Moderation API and returns a detailed report.

```python
# FILE: commons/ch8/helpers.py
# === Moderation Utility (New for Chapter 8) ===
def helper_moderate_content(text_to_moderate, client):
    """
    Uses the OpenAI Moderation API to check if content is flagged and returns a full report.
    """
    logging.info(f"Moderating content...")
    try:
        response = client.moderations.create(input=text_to_moderate)
        mod_result = response.results[0]

        report = {
            "flagged": mod_result.flagged,
            "categories": dict(mod_result.categories),
            "scores": dict(mod_result.category_scores)
        }

        if report["flagged"]:
            logging.warning(f"Content was FLAGGED by moderation API. Report: {report['categories']}")
        else:
            logging.info("Content PASSED moderation.")

        return report

    except Exception as e:
        logging.error(f"An error occurred during content moderation: {e}")
        # Fail safe: if we can't check it, we assume it's not safe.
        return {"flagged": True, "categories": {"error": str(e)}, "scores": {}}
```

**Why it works**:
- Single responsibility — only handles moderation
- Returns a structured report (`flagged`, `categories`, `scores`) instead of a boolean
- `try...except` ensures the system fails safe when the API errors
- Logging at `info` and `warning` levels gives an audit trail

## Example 2: Upgraded Engine Room with Moderation Integration

The central `execute_and_display` function becomes the engine's safety orchestrator. A `moderation_active` toggle controls whether the two-stage protocol runs.

```python
# In Legal_Compliance_Assistant.ipynb (Upgraded Engine Room)
def execute_and_display(goal, config, client, pc, moderation_active):
    """
    Runs the context engine, now with an optional, two-stage moderation check.
    """
    # --- PRE-FLIGHT MODERATION CHECK (on user input) ---
    if moderation_active:
        print("--- [Safety Guardrail] Performing Pre-Flight Moderation Check on Goal ---")
        moderation_report = helpers.helper_moderate_content(text_to_moderate=goal, client=client)

        print("Moderation Report:")
        pprint.pprint(moderation_report)

        if moderation_report["flagged"]:
            print("\nGoal failed pre-flight moderation. Execution halted.")
            return

    # 1. Run the Context Engine...
    result, trace = context_engine(goal, client=client, pc=pc, **config)

    # --- POST-FLIGHT MODERATION CHECK (on AI output) ---
    if result and moderation_active:
        print("\n--- [Safety Guardrail] Performing Post-Flight Moderation Check on Output ---")
        moderation_report = helpers.helper_moderate_content(text_to_moderate=result, client=client)

        print("Moderation Report:")
        pprint.pprint(moderation_report)

        if moderation_report["flagged"]:
            print("\nGenerated output failed post-flight moderation and will be redacted.")
            result = "[Content flagged as potentially harmful by moderation policy and has been redacted.]"

    # 2. Display the Final Result...
    ... (display logic remains the same)
```

**Why it works**:
- Two sequential checks — pre-flight on input, post-flight on output
- Pre-flight failure halts execution immediately (saves cost on harmful goals)
- Post-flight failure redacts to a standardized safe message
- The `moderation_active` parameter makes safety toggleable per environment
- Reasoning logic (`context_engine`) is unchanged — moderation only wraps it

## Example 3: Moderation Guardrail in Action (Control Deck)

A standard summarization task with the safety system engaged. This demonstrates the end-to-end two-stage workflow on safe content.

```python
#@title CONTROL DECK: Moderation
# 1. Define a simple, safe goal to test the moderation workflow.
goal = "Summarize the key points of the Non-Disclosure Agreement."

# 2. Define the standard configuration.
config = {
    "index_name": 'genai-mas-mcp-ch3',
    "generation_model": "gpt-5",
    "embedding_model": "text-embedding-3-small",
    "namespace_context": 'ContextLibrary',
    "namespace_knowledge": 'KnowledgeStore'
}

# 3. Call the execution function with moderation explicitly activated.
execute_and_display(goal, config, client, pc, moderation_active=True)
```

**What happens at runtime**:
1. **Pre-flight check** runs on the goal. `flagged` returns `False`; all category scores are extremely low (e.g., `4.26e-06`).
2. The engine executes the plan (Planner → Researcher → Writer).
3. **Post-flight check** runs on the AI output. `flagged` returns `False`.
4. The unredacted output is displayed.

**Why it works**:
- A known-safe goal validates the full pipeline end-to-end
- The `moderation_active=True` toggle exercises both stages
- Printed reports give a transparent, auditable record of every check

## Reading the Moderation Report

The report returned by `helper_moderate_content` has three fields:

```python
{
    "flagged": False,                           # Overall pass/fail
    "categories": {                             # Booleans per category
        "hate": False,
        "violence": False,
        # ...
    },
    "scores": {                                 # Raw confidence scores
        "hate": 4.26e-06,
        "violence": 1.12e-05,
        # ...
    }
}
```

**Interpreting scores**: Lower scores indicate higher confidence the text is safe. A score like `4.26e-06` is essentially zero confidence the text belongs to that harm category.

## Refactoring Walkthrough — Adding Moderation to an Existing Engine

### Before

```python
def execute_and_display(goal, config, client, pc):
    result, trace = context_engine(goal, client=client, pc=pc, **config)
    # Display the Final Result...
```

### After

```python
def execute_and_display(goal, config, client, pc, moderation_active):
    if moderation_active:
        moderation_report = helpers.helper_moderate_content(text_to_moderate=goal, client=client)
        if moderation_report["flagged"]:
            print("\nGoal failed pre-flight moderation. Execution halted.")
            return

    result, trace = context_engine(goal, client=client, pc=pc, **config)

    if result and moderation_active:
        moderation_report = helpers.helper_moderate_content(text_to_moderate=result, client=client)
        if moderation_report["flagged"]:
            result = "[Content flagged as potentially harmful by moderation policy and has been redacted.]"
    # Display the Final Result...
```

### Changes Made

1. **Added `moderation_active` parameter** so the safety layer is toggleable per environment.
2. **Inserted pre-flight check** before the engine runs to halt on harmful input and save cost.
3. **Inserted post-flight check** after the engine runs to redact harmful generations.
4. **Preserved reasoning logic** — `context_engine` itself is unchanged; moderation is a pure wrapper.
