# Agent Design Smells

Anti-patterns and red flags in agent design and evaluation. Use during code review and when triaging agent failures.

---

## A1: Trusting the Agent's Self-Report

**What it is**: Treating "I'm done" from the agent as proof of completion.

**How to detect**:
- Code path: `if agent.says_done(): return success`.
- No predicate-based check on the actual output.
- Test suite has no "did it really finish?" assertions.

**Why it's bad**:
- Reflection failures pass undetected — the agent can be confidently wrong.
- Constraint violations (budget, count, deadline) slip through.

**How to fix**:
- Encode success as machine-checkable predicates.
- Verify outputs against the original task and constraints.

**Example**:
```python
# Smell
if agent.says_done():
    return "success"

# Fixed
if check_constraints(result, task) and check_goal(result, task):
    return "success"
```

---

## A2: No Plan Validation Before Execution

**What it is**: Running the agent's plan without checking whether the tools and parameters are valid.

**How to detect**:
- No call to a `validate_plan(...)` function.
- Tool execution wraps every call in a try/except that swallows errors.
- Failures only surface as cryptic runtime errors.

**Why it's bad**:
- Wastes tokens, time, and money executing broken plans.
- Hides which class of planning failure occurred.

**How to fix**:
- Validate tool names against the inventory.
- Validate parameter shape against each tool's schema.
- Reject invalid plans up front and surface a structured error.

---

## A3: Untested Tools

**What it is**: Treating tools as black boxes without per-tool benchmarks.

**How to detect**:
- No test file per tool.
- No translator benchmark when one is in use.
- All evaluation is end-to-end.

**Why it's bad**:
- Tool failures are tool-dependent and invisible from end-to-end runs.
- A bug in one tool degrades every plan that uses it.

**How to fix**:
- Build a per-tool benchmark with known inputs and gold outputs.
- Track per-tool accuracy over time and alert on regressions.

---

## A4: No Tool Call Logs

**What it is**: Tools are invoked, but inputs and outputs are not printed or stored.

**How to detect**:
- Logs only show high-level agent state.
- Failures cannot be reproduced because the failing tool call isn't recorded.

**Why it's bad**:
- Impossible to debug tool failures or translation errors.
- Cannot compute per-tool failure rates.

**How to fix**:
- Log `(tool_name, args, output)` for every step, tagged with task and step index.

---

## A5: Success Without Efficiency Metrics

**What it is**: Evaluation pipeline reports only pass/fail, never steps, cost, or latency.

**How to detect**:
- Eval output has a single column: `status`.
- No baseline (human or other agent) for comparison.

**Why it's bad**:
- Wasteful agents look identical to efficient ones.
- Regressions in cost or latency go unnoticed until the bill arrives.

**How to fix**:
- Record steps per task, cost per task, latency per action.
- Compare against a baseline agent or human operator.

---

## A6: Ignoring Time as a Constraint

**What it is**: Treating wall-clock time as a soft metric for tasks where deadlines matter.

**How to detect**:
- Deadline-sensitive tasks (proposals, market trades, time-boxed decisions) have no time-out.
- "Success" is reported even when the work is delivered after the deadline.

**Why it's bad**:
- A correct grant proposal delivered after the deadline is worthless.
- Agent appears to be working when it has effectively failed.

**How to fix**:
- Add hard deadlines to time-sensitive tasks.
- Mark over-deadline runs as failures even if the output is correct.

---

## A7: Blaming the Model for Domain Failures

**What it is**: When the agent fails on a domain, the first response is to swap the model or rewrite the prompt.

**How to detect**:
- Failures cluster sharply in one domain (e.g., finance, medical, current events).
- No analysis of whether the agent had the right tools.

**Why it's bad**:
- Wastes effort on the wrong layer.
- The actual gap is a missing tool, not a model defect.

**How to fix**:
- Bucket failures by domain.
- Talk to a domain expert about what tools they use.
- Add the missing tool before tuning the model.

---

## A8: Comparing AI Steps to Human Steps Naively

**What it is**: Concluding the agent is inefficient because it took more "steps" than a human.

**How to detect**:
- Efficiency report claims agent is wasteful purely on a step count.
- No accounting for parallelism or differing modes of operation.

**Why it's bad**:
- An AI that loads 100 pages in parallel may be vastly cheaper than a human visiting one at a time.
- Misleading metric drives the wrong optimization.

**How to fix**:
- Compare on cost and wall-clock time, not raw step count.
- Note when AI and human modes of operation differ before comparing.

---

## Quick Detection Table

| ID | Smell | Key Indicator |
|----|-------|---------------|
| A1 | Trusting self-report | `agent.says_done()` gates success |
| A2 | No plan validation | Plans run without schema check |
| A3 | Untested tools | No per-tool benchmark |
| A4 | No tool call logs | Cannot reproduce a failed tool call |
| A5 | No efficiency metrics | Eval reports only pass/fail |
| A6 | Time ignored | Deadline tasks have no timeout |
| A7 | Blaming the model | Domain failures fixed with prompt edits |
| A8 | Naive step comparison | Step count drives efficiency claims |
