---
name: job-description-analyzer
description: |
  Parses a raw job description into a structured TargetProfile — role, seniority, must-have vs nice-to-have requirements, hard/soft skills, responsibilities, ATS keywords, and a truthful crossover (their-term ↔ your-term) map. Distilled from "Resumes For Dummies" (AI-era ed.). Built for automated pipelines (e.g. JobHunter) as the shared front-end that feeds both resume tailoring and scoring.

  Use this skill when:
  - Turning a job posting into structured requirements before tailoring a resume
  - Separating must-have from nice-to-have qualifications
  - Splitting hard skills (tools/certs) from soft skills
  - Extracting ATS keywords to mirror truthfully
  - Inferring a role's target seniority and focus
  - Building a crossover map between a JD's wording and a candidate's vocabulary
  - Providing a TargetProfile to resume-content-writer or resume-fit-scorer
---

# job-description-analyzer

Converts a messy job posting into one clean, machine-usable `TargetProfile`: what's required vs preferred, the hard and soft skills, the responsibilities, the exact ATS keywords to mirror, the inferred seniority/focus, and a truthful crossover map. This is the shared source of truth so tailoring and scoring agree on the target. Built from "Resumes For Dummies" (AI-era ed.), chapters 1, 3, 5, 6.

## Role in the JobHunter pipeline

```
[job-description-analyzer] → resume-content-writer → resume-fit-scorer
       TargetProfile  ───────────────┴───────────────────────┘
       (one source of truth feeds both tailoring and scoring)
```

See `workflows/analyze-job-description.md` for the full I/O contract and the `TargetProfile` schema.

## Quick Start

1. Read `guidelines.md` — it routes from your task/symptom to the right files.
2. For an end-to-end analysis, follow `workflows/analyze-job-description.md`.
3. Load only the reference files the guidelines point to.
4. Emit a `TargetProfile` (or the caller's `output_schema`); keep crossover mappings truthful.

## Contents

### References

| Category | Files | Purpose |
|----------|-------|---------|
| `references/requirement-extraction/` | knowledge, rules, examples | JD anatomy; must vs nice; hard vs soft skills; seniority inference |
| `references/keywords-and-crossover/` | knowledge, rules, examples | ATS keywords; crossover mapping; over-cloning risk |

### Workflows

| Task | Workflow |
|------|----------|
| Analyze a JD into a structured TargetProfile | `workflows/analyze-job-description.md` |

## Guidelines

See `guidelines.md` for task/symptom-based file selection, a decision tree, the full file index, and common combinations.
