# Ethics Review Checklist Workflow

A review-time checklist for ML decision systems and privacy practices, used as a pre-launch or quarterly audit gate.

## When to Use

- Before launching a system that makes algorithmic decisions about people
- Before adding a new data collection point or tracking event
- During quarterly privacy/compliance audits
- Before signing a third-party data-sharing agreement

## Prerequisites

- System documentation (data flows, model cards if applicable)
- Access to consent UX, retention policy, and incident response plan

**References**: `references/predictive-analytics-bias/rules.md`, `references/privacy-and-tracking/rules.md`

---

## Section A: ML / Algorithmic Decision Systems

Skip this section if no ML or rules-based scoring affects user outcomes.

### A.1 Decision Scope and Reversibility

- [ ] Identified what decisions this model influences (credit, hiring, content moderation, pricing, etc.)
- [ ] Listed failure modes — what happens when the model is wrong?
- [ ] Classified harm: is a wrong answer **reversible** or **irreversible**?
- [ ] If irreversible (liberty, safety, survival): challenged whether ML is the right tool at all

**Ask**: "If this is wrong about one person, what does their day look like tomorrow?"

**Reference**: `references/predictive-analytics-bias/rules.md` (Rule 6)

### A.2 Bias Audit

- [ ] Outcome rates measured across protected classes (race, gender, age, geography, disability)
- [ ] Proxy features investigated (postal code, device, browsing history that correlates with protected traits)
- [ ] Hold-out evaluation done on demographically representative data
- [ ] Disparate-impact threshold defined and monitored post-launch

**Reference**: `references/predictive-analytics-bias/rules.md` (Rule 3)

### A.3 Feedback Loops

- [ ] Mapped the sociotechnical loop: does using the model generate the data it learns from?
- [ ] Control group reserved whose treatment is independent of model predictions
- [ ] Retraining pipeline does not exclusively use model-shaped data
- [ ] Watch for downward spirals on already-disadvantaged subjects

**Reference**: `references/predictive-analytics-bias/rules.md` (Rule 4)

### A.4 Human Review and Appeal

- [ ] Appeal path exists and is published before launch (not after a complaint)
- [ ] Reviewer has authority and data to override the model
- [ ] Appeal UX is as easy as the original decision flow (no dark patterns)
- [ ] Refusal reasons are human-readable, not "you do not meet our criteria"

**Reference**: `references/predictive-analytics-bias/rules.md` (Rule 2)

### A.5 Documentation and Explainability

- [ ] Model card exists: training data sources, snapshot dates, label definitions, known limitations
- [ ] Feature importance recorded for production decisions
- [ ] Model version, evaluation metrics, and failure modes archived
- [ ] Marketing copy does not call the system "neutral," "objective," or "unbiased"

**Reference**: `references/predictive-analytics-bias/rules.md` (Rules 1, 5)

---

## Section B: Privacy and Data Collection

### B.1 Data Minimization

- [ ] Each collected field tied to a specific, documented purpose
- [ ] No "collect everything, decide later" event payloads
- [ ] Aggregation or sampling used where raw records are not required
- [ ] New fields default to *off*, requiring justification to add

**Reference**: `references/privacy-and-tracking/rules.md` (Rule 1)

### B.2 Consent UX

- [ ] Consent is granular per purpose (analytics vs. ads vs. personalization vs. third parties)
- [ ] Revocation is one-click and as easy as opting in
- [ ] No pre-ticked boxes, no "reject all" buried in submenus
- [ ] Continued use is **not** treated as consent

**Reference**: `references/privacy-and-tracking/rules.md` (Rule 2)

### B.3 Purpose Limitation

- [ ] Data collected for purpose X is not silently used for purpose Y
- [ ] New uses (e.g. ML training) trigger fresh consent, not buried ToS updates
- [ ] Access controls scoped by purpose, not just by team
- [ ] Data flows audited for "purpose creep"

**Reference**: `references/privacy-and-tracking/rules.md` (Rule 3)

### B.4 Right-to-Erasure

