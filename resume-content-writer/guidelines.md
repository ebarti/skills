# resume-content-writer Guidelines

Routing layer: find your situation, then load ONLY the listed files. Each category has `knowledge.md` (concepts), `rules.md` (do's & don'ts), and `examples.md` (before/after resume text).

**This skill is step 2 of the JobHunter loop:** `job-description-analyzer` → **resume-content-writer** → `resume-fit-scorer` → (revise). It consumes a `TargetProfile` and emits schema-conformant resume content.

---

## Workflows

For the full task, prefer the workflow — it sequences every reference below.

| Task | Workflow |
|------|----------|
| Generate/tailor full resume content for a job (headline, summary, skills, bullets) | `workflows/tailor-resume-content.md` |

---

## By Task

### Writing experience content

| What you're doing | Load these files |
|-------------------|------------------|
| Turning a duty into an achievement bullet | `references/achievement-anatomy/rules.md`, `references/achievement-anatomy/patterns.md` |
| Quantifying impact (numbers / % / $) | `references/achievement-anatomy/patterns.md`, `references/achievement-anatomy/examples.md` |
| Picking strong verbs / killing weak phrasing | `references/wow-words/rules.md`, `references/wow-words/examples.md` |
| No hard metrics available | `references/achievement-anatomy/patterns.md` (quantify by scope/scale/frequency) |

### Targeting a specific role

| What you're doing | Load these files |
|-------------------|------------------|
| Tailoring bullets to a JD (crossover language) | `references/tailoring-to-role/rules.md`, `references/tailoring-to-role/examples.md` |
| Selecting & ordering the skills section | `references/tailoring-to-role/rules.md` |
| Deciding what experience to feature | `references/tailoring-to-role/knowledge.md`, `references/by-seniority/rules.md` |

### Opening the resume

| What you're doing | Load these files |
|-------------------|------------------|
| Writing a headline / branding summary | `references/headline-and-summary/rules.md`, `references/headline-and-summary/examples.md` |
| Replacing a weak objective | `references/headline-and-summary/examples.md` |

### Adjusting for the candidate

| What you're doing | Load these files |
|-------------------|------------------|
| New grad / thin experience | `references/by-seniority/rules.md`, `references/by-seniority/examples.md` |
| Senior / experienced framing | `references/by-seniority/rules.md`, `references/by-seniority/examples.md` |
| Avoiding AI-written giveaways | `references/ai-writing-pitfalls/smells.md` |

---

## By Problem/Symptom

| If you notice... | Load these files |
|------------------|------------------|
| "Bullets read like a job description" | `references/achievement-anatomy/rules.md` |
| "Everything starts with 'Responsible for'" | `references/wow-words/rules.md` |
| "Resume isn't matching the JD" | `references/tailoring-to-role/rules.md` |
| "Candidate has no numbers" | `references/achievement-anatomy/patterns.md` |
| "Summary is generic" | `references/headline-and-summary/rules.md` |
| "Content sounds AI-generated / fabricated" | `references/ai-writing-pitfalls/smells.md` |
| "Too much old/irrelevant experience" | `references/by-seniority/rules.md`, `references/tailoring-to-role/rules.md` |

---

## By Topic

### Achievement Anatomy
- **Knowledge**: `references/achievement-anatomy/knowledge.md`
- **Rules**: `references/achievement-anatomy/rules.md`
- **Examples**: `references/achievement-anatomy/examples.md`
- **Patterns**: `references/achievement-anatomy/patterns.md`

### Wow Words
- **Knowledge**: `references/wow-words/knowledge.md` · **Rules**: `references/wow-words/rules.md` · **Examples**: `references/wow-words/examples.md`

### Tailoring to Role
- **Knowledge**: `references/tailoring-to-role/knowledge.md` · **Rules**: `references/tailoring-to-role/rules.md` · **Examples**: `references/tailoring-to-role/examples.md`

### By Seniority
- **Knowledge**: `references/by-seniority/knowledge.md` · **Rules**: `references/by-seniority/rules.md` · **Examples**: `references/by-seniority/examples.md`

### Headline & Summary
- **Knowledge**: `references/headline-and-summary/knowledge.md` · **Rules**: `references/headline-and-summary/rules.md` · **Examples**: `references/headline-and-summary/examples.md`

### AI Writing Pitfalls
- **Smells**: `references/ai-writing-pitfalls/smells.md`

---

## Decision Tree

```
Writing resume content?
│
├─► Need the whole thing for a job → workflows/tailor-resume-content.md
│
├─► Just bullets
│   ├─► Duty → achievement → achievement-anatomy/rules.md + patterns.md
│   ├─► Weak verbs → wow-words/rules.md
│   └─► No metrics → achievement-anatomy/patterns.md
│
├─► Just the opener → headline-and-summary/rules.md
│
├─► Match to a JD → tailoring-to-role/rules.md
│
├─► Adjust for candidate level → by-seniority/rules.md
│
└─► Worried it sounds fake → ai-writing-pitfalls/smells.md
```

---

## File Index (17 reference files)

### Achievement Anatomy
| File | Purpose |
|------|---------|
| `references/achievement-anatomy/knowledge.md` | Telling vs selling, CAR/PAR, quantification levers |
| `references/achievement-anatomy/rules.md` | Rules for writing achievement bullets |
| `references/achievement-anatomy/examples.md` | Before/after bullet rewrites |
| `references/achievement-anatomy/patterns.md` | Fill-in-the-blank bullet formulas |

### Wow Words
| File | Purpose |
|------|---------|
| `references/wow-words/knowledge.md` | Power verbs and functional verb categories |
| `references/wow-words/rules.md` | Verb usage rules; weak→strong swaps |
| `references/wow-words/examples.md` | Verb bank tables + rewrite pairs |

### Tailoring to Role
| File | Purpose |
|------|---------|
| `references/tailoring-to-role/knowledge.md` | OnTarget tailoring, crossover language |
| `references/tailoring-to-role/rules.md` | Mirroring, featuring, skills selection rules |
| `references/tailoring-to-role/examples.md` | Generic→tailored rewrites |

### By Seniority
| File | Purpose |
|------|---------|
| `references/by-seniority/knowledge.md` | Seniority model; emphasis per level |
| `references/by-seniority/rules.md` | New-grad vs experienced rules |
| `references/by-seniority/examples.md` | Same experience framed by level |

### Headline & Summary
| File | Purpose |
|------|---------|
| `references/headline-and-summary/knowledge.md` | Headline vs objective vs branding summary |
| `references/headline-and-summary/rules.md` | Rules for a strong, targeted opener |
| `references/headline-and-summary/examples.md` | Weak→strong openers |

### AI Writing Pitfalls
| File | Purpose |
|------|---------|
| `references/ai-writing-pitfalls/smells.md` | AI-written resume anti-patterns + detection |

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| Full tailoring run | `workflows/tailor-resume-content.md` (pulls the rest) |
| Bullet rewrite pass | `achievement-anatomy/rules.md` + `wow-words/examples.md` |
| JD match pass | `tailoring-to-role/rules.md` + `achievement-anatomy/patterns.md` |
| New-grad resume | `by-seniority/rules.md` + `achievement-anatomy/patterns.md` + `headline-and-summary/examples.md` |
| Quality guard before output | `ai-writing-pitfalls/smells.md` |
