# AI Use Case Evaluation Patterns

Reusable patterns for deciding whether a use case is a good fit for foundation models.

## Pattern: Task Exposure Test

### Intent

Quickly judge whether AI can meaningfully accelerate a task.

### When to Use

- Considering a new application
- Prioritizing a backlog of AI ideas
- Pushing back on stakeholder requests that don't fit AI

### Structure

```python
def is_good_ai_fit(task):
    return (
        ai_can_reduce_time_by(task) >= 0.50
        and not requires_physical_presence(task)
        and has_clear_success_signal(task)
    )
```

### Example

- Translation: 50%+ time reduction, no body needed, output verifiable -> good fit
- Stonemasonry: requires hands and a chisel -> bad fit
- Customer support reply drafting: 50%+ time reduction, human can edit -> good fit

### Benefits

- Filters obvious non-fits in seconds
- Anchors the conversation in measurable productivity gains

### Considerations

- 50% is a heuristic; high-stakes tasks may need a higher bar
- Some "no fit today" tasks become fits as models improve

---

## Pattern: Critical vs Complementary Classification

### Intent

Decide whether AI is doing the work or assisting a human, and design guardrails accordingly.

### When to Use

- Before scoping any new AI feature
- When evaluating risk and review requirements
- When choosing between automation and copilot UX

### Structure

```python
class AIRole:
    CRITICAL = "ai_decides_final_output"
    COMPLEMENTARY = "human_reviews_ai_output"

def choose_role(task):
    if cost_of_error(task) > tolerance and not can_auto_verify(task):
        return AIRole.COMPLEMENTARY
    if has_review_loop(task):
        return AIRole.COMPLEMENTARY
    return AIRole.CRITICAL
```

### Example

- Internal meeting summarizer with manager review: complementary
- Autonomous customer refund decisions: critical (raise the bar a lot)
- Code suggestions in IDE: complementary (developer accepts/rejects)

### Benefits

- Clarifies how strict evaluation must be
- Drives UX choices (suggest vs. execute)

### Considerations

- A complementary feature can drift toward critical if humans stop reviewing — instrument for this

---

## Pattern: Risk-Sorted Rollout

### Intent

Sequence AI deployments to build expertise on safe surfaces before exposing AI to customers.

### When to Use

- Enterprise rollouts
- Brand-sensitive products
- Regulated industries

### Structure

```text
1. Internal-only tooling      <- learn, fail safely
2. Power-user copilot         <- expert reviews still in loop
3. General workforce copilot  <- broader use, still human-in-loop
4. External, customer-facing  <- highest scrutiny, most evaluation
5. Autonomous external action <- only after sustained reliability
```

### Example

- Stage 1: internal knowledge search across docs
- Stage 2: copilot for support agents
- Stage 3: autonomous customer support chatbot for tier-1 issues

### Benefits

- Each stage de-risks the next
- Builds organizational AI engineering muscle

### Considerations

- Pressure to skip stages is real; resist unless evaluation is exceptional

---

## Pattern: Adaptation Ladder

### Intent

Choose the cheapest adaptation technique that meets the quality bar.

### When to Use

- Every new use case
- When quality plateaus and you must decide what to try next

### Structure

```python
def adapt(use_case):
    out = prompt_engineering(use_case)
    if quality(out) >= bar:
        return out

    out = rag(use_case)
    if quality(out) >= bar:
        return out

    out = finetune(use_case)
    if quality(out) >= bar:
        return out

    return reconsider_problem_or_change_model(use_case)
```

### Benefits

- Avoids premature optimization (no finetuning when a prompt would do)
- Each step adds capability without throwing away the previous step's investment

### Considerations

- Not strictly linear: some problems jump straight to RAG (e.g., needs fresh data)
- Track cost-per-call alongside quality

---

## Pattern: Defensibility Audit

### Intent

Surface whether your AI product has any moat beyond the underlying model.

### When to Use

- Before committing to build a product on a foundation model
- During strategy reviews
- When a competitor announces something similar

### Structure

```text
For your use case, ask:
1. Could a user achieve 80% of this in a chat with the base model?
2. What proprietary data, distribution, or workflow do you add?
3. If the base model improves 10x, does your product become better or obsolete?
```

### Example

- Bad: "wrapper that summarizes pasted text" — base model already does this
- Good: "summarizer integrated into a CRM with customer history, action item extraction, and assignment to project tracking" — workflow + data moat
- Cautionary: Chegg-style homework help displaced when ChatGPT made the underlying capability free

### Benefits

- Catches projects with no defensibility before significant investment
- Forces clarity on the real value-add

### Considerations

- A product can survive without a moat if it has speed-to-market, distribution, or strong UX
- Moats erode as models improve; revisit annually

---

## Pattern: Output Structure First

### Intent

Reframe open-ended tasks as close-ended ones to make evaluation tractable.

### When to Use

- Risk is non-trivial
- You need automated quality measurement
- The task has natural categories or fields

### Structure

```python
# Instead of: "Generate a response about this support ticket"
# Use:
prompt = """
Classify this ticket:
- category: [billing|technical|account|other]
- urgency: [low|medium|high]
- suggested_action: [refund|escalate|reply|close]
- draft_reply: <text>
Output JSON.
"""
```

### Benefits

- Each field can be evaluated independently
- Easier to detect and recover from failures
- Easier to build dashboards and SLAs

### Considerations

- Some tasks genuinely need open-ended output; don't force structure where it hurts UX

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|-------------------|
| Triaging a new use case idea | Task Exposure Test |
| Defining UX for an AI feature | Critical vs Complementary |
| Planning enterprise rollout | Risk-Sorted Rollout |
| Choosing how to adapt the model | Adaptation Ladder |
| Validating product strategy | Defensibility Audit |
| Reducing risk on generation tasks | Output Structure First |
