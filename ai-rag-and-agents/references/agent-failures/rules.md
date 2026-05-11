# Agent Failure Detection Rules

Guidelines for detecting and measuring planning failures, tool failures, and efficiency issues in agents.

## Core Rules

### 1. Validate Every Plan Before Execution

Catch planning failures before they hit production tools.

- Confirm every called tool exists in the tool inventory.
- Validate parameter names and types against the tool's schema.
- Where possible, sanity-check parameter values against the original task input.

**Example**:
```python
# Bad: execute first, debug later
result = run_plan(plan)

# Good: validate, then execute
errors = validate_plan(plan, tool_inventory)
if errors:
    raise PlanValidationError(errors)
result = run_plan(plan)
```

### 2. Build a Planning Dataset

Evaluation requires a dataset of `(task, tool_inventory)` tuples. For each task, generate K plans and compute:

1. Fraction of plans that are valid.
2. Average plans needed before reaching a valid one.
3. Fraction of tool calls that are valid.
4. Rate of invalid tool calls.
5. Rate of valid tools called with invalid parameters.
6. Rate of valid tools called with incorrect parameter values.

### 3. Always Log Tool Calls and Outputs

Tool failures are invisible without logs.

- Print every tool call (name, args).
- Print every tool output.
- Tag logs with the parent task and step index so failures can be traced back.

### 4. Test Each Tool Independently

Tool failures are tool-dependent. Don't assume an end-to-end test exercises a tool correctly.

- Create per-tool test suites with known inputs and expected outputs.
- If a translator converts plans to commands, build a separate translator benchmark.

### 5. Verify Goal Completion Independently of Reflection

Never trust the agent's self-assessment.

- Compare the actual output against the task's success criteria.
- Check constraint satisfaction (budget, deadline, count).

**Example**:
```python
# Bad
if agent.says_done():
    return "success"

# Good
if check_constraints(result, task.constraints) and check_goal(result, task.goal):
    return "success"
```

### 6. Track Time as a Constraint

For deadline-sensitive tasks, time is a hard constraint, not a metric.

- Record wall-clock time per task.
- Fail tasks that complete after a deadline, even if functionally correct.

### 7. Measure Efficiency Even on Successful Runs

Success without efficiency metrics is incomplete evaluation.

- Steps per task (average and max).
- Cost per task (token spend, API charges).
- Latency per action and per task.
- Identify the slowest or most expensive actions.

### 8. Detect Missing Tools by Domain Pattern

If the agent consistently fails on one domain, the cause is often a missing tool, not a model defect.

- Bucket failures by task domain.
- Consult human domain experts for the toolset they use.
- Add the missing tool before tuning prompts.

## Guidelines

- Analyze failure patterns, not just failure rates — find the task types and tools that fail most often.
- For a hard-to-use tool, try better prompting, more examples, or finetuning before swapping it.
- If those fail, swap the tool for a simpler-to-use equivalent.
- Compare efficiency to a baseline (another agent or human), but acknowledge AI and human modes differ.

## Exceptions

- **Async / fire-and-forget tasks**: Time tracking matters less when you only check in when finished.
- **Exploratory agents**: Step counts may be intentionally high; measure cost and value instead.

## Quick Reference

| Rule | Summary |
|------|---------|
| Validate plans | Check tool, params, values before run |
| Build planning dataset | `(task, tool_inventory)` tuples + 6 metrics |
| Log tool I/O | Print every call and output |
| Test tools alone | Each tool has its own benchmark |
| Verify goal independently | Don't trust self-reflection |
| Track time | Treat deadlines as hard constraints |
| Measure efficiency | Steps, cost, latency on every run |
| Detect missing tools | Bucket failures by domain |
