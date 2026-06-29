# job-description-analyzer Guidelines

Routing layer: find your situation, then load ONLY the listed files.

**This skill is step 1 of the JobHunter loop:** **job-description-analyzer** → `resume-content-writer` → `resume-fit-scorer`. It turns raw JD text into a `TargetProfile` consumed by the other two skills.

---

## Workflows

| Task | Workflow |
|------|----------|
| Analyze a JD into a structured TargetProfile | `workflows/analyze-job-description.md` |

---

## By Task

| What you're doing | Load these files |
|-------------------|------------------|
| Full JD analysis | `workflows/analyze-job-description.md` (pulls the rest) |
| Tiering requirements (must-have vs nice-to-have) | `references/requirement-extraction/rules.md` |
| Splitting hard vs soft skills | `references/requirement-extraction/knowledge.md` |
| Inferring seniority / focus | `references/requirement-extraction/rules.md` |
| Extracting ATS keywords | `references/keywords-and-crossover/rules.md` |
| Building a crossover (their-term ↔ your-term) map | `references/keywords-and-crossover/rules.md`, `references/keywords-and-crossover/examples.md` |
| Avoiding keyword stuffing / over-cloning | `references/keywords-and-crossover/knowledge.md` |

---

## By Problem/Symptom

| If you notice... | Load these files |
|------------------|------------------|
| "What does this job actually require?" | `references/requirement-extraction/knowledge.md`, `references/requirement-extraction/rules.md` |
| "Is this a must or a nice-to-have?" | `references/requirement-extraction/rules.md` (cue-word table) |
| "What seniority is this role?" | `references/requirement-extraction/rules.md` |
| "Which exact keywords should the resume mirror?" | `references/keywords-and-crossover/rules.md` |
| "How do I map my experience to their wording?" | `references/keywords-and-crossover/examples.md` |
| "Am I over-cloning the ad?" | `references/keywords-and-crossover/knowledge.md` |

---

## By Topic

### Requirement Extraction
- **Knowledge**: `references/requirement-extraction/knowledge.md` (JD anatomy, must/nice, hard/soft, seniority signals)
- **Rules**: `references/requirement-extraction/rules.md` (classification cues, seniority inference)
- **Examples**: `references/requirement-extraction/examples.md` (worked JD → structure)

### Keywords & Crossover
- **Knowledge**: `references/keywords-and-crossover/knowledge.md` (ATS keywords, crossover map, over-cloning risk)
- **Rules**: `references/keywords-and-crossover/rules.md` (what to extract, mirror vs paraphrase)
- **Examples**: `references/keywords-and-crossover/examples.md` (keyword list + crossover table)

---

## Decision Tree

```
Analyzing a JD?
│
├─► Full structured profile → workflows/analyze-job-description.md
│
├─► Just requirements/skills/seniority → requirement-extraction/rules.md (+ knowledge.md)
│
└─► Just keywords/crossover vocabulary → keywords-and-crossover/rules.md (+ examples.md)
```

---

## File Index (6 reference files)

### Requirement Extraction
| File | Purpose |
|------|---------|
| `references/requirement-extraction/knowledge.md` | JD anatomy; must vs nice; hard vs soft; seniority signals |
| `references/requirement-extraction/rules.md` | Classification cue words; seniority inference; ignore boilerplate |
| `references/requirement-extraction/examples.md` | Worked JD → structured requirements |

### Keywords & Crossover
| File | Purpose |
|------|---------|
| `references/keywords-and-crossover/knowledge.md` | ATS keywords; crossover language; over-cloning risk |
| `references/keywords-and-crossover/rules.md` | Extract/mirror rules; truthful mapping |
| `references/keywords-and-crossover/examples.md` | Keyword list + crossover map; good vs stuffing |

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| Full JD → TargetProfile | `workflows/analyze-job-description.md` (pulls the rest) |
| Requirements only | `requirement-extraction/rules.md` + `requirement-extraction/knowledge.md` |
| Keyword/crossover only | `keywords-and-crossover/rules.md` + `keywords-and-crossover/examples.md` |
