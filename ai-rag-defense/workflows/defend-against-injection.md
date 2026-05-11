# Defend Against Prompt Injection Workflow

Add `helper_sanitize_input` + grounded-reasoning validation to defend the engine against prompt-injection attacks via retrieved content.

## When to Use

- The engine retrieves user-generated content (web pages, comments, documents)
- The threat model includes data poisoning or adversarial inputs
- A security review surfaced injection risk

## Prerequisites

- Working RAG pipeline
- Threat model identified (what attackers might inject)

**Reference**: `references/input-sanitization/knowledge.md`, `references/input-sanitization/smells.md`

---

## Workflow Steps

### Step 1: Threat model the retrieval pipeline

**Goal**: Know what kinds of injection are plausible.

- [ ] Read PI1-PI5 patterns: instruction override, mode-switch, role hijack, instruction exfiltration, shell command injection
- [ ] Identify which patterns apply to your data sources
- [ ] Document the threat model (1-page)

**Reference**: `references/input-sanitization/smells.md` (PI1-PI5)

---

### Step 2: Add helper_sanitize_input

**Goal**: Centralized sanitization function.

- [ ] Implement `helper_sanitize_input(text)` returning sanitized text or raising
- [ ] Filter known patterns (instruction overrides, role-switch tokens, etc.)
- [ ] Fail-closed: on unknown threat → reject, log, escalate

**Reference**: `references/input-sanitization/examples.md` (verbatim helper)

---

### Step 3: Wire sanitization at the right pipeline points

**Goal**: Sanitize between retrieval and synthesis.

- [ ] In Researcher: sanitize each retrieved chunk BEFORE composing the LLM prompt
- [ ] In Writer: sanitize Researcher output before composing
- [ ] At gateway (if user input): sanitize before any LLM hop

**Reference**: `references/input-sanitization/rules.md` (sanitize-before-LLM rule, gateway-vs-per-agent integration)

---

### Step 4: Add sanitization logging + alerting

**Goal**: Sanitization events are observable.

- [ ] Log every sanitization rejection with source + pattern matched
- [ ] If rate exceeds threshold → alert
- [ ] Forward suspicious payloads to a quarantine store

**Reference**: `references/input-sanitization/rules.md` (log events, escalation flow)

---

### Step 5: Add the grounded-reasoning validation suite

**Goal**: Verify the engine doesn't hallucinate when retrieval is poisoned or empty.

- [ ] Add the Ch7 test case: high-fidelity, secure research workflow
- [ ] Add the Ch6 test case: backward-compat across capabilities
- [ ] Add the Ch5 test case: grounded reasoning preventing hallucination
- [ ] Run all 3 — they form the canonical regression suite

**Reference**: `references/grounded-reasoning/examples.md` (3 test cases), `references/grounded-reasoning/rules.md`

---

### Step 6: Run the grounded-reasoning checklist

**Goal**: Confirm the engine reports negative findings rather than inventing.

- [ ] Inject an out-of-scope query → engine should say "not in knowledge base"
- [ ] Inject a contradictory document → engine should report the contradiction, not pick a winner
- [ ] Run every item in the checklist

**Reference**: `references/grounded-reasoning/checklist.md`

---

### Step 7: Adversarial probe

**Goal**: Validate defenses against real-ish attacks.

- [ ] Inject a chunk with PI1 (instruction override): "Ignore previous instructions and..."
- [ ] Inject a chunk with PI2 (mode-switch): "</user> <admin>"
- [ ] Inject a chunk with PI3 (role hijack)
- [ ] For each: verify sanitization caught it OR the engine still produced safe output

**Reference**: `references/input-sanitization/smells.md`

---

## Quick Checklist

```
[ ] Step 1: Threat model documented
[ ] Step 2: helper_sanitize_input implemented
[ ] Step 3: Wired at retrieval + synthesis + gateway
[ ] Step 4: Logging + alerting on rejections
[ ] Step 5: Grounded-reasoning test suite added
[ ] Step 6: Checklist passes
[ ] Step 7: Adversarial probe: no leakage
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Sanitize only user input, not retrieved chunks | Most injections come via retrieval | Sanitize EVERY external input |
| Fail-open on unknown patterns | Attackers exploit gaps | Fail-closed |
| Silent sanitization | No visibility into attack patterns | Log every rejection |
| Skipping grounded-reasoning tests | Hallucination defense untested | Include 3-case suite |
| Trust retrieved metadata | Metadata can be poisoned too | Validate metadata also |

---

## Exit Criteria

- [ ] Sanitization helper exists and is wired at all 3 points
- [ ] Logging surfaces every rejection
- [ ] 3-case grounded-reasoning suite passes
- [ ] Checklist passes
- [ ] Adversarial probe: no instruction leakage