- [ ] Deletion propagates to: OLTP, replicas, caches, search indexes
- [ ] Derived datasets, aggregates, and materialized views included
- [ ] Backups handled (deletion or documented retention window)
- [ ] Event logs / immutable streams: crypto-shredding plan in place
- [ ] ML training datasets and trained models include the user's data removal path
- [ ] Third-party processors notified

**Reference**: `references/privacy-and-tracking/rules.md` (Rule 4)

### B.5 Third-Party Sharing and Surveillance Creep

- [ ] All data sales/shares enumerated; user notified per purpose
- [ ] No third-party tracking SDKs where first-party analytics suffice
- [ ] No fingerprinting (font + screen + timezone re-identification)
- [ ] Sensor side channels (motion, mic, camera) reviewed for leakage
- [ ] Tracking scope matches user expectation — no creep beyond stated feature

---

## Section C: System and Compliance

### C.1 Audit Trail

- [ ] Can reconstruct any decision: data, features, model version, decision criteria
- [ ] Access to personal data is logged, not just modifications
- [ ] Records tagged with provenance (collection time, source, consent basis)
- [ ] Data subject access reports producible on request

**Reference**: `references/privacy-and-tracking/rules.md` (Rule 6)

### C.2 Retention and Cross-Border

- [ ] Retention period defined per dataset; auto-purge timers set; default is delete
- [ ] Cross-border transfers documented and GDPR/CCPA compliant
- [ ] GDPR-style standards applied globally — no two-tier privacy by jurisdiction
- [ ] Data register maintained: what, why, where, how long

**Reference**: `references/privacy-and-tracking/rules.md` (Rules 5, 7)

### C.3 Security and Incident Response

- [ ] Encrypted at rest and in transit; plaintext copies minimized
- [ ] Access controls enforce least privilege
- [ ] Incident response plan exists and was rehearsed in the last 12 months
- [ ] "What if this leaked tomorrow?" exercise run for each sensitive dataset

---

## Decision Tree: Should We Ship?

After completing the checklist, use this red-flag table to decide.

| Red Flag | Severity | Action |
|----------|----------|--------|
| Irreversible harm + ML used for the decision | BLOCKER | Do not ship; revisit with rules-based logic + human judgment |
| No appeal path for a consequential decision | BLOCKER | Do not ship; build appeal UX first |
| Right-to-erasure cannot reach backups, ML models, or third parties | BLOCKER | Do not ship; fix erasure end-to-end or remove personal data from those systems |
| Consent is bundled or revocation is harder than opt-in | BLOCKER | Do not ship; rebuild consent UX |
| Disparate impact across protected classes, no mitigation plan | BLOCKER | Do not ship; audit proxies and rebalance |
| Feedback loop unaddressed (model trains on its own outputs) | HIGH | Add control group + retraining policy before launch |
| No model card / lineage documentation | HIGH | Document before launch; required for legal challenges |
| Third-party data sharing not disclosed per purpose | HIGH | Update consent UX before launch |
| Retention period undefined or "indefinite" | MEDIUM | Define and implement auto-purge before next audit |
| No incident response rehearsal in 12 months | MEDIUM | Schedule rehearsal within 90 days of launch |

**Ship rule**: Zero BLOCKERs. All HIGH items have a dated remediation plan owned by a named person.

---

## Quick Checklist

```
[ ] A. ML systems: scope, bias, feedback loops, appeal, documentation
[ ] B. Privacy: minimization, consent, purpose limit, erasure, sharing
[ ] C. Compliance: audit trail, retention, cross-border, security, incident response
[ ] Decision tree: zero BLOCKERs; HIGHs have owners and dates
```

---

## Common Mistakes

| Mistake | Do Instead |
|---------|------------|
| Treating this as one-time pre-launch | Re-run quarterly and on major changes |
| Removing the "race" column and declaring fairness done | Audit outcome rates by class on production data |
| "We'll add appeal if users complain" | Ship appeal path on day one |
| Marking erasure done because OLTP is wiped | Trace deletion to backups, ML models, and third parties |

## Exit Criteria

- [ ] All applicable sections (A, B, C) walked through with a named reviewer
- [ ] Decision tree run; zero BLOCKERs unresolved; HIGHs have owners and dates
- [ ] Findings logged in data register / model card; next review scheduled (default 90 days)
