# Agent Planning Examples

Concrete prompts, traces, and Python snippets for plan generation, ReAct, reflection, and tool selection.

## Plan Generation Prompt

System prompt that constrains the planner to declared actions:

```text
SYSTEM PROMPT
Propose a plan to solve the task. You have access to 5 actions:
get_today_date()
fetch_top_products(start_date, end_date, num_products)
fetch_product_info(product_name)
generate_query(task_history, tool_output)
generate_response(query)

The plan must be a sequence of valid actions.

Examples
Task: "Tell me about Fruity Fedora"
Plan: [fetch_product_info, generate_query, generate_response]

Task: "What was the best selling product last week?"
Plan: [fetch_top_products, generate_query, generate_response]

Task: {USER INPUT}
Plan:
```

A generated plan for the query "What's the price of the best-selling product last week?":

```text
1. get_today_date()
2. fetch_top_products()
3. fetch_product_info()
4. generate_query()
5. generate_response()
```

After step 1 outputs `2030-09-13`, the agent infers parameters for step 2:

```python
fetch_top_products(
    start_date="2030-09-07",
    end_date="2030-09-13",
    num_products=1,
)
```

## Plan Validator (Heuristic + AI Judge)

```python
def validate_plan(plan: list[str], allowed_tools: set[str], max_steps: int = 10) -> bool:
    if len(plan) > max_steps:
        return False
    return all(action in allowed_tools for action in plan)

def ai_judge_plan(plan: list[str], task: str) -> tuple[bool, str]:
    prompt = f"""Task: {task}
Proposed plan:
{plan}

Reply with 'OK' if the plan is reasonable, otherwise 'BAD: <reason>'."""
    verdict = llm(prompt)
    return verdict.startswith("OK"), verdict
```

## ReAct Trace

Format used by ReAct (Yao et al., 2022). The agent interleaves planning and reflection until it decides the task is done.

```text
Question: Aside from the Apple Remote, what other device can control the program Apple Remote was originally designed to interact with?

Thought 1: I need to find out what program the Apple Remote was originally designed to interact with.
Act 1: Search["Apple Remote"]
Observation 1: The Apple Remote is a remote control device first introduced in 2005 to control the Front Row media center program on the iMac G5.

Thought 2: Apple Remote was designed to control the Front Row program. I need to find what other device can control Front Row.
Act 2: Search["Front Row (software)"]
Observation 2: Front Row can be controlled by the Apple Remote or the keyboard function keys.

Thought 3: The answer is keyboard function keys.
Act 3: Finish[keyboard function keys]
```

## Reflexion-Style Reflection

After execution fails, prompt the agent to diagnose and revise.

```python
REFLECT_PROMPT = """You attempted this task: {task}

Your plan was:
{plan}

Result: {result}
Evaluation: {evaluation}

Reflect on why it failed and how to improve. Then propose a new plan."""

def reflect_and_replan(task, plan, result, evaluation):
    prompt = REFLECT_PROMPT.format(
        task=task, plan=plan, result=result, evaluation=evaluation,
    )
    reflection = llm(prompt)
    return parse_new_plan(reflection)
```

Concrete coding example: an evaluator reports the generated code fails 1/3 of test cases. The agent reflects: "I didn't handle arrays where all numbers are negative." It then regenerates code accounting for that case.

## Function Calling (pseudocode)

```python
tools = [
    {
        "name": "lbs_to_kg",
        "description": "Convert pounds to kilograms.",
        "parameters": {"lbs": {"type": "number"}},
    },
]

response = client.messages.create(
    model="claude",
    tools=tools,
    tool_choice="auto",  # or "required" / "none"
    messages=[{"role": "user", "content": "How many kg are 40 lbs?"}],
)

# response.tool_use -> {"name": "lbs_to_kg", "input": {"lbs": 40}}
result = lbs_to_kg(**response.tool_use["input"])
```

## Tool Selection Prompt (Intent-Driven)

```text
SYSTEM PROMPT
You are routing a customer support query to the right tool.

Tools:
- get_user_payments(user_id) — billing/payment history
- search_docs(query) — product docs and how-to articles
- escalate_to_human() — anything you cannot handle

First classify the intent: BILLING | HOWTO | OTHER | IRRELEVANT
If IRRELEVANT, reply: "Sorry, I can't help with that."
Otherwise, choose the single best tool and the parameters.

Query: {USER INPUT}
```

## Natural-Language Plan + Translator

Higher-level plan, robust to renamed tools:

```text
1. get current date
2. retrieve the best-selling product last week
3. retrieve product information
4. generate query
5. generate response
```

Translator (a smaller, cheaper model) maps each step to a function call:

```python
TRANSLATE = """Map the natural-language step to one of these functions:
{tool_signatures}

Step: {step}
Return JSON: {{"name": ..., "args": {{...}}}}"""

def translate(step, tool_signatures):
    return json.loads(llm(TRANSLATE.format(step=step, tool_signatures=tool_signatures)))
```

## Parallel Plan Generation

```python
async def best_plan(task, planner, k=3):
    candidates = await asyncio.gather(*[planner(task) for _ in range(k)])
    scored = [(p, ai_judge_plan(p, task)) for p in candidates]
    valid = [(p, v) for p, (ok, v) in scored if ok]
    return max(valid, key=lambda x: score(x[1]))[0] if valid else None
```
