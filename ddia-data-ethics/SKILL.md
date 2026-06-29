---
name: ddia-data-ethics
description: |
  Ethical and societal frameworks for designing data-intensive systems, distilled from "Designing Data-Intensive Applications" (Kleppmann, 2nd ed) chapter 14. Covers algorithmic accountability, bias, surveillance, consent, and the data-as-liability mindset — normative guidance, not pure engineering technique.

  Use this skill when:
  - Building or reviewing ML decision systems (credit, hiring, criminal justice)
  - Designing systems handling personal data
  - Implementing GDPR/CCPA right-to-erasure
  - Reviewing surveillance/tracking features
  - Auditing for algorithmic bias
  - Architecting consent flows
  - Making product decisions involving user data
---

# DDIA Data Ethics

This skill encodes the *normative* side of data engineering: what we *should* and *should not* build, separate from what we *can* build. It draws from chapter 14 of "Designing Data-Intensive Applications" (Kleppmann, 2nd ed). Where most of DDIA gives mechanical guidance ("use this index for that workload"), this material asks harder questions about the human consequences of automated decisions and large-scale data collection.

Treat the contents as a checklist of ethical concerns to surface during design, review, and product decisions — not a compliance script. Many recommendations here will create friction with growth, monetization, or simplicity goals; that friction is the point.

## Quick Start

1. Read `guidelines.md` to find the right reference file for your situation
2. Load only the files relevant to your task — do not load the whole skill
3. Apply the framing as a review lens; surface tradeoffs explicitly, do not silently bypass them

## Contents

### References

| Category | Files | Purpose |
|----------|-------|---------|
| `references/predictive-analytics-bias/` | knowledge.md, rules.md, examples.md | Algorithmic decision-making, bias sources, feedback loops, accountability |
| `references/privacy-and-tracking/` | knowledge.md, rules.md, examples.md | Surveillance, consent, data minimization, right-to-erasure, data-as-liability |

### Workflows

| Task | Workflow |
|------|----------|
| Review an ML decision system or data-handling feature for ethics & privacy | `workflows/ethics-review-checklist.md` |

## Guidelines

See `guidelines.md` for:
- Task-based file selection (ML review, privacy engineering, compliance)
- Symptom/question lookup ("our model rejects more applicants from group X")
- Topic-based browsing
- Decision tree for the two main review paths
