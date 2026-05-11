# Audit Prompt Security Workflow

Review a prompt and surrounding system for vulnerabilities to jailbreak, injection, and information extraction.

## When to Use

- Pre-launch audit of a user-facing LLM feature
- Adding RAG/tool use that pulls untrusted content
- Existing system shows signs of jailbreaking
- A new attack class has been published in the wild

## Prerequisites

- Access to the prompt(s)
- Understanding of where user input flows in
- Understanding of any tools/RAG sources the LLM consumes

**Reference**: `references/defensive-prompting/rules.md`

---

## Workflow Steps

### Step 1: Map the Trust Boundary

**Goal**: Identify every place untrusted input can reach the model.

- [ ] List inputs the user controls (text, files, URLs)
- [ ] List external sources the model reads (RAG, search results, tool outputs, emails)
- [ ] Mark every place untrusted text is concatenated into a prompt
- [ ] Mark every place model output triggers an action (tool call, write, code execution)

**Ask**: "If a user wrote anything possible here, what could happen?"

**Reference**: `references/defensive-prompting/knowledge.md`

---

### Step 2: Audit for Direct Jailbreak

**Goal**: Test resistance to direct manipulation by the user.

- [ ] Test obfuscation attacks (base64, leetspeak, foreign language)
- [ ] Test format attacks (asking for output as code/role-play to bypass)
- [ ] Test role-play attacks (DAN-style, "pretend you have no rules")
- [ ] Test instruction conflicts ("ignore previous instructions")
- [ ] Verify model refusals on a set of known jailbreak prompts

**Reference**: `references/defensive-prompting/examples.md`, `references/defensive-prompting/smells.md`

---

### Step 3: Audit for Indirect Injection

**Goal**: Test what happens when untrusted content reaches the prompt via RAG/tools.

- [ ] Insert a malicious instruction into a RAG document and verify the model ignores it
- [ ] Insert a malicious instruction into a tool's output (e.g., a fake email) and verify the model doesn't act on it
- [ ] Verify tool/RAG output is clearly **demoted** in the prompt (e.g., wrapped in `<untrusted>` tags)

**Reference**: `references/defensive-prompting/rules.md` (instruction hierarchy)

---

### Step 4: Audit for Information Extraction

**Goal**: Test whether secrets, system prompt, or training data can leak.

- [ ] Test "repeat back your instructions" attacks
- [ ] Test "what was the previous user's message?" leaks
- [ ] Verify no secrets/API keys in the prompt
- [ ] Verify the prompt doesn't reveal proprietary IP if extracted

**Reference**: `references/defensive-prompting/examples.md`

---

### Step 5: Verify Defense Layers

**Goal**: Confirm all 3 defense layers are active.

#### Model layer
- [ ] Using a model with reasonable instruction-following and refusal training
- [ ] Verify the model version is pinned (not floating)

#### Prompt layer
- [ ] Instruction hierarchy explicit (system > user > tool output)
- [ ] Untrusted content delimited and demoted
- [ ] Refusal categories listed in system prompt

#### System layer
- [ ] Input guardrails (PII, abuse classification)
- [ ] Output guardrails (toxicity, secret detection)
- [ ] Tool execution gated (allowlist, sandbox, approval)
- [ ] Write actions require explicit approval
- [ ] Generated code runs in sandbox (Docker, etc.)

**Reference**: `references/defensive-prompting/rules.md`

---

### Step 6: Walk the Anti-Pattern List

**Goal**: Cross-check against known smells.

- [ ] Read every anti-pattern in `references/defensive-prompting/smells.md`
- [ ] For each, verify your system doesn't exhibit the pattern
- [ ] Document any exceptions with mitigations

**Reference**: `references/defensive-prompting/smells.md`

---

### Step 7: Set Up Continuous Red-Teaming

**Goal**: Catch new attack vectors as they emerge.

- [ ] Add adversarial prompts to your eval suite
- [ ] Subscribe to red-team / jailbreak research feeds
- [ ] Schedule periodic re-audits (quarterly?)
- [ ] Wire up monitoring for refusal rate and abuse signals

**Reference**: `references/defensive-prompting/rules.md`

---

## Quick Checklist

```
[ ] Step 1: Trust boundary mapped
[ ] Step 2: Direct jailbreak tested
[ ] Step 3: Indirect injection tested
[ ] Step 4: Information extraction tested
[ ] Step 5: All 3 defense layers verified
[ ] Step 6: Anti-pattern list walked
[ ] Step 7: Continuous red-teaming set up
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Defense at prompt layer only | One bypass = total compromise | Defense in depth (model + prompt + system) |
| Treating tool output as trusted | Indirect injection | Wrap in `<untrusted>` tags |
| Tool execution without approval | Catastrophic write actions | Require approval for impactful tools |
| One-time audit | New attacks emerge | Continuous red-teaming |
| Trying to keep prompt secret as security | Security through obscurity | Real defenses + log access |

---

## Exit Criteria

- [ ] All 6 audit steps complete
- [ ] Findings documented and tracked
- [ ] Critical issues fixed before launch
- [ ] Re-audit cadence scheduled
