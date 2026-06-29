# resume-fit-scorer — Creation Progress

## Status: complete (12/12 files)

Source: "Resumes For Dummies" (AI-era ed.), Ch 1, 2, 3, 5, 6, 10, 15, 16, 18. Verifier in the JobHunter loop: consumes resume + `TargetProfile`, emits `FitScore` (0–10 + critique + prioritized fixes).

## Foundation
- [x] SKILL.md
- [x] guidelines.md
- [x] progress.md
- [x] workflows/score-resume-against-jd.md

## References
- [x] scoring-rubric/{knowledge,rules,examples}   ← Ch18 + Ch15 (synthesized into 6-dim rubric)
- [x] jd-match/{knowledge,rules,examples}          ← Ch5 L43–115 + Ch1 L69–108 + Ch2 L27–55
- [x] red-flags/{smells,checklist}                 ← Ch16 + Ch3 L303–327 + Ch6 L89–123 + Ch10 L261–356

## Notes
- Default weights (JD match 30 / achievement 25 / targeting 15 / ATS 10 / red flags 10 / language 10) and 0–10 bands are encoded in `scoring-rubric/`; overridable via the workflow's `weights` input.
- Calibration is deliberately harsh (generic resume = 3–5). Major red flags & missing must-haves apply a ceiling.
- Minor cleanup applied in review: `scoring-rubric/examples.md` Language-row weight label.
- Cross-skill contract: pairs with `job-description-analyzer` (TargetProfile) and `resume-content-writer` (consumes prioritized_fixes).
