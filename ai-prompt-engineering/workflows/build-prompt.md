# Build Prompt Workflow

Apply best practices to write a new prompt from scratch.

## When to Use

- New LLM-powered feature needs its first prompt
- Replacing a brittle existing prompt
- Adding a new use case to an existing system

## Prerequisites

- Clear task definition (input → output)
- Access to the LLM you'll be calling
- A small set of test inputs (5-10 cases including edge cases)

**Reference**: `references/prompting-best-practices/rules.md`

---

## Workflow Steps

### Step 1: Clarify the Task

**Goal**: Eliminate ambiguity before writing prose.

- [ ] Write the task in one sentence: "Given X, produce Y"
- [ ] Specify the output format (JSON schema? Markdown? Plain text?)
- [ ] Specify constraints (length, language, style)
- [ ] Identify edge cases the prompt must handle

**Reference**: `references/prompting-fundamentals/rules.md`

---

### Step 2: Choose Prompt Structure

**Goal**: Decide the system/user split and example strategy.

- [ ] Put role, persona, output format, and constraints in **system prompt**
- [ ] Put per-request data in **user prompt**
- [ ] Decide: zero-shot or few-shot?
  - Few-shot if format is non-obvious or task is novel
  - Zero-shot if model already nails it
- [ ] If few-shot: pick 2-5 high-quality examples covering edge cases

**Reference**: `references/prompting-fundamentals/rules.md`, `references/prompting-fundamentals/examples.md`

---

### Step 3: Write Clear Instructions

**Goal**: Apply the explicit-instruction rule.

- [ ] Start with the action verb
- [ ] State the persona (if it helps): "You are a..."
- [ ] State the output format precisely (with example)
- [ ] State what to do if the answer is unknown ("respond with NULL")
- [ ] State what NOT to do (e.g., "Do not include explanations")

**Reference**: `references/prompting-best-practices/rules.md`, `references/prompting-best-practices/examples.md`

---

### Step 4: Add Reasoning (if multi-step)

**Goal**: Give the model time to think when the task is non-trivial.

- [ ] If single-step lookup: skip reasoning
- [ ] If multi-step or arithmetic: add chain-of-thought
- [ ] If complex: decompose into multiple LLM calls (one per step)
- [ ] Pick CoT variant: zero-shot ("Let's think step by step"), scripted (specific steps), or one-shot (example with reasoning)

**Reference**: `references/prompting-best-practices/patterns.md`

---

### Step 5: Add Context (if needed)

**Goal**: Provide what the model needs to answer correctly.

- [ ] Identify what context the model can't be expected to know
- [ ] Place context near the END of the prompt (or sandwich the instruction)
- [ ] Use delimiters (XML tags, triple-quotes) to separate context from instructions
- [ ] Restrict the model: "Only use information from the context provided"

**Reference**: `references/prompting-best-practices/rules.md`, `references/prompting-best-practices/examples.md`

---

### Step 6: Test on Edge Cases

**Goal**: Verify before shipping.

- [ ] Run on the test set
- [ ] Check parse success (if structured output)
- [ ] Check edge cases: empty input, very long input, adversarial input
- [ ] Compare against a baseline (simple prompt)
- [ ] Walk through `references/prompting-best-practices/checklist.md`

**Reference**: `references/prompting-best-practices/checklist.md`

---

### Step 7: Iterate and Version

**Goal**: Lock in what works, log changes.

- [ ] Save the prompt with a version number
- [ ] Document the test cases it was validated against
- [ ] Set up A/B testing if changing an existing prompt
- [ ] Plan re-validation when the model version changes

**Reference**: `references/prompting-best-practices/rules.md`

---

### Step 8: Defensive Pass (for user-facing prompts)

**Goal**: Add defenses if the prompt is exposed to users.

- [ ] If user input is part of the prompt: run `audit-prompt-security.md` workflow

**Reference**: `workflows/audit-prompt-security.md`

---

## Quick Checklist

```
[ ] Step 1: Task clarified (input/output/format/constraints)
[ ] Step 2: System/user split + zero/few-shot decided
[ ] Step 3: Clear instructions written
[ ] Step 4: Reasoning added if multi-step
[ ] Step 5: Context added with delimiters
[ ] Step 6: Tested on edge cases
[ ] Step 7: Versioned and saved
[ ] Step 8: Security audit (if user-facing)
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Vague instructions ("write something good") | Inconsistent outputs | Spell out criteria |
| Examples but no edge cases | Model fails on real data | Include edge cases in few-shot |
| Instruction in middle of long context | Lost-in-the-middle | Place at start AND/OR end |
| Skipping the test set | Bugs found in production | Always validate before shipping |

---

## Exit Criteria

- [ ] Prompt versioned in code/config
- [ ] Test set passes at quality bar
- [ ] If user-facing: security audit complete
- [ ] Documented who owns it and when to re-evaluate
