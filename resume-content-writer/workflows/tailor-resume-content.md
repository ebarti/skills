# Tailor Resume Content Workflow

Generate tailored, schema-conformant resume content (headline, summary, skills, and quantified experience bullets) for ONE target job — honoring user-pinned "must-include" achievements.

This is the primary entry point of `resume-content-writer`. It is designed to be called by an agent (JobHunter) in a `analyze-jd → write → score → revise` loop.

## When to Use

- Tailoring a candidate's base resume to a specific job
- (Re)writing experience bullets into quantified, achievement-led form
- Generating a headline + branding summary aimed at a target role
- Selecting and ordering the skills section to match a JD
- Revising content after `resume-fit-scorer` returned `prioritized_fixes`

## Inputs (contract)

```jsonc
{
  "raw_experience": [                 // the candidate's real history (source of truth)
    {
      "company": "string",
      "title": "string",
      "dates": "string",
      "responsibilities": ["string"], // raw duties
      "raw_wins": ["string"],         // any results/metrics the user already knows
      "education": false
    }
  ],
  "education": [ { "school": "string", "credential": "string", "dates": "string" } ],
  "skills_pool": ["string"],          // everything the candidate can truthfully claim
  "target": { /* TargetProfile from job-description-analyzer */ },
  "seniority": "entry|junior|mid|senior|lead|manager|director|exec", // optional; else use target.seniority
  "focus": ["string"],                // angle to emphasize, e.g. ["leadership","cost-reduction"]
  "must_include": ["string"],         // PINNED achievements that must appear (do not drop)
  "output_schema": { /* optional */ } // caller's resume data model; if absent, use Default Output below
}
```

## Output (default schema — overridden by `output_schema` if provided)

```jsonc
{
  "headline": "string",
  "summary": "string",
  "skills": ["string"],               // ordered, JD-matched, truthful subset of skills_pool
  "experience": [
    {
      "company": "string", "title": "string", "dates": "string",
      "bullets": [
        { "text": "string",
          "maps_to": ["must_have or ats_keyword it satisfies"],
          "has_metric": true,
          "source": "raw|pinned|inferred" }
      ]
    }
  ],
  "education": [ /* passed through, lightly tailored */ ],
  "dropped": [ { "item": "string", "reason": "string" } ],
  "warnings": ["string"]              // e.g. "removed unverifiable claim X"
}
```

**Rule:** If `output_schema` is supplied, map the generated content into that shape exactly and return it; keep `dropped`/`warnings` only if the schema allows, otherwise surface them in a side channel. Never invent fields the schema forbids.

**Prerequisites:** a `TargetProfile` (run `job-description-analyzer` first) and the candidate's real `raw_experience`. Never fabricate experience to fit the target.

**References:** `references/achievement-anatomy/`, `references/wow-words/`, `references/tailoring-to-role/`, `references/by-seniority/`, `references/headline-and-summary/`, `references/ai-writing-pitfalls/smells.md`

---

## Workflow Steps

### Step 1: Set Parameters

**Goal:** Lock the targeting knobs before writing a word.

- [ ] Resolve `seniority` (explicit input > `target.seniority`)
- [ ] Resolve `focus` (explicit input > `target.focus_hints`)
- [ ] Note `must_include[]` items — these are pinned and survive every later step
- [ ] Note the `output_schema` (or default)

**Reference:** `references/by-seniority/knowledge.md`

---

### Step 2: Select & Order Experience

**Goal:** Decide what to feature; relevance beats chronology.

- [ ] Rank `raw_experience` by relevance to `target.must_have` + `responsibilities`
- [ ] Lead with the most relevant + recent roles; demote or compress irrelevant ones
- [ ] Apply the seniority recency window (experienced: focus ~last 10–15 yrs; new-grad: elevate education/projects)
- [ ] Record anything not featured in `dropped[]` with a reason

**Reference:** `references/tailoring-to-role/rules.md`, `references/by-seniority/rules.md`

---

### Step 3: Write Achievement Bullets

