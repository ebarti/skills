# Requirement Extraction Examples

Worked examples turning raw JD text into structured requirements.

## Full Worked Example

### Input: Raw Job Description

```
Senior Data Engineer — Acme Analytics

About us: Acme is a fast-growing analytics startup on a mission to
democratize data. We offer competitive pay, unlimited PTO, and full
health coverage. Acme is an equal opportunity employer.

What you'll do:
- Own and scale our batch and streaming data pipelines
- Lead the migration from Redshift to Snowflake
- Mentor two junior engineers and set data-modeling standards
- Partner with analysts to ship trusted datasets

What we're looking for:
- 6+ years building production data pipelines (required)
- Strong Python and SQL — this is a must
- Experience with Airflow or a similar orchestrator
- Excellent communication with non-technical stakeholders

Nice to have:
- Familiarity with dbt
- AWS certification a plus
- Exposure to real-time streaming (Kafka)
```

### Output: Extracted Structure

```yaml
title: Senior Data Engineer
company: Acme Analytics

must_have:
  - 6+ years building production data pipelines   # cue: "required", "6+ years"
  - Python                                         # cue: "must"
  - SQL                                            # cue: "must"
  - Airflow (or similar orchestrator)              # under Requirements, no nice cue
  - Communication with non-technical stakeholders  # cue: "Excellent", customer-facing

nice_to_have:
  - dbt                                            # cue: "familiarity with"
  - AWS certification                              # cue: "a plus"
  - Kafka / real-time streaming                    # cue: "exposure to", nice block

hard_skills:
  - Python
  - SQL
  - Airflow
  - dbt
  - AWS certification (license)
  - Kafka
  - Data pipeline construction (6+ yrs)

soft_skills:
  - Communication (with non-technical stakeholders)
  - Mentoring / coaching          # implied by responsibility
  - Cross-functional partnership  # implied by responsibility

responsibilities:
  - Own and scale batch + streaming data pipelines
  - Lead Redshift -> Snowflake migration
  - Mentor 2 junior engineers; set data-modeling standards
  - Partner with analysts to ship trusted datasets

inferred_seniority:
  level: Senior / Lead
  signals:
    - "6+ years" -> senior band
    - verbs "own", "lead", "set standards" -> high scope
    - "Mentor two junior engineers" -> people/leadership scope
    - title contains "Senior"

ignored:
  - Company mission blurb ("democratize data")
  - Benefits (PTO, health coverage, pay)
  - EEO statement
```

## Tricky Classification Snippets

### Snippet 1: A "must" hiding in the Preferred block

```
Preferred qualifications:
- Background in fintech is preferred
- You must hold an active Series 7 license
```

**Classification**:
- "Background in fintech" -> `nice_to_have`, hard skill (cue: "preferred").
- "Series 7 license" -> `must_have`, hard skill (cue: "must hold"), even though
  it sits under *Preferred*. **Wording beats the heading** (Rule 1).

### Snippet 2: One line, two skills, two priorities

```
- Expert in React (required); experience with React Native is a bonus
```

**Classification** — split the line (Rule: bundled skills):
- React -> `must_have`, hard skill (cue: "required").
- React Native -> `nice_to_have`, hard skill (cue: "a bonus").

### Snippet 3: Hard vs soft + implied soft skill

```
- Detail-oriented self-starter who can manage GAAP-compliant
  financial reporting in Excel and NetSuite
```

**Classification** — separate dimensions (Rule 2 & 3):
- "GAAP-compliant financial reporting" -> hard skill, must-have (domain method).
- "Excel", "NetSuite" -> hard skills, must-have (named tools).
- "Detail-oriented", "self-starter" -> soft skills, must-have.

### Snippet 4: Ambiguous seniority — let signals decide

```
Marketing Coordinator
- Support the marketing team with campaign execution
- 1-2 years of experience
- Help schedule social posts and assist with reporting
```

**Inferred seniority**: Junior.
- Years 1-2 -> junior band.
- Verbs "support", "help", "assist" -> low scope.
- No people scope. Title "Coordinator" agrees -> Junior (Rule 5).
