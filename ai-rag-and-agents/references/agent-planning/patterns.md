# Agent Planning Patterns

Reusable patterns for structuring agent planning, reflection, and tool composition.

## Pattern: Decoupled Plan-Validate-Execute

**Intent**: Avoid runaway agent execution by validating plans before they run.

**When to Use**: Tasks > 2-3 steps; tasks with side effects; production agents.

```python
def run_agent(task):
    plan = generate_plan(task)
    if not validate_plan(plan):
        plan = generate_plan(task, feedback="prior plan was invalid")
    return execute(plan)
```

**Trade-offs**: Prevents dead-end loops and enables gating; adds one validation call.

---

## Pattern: ReAct (Reason + Act)

**Intent**: Interleave reasoning and action so the agent reflects after every observation.

**When to Use**: Multi-hop QA; tasks where observations should change the plan; when trace interpretability matters.

```text
Thought 1: <reasoning>
Act 1: <tool call>
Observation 1: <tool result>
...
Thought N: <reasoning>
Act N: Finish[<final answer>]
```

**Trade-offs**: Self-correcting and human-readable; heavy token cost and latency scales with steps.

---

## Pattern: Reflexion (Evaluator + Self-Reflection)

**Intent**: Separate "did it work?" from "why did it fail?" and feed reflections into the next attempt.

**When to Use**: Tasks with measurable success signal; iterative tasks (coding, multi-attempt QA).

```python
def reflexion_loop(task, max_attempts=3):
    plan = generate_plan(task)
    for _ in range(max_attempts):
        result = execute(plan)
        score = evaluator(result, task)
        if score.passed:
            return result
        reflection = self_reflect(task, plan, result, score)
        plan = generate_plan(task, prior_reflection=reflection)
    return result
```

**Trade-offs**: Strong gains for low cost; needs reliable evaluator; cap attempts.

---

## Pattern: Hierarchical Planning

**Intent**: Resolve the granularity trade-off — detailed plans are easier to execute, high-level easier to generate.

**When to Use**: Long-horizon tasks; same planner across many task types.

```python
def hierarchical_plan(task):
    high_level = generate_high_level_plan(task)   # quarter-by-quarter
    return [generate_detailed_plan(step) for step in high_level]
```

**Trade-offs**: Manageable per-call; more planner calls overall.

---

## Pattern: Multi-Agent Plan/Execute/Evaluate

**Intent**: Split planning, execution, and evaluation into specialized agents.

**When to Use**: Production systems where roles benefit from different prompts/models.

```python
planner   = Agent(model="strong", role="plan")
executor  = Agent(model="cheap",  role="run plan steps")
evaluator = Agent(model="strong", role="score outcomes")

plan   = planner(task)
result = executor(plan)
score  = evaluator(task, result)
```

**Trade-offs**: Focused prompts per role; coordination overhead.

---

## Pattern: Natural-Language Plan + Translator

**Intent**: Make plans robust to tool renames or new tool inventories.

**When to Use**: Tools change often; same planner across deployments; finetuned planner you cannot retrain.

**Structure**:
1. Planner outputs steps in natural language
2. A small translator maps each NL step to a function call
3. Executor runs the call

**Trade-offs**: Tool changes only touch translator; extra translation step adds latency.

---

## Pattern: Tool Composition / Skill Manager

**Intent**: Build new tools by composing existing ones and save them for reuse (Voyager-style).

**When to Use**: Long-running agents; tasks with recurring multi-tool sequences.

```python
class SkillManager:
    def __init__(self):
        self.skills = {}  # name -> code

    def add_if_useful(self, name, code, succeeded):
        if succeeded:
            self.skills[name] = code

    def retrieve(self, query):
        return semantic_search(self.skills, query)
```

**Trade-offs**: Capability grows over time; needs quality gating to avoid bad-skill drift.

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|--------------------|
| Long task, side effects | Decoupled Plan-Validate-Execute |
| Multi-hop QA, transparent trace | ReAct |
| Iterative tasks with success signal | Reflexion |
| Multi-day or multi-phase project | Hierarchical Planning |
| Production with role specialization | Multi-Agent Plan/Execute/Evaluate |
| Tool inventory changes often | Natural-Language Plan + Translator |
| Long-lived agent, recurring patterns | Skill Manager / Tool Composition |
