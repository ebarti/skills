# Debug Agent Workflow

Diagnose and fix agent failures: planning, tool, or efficiency issues.

## When to Use

- Agent succeeds in dev but fails in production
- Agent runs forever / costs too much
- Agent calls wrong tools or passes bad parameters
- Agent claims success but the goal isn't achieved

## Prerequisites

- Logs/traces from the failing run(s)
- Access to the agent's tool outputs
- Ground truth for what should have happened

**Reference**: `references/agent-failures/rules.md`

---

## Workflow Steps

### Step 1: Reproduce the Failure

**Goal**: Get a deterministic repro before changing anything.

- [ ] Locate the failing trace (which run, which input)
- [ ] Run the same input again with logging enabled
- [ ] Confirm failure reproduces (if not: stochastic — temperature?)
- [ ] Save the full trace: prompts, tool calls, outputs, timings

**Reference**: `ai-production-architecture/references/monitoring-observability/rules.md`

---

### Step 2: Classify the Failure

**Goal**: Pinpoint which category of failure occurred.

| Symptom | Category | Files |
|---------|----------|-------|
| Agent picks a tool that doesn't exist | Planning: invalid tool | `references/agent-failures/rules.md` |
| Agent calls right tool, wrong params | Planning: bad params | `references/agent-failures/examples.md` |
| Agent calls right tool, right params, but wrong values | Planning: wrong values | `references/agent-failures/examples.md` |
| Agent succeeds at sub-tasks, misses goal | Planning: goal failure | `references/agent-failures/rules.md` |
| Agent hits max steps / time | Planning: time | `references/agent-failures/rules.md` |
| Tool returns wrong result for valid input | Tool: wrong output | `references/agent-failures/rules.md` |
| Tool returns format the agent can't parse | Tool: translation | `references/agent-failures/examples.md` |
| No tool exists for the task | Missing tool | `references/agent-failures/rules.md` |
| Agent uses too many AI calls vs human baseline | Efficiency | `references/agent-failures/rules.md` |

- [ ] Read the trace and assign one or more categories
- [ ] Don't blame the model — distinguish "model picked wrong" from "tool failed"

**Reference**: `references/agent-failures/rules.md`

---

### Step 3: Apply Category-Specific Fixes

**Goal**: Use the right remediation for the failure type.

#### Planning failures
- [ ] Improve plan validation (heuristic + AI judge)
- [ ] Add reflection step after each tool call
- [ ] Check tool descriptions: are they clear?
- [ ] Reduce tool inventory if too many options

#### Tool failures
- [ ] Test the tool independently with the failing input
- [ ] If output is wrong: fix the tool
- [ ] If format is wrong: add a translation/normalization layer
- [ ] Add structured output (JSON schema) instead of free text

#### Missing tool
- [ ] Identify the tool that should exist
- [ ] Build it (don't blame the model for what isn't there)

#### Efficiency
- [ ] Compare AI step count to human baseline
- [ ] Check for repeated tool calls (cache results?)
- [ ] Check for unnecessary reflection loops
- [ ] Set max-iteration and max-cost limits

**Reference**: `references/agent-failures/examples.md`

---

### Step 4: Cross-Check Against Anti-Patterns

**Goal**: Find systemic issues.

- [ ] Walk every anti-pattern in `references/agent-failures/smells.md`
- [ ] Look especially for: trusting self-reports, no plan validation, untested tools, no logs, no cost tracking

**Reference**: `references/agent-failures/smells.md`

---

### Step 5: Add Regression Test

**Goal**: Make sure the failure doesn't recur.

- [ ] Add the failing input to the agent's eval set
- [ ] Define the expected outcome
- [ ] Wire it into CI/eval pipeline
- [ ] Re-run on every change

**Reference**: `ai-evaluation/workflows/design-eval-pipeline.md`

---

### Step 6: Add Monitoring for the Failure Class

**Goal**: Catch the next instance faster.

- [ ] Add a metric for the failure category (e.g., "planning_failure_rate")
- [ ] Alert when the rate exceeds threshold
- [ ] Log the trace for any future occurrence

**Reference**: `ai-production-architecture/references/monitoring-observability/rules.md`

---

## Quick Checklist

```
[ ] Step 1: Failure reproduced
[ ] Step 2: Category identified
[ ] Step 3: Category-specific fix applied
[ ] Step 4: Anti-patterns audited
[ ] Step 5: Regression test added
[ ] Step 6: Monitoring added for class
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Blaming "the model" | Hides the real bug | Classify into 3 failure categories |
| Trusting agent self-reports | They lie | Independently verify outcomes |
| Fixing without a regression test | Bug recurs | Add to eval set |
| Tuning prompt for one trace | Overfits to anecdote | Run against full eval set |

---

## Exit Criteria

- [ ] Failure understood and category-identified
- [ ] Fix applied
- [ ] Regression test passes
- [ ] Monitoring in place to catch recurrence