**Goal:** Turn duties into quantified, verb-led achievements mapped to the JD.

- [ ] For each featured role, convert responsibilities → CAR/PAR achievement bullets
- [ ] Quantify with numbers / percentages / dollars; if no hard metric, quantify by scale, scope, frequency, or time saved
- [ ] Open each bullet with a strong wow verb (no "Responsible for", "Helped with", "Worked on")
- [ ] Tag each bullet's `maps_to` with the `must_have`/`ats_keyword` it satisfies; set `has_metric`
- [ ] **Pinned `must_include` items**: include each as a bullet (`source:"pinned"`). Polish wording only — do not drop, weaken, or change its meaning/metrics
- [ ] Mark any bullet you could not ground in `raw_experience` as `source:"inferred"` and add a `warning`

**Ask:** "Would a recruiter know the *result*, not just the *task*, from this line?"

**Reference:** `references/achievement-anatomy/rules.md`, `references/achievement-anatomy/patterns.md`, `references/wow-words/examples.md`

---

### Step 4: Tailor the Skills Section

**Goal:** Mirror the JD's priorities truthfully.

- [ ] Intersect `skills_pool` with `target.hard_skills` + `target.ats_keywords`; lead with those
- [ ] Use the JD's exact phrasing for hard requirements the candidate genuinely has (crossover terms)
- [ ] Drop skills irrelevant to the target; never add a skill the candidate lacks

**Reference:** `references/tailoring-to-role/rules.md`

---

### Step 5: Write Headline + Summary

**Goal:** Open with a targeted, quantified pitch.

- [ ] Headline = target job title + 1 differentiating value proposition
- [ ] Summary = 2–4 lines: who they are for THIS role + top quantified proof + key JD-matched skills
- [ ] No generic objectives, no first-person fluff, no clichés

**Reference:** `references/headline-and-summary/rules.md`, `references/headline-and-summary/examples.md`

---

### Step 6: Guard Against AI Pitfalls

**Goal:** Strip anything that reads as fabricated or AI slop.

- [ ] Verify every claim/metric traces to `raw_experience`/`raw_wins`/`must_include`; remove or flag the rest
- [ ] Remove keyword stuffing, repeated verbs, over-formal clichés
- [ ] Keep the candidate's authentic voice and a human level of specificity

**Reference:** `references/ai-writing-pitfalls/smells.md`

---

### Step 7: Emit Structured Output

**Goal:** Return machine-usable content.

- [ ] Map content into `output_schema` (or the Default Output)
- [ ] Populate `dropped[]` and `warnings[]`
- [ ] Validate it parses and that every `must_include` item is present

---

## Quick Checklist

```
[ ] Step 1: seniority, focus, pinned items, schema resolved
[ ] Step 2: experience selected & ordered by relevance
[ ] Step 3: bullets are quantified, verb-led, mapped; must_include present
[ ] Step 4: skills section mirrors JD, truthfully
[ ] Step 5: headline + summary targeted and quantified
[ ] Step 6: no fabrication / stuffing / slop
[ ] Step 7: output conforms to schema; validated
```

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Fabricating metrics to hit keywords | Fails verification, ethical + interview risk | Quantify only real results; else use scope/scale |
| Dropping or rewording a pinned `must_include` | Violates the user's explicit intent | Keep it; polish wording only |
| Listing duties instead of achievements | Reads as "telling", scores low | CAR/PAR with a result every line |
| Keyword-stuffing the skills section | ATS + humans penalize it | Mirror only truthful, relevant skills |
| Ignoring `output_schema` | Breaks JobHunter's data flow | Conform exactly to the supplied schema |
| Generic headline/objective | Wastes the highest-value space | Target title + quantified value prop |

## Exit Criteria

- [ ] Output parses and conforms to `output_schema` (or Default Output)
- [ ] Every `must_include` item appears (`source:"pinned"`)
- [ ] Every bullet is grounded in real history (or flagged `inferred` with a warning)
- [ ] Headline, summary, skills, and bullets all reflect the `target`
- [ ] `dropped[]` explains everything left out
