# Score Resume Against JD Workflow

Score how well a resume fits a specific job, return a brutally honest critique, and emit a structured 0–10 result with prioritized fixes.

This is the primary entry point of `resume-fit-scorer`. It is the verifier in the JobHunter loop: its `prioritized_fixes` feed back into `resume-content-writer` for revision.

## When to Use

- Gating whether a tailored resume is good enough to submit
- Ranking several resume variants against one JD
- Producing the critique that drives a revise loop
- Auditing a resume for ATS / red-flag risk before applying

## Inputs (contract)

```jsonc
{
  "resume": "string | ResumeContent",   // plain text OR resume-content-writer output
  "target": { /* TargetProfile from job-description-analyzer */ },
  "jd_text": "string",                   // optional raw JD if no TargetProfile
  "weights": { /* optional override of dimension weights */ },
  "output_schema": { /* optional caller schema */ }
}
```

If a `TargetProfile` is absent, derive must-haves/keywords from `jd_text` first (or call `job-description-analyzer`).

## Output (default schema — `FitScore`)

```jsonc
{
  "overall": 0.0,                        // 0–10, weighted, one decimal
  "verdict": "trash|weak|ok|strong|excellent",
  "dimensions": {
    "jd_match":             { "score": 0, "weight": 0.30, "why": "string" },
    "achievement_strength": { "score": 0, "weight": 0.25, "why": "string" },
    "targeting_focus":      { "score": 0, "weight": 0.15, "why": "string" },
    "ats_parseability":     { "score": 0, "weight": 0.10, "why": "string" },
    "red_flags":            { "score": 0, "weight": 0.10, "why": "string", "flags": ["RF#: ..."] },
    "language":             { "score": 0, "weight": 0.10, "why": "string" }
  },
  "must_have_coverage": { "covered": ["..."], "missing": ["..."] },
  "critique": ["specific, harsh, actionable point", "..."],
  "prioritized_fixes": [
    { "fix": "string", "dimension": "string", "expected_gain": "+1.5", "effort": "low|med|high" }
  ]
}
```

**Reference:** `references/scoring-rubric/` (dimensions, weights, bands, calibration), `references/jd-match/` (the 30% dimension), `references/red-flags/` (catalog + scan)

---

## Workflow Steps

### Step 1: Establish the Target

**Goal:** Know exactly what "fit" means for this job.

- [ ] Load `target.must_have`, `nice_to_have`, `hard_skills`, `ats_keywords`, `seniority`
- [ ] If only `jd_text` is given, extract them first

**Reference:** `references/jd-match/knowledge.md`

---

### Step 2: Score `jd_match` (30%)

**Goal:** Measure truthful requirement + keyword coverage and ATS-survivability.

- [ ] Compute must-have coverage → fill `must_have_coverage.covered/missing`
- [ ] Check keyword/title alignment and mirrored terminology
- [ ] Check ATS-parseable formatting (no columns/tables/graphics-only text, right file type)
- [ ] Score 0–10; **missing must-haves cap this dimension low**

**Reference:** `references/jd-match/rules.md`, `references/jd-match/examples.md`

---

### Step 3: Score `achievement_strength` (25%)

**Goal:** Judge whether bullets prove impact.

- [ ] % of bullets that are quantified and result-led (not duties)
- [ ] Strong verbs, concrete outcomes, no filler
- [ ] Score 0–10

**Reference:** `references/scoring-rubric/rules.md`

---

### Step 4: Score `targeting_focus` (15%) and `language` (10%)

**Goal:** Judge tailoring and writing quality.

- [ ] `targeting_focus`: is the right experience featured? Is irrelevant material trimmed? Is the headline/summary aimed at THIS role?
- [ ] `language`: concision, consistency, grammar, no repeated verbs, no clichés
- [ ] Score each 0–10

**Reference:** `references/scoring-rubric/knowledge.md`

---

### Step 5: Scan `red_flags` (10%) and score `ats_parseability` (10%)

**Goal:** Detect penalties.

- [ ] Run the red-flag checklist; list each hit as `RF#: ...` in `dimensions.red_flags.flags`
- [ ] Major red flags (fabrication, auto-reject-level issues) → cap overall low regardless of other scores
- [ ] Score `ats_parseability` from Step 2's formatting findings

**Reference:** `references/red-flags/checklist.md`, `references/red-flags/smells.md`

---

### Step 6: Compute Overall & Verdict

**Goal:** Combine into a calibrated score.

- [ ] `overall = Σ(score_i × weight_i)`, rounded to one decimal
- [ ] Map to verdict band (0–2 trash · 3–4 weak · 5–6 ok · 7–8 strong · 9–10 excellent)
- [ ] **Calibrate harshly**: an untargeted/generic resume should land 3–5, not 7. Do not inflate.
- [ ] Apply any major-red-flag or missing-must-have ceiling

**Reference:** `references/scoring-rubric/rules.md` (weighted formula + calibration)

---

### Step 7: Write Critique & Prioritized Fixes

**Goal:** Make the score actionable for the writer.

- [ ] `critique[]`: specific, blunt points ("Bullet 3 lists duties, zero metrics"), not vague praise
- [ ] `prioritized_fixes[]`: ordered by `expected_gain`; each names the `dimension` and `effort`
- [ ] Ensure fixes map to things `resume-content-writer` can act on
- [ ] Emit in `output_schema` (or `FitScore` default); validate it parses

---

## Quick Checklist

```
[ ] Step 1: target established
[ ] Step 2: jd_match scored (coverage computed)
[ ] Step 3: achievement_strength scored
[ ] Step 4: targeting_focus + language scored
[ ] Step 5: red_flags scanned + ats_parseability scored
[ ] Step 6: weighted overall + verdict (harsh calibration)
[ ] Step 7: critique + prioritized fixes emitted; schema valid
```

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Grade inflation | Lets weak resumes through the gate | Anchor: generic resume = 3–5; demand proof for 7+ |
| Ignoring missing must-haves | Overstates real fit | Cap `jd_match` and overall when must-haves are missing |
| Vague critique ("could be stronger") | Writer can't act on it | Cite the exact bullet/line and the exact problem |
| Counting keywords blindly | Rewards stuffing | Credit only truthful, in-context matches |
| Letting one great dimension mask a fatal flaw | Fabrication/auto-reject slips through | Apply major-red-flag ceiling |
| Fixes not ordered by impact | Wastes revise cycles | Sort `prioritized_fixes` by `expected_gain` |

## Exit Criteria

- [ ] All 6 dimensions scored with one-line `why`
- [ ] `must_have_coverage` filled
- [ ] `overall` computed via weighted formula; `verdict` set; calibration applied
- [ ] `critique[]` is specific and `prioritized_fixes[]` is impact-ordered
- [ ] Output parses and conforms to `output_schema` (or `FitScore`)
