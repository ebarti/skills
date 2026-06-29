---
name: resume-content-writer
description: |
  Generates tailored, schema-conformant resume content — headline, branding summary, JD-matched skills section, and quantified achievement bullets — tuned to a target role, seniority, and focus, while honoring user-pinned "must-include" achievements. Distilled from "Resumes For Dummies" (AI-era ed.). Built for automated pipelines (e.g. JobHunter): consumes a TargetProfile and emits structured resume data.

  Use this skill when:
  - Tailoring a resume's content to a specific job description
  - Rewriting experience into quantified, action-verb-led achievement bullets
  - Writing a targeted headline / branding summary (replacing weak objectives)
  - Selecting and ordering a skills section to match a JD
  - Framing content by seniority (new-grad/thin experience vs senior/experienced)
  - Revising resume content from a scorer's prioritized fixes
  - Producing resume content that must conform to a caller-supplied JSON schema
---

# resume-content-writer

Turns a candidate's real history into compelling, **targeted, machine-usable** resume content. It writes the headline, branding summary, skills section, and quantified achievement bullets — bent toward one job, calibrated to seniority and focus — and never fabricates experience. Built from "Resumes For Dummies" (AI-era ed.), chapters 3–7 & 9.

## Role in the JobHunter pipeline

```
job-description-analyzer → [resume-content-writer] → resume-fit-scorer → (revise loop)
        TargetProfile            ResumeContent             FitScore
```

It accepts a `TargetProfile` (from `job-description-analyzer`), a candidate's `raw_experience`, a `focus`, pinned `must_include` achievements, and an optional `output_schema`. It returns resume content conforming to that schema. See `workflows/tailor-resume-content.md` for the full I/O contract.

## Quick Start

1. Read `guidelines.md` — it routes from your task/symptom to the right files.
2. For an end-to-end run, follow `workflows/tailor-resume-content.md`.
3. Load only the reference files the guidelines point to (each category has `knowledge.md`, `rules.md`, `examples.md`).
4. Ground every claim in the candidate's real history; conform output to the schema.

## Contents

### References

| Category | Files | Purpose |
|----------|-------|---------|
| `references/achievement-anatomy/` | knowledge, rules, examples, patterns | Duty→achievement, CAR/PAR, quantification (#/%/$), bullet formulas |
| `references/wow-words/` | knowledge, rules, examples | Power verbs by function; weak→strong phrasing |
| `references/tailoring-to-role/` | knowledge, rules, examples | Crossover language, featuring relevant experience, skills selection |
| `references/by-seniority/` | knowledge, rules, examples | New-grad vs experienced framing |
| `references/headline-and-summary/` | knowledge, rules, examples | Headline + branding summary (vs weak objectives) |
| `references/ai-writing-pitfalls/` | smells | AI-written resume anti-patterns + detection |

### Workflows

| Task | Workflow |
|------|----------|
| Tailor full resume content for a job (headline, summary, skills, bullets) | `workflows/tailor-resume-content.md` |

## Guidelines

See `guidelines.md` for task-based and symptom-based file selection, a decision tree, the full file index, and common file combinations.
