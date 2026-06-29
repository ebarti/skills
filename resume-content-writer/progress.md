# resume-content-writer — Creation Progress

## Status: complete (21/21 files)

Source: "Resumes For Dummies" (AI-era ed.), Ch 3–7 & 9. Purpose-built for JobHunter: consumes a `TargetProfile`, emits schema-conformant resume content; honors pinned `must_include` achievements.

## Foundation
- [x] SKILL.md
- [x] guidelines.md
- [x] progress.md
- [x] workflows/tailor-resume-content.md

## References
- [x] achievement-anatomy/{knowledge,rules,examples,patterns}   ← Ch4 L42–218
- [x] wow-words/{knowledge,rules,examples}                       ← Ch7
- [x] tailoring-to-role/{knowledge,rules,examples}               ← Ch5 L115–178 + Ch4 L246–318 + Ch6 L68–88
- [x] by-seniority/{knowledge,rules,examples}                    ← Ch9 L56–283
- [x] headline-and-summary/{knowledge,rules,examples}            ← Ch3 L58–106 + Ch6 L43–67
- [x] ai-writing-pitfalls/smells                                 ← Ch6 L89–123

## Notes
- **Wow-words verb banks**: the book rendered its nine verb lists as images, so they did not extract as text. `wow-words/examples.md` uses a clearly-labeled starter bank of standard strong verbs (flagged as safe defaults, not verbatim from the book) plus the 4 verbs quoted inline. Replace with a verbatim bank later if desired.
- Output conforms to a caller-supplied `output_schema`; a default schema lives in the workflow.
- Cross-skill contract: pairs with `job-description-analyzer` (TargetProfile) and `resume-fit-scorer` (FitScore).
