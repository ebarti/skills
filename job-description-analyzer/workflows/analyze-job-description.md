# Analyze Job Description Workflow

Turn a raw job description into a structured `TargetProfile` — the single source of truth that drives resume tailoring and scoring.

This is the primary entry point of `job-description-analyzer` and **step 1 of the JobHunter loop**. Its output feeds both `resume-content-writer` and `resume-fit-scorer`.

## When to Use

- Before tailoring a resume to a job (always run this first)
- Before scoring a resume, when only raw JD text is available
- Building a per-job requirement/keyword index
- Inferring a job's target seniority and focus

## Inputs (contract)

```jsonc
{
  "jd_text": "string",                  // the raw job posting
  "candidate_skills": ["string"],       // optional; enables crossover mapping
  "output_schema": { /* optional */ }   // caller schema; else emit TargetProfile below
}
```

## Output (default schema — `TargetProfile`)

```jsonc
{
  "role_title": "string",
  "seniority": "entry|junior|mid|senior|lead|manager|director|exec",
  "must_have": ["string"],              // required qualifications
  "nice_to_have": ["string"],           // preferred / bonus
  "hard_skills": ["string"],            // tools, tech, certs, measurable competencies
  "soft_skills": ["string"],
  "responsibilities": ["string"],
  "ats_keywords": ["string"],           // exact phrases to mirror truthfully
  "crossover_terms": [ { "jd_term": "string", "candidate_term": "string" } ],
  "focus_hints": ["string"],            // e.g. ["leadership","scale","cost-reduction"]
  "industry": "string|null",
  "notes": "string|null"
}
```

**Reference:** `references/requirement-extraction/`, `references/keywords-and-crossover/`

---

## Workflow Steps

### Step 1: Segment the JD

**Goal:** Separate signal from boilerplate.

- [ ] Identify the requirements/qualifications block, responsibilities block, and "about the role" text
- [ ] Ignore boilerplate: EEO statements, benefits, company history, legal

**Reference:** `references/requirement-extraction/rules.md`

---

### Step 2: Classify Requirements (must-have vs nice-to-have)

**Goal:** Tier every requirement.

- [ ] Tag must-haves via cue words: "required", "must", "minimum", "X+ years"
- [ ] Tag nice-to-haves via: "preferred", "bonus", "a plus", "nice to have"
- [ ] When ambiguous, default to `nice_to_have` and add a `note`

**Reference:** `references/requirement-extraction/rules.md` (cue-word table), `references/requirement-extraction/examples.md`

---

### Step 3: Split Hard vs Soft Skills

**Goal:** Separate measurable competencies from traits.

- [ ] `hard_skills`: tools, technologies, certifications, domain methods
- [ ] `soft_skills`: communication, leadership, collaboration, etc.

**Reference:** `references/requirement-extraction/knowledge.md`

---

### Step 4: Extract Responsibilities & Infer Seniority

**Goal:** Capture the work and the level.

- [ ] List the core responsibilities as short phrases
- [ ] Infer `seniority` from years required, scope, leadership language, and verbs (own/lead vs assist/support)
- [ ] Derive `focus_hints` from what the JD emphasizes most

**Reference:** `references/requirement-extraction/rules.md` (seniority inference)

---

### Step 5: Extract ATS Keywords & Build Crossover Map

**Goal:** Capture the exact vocabulary to mirror.

- [ ] Pull high-value exact phrases (titles, tools, skills, certs) → `ats_keywords`
- [ ] If `candidate_skills` provided, map JD terms ↔ the candidate's truthful equivalents → `crossover_terms`
- [ ] Do NOT invent equivalents the candidate can't support; flag gaps in `notes`
- [ ] Avoid over-cloning: capture distinct keywords, not every phrase verbatim

**Reference:** `references/keywords-and-crossover/rules.md`, `references/keywords-and-crossover/examples.md`

---

### Step 6: Emit Structured Output

**Goal:** Return a clean, machine-usable profile.

- [ ] Populate `TargetProfile` (or the caller's `output_schema`)
- [ ] De-duplicate; keep lists concise and concrete
- [ ] Validate it parses and that `must_have` is non-empty when the JD states requirements

---

## Quick Checklist

```
[ ] Step 1: JD segmented; boilerplate dropped
[ ] Step 2: requirements tiered (must vs nice)
[ ] Step 3: hard vs soft skills split
[ ] Step 4: responsibilities listed; seniority + focus inferred
[ ] Step 5: ats_keywords + crossover_terms built (truthfully)
[ ] Step 6: TargetProfile emitted; schema valid
```

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Treating every line as must-have | Inflates requirements; over-filters candidates | Tier by cue words; default ambiguous → nice-to-have |
| Mixing hard and soft skills | Downstream skills selection gets noisy | Keep separate lists |
| Verbatim-cloning the whole JD | Leads to keyword stuffing downstream | Extract distinct keywords only |
| Inventing crossover equivalents | Produces dishonest resumes | Map only truthful equivalents; flag gaps |
| Skipping seniority inference | Writer can't calibrate framing | Infer from years/scope/verbs |

## Exit Criteria

- [ ] `TargetProfile` (or `output_schema`) is populated and parses
- [ ] Requirements tiered into `must_have` / `nice_to_have`
- [ ] `hard_skills` / `soft_skills` separated; `responsibilities` listed
- [ ] `seniority` and `focus_hints` inferred
- [ ] `ats_keywords` extracted; `crossover_terms` truthful (gaps noted)
