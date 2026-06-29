# DDIA Data Ethics Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use**: Find your situation below, then load ONLY the listed files. This skill is intentionally compact — most tasks need just one knowledge file plus its rules.

---

## Workflows

| Task | Workflow |
|------|----------|
| Review an ML decision system or data-handling feature for ethics & privacy | `workflows/ethics-review-checklist.md` |

---

## By Task

### ML/AI System Review

| What you're doing | Load these files |
|-------------------|------------------|
| Auditing a model for bias (sampling, feedback, proxy variables) | `references/predictive-analytics-bias/knowledge.md`, `references/predictive-analytics-bias/rules.md` (and `workflows/ethics-review-checklist.md` for an end-to-end pass) |
| Reviewing accountability gaps ("who is responsible when the model is wrong?") | `references/predictive-analytics-bias/knowledge.md`, `references/predictive-analytics-bias/rules.md` (and `workflows/ethics-review-checklist.md`) |
| Spotting feedback loops in "predict then act" systems | `references/predictive-analytics-bias/knowledge.md`, `references/predictive-analytics-bias/examples.md` |
| Reviewing concrete model code or pipeline | `references/predictive-analytics-bias/examples.md`, `references/predictive-analytics-bias/rules.md` (and `workflows/ethics-review-checklist.md`) |

### Privacy Engineering

| What you're doing | Load these files |
|-------------------|------------------|
| Applying data minimization to a new feature | `references/privacy-and-tracking/rules.md`, `references/privacy-and-tracking/knowledge.md` (and `workflows/ethics-review-checklist.md` for full review) |
| Designing consent UX (opt-in, dark patterns, granularity) | `references/privacy-and-tracking/rules.md`, `references/privacy-and-tracking/examples.md` |
| Building right-to-erasure (deletion across stores, backups, derived data, ML models) | `references/privacy-and-tracking/rules.md`, `references/privacy-and-tracking/examples.md` |
| Adopting a data-as-liability mindset for design reviews | `references/privacy-and-tracking/knowledge.md` (and `workflows/ethics-review-checklist.md`) |

### Compliance

| What you're doing | Load these files |
|-------------------|------------------|
| GDPR/CCPA review of a system | `references/privacy-and-tracking/rules.md`, `references/privacy-and-tracking/knowledge.md` (use `workflows/ethics-review-checklist.md` to structure the pass) |
| Defining audit trails for automated decisions | `references/predictive-analytics-bias/rules.md` |
| Setting data retention policies | `references/privacy-and-tracking/rules.md` |
| Running an end-to-end ethics review of a system or feature | `workflows/ethics-review-checklist.md` |

---

## By Problem/Symptom

| If you notice / are asked... | Load these files |
|------------------------------|------------------|
| "Our ML model rejects more applicants from group X" | `references/predictive-analytics-bias/knowledge.md`, `references/predictive-analytics-bias/rules.md` |
| "We're building a 'predict then act' loop (recs, policing, hiring)" | `references/predictive-analytics-bias/knowledge.md` (feedback loops), `references/predictive-analytics-bias/examples.md` |
| "Need to delete a user's data — including from backups, analytics, ML models" | `references/privacy-and-tracking/rules.md`, `references/privacy-and-tracking/examples.md` |
| "Designing tracking/analytics for new feature" | `references/privacy-and-tracking/knowledge.md`, `references/privacy-and-tracking/rules.md` |
| "Should we collect this field?" | `references/privacy-and-tracking/rules.md` (data minimization) |
| "How do we get meaningful consent?" | `references/privacy-and-tracking/rules.md`, `references/privacy-and-tracking/examples.md` |
| "GDPR / CCPA compliance review" | `references/privacy-and-tracking/rules.md`, `references/privacy-and-tracking/knowledge.md` |
| "Who is accountable for this model's decision?" | `references/predictive-analytics-bias/knowledge.md`, `references/predictive-analytics-bias/rules.md` |

---

## By Topic

### Predictive Analytics, Bias, and Accountability

- **Knowledge**: `references/predictive-analytics-bias/knowledge.md`
- **Rules**: `references/predictive-analytics-bias/rules.md`
- **Examples**: `references/predictive-analytics-bias/examples.md`

### Privacy and Tracking

- **Knowledge**: `references/privacy-and-tracking/knowledge.md`
- **Rules**: `references/privacy-and-tracking/rules.md`
- **Examples**: `references/privacy-and-tracking/examples.md`

---

## Decision Tree

```
What kind of ethics review?
│
├─► ML / automated decision system
│   ├─► Understand bias sources, accountability, feedback loops
│   │     → references/predictive-analytics-bias/knowledge.md
│   ├─► Apply concrete rules to a model or pipeline
│   │     → references/predictive-analytics-bias/rules.md
│   └─► Review concrete code / examples
│         → references/predictive-analytics-bias/examples.md
│
└─► Privacy / data collection / consent
    ├─► Understand surveillance framing, data-as-liability
    │     → references/privacy-and-tracking/knowledge.md
    ├─► Apply minimization, consent, retention, erasure rules
    │     → references/privacy-and-tracking/rules.md
    └─► Review consent flows, deletion implementations
          → references/privacy-and-tracking/examples.md
```

---

## File Index

Complete list of all knowledge files in this skill:

### Predictive Analytics, Bias, and Accountability
| File | Purpose |
|------|---------|
| `references/predictive-analytics-bias/knowledge.md` | Core concepts: predictive analytics vs. credit scoring, sources of bias, feedback loops, accountability gaps, the "algorithmic prison" |
| `references/predictive-analytics-bias/rules.md` | Concrete do's and don'ts for building, deploying, and reviewing ML decision systems |
| `references/predictive-analytics-bias/examples.md` | Worked scenarios: biased pipelines, feedback loops, accountable vs. opaque systems |

### Privacy and Tracking
| File | Purpose |
|------|---------|
| `references/privacy-and-tracking/knowledge.md` | Core concepts: surveillance framing, behavioral data, third-party tracking, data-as-liability, consent quality |
| `references/privacy-and-tracking/rules.md` | Rules for data minimization, consent, retention, third-party sharing, right-to-erasure |
| `references/privacy-and-tracking/examples.md` | Worked scenarios: collection patterns, consent flows, deletion across systems |

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| Full ML decision-system review | `predictive-analytics-bias/knowledge.md` + `rules.md` + `examples.md` |
| Full privacy review of a feature | `privacy-and-tracking/knowledge.md` + `rules.md` + `examples.md` |
| New product design touching both | `predictive-analytics-bias/knowledge.md` + `privacy-and-tracking/knowledge.md` |
