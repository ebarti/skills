# resume-fit-scorer Guidelines

Routing layer: find your situation, then load ONLY the listed files.

**This skill is step 3 of the JobHunter loop:** `job-description-analyzer` → `resume-content-writer` → **resume-fit-scorer** → (revise). It consumes a resume + `TargetProfile` and emits a `FitScore` (0–10 + critique + prioritized fixes).

---

## Workflows

| Task | Workflow |
|------|----------|
| Score a resume against a JD (0–10 + critique + fixes) | `workflows/score-resume-against-jd.md` |

---

## By Task

| What you're doing | Load these files |
|-------------------|------------------|
| Running a full score | `workflows/score-resume-against-jd.md` (pulls the rest) |
| Defining/understanding the rubric (dimensions, weights, bands) | `references/scoring-rubric/knowledge.md` |
| Computing the weighted overall + calibrating harshly | `references/scoring-rubric/rules.md` |
| Scoring the JD-match dimension (coverage, ATS, keywords) | `references/jd-match/rules.md`, `references/jd-match/knowledge.md` |
| Judging ATS-parseability / formatting | `references/jd-match/examples.md` |
| Detecting red flags | `references/red-flags/checklist.md`, `references/red-flags/smells.md` |
| Writing a worked example score | `references/scoring-rubric/examples.md` |

---

## By Problem/Symptom

| If you notice... | Load these files |
|------------------|------------------|
| "How do I turn the checklist into a number?" | `references/scoring-rubric/knowledge.md`, `references/scoring-rubric/rules.md` |
| "Is this resume going to pass ATS?" | `references/jd-match/knowledge.md`, `references/jd-match/examples.md` |
| "Which must-haves are missing?" | `references/jd-match/rules.md` |
| "What should I penalize?" | `references/red-flags/smells.md` |
| "Quick pass/fail red-flag scan" | `references/red-flags/checklist.md` |
| "My scores feel too generous" | `references/scoring-rubric/rules.md` (calibration: generic = 3–5) |
| "Need to justify a score to the writer" | `references/scoring-rubric/examples.md` |

---

## By Topic

### Scoring Rubric
- **Knowledge**: `references/scoring-rubric/knowledge.md` (6 dimensions, weights, 0–10 bands)
- **Rules**: `references/scoring-rubric/rules.md` (weighted formula, calibration, deductions)
- **Examples**: `references/scoring-rubric/examples.md` (worked scores)

### JD Match (the 30% dimension)
- **Knowledge**: `references/jd-match/knowledge.md` (3 screening stages, what employers crave)
- **Rules**: `references/jd-match/rules.md` (coverage, keyword/title alignment, what to penalize)
- **Examples**: `references/jd-match/examples.md` (high vs low match, ATS-unfriendly formats)

### Red Flags
- **Smells**: `references/red-flags/smells.md` (catalog RF1–RF14 + severity)
- **Checklist**: `references/red-flags/checklist.md` (fast scan + auto-reject section)

---

## Decision Tree

```
Scoring a resume?
│
├─► Full score → workflows/score-resume-against-jd.md
│
├─► Need the rubric → scoring-rubric/knowledge.md (+ rules.md to compute)
│
├─► Focus on JD/ATS fit → jd-match/rules.md + jd-match/examples.md
│
├─► Hunting for penalties → red-flags/checklist.md (then smells.md for detail)
│
└─► Scores feel inflated → scoring-rubric/rules.md (calibration)
```

---

## File Index (8 reference files)

### Scoring Rubric
| File | Purpose |
|------|---------|
| `references/scoring-rubric/knowledge.md` | 6 dimensions, weights, 0–10 bands, verdict labels |
| `references/scoring-rubric/rules.md` | Weighted-overall formula, harsh calibration, deductions |
| `references/scoring-rubric/examples.md` | Fully worked example scores (weak/ok/strong) |

### JD Match
| File | Purpose |
|------|---------|
| `references/jd-match/knowledge.md` | ATS → 6-sec glance → decision-maker; what employers crave |
| `references/jd-match/rules.md` | Coverage, keyword/title alignment, penalties |
| `references/jd-match/examples.md` | High/low-match excerpts; ATS-unfriendly formatting fixes |

### Red Flags
| File | Purpose |
|------|---------|
| `references/red-flags/smells.md` | Catalog of 14 red flags with detection + severity |
| `references/red-flags/checklist.md` | Fast red-flag scan; auto-reject section |

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| Full scoring run | `workflows/score-resume-against-jd.md` (pulls the rest) |
| Rubric setup | `scoring-rubric/knowledge.md` + `scoring-rubric/rules.md` |
| ATS/JD-fit deep dive | `jd-match/rules.md` + `jd-match/examples.md` |
| Red-flag audit | `red-flags/checklist.md` + `red-flags/smells.md` |
