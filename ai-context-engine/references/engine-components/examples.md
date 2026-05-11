# Engine Components Examples

Verbatim code for the Planner, Executor, Tracer, and `context_engine()` assembly.

## Planner

`goal` is the request; `capabilities` is from `AgentRegistry.get_capabilities_description()`. Prompt lists tools and rules; LLM call validates JSON shape.

```python
def planner(goal, capabilities):
  """
    Analyzes the goal and generates a structured Execution Plan using the LLM.
    """

    print("[Engine: Planner] Analyzing goal and generating execution plan...")

    system_prompt = f"""
You are the strategic core of the Context Engine. Analyze the user's high-level goal and create a structured Execution Plan using the available agents.

--- AVAILABLE CAPABILITIES ---
{capabilities}
--- END CAPABILITIES ---

INSTRUCTIONS:
1. The plan MUST be a JSON list of objects, where each object is a "step".
2. You MUST use Context Chaining. If a step requires input from a previous step, reference it using the syntax $$STEP_X_OUTPUT$$.
3. Be strategic. Break down complex goals (like sequential rewriting) into distinct steps. Use the correct input keys ('facts' vs 'previous_content') for the Writer agent.

EXAMPLE GOAL: "Write a suspenseful story about Apollo 11."
EXAMPLE PLAN (JSON LIST):
[
    {{"step": 1, "agent": "Librarian", "input": {{"intent_query": "suspenseful narrative blueprint"}}}},
    {{"step": 2, "agent": "Researcher", "input": {{"topic_query": "Apollo 11 landing details"}}}},
    {{"step": 3, "agent": "Writer", "input": {{"blueprint": "$$STEP_1_OUTPUT$$", "facts": "$$STEP_2_OUTPUT$$"}}}}
]

EXAMPLE GOAL: "Write a technical report on Juno, then rewrite it casually."
EXAMPLE PLAN (JSON LIST):
[
    {{"step": 1, "agent": "Librarian", "input": {{"intent_query": "technical report structure"}}}},
    {{"step": 2, "agent": "Researcher", "input": {{"topic_query": "Juno mission technology"}}}},
    {{"step": 3, "agent": "Writer", "input": {{"blueprint": "$$STEP_1_OUTPUT$$", "facts": "$$STEP_2_OUTPUT$$"}}}},
    {{"step": 4, "agent": "Librarian", "input": {{"intent_query": "casual summary style"}}}},
    {{"step": 5, "agent": "Writer", "input": {{"blueprint": "$$STEP_4_OUTPUT$$", "previous_content": "$$STEP_3_OUTPUT$$"}}}}
]

    plan_json = ""
    try:
        plan_json = call_llm_robust(system_prompt, goal, json_mode=True)
        plan = json.loads(plan_json)

        # Validate the output structure
        if not isinstance(plan, list):
            # Handle cases where the LLM wraps the list in a dictionary (e.g., {"plan": [...]})
            if isinstance(plan, dict) and "plan" in plan and isinstance(
                plan["plan"], list
            ):
                plan = plan["plan"]
            else:
                raise ValueError("Planner did not return a valid JSON list structure.")

        print("[Engine: Planner] Plan generated successfully.")
        return plan
    except Exception as e:
        print(f"[Engine: Planner] Failed to generate a valid plan. Error: {e}. Raw LLM Output: {plan_json}")
        raise e
```

## Executor — `resolve_dependencies`

Deep-copies input, recursively walks dicts/lists, substitutes `$$REF$$` strings from state.

```python
def resolve_dependencies(input_params, state):
    """
    Helper function to replace $$REF$$ placeholders with actual data from the execution state.
    This implements Context Chaining.
    """
    # Use copy.deepcopy to ensure the original plan structure is not modified
    resolved_input = copy.deepcopy(input_params)

    # Recursive function to handle potential nested structures
    def resolve(value):
        if isinstance(value, str) and value.startswith("$$") and value.endswith("$$"):
            ref_key = value[2:-2]
            if ref_key in state:
            # Retrieve the actual data (string) from the previous step's output
                print(f"[Engine: Executor] Resolved dependency {ref_key}.")
                return state[ref_key]
            else:
                raise ValueError(f"Dependency Error: Reference {ref_key} not found in execution state.")
        elif isinstance(value, dict):
            return {k: resolve(v) for k, v in value.items()}
        elif isinstance(value, list):
            return [resolve(v) for v in value]
        return value

    return resolve(resolved_input)
```

## Execution Tracer

Constructor starts the timer. `log_plan` stores the strategy. `log_step` captures agent, planned input, resolved context, and output. `finalize` records status, output, duration.

```python
class ExecutionTrace:
    """Logs the entire execution flow for debugging and analysis."""
    def __init__(self, goal):
        self.goal = goal
        self.plan = None
        self.steps = []
        self.status = "Initialized"
        self.final_output = None
        self.start_time = time.time()

    def log_plan(self, plan):
        self.plan = plan

    def log_step(
        self, step_num, agent, planned_input, mcp_output, resolved_input
    ):
        """Logs the details of a single execution step."""

        self.steps.append({
            "step": step_num,
            "agent": agent,
            "planned_input": planned_input,
            "resolved_context": resolved_input,
            "output": mcp_output['content']
        })

    def finalize(self, status, final_output=None):
        self.status = status
        self.final_output = final_output
        self.duration = time.time() - self.start_time
```

## Putting It All Together — `context_engine()`

Two-phase orchestration: init, Phase 1 plan, Phase 2 execution loop (per-step body shown), finalization. Returns `(final_output, trace)` — trace returned even on failure.

```python
def context_engine(goal):
    """
    The main entry point for the Context Engine. Manages Planning and Execution.
    """

    print(f"\n=== [Context Engine] Starting New Task ===\nGoal: {goal}\n")
    trace = ExecutionTrace(goal)
    registry = AGENT_TOOLKIT

    # Phase 1: Plan
    try:
        capabilities = registry.get_capabilities_description()
        plan = planner(goal, capabilities)
        trace.log_plan(plan)
    except Exception as e:
        trace.finalize("Failed during Planning")
        # Return the trace even in failure for debugging
        return None, trace
```

```python
        print(f"\n[Engine: Executor] Starting Step {step_num}: {agent_name}")

        try:
            handler = registry.get_handler(agent_name)

            # Context Assembly: Resolve dependencies
            resolved_input = resolve_dependencies(planned_input, state)

            # Execute Agent via MCP
            # Create an MCP message with the RESOLVED input for the agent
            mcp_resolved_input = create_mcp_message(
                "Engine", resolved_input)
            mcp_output = handler(mcp_resolved_input)

            # Update State and Log Trace
            output_data = mcp_output["content"]

            # Store the output data (the context itself)
            state[f"STEP_{step_num}_OUTPUT"] = output_data
            trace.log_step(step_num, agent_name, planned_input,
                    mcp_output, resolved_input)
            print(f"[Engine: Executor] Step {step_num} completed.")

        except Exception as e:
            error_message = f"Execution failed at step {step_num}({agent_name}):{e}"
            print(f"[Engine: Executor] ERROR: {error_message}")
            trace.finalize(f"Failed at Step {step_num}")
            # Return the trace for debugging the failure
            return None, trace
```

```python
    final_output = state.get(f"STEP_{len(plan)}_OUTPUT")
    trace.finalize("Success", final_output)
    print("\n=== [Context Engine] Task Complete ===")
    return final_output, trace
```
