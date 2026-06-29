# Requirement Extraction Rules

Rules for classifying JD content into structured requirements.

## Core Rules

### 1. Classify priority by language cues, not by section heading alone

A line's wording outranks where it sits. A "must" inside a "Preferred" block is still a must-have.

- **MUST-have cues**: "required", "must", "must have", "minimum", "at least", "X+ years", "demonstrated", "proven", "essential", "you have", "we require".
- **NICE-to-have cues**: "preferred", "preferably", "bonus", "a plus", "nice to have", "ideally", "desired", "familiarity with", "exposure to", "would be great".
- Default rule: if no cue and the line sits under Requirements/Qualifications, treat as must-have; if under Preferred/Bonus, treat as nice-to-have.

### 2. Separate hard skills from soft skills by testability

If you could verify it with a test, cert, or work sample, it's a hard skill. If it's an interpersonal trait, it's a soft skill.

- **Hard skill markers**: named tools/tech, certifications/licenses, methods, quantities, domain knowledge (e.g., "Python", "AWS", "CPA", "SQL", "GAAP", "X-rays").
- **Soft skill markers**: trait words — "communication", "teamwork", "collaboration", "leadership", "adaptable", "self-starter", "detail-oriented", "problem-solving".
- A requirement can be a hard skill AND a must-have at once — tag both dimensions independently.

### 3. A requirement carries two independent tags

Priority (must/nice) and type (hard/soft) are orthogonal. Always assign both.

```
"5+ years of Python required"     -> priority: must,  type: hard
"Experience with Kubernetes a plus" -> priority: nice, type: hard
"Excellent written communication"  -> priority: must,  type: soft (often implied)
"Familiarity with Agile preferred" -> priority: nice, type: hard
```

### 4. Extract responsibilities from action-led lines

Lines that describe what the person DOES (lead verb + object) are responsibilities, not qualifications.

- Pull the verb + object: "Lead the redesign of the checkout flow" -> responsibility.
- Keep them as a separate list; do not mix with skills.

### 5. Infer seniority from years + scope verbs + people scope

Combine multiple signals; never rely on the title alone.

- **Years**: 0-2 = junior; 2-5 = mid; 5-8 = senior; 8+ = lead/staff/principal.
- **Scope verbs**: "assist/support/help" → junior; "build/own/deliver" → mid/senior; "define/drive strategy/set direction" → senior+.
- **People scope**: "mentor" → senior; "manage/hire/lead a team" → manager/lead.
- **Title modifiers**: Junior/Associate < (none) < Senior < Staff/Lead < Principal < Manager/Head/Director.
- When signals conflict, weight years + scope verbs over the title word.

### 6. Ignore boilerplate

Do not extract requirements from non-requirement content.

- Skip: EEO/diversity statements, benefits/perks, salary range, company history/mission blurb, "how to apply" instructions, legal disclaimers.

### 7. Preserve the employer's exact wording

Capture the skill as written so it can be mirrored for ATS matching downstream.

- Keep "client success" rather than normalizing to "account management" (synonyms are added later as crossover terms, not in extraction).

## Guidelines

- When a single line bundles several skills ("Python, SQL, and Airflow"), split into separate skill entries.
- Treat "X or equivalent" (e.g., degree) as a must-have with a relaxable bar — flag it as soft-required.
- If years are given as a range ("3-5 years"), use the lower bound for the floor and the upper for the seniority read.
- Deduplicate skills that appear in both responsibilities and requirements; keep the requirement instance.

## Exceptions

- **Implied soft skills**: customer-facing or team roles imply communication/teamwork even when unstated — extract them as must-have/soft and mark `implied: true`.
- **Startup "wear many hats" JDs**: broad responsibility lists may overstate seniority — lean on years + people scope to calibrate.
- **Reposted/templated JDs**: a generic boilerplate skill list may not reflect the real role — weight responsibilities over a long undifferentiated skills dump.

## Quick Reference

| Cue word / phrase | Classification |
|-------------------|----------------|
| required, must, must have | must-have |
| minimum, at least, X+ years | must-have |
| demonstrated, proven, essential | must-have |
| preferred, preferably, ideally | nice-to-have |
| bonus, a plus, nice to have | nice-to-have |
| familiarity with, exposure to, desired | nice-to-have |
| named tool / cert / license / method | hard skill |
| communication, teamwork, leadership | soft skill |
| assist, support, help | junior seniority |
| own, deliver, build | mid/senior seniority |
| define, drive strategy, set direction | senior+ seniority |
| mentor, manage, hire, lead team | lead/manager |
| EEO, benefits, salary, company mission | ignore (boilerplate) |
