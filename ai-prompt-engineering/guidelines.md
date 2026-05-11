# AI Prompt Engineering Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use**: Find your situation below, then load ONLY the listed files.

---

## By Task

### Writing or Improving a Prompt

| What you're doing | Load these files |
|-------------------|------------------|
| Writing your first prompt for a new feature | `references/prompting-fundamentals/rules.md`, `references/prompting-best-practices/rules.md` |
| Improving an existing prompt | `references/prompting-best-practices/rules.md`, `references/prompting-best-practices/checklist.md` |
| Choosing zero-shot vs few-shot | `references/prompting-fundamentals/rules.md`, `references/prompting-fundamentals/examples.md` |
| Designing system prompt + user prompt | `references/prompting-fundamentals/rules.md`, `references/prompting-fundamentals/examples.md` |
| Adding chain-of-thought reasoning | `references/prompting-best-practices/patterns.md`, `references/prompting-best-practices/examples.md` |
| Pre-flight prompt review | `references/prompting-best-practices/checklist.md` |

### Breaking Down Complex Tasks

| What you're doing | Load these files |
|-------------------|------------------|
| Decomposing a complex task into prompts | `references/prompting-best-practices/rules.md`, `references/prompting-best-practices/patterns.md` |
| Adding self-critique step | `references/prompting-best-practices/patterns.md` |
| Iterating on prompts systematically | `references/prompting-best-practices/rules.md`, `references/prompting-best-practices/checklist.md` |

### Defending Against Attacks

| What you're doing | Load these files |
|-------------------|------------------|
| Auditing a prompt for vulnerabilities | `references/defensive-prompting/smells.md`, `references/defensive-prompting/rules.md` |
| Adding input/output guardrails | `references/defensive-prompting/rules.md`, `references/defensive-prompting/examples.md` |
| Defending against jailbreaks | `references/defensive-prompting/rules.md`, `references/defensive-prompting/examples.md` |
| Defending against prompt injection (direct/indirect) | `references/defensive-prompting/rules.md`, `references/defensive-prompting/examples.md` |
| Protecting proprietary prompts | `references/defensive-prompting/rules.md`, `references/defensive-prompting/smells.md` |

### Organizing Prompts

| What you're doing | Load these files |
|-------------------|------------------|
| Setting up prompt versioning | `references/prompting-best-practices/rules.md` |
| Choosing a prompt engineering tool | `references/prompting-best-practices/knowledge.md` |

---

## By Symptom/Problem

| If you notice... | Load these files |
|------------------|------------------|
| Inconsistent outputs from same prompt | `references/prompting-best-practices/rules.md` (clear instructions) |
| Model ignores instructions | `references/prompting-fundamentals/rules.md` (system vs user) |
| Model gives wrong answer to multi-step problem | `references/prompting-best-practices/patterns.md` (CoT, decomposition) |
| User can override the system prompt | `references/defensive-prompting/rules.md`, `references/defensive-prompting/smells.md` |
| Tool/RAG output gets injected as instruction | `references/defensive-prompting/rules.md` (instruction hierarchy) |
| Output runs over context limit | `references/prompting-fundamentals/rules.md` (context efficiency) |
| Prompt works in dev, fails in prod | `references/prompting-best-practices/rules.md` (iterate, version) |

---

## By Topic (Direct Index)

### Prompting Fundamentals
- `references/prompting-fundamentals/knowledge.md` — Prompt anatomy, in-context learning, system/user, context length
- `references/prompting-fundamentals/rules.md` — 8 core rules
- `references/prompting-fundamentals/examples.md` — Zero/few-shot, system/user split

### Prompting Best Practices
- `references/prompting-best-practices/knowledge.md` — All 10 best practice categories
- `references/prompting-best-practices/rules.md` — 10 actionable rules with code
- `references/prompting-best-practices/examples.md` — Bad/good prompt pairs
- `references/prompting-best-practices/patterns.md` — 7 patterns (CoT variants, decomposition, etc.)
- `references/prompting-best-practices/checklist.md` — Pre-flight checklist

### Defensive Prompting
- `references/defensive-prompting/knowledge.md` — Attack categories, jailbreaking, injection
- `references/defensive-prompting/rules.md` — 16 defensive rules across 3 layers
- `references/defensive-prompting/examples.md` — Concrete attacks and defenses
- `references/defensive-prompting/smells.md` — 12 anti-patterns

---

## Decision Tree

```
What are you doing?
│
├─► Writing a prompt
│   ├─► First time → prompting-fundamentals/rules.md + prompting-best-practices/rules.md
│   ├─► Adding examples → prompting-fundamentals/examples.md
│   └─► Adding reasoning → prompting-best-practices/patterns.md (CoT)
│
├─► Improving a prompt
│   ├─► Quality → prompting-best-practices/checklist.md
│   ├─► Reliability → prompting-best-practices/rules.md
│   └─► Multi-step → prompting-best-practices/patterns.md (decomposition)
│
├─► Defending a prompt
│   ├─► Audit existing → defensive-prompting/smells.md
│   ├─► New defenses → defensive-prompting/rules.md
│   └─► Jailbreak/injection → defensive-prompting/examples.md
│
└─► Organizing prompts
    └─► Versioning, tools → prompting-best-practices/knowledge.md + rules.md
```

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| New prompt for a new feature | `prompting-fundamentals/rules.md` + `prompting-best-practices/checklist.md` |
| Production-hardening a prompt | `prompting-best-practices/checklist.md` + `defensive-prompting/rules.md` |
| Complex multi-step task | `prompting-best-practices/patterns.md` (CoT, decomposition) |
| Securing a customer-facing assistant | `defensive-prompting/rules.md` + `defensive-prompting/smells.md` + `defensive-prompting/examples.md` |
