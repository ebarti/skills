# Build Agent Workflow

End-to-end agent construction from tool design to production.

## When to Use

- Task requires multiple LLM calls in a loop
- Task needs external tools (search, code execution, write actions)
- Task is complex enough that a single prompt doesn't suffice

## Prerequisites

- Defined task and target environment
- LLM API with function calling support
- Decided agent is the right approach (not just a single LLM call)

**Reference**: `references/agent-overview/rules.md`

---

## Workflow Steps

### Step 1: Define the Environment and Goal

**Goal**: Specify what the agent operates on and what success looks like.

- [ ] Describe the environment (file system, database, web, API surface)
- [ ] Define the goal explicitly
- [ ] Define constraints (time, money, side effects)
- [ ] Define success criteria (verifiable, not just "looks good")

**Reference**: `references/agent-overview/knowledge.md`

---

### Step 2: Design the Tool Inventory

**Goal**: Pick the minimum set of tools needed.

- [ ] Categorize each tool: knowledge augmentation, capability extension, or write action
- [ ] Right-size: too many tools confuses the model, too few limits capability
- [ ] Separate read-only from write tools
- [ ] For each write tool: define approval flow (auto, log, gate, propose-only)
- [ ] Sandbox any code interpreter (Docker, restricted env)

**Reference**: `references/agent-overview/rules.md`, `references/agent-overview/examples.md`

---

### Step 3: Write Tool Descriptions

**Goal**: Tool descriptions are the agent's most-read documentation. Make them excellent.

- [ ] Each tool: clear name, one-sentence purpose, parameter schema with types and descriptions
- [ ] Document side effects (what the tool changes in the environment)
- [ ] Add examples in the tool description
- [ ] Use native function calling (e.g., OpenAI/Anthropic JSON schema), not free-form

**Reference**: `references/agent-overview/examples.md`

---

### Step 4: Choose Planning Pattern

**Goal**: Pick the planning loop architecture.

| Pattern | When |
|---------|------|
| **ReAct** (reason→act→observe loop) | General default; simple agents |
| **Plan-and-Execute** | Multi-step tasks where plan is reusable |
| **Reflexion** (with reflection) | Errors are common; need self-correction |
| **Hierarchical** | Very complex tasks (planner + executor) |
| **NL Plan + Translator** | Need a human-readable plan first |

- [ ] Pick a pattern from `references/agent-planning/patterns.md`
- [ ] Decouple planning from execution (validate before executing)
- [ ] Add intent classification at the start

**Reference**: `references/agent-planning/patterns.md`

---

### Step 5: Add Validation and Reflection

**Goal**: Catch errors early and recover.

- [ ] Validate plans before execution (heuristic + AI judge)
- [ ] After each tool call, log the result and let the model reflect
- [ ] On failure: try replanning before retrying
- [ ] Set a max-iteration limit to prevent infinite loops

**Reference**: `references/agent-planning/rules.md`

---

### Step 6: Add Memory (if needed)

**Goal**: Give the agent state across turns.

- [ ] Decide on short-term memory (current task budget) and long-term memory (across sessions)
- [ ] Don't use naive FIFO; budget tokens with a summary or eviction strategy
- [ ] For long-term: use embedding store + retrieval

**Reference**: `references/agent-memory/rules.md`, `references/agent-memory/examples.md`

---

### Step 7: Evaluate Failure Modes

**Goal**: Test against the known failure categories.

- [ ] Planning failures: invalid tool, bad params, wrong values, goal violation, time, missing tools
- [ ] Tool failures: wrong output, translation errors
- [ ] Efficiency: AI vs human steps, cost per task
- [ ] Build a planning eval set with ground-truth plans

**Reference**: `references/agent-failures/rules.md`, `references/agent-failures/examples.md`

---

### Step 8: Add Production Infrastructure

**Goal**: Run it safely.

- [ ] Wrap write actions with allowlists and audit logs
- [ ] Add per-call cost tracking (cumulative cost > limit → abort)
- [ ] Add per-call latency tracking
- [ ] Add monitoring on success rate, average steps, cost per task

**Reference**: `ai-production-architecture/references/architecture-patterns/rules.md`

---

## Quick Checklist

```
[ ] Step 1: Environment + goal + success criteria defined
[ ] Step 2: Tool inventory designed (sized, sandboxed)
[ ] Step 3: Tool descriptions written
[ ] Step 4: Planning pattern chosen
[ ] Step 5: Validation + reflection added
[ ] Step 6: Memory added (if needed)
[ ] Step 7: Failure modes tested
[ ] Step 8: Production infrastructure in place
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Too many tools | Confuses the model | Curate to the minimum |
| Vague tool descriptions | Wrong tool selection | Examples + parameter docs |
| No plan validation | Bad plans waste tool calls | Validate before executing |
| Trusting agent self-reports | Optimistic bias | Independently verify outcomes |
| No max-iteration limit | Runaway costs | Cap iterations, cap cost |
| Auto-execute write actions | Catastrophic mistakes | Require approval gate |

---

## Exit Criteria

- [ ] Agent succeeds on the eval set at the target rate
- [ ] Cost per task within budget
- [ ] No write action executes without approval
- [ ] Monitoring + alerting on failures and runaway costs
