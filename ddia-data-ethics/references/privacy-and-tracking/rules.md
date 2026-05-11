# Privacy and Tracking Rules

Privacy-by-design rules for engineers, designers, and product managers building systems that handle personal data.

## Core Rules

### 1. Collect the Minimum Data Needed for the Stated Purpose

If you don't *need* it for the feature, don't collect it. Data you don't have can't be leaked, stolen, subpoenaed, or repurposed.

- Default every new field, event, or log line to *off*; require justification to add it
- Tie every collected attribute to a specific, documented purpose
- Aggregate or sample where possible instead of storing raw records

**Example**:
```
// Bad
log.event("page_view", {
  user_id, session_id, ip, user_agent, referrer,
  screen_size, mouse_path, scroll_depth, timestamp_ms,
  ... // collect everything, decide later
});

// Good
log.event("page_view", { page_id, anonymized_user_bucket });
// Only fields needed by the analytics use case
```

### 2. Make Consent Granular, Specific, and Revocable

A single "I agree to everything" checkbox is not consent. Users must be able to choose per-purpose and change their minds without penalty.

- Separate consent for each distinct purpose (analytics, ads, personalization, third parties)
- Provide a one-click revocation path that is as easy as opting in
- No pre-ticked boxes, no dark patterns, no "reject all" buried three menus deep
- Treat continued use as not equivalent to consent

### 3. Don't Repurpose Data Beyond the Original Consent

Data collected for one purpose ("show you order status") cannot silently be used for another ("train an ML model" or "sell to brokers").

- New uses require new consent, not buried ToS updates
- Build access controls scoped by purpose, not just by team
- Audit data flows for "purpose creep"

### 4. Implement Right-to-Erasure End-to-End

Deletion must propagate everywhere personal data lives — not just the primary database.

- Production OLTP stores
- Read replicas, caches, search indexes
- Derived datasets, aggregates, materialized views
- Backups and snapshots (or document the retention window clearly)
- Event logs and immutable streams (use crypto-shredding if logs cannot be edited)
- ML training datasets and models trained on user data
- Third-party processors and analytics partners

If you cannot delete from a system, do not put personal data in it.

### 5. Treat Data as a Liability, Not Just an Asset

Every record you store is a potential breach, subpoena, or scandal. Inventory the risks alongside the value.

- Maintain a data register: what you hold, why, where, retention period
- Set automatic purge timers; default to delete, not retain
- Encrypt at rest and in transit; minimize plaintext copies
- Run a "what if this leaked tomorrow" exercise for each dataset

### 6. Build for Auditability and Explainability

You should be able to answer, for any individual: what data do we have, where did it come from, who accessed it, and why?

- Log access to personal data, not just modification
- Tag records with provenance (collection time, source, consent basis)
- Be able to produce a data subject access report on request

### 7. Apply GDPR-Style Standards Globally

GDPR, CCPA, and similar laws set a useful floor. Apply them to all users, not just users in regulated jurisdictions.

- Avoid building two-tier systems where EU users get rights and others don't
- Future regulation is likely; designing for the higher bar is cheaper than retrofitting
- It is also the right thing to do regardless of jurisdiction

## Guidelines

Less strict but still important:

- **Question every new tracking event** in code review — "What decision does this enable? Could we make it without this?"
- **Prefer privacy-preserving alternatives**: differential privacy, on-device processing, federated learning, aggregated metrics
- **Avoid third-party tracking SDKs** when first-party analytics will do
- **Watch for fingerprinting**: combining "innocuous" attributes (font list, screen size, timezone) can re-identify users
- **Watch out for sensor side channels**: motion sensors, microphones, and cameras can leak far more than they appear to
- **Document the human cost** when data is used to make decisions about people (insurance, employment, credit)

## Exceptions

When these rules may be relaxed:

- **Legal obligations**: Some retention is mandated (financial records, fraud reporting). Document the basis.
- **Vital interests**: Processing to protect life (emergency services, safety) has a separate lawful basis under GDPR.
- **Aggregated public-good research**: Where data is properly anonymized, aggregated, and the use is transparent. Be skeptical: re-identification of "anonymized" data is often easier than expected.

In all cases, document *which* exception applies and *why* — never default to it.

## Quick Reference

| Rule | Summary |
|------|---------|
| Minimize collection | Don't collect what you don't need |
| Granular consent | Per-purpose, easy to revoke, no dark patterns |
| Purpose limitation | Original consent only, no silent repurposing |
| End-to-end erasure | Delete from backups, derived data, models too |
| Data as liability | Inventory risk, set retention, encrypt |
| Auditability | Know what you have, where, who touched it |
| Apply GDPR everywhere | Don't build two-tier privacy by jurisdiction |
