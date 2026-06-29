# job-description-analyzer — Creation Progress

## Status: complete (10/10 files)

Source: "Resumes For Dummies" (AI-era ed.), Ch 1, 3, 5, 6. Step 1 of the JobHunter loop: turns raw JD text into a `TargetProfile` consumed by `resume-content-writer` and `resume-fit-scorer`.

## Foundation
- [x] SKILL.md
- [x] guidelines.md
- [x] progress.md
- [x] workflows/analyze-job-description.md

## References
- [x] requirement-extraction/{knowledge,rules,examples}   ← Ch6 L13–42 + Ch3 L107–126 + Ch1 L92–108
- [x] keywords-and-crossover/{knowledge,rules,examples}    ← Ch5 L115–178 + Ch6 L27–42

## Notes
- Output is the shared `TargetProfile` contract (role, seniority, must/nice, hard/soft skills, responsibilities, ats_keywords, crossover_terms, focus_hints). Overridable via the workflow's `output_schema`.
- Crossover mapping requires `candidate_skills` to be truthful; gaps are flagged in `notes`.
- Cross-skill contract: produces the `TargetProfile` that the other two skills consume.
