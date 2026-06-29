---
name: resume-fit-scorer
description: |
  Scores how well a resume fits a specific job description on a 0–10 scale across 6 weighted dimensions (JD match, achievement strength, targeting, ATS-parseability, red flags, language), returns a brutally honest critique, and emits structured prioritized fixes. Distilled from "Resumes For Dummies" (AI-era ed.). Built for automated pipelines (e.g. JobHunter) as the verifier in a write→score→revise loop.

  Use this skill when:
  - Gating whether a tailored resume is good enough to submit
  - Producing a 0–10 fit score with per-dimension sub-scores
  - Generating an actionable critique + prioritized fixes for revision
  - Ranking multiple resume variants against one JD
  - Auditing a resume for ATS or red-flag risk before applying
  - Checking which JD must-haves a resume fails to cover
---

# resume-fit-scorer

Judges a resume against one job — harshly, on a 0–10 scale — and explains exactly why. It scores 6 weighted dimensions, detects red flags, computes must-have coverage, and returns a critique plus impact-ordered fixes that the writer can act on. Built from "Resumes For Dummies" (AI-era ed.), chapters 1, 2, 3, 5, 6, 10, 15, 16, 18.

## Role in the JobHunter pipeline

```
job-description-analyzer → resume-content-writer → [resume-fit-scorer] → (revise loop)
        TargetProfile           ResumeContent           FitScore  ──┐
                                      ▲                              │ prioritized_fixes
                                      └──────────────────────────────┘
```

It accepts a resume (plain text or `resume-content-writer` output) + a `TargetProfile`, and returns a `FitScore`. See `workflows/score-resume-against-jd.md` for the full I/O contract and the rubric.

## Default rubric (overridable via `weights`)

| Dimension | Weight | | Band | Verdict |
|---|---|---|---|---|
| JD match | 30% | | 0–2 | Trash |
| Achievement strength | 25% | | 3–4 | Weak |
| Targeting & focus | 15% | | 5–6 | OK |
| ATS parseability | 10% | | 7–8 | Strong |
| Red flags | 10% | | 9–10 | Excellent |
| Language | 10% | | | |

Calibrated harshly: a generic, untargeted resume should land **3–5**, not 7.

## Quick Start

1. Read `guidelines.md` — it routes from your task/symptom to the right files.
2. For an end-to-end score, follow `workflows/score-resume-against-jd.md`.
3. Load only the reference files the guidelines point to.
4. Compute the weighted overall, apply red-flag/missing-must-have ceilings, and return actionable fixes.

## Contents

### References

| Category | Files | Purpose |
|----------|-------|---------|
| `references/scoring-rubric/` | knowledge, rules, examples | The 6 dimensions, weights, 0–10 bands, weighted formula, calibration |
| `references/jd-match/` | knowledge, rules, examples | The 30% dimension: ATS + glance + decision-maker screening, coverage |
| `references/red-flags/` | smells, checklist | Red-flag catalog + fast scan / auto-reject criteria |

### Workflows

| Task | Workflow |
|------|----------|
| Score a resume against a JD (0–10 + critique + fixes) | `workflows/score-resume-against-jd.md` |

## Guidelines

See `guidelines.md` for task/symptom-based file selection, a decision tree, the full file index, and common combinations.
