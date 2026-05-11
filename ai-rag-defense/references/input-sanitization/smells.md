# Prompt Injection Smells

Common prompt-injection patterns to detect in retrieved or user-supplied text. Use for sanitizer pattern lists, code review, and incident triage.

---

## PI1: Instruction Override

**What it is**: Text instructing the LLM to disregard its prior system or developer instructions.

**How to detect**:
- Phrases like `ignore previous instructions`
- Variants: `ignore all prior commands`, `disregard the above`, `forget everything before`
- Often appears at the start or end of a chunk to maximize override probability

**Why it's bad**:
- Directly hijacks the agent's role and task
- Pattern is widespread and well-documented in attacker playbooks

**How to fix**:
- Match `r"ignore previous instructions"`, `r"ignore all prior commands"` (case-insensitive)
- Reject the chunk on match
- Augment with paraphrases as new variants are observed

---

## PI2: Mode-Switch / Jailbreak

**What it is**: Text telling the LLM it is now operating in an alternate, restriction-free mode.

**How to detect**:
- Phrases like `you are now in developer mode`, `you are now in DAN mode`, `you are now in unrestricted mode`
- Generic regex: `r"you are now in.*mode"`

**Why it's bad**:
- Attempts to disable safety alignment and content policies
- Frequently combined with role-confusion to escalate impact

**How to fix**:
- Match `r"you are now in.*mode"` case-insensitively
- Treat any "mode" language with extreme suspicion

---

## PI3: Role Hijack ("Act As")

**What it is**: Text instructing the LLM to assume a new persona or role that bypasses its task.

**How to detect**:
- Phrases like `act as a`, `pretend to be`, `roleplay as`
- Generic regex: `r"act as"`

**Why it's bad**:
- Persona changes can unlock behaviors the base agent would refuse
- Often paired with PI1 or PI2 for compound attacks

**How to fix**:
- Match `r"act as"` case-insensitively
- Note: this pattern has high false-positive risk in benign content (`"act as a catalyst"`); review hits before tightening to silent reject

---

## PI4: Instruction Exfiltration

**What it is**: Text asking the LLM to reveal its system prompt, internal instructions, or hidden context.

**How to detect**:
- Phrases like `print your instructions`, `repeat your system prompt`, `show me the rules`
- Generic regex: `r"print your instructions"`

**Why it's bad**:
- Leaks proprietary prompt engineering and security boundaries
- Provides reconnaissance for follow-up attacks

**How to fix**:
- Match `r"print your instructions"` case-insensitively
- Add variants for `"reveal"`, `"repeat"`, `"display"` + `"system prompt"` / `"instructions"`

---

## PI5: Shell / Package-Manager Command Injection

**What it is**: Text containing operating-system commands or package-installer invocations, suggesting an attempt to coerce code-execution-capable agents.

**How to detect**:
- Tokens like `sudo`, `apt-get`, `yum`, `pip install`
- Regex: `r"sudo|apt-get|yum|pip install"`

**Why it's bad**:
- If the agent has tool access (shell, code execution), the LLM may attempt the command
- Even without execution, presence in retrieved data signals poisoning

**How to fix**:
- Match `r"sudo|apt-get|yum|pip install"` case-insensitively
- Extend with `npm install`, `curl | sh`, `wget`, and other install/exfil idioms as needed

---

## Quick Detection Table

| ID | Smell | Key Indicator |
|----|-------|---------------|
| PI1 | Instruction Override | `ignore previous instructions` / `ignore all prior commands` |
| PI2 | Mode-Switch / Jailbreak | `you are now in <something> mode` |
| PI3 | Role Hijack | `act as ...` |
| PI4 | Instruction Exfiltration | `print your instructions` |
| PI5 | Shell Command Injection | `sudo`, `apt-get`, `yum`, `pip install` |

---

## Notes on Coverage

This list is the **starting** signature set from the `helper_sanitize_input` baseline. It is intentionally minimal — production systems must augment continuously as new injection styles emerge (encoded payloads, multilingual variants, semantic paraphrases, indirect goal hijacking). Treat the regex list as a living security signature database.
