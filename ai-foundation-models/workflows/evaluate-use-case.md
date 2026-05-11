# Evaluate AI Use Case Workflow

Decide whether (and how) to use foundation models for a proposed use case.

## When to Use

- New product/feature idea that might involve AI
- Prioritizing AI projects vs traditional software
- Justifying or rejecting an AI approach to stakeholders
- Pre-investment go/no-go on an AI initiative

## Prerequisites

- Clear problem statement or user story
- Initial sense of who/what/where the AI fits
- Authority or input on use case selection

**Reference**: `references/ai-engineering-overview/rules.md`

---

## Workflow Steps

### Step 1: Define the Task

**Goal**: Reduce the use case to a concrete task an FM could perform.

- [ ] State the input the model receives (text, image, structured data, etc.)
- [ ] State the output the model should produce
- [ ] Identify whether the task is open-ended (creative) or close-ended (verifiable)
- [ ] Identify the FM use case category (coding, writing, info aggregation, data org, conversational, workflow automation, image/video, education)

**Ask**: "Could a human do this task with the same input?"

**Reference**: `references/ai-engineering-overview/examples.md`

---

### Step 2: Classify the Role of AI

**Goal**: Determine whether AI is critical or complementary, and the human-in-the-loop level.

- [ ] Decide: Is AI **critical** (product breaks without it) or **complementary** (helpful add-on)?
- [ ] Decide: Is the AI's role **assist** (human does it), **augment** (AI suggests, human commits), or **automate** (AI commits)?
- [ ] Estimate the cost of an error (low / medium / high / catastrophic)
- [ ] Decide on a "Crawl-Walk-Run" rollout: start as assist or augment, escalate later

**If error cost is high or catastrophic**: keep human-in-the-loop in the first release.

**Reference**: `references/planning-applications/rules.md`

---

### Step 3: Audit Defensibility

**Goal**: Verify the use case has staying power beyond just the model.

- [ ] Ask: If a competitor used the same model tomorrow, what would still differentiate this product?
- [ ] List defensibility sources: proprietary data, distribution, workflow integration, brand, network effect
- [ ] Eliminate use cases whose only moat is "we have access to the model"

**Reference**: `references/planning-applications/rules.md`, `references/planning-applications/examples.md`

---

### Step 4: Pick the Adaptation Approach

**Goal**: Choose the cheapest adaptation that meets the bar.

- [ ] Default order: prompt engineering → RAG → finetuning → train from scratch (essentially never)
- [ ] Estimate the gap between the base model and the target performance
- [ ] Pick the lightest adaptation that closes the gap

**Reference**: `references/ai-engineering-overview/patterns.md` (Adaptation Ladder)

---

### Step 5: Set Expectations and Milestones

**Goal**: Plan release in stages with the last-mile budget upfront.

- [ ] Define a usefulness threshold (the quality bar at which release is worthwhile)
- [ ] Plan Crawl → Walk → Run stages with criteria for each
- [ ] Budget time/money for the last-mile (often >50% of total)
- [ ] Define maintenance plan: who owns it, how it's evaluated over time

**Reference**: `references/planning-applications/rules.md`, `references/planning-applications/checklist.md`

---

### Step 6: Final Go/No-Go

**Goal**: Run the pre-launch checklist.

- [ ] Walk through every item in `references/planning-applications/checklist.md`
- [ ] Document the answer to each question
- [ ] Get sign-off from key stakeholders

**Reference**: `references/planning-applications/checklist.md`

---

## Quick Checklist

```
[ ] Step 1: Task defined (input/output/category)
[ ] Step 2: AI role classified (critical/complementary, HITL level)
[ ] Step 3: Defensibility audited
[ ] Step 4: Adaptation approach picked
[ ] Step 5: Milestones and last-mile budget set
[ ] Step 6: Pre-launch checklist passed
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Skipping defensibility | Easily replicated by competitors | Build moats beyond the model |
| Going straight to fine-tuning | Wastes time/money | Try prompting and RAG first |
| Underestimating last mile | Missed deadlines, blown budget | Budget >50% for polish |
| Setting "AI must be perfect" bar | Never ships | Set a realistic usefulness threshold |

---

## Exit Criteria

- [ ] Documented decision: pursue, defer, or kill
- [ ] If pursuing: chosen adaptation approach, milestones, and owner
- [ ] If pursuing: written defensibility hypothesis
