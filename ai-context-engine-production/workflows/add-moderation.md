# Add Moderation Gatekeeper Workflow

Wire the two-stage moderation protocol (input + output) into the Context Engine's execution loop.

## When to Use

- Engine is about to handle untrusted user input (public-facing assistant)
- Compliance / safety review requires content moderation
- Going to production in a regulated domain (legal, medical, finance)

## Prerequisites

- Working Context Engine (hardened, from `ai-context-engine/workflows/harden-engine.md`)
- Decision: which moderation provider (OpenAI moderation API, Azure Content Safety, custom classifier, etc.)

**Reference**: `references/moderation/knowledge.md`

---

## Workflow Steps

### Step 1: Build helper_moderate_content

**Goal**: One canonical moderation utility used everywhere.

- [ ] Implement `helper_moderate_content(text)` returning a structured report
- [ ] Cover the harm categories your provider supports (sexual, violence, self-harm, hate, etc.)
- [ ] Choose halt-vs-redact policy per category

**Reference**: `references/moderation/examples.md` (verbatim helper)

---

### Step 2: Decide the activation policy

**Goal**: When does moderation run, and on what?

- [ ] Decide: input-only, output-only, or both? (Two-stage = both, recommended)
- [ ] Decide: dev mode vs prod mode (env flag)
- [ ] Decide: per-deck override (some decks may need higher/lower bar)

**Reference**: `references/moderation/rules.md` (toggleable activation)

---

### Step 3: Integrate at the input boundary

**Goal**: Catch unsafe inputs before LLM hops.

- [ ] In `execute_and_display`, run moderation on the goal text early
- [ ] If unsafe → halt, return a structured rejection (don't run the engine)
- [ ] Log the rejection with category + score

**Reference**: `references/moderation/examples.md` (upgraded engine room)

---

### Step 4: Integrate at the output boundary

**Goal**: Catch unsafe outputs before returning to user.

- [ ] Before returning final output, run moderation on it
- [ ] If unsafe → halt OR redact (per policy)
- [ ] Log every rejection

**Reference**: `references/moderation/examples.md`

---

### Step 5: Make it fail-safe

**Goal**: If moderation provider is down, the engine should refuse, not bypass.

- [ ] On moderation API timeout → reject the request (fail-closed)
- [ ] On moderation API error → log + reject
- [ ] Never silently skip moderation

**Reference**: `references/moderation/rules.md` (fail-safe rule)

---

### Step 6: Test with the limit cases

**Goal**: Verify moderation actually triggers and gracefully reports.

- [ ] Run a safe goal → no rejection, normal output
- [ ] Run an unsafe goal → input-stage rejection
- [ ] Mock an unsafe LLM output → output-stage rejection
- [ ] Mock moderation API down → fail-closed rejection

**Reference**: `references/moderation/examples.md` (control deck + report interpretation)

---

### Step 7: Audit with the checklist

- [ ] Gatekeeper exists
- [ ] Input check wired
- [ ] Output check wired
- [ ] Fail-safe behavior verified
- [ ] Toggleable activation works
- [ ] All rejections logged
- [ ] No bypass paths

**Reference**: `references/moderation/checklist.md`

---

## Quick Checklist

```
[ ] Step 1: helper_moderate_content
[ ] Step 2: Activation policy decided
[ ] Step 3: Input-stage moderation
[ ] Step 4: Output-stage moderation
[ ] Step 5: Fail-safe behavior
[ ] Step 6: All limit cases tested
[ ] Step 7: Checklist passes
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Moderate input only, not output | LLM can produce unsafe output from safe input | Two-stage protocol |
| Fail-open on moderation API error | Bypass under attack | Fail-closed |
| Per-agent moderation duplication | Inconsistent enforcement | Centralized gatekeeper |
| Silent rejections | Audit/compliance fails | Log every rejection |
| Hardcoded thresholds | Can't tune for different decks | Per-deck override |

---

## Exit Criteria

- [ ] Two-stage protocol active in production mode
- [ ] All rejections visible in logs
- [ ] Moderation API failure → engine refuses cleanly
- [ ] Per-deck override available
- [ ] Checklist passes
