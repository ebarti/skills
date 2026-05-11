# Privacy and Tracking Examples

Real-world scenarios from DDIA and the broader literature illustrating privacy and surveillance issues — and how they could be handled differently.

## Surveillance Scenarios From the Book

### Always-On Microphones

Smartphones, smart TVs, voice assistants, baby monitors, and connected children's toys put internet-connected microphones into nearly every inhabited space — many with poor security records.

**Why it matters**: A surveillance footprint that no totalitarian regime of the past could have built, accepted voluntarily because the devices also provide value.

### Cars Tracking Drivers Without Consent

The FTC took action against General Motors for sharing drivers' precise location and driving-behavior data without consent, where that data fed into insurance pricing.

**Why it matters**: Behavioral data collected for one purpose (vehicle telemetry) flowed into life-altering decisions (insurance premiums) without the driver knowing, let alone consenting.

### Health Insurance Tied to Fitness Trackers

Insurance coverage that depends on the policyholder wearing a fitness device.

**Why it matters**: Surveillance becomes a precondition of access to a basic service — not a "free choice."

### Smartwatch Motion Sensors as Keyloggers

Motion sensors in a smartwatch or fitness tracker can be analyzed to infer what the user is typing — including passwords — with reasonable accuracy.

**Why it matters**: Sensors that *appear* benign can leak deeply sensitive data. Engineers must design assuming sensor outputs may be combined and inferred from in unexpected ways.

## "Innocuous" Data Combined to Identify Individuals

### Ad-Targeting as Indirect Disclosure

A company says "we don't sell raw data — we just let advertisers target a group like 'people interested in diabetes products.'" Even if no individual is named, the user has lost the right to decide who knows about their condition.

**Problem**: Privacy was *transferred* to the company, not preserved. The company exercises the disclosure right on the user's behalf, optimizing for ad revenue.

### Browser Fingerprinting

Combining font list, screen resolution, installed plugins, timezone, and language can uniquely identify a browser without any cookie.

**Problem**: Each attribute is "innocuous" alone, but the combination is a stable identifier that survives clearing cookies.

### Re-identification of "Anonymized" Datasets

Anonymized location traces, search histories, and viewing data have been repeatedly re-identified by joining with public records.

**Problem**: Anonymization is a much weaker guarantee than it appears once data is rich enough to be cross-referenced.

## Right-to-Erasure Across Distributed Systems

The book emphasizes that derived datasets — combining data from many users with behavioral tracking and external sources — are precisely the data that users cannot meaningfully understand or control. Deletion is correspondingly hard.

### Hard Cases

| System | Why deletion is hard | Approach |
|--------|---------------------|----------|
| Backups | Often immutable, retention-bound | Document retention, use crypto-shredding |
| Append-only event logs | Cannot edit history | Encrypt per-user, delete the key |
| Search indexes | Eventually consistent, denormalized | Treat as tier-1 system; propagate deletes |
| Aggregated metrics | Already mixed with other users' data | Acceptable if truly aggregated and not re-identifiable |
| ML model weights | Personal data baked into parameters | Retrain or use machine-unlearning techniques |
| Third-party processors | Outside your direct control | Contractual obligations + audit |

### Bad Pattern

```
DELETE FROM users WHERE id = 42;
-- Done!
```

User data still lives in: replicas, daily backups (90-day retention), the analytics warehouse, the recommendation model trained last week, three SaaS analytics tools, the customer support tool, the email service provider, and several event log topics.

### Good Pattern

A documented erasure runbook that:
1. Marks the user record as pending deletion
2. Cascades deletes through OLTP, caches, search indexes
3. Triggers deletion APIs on every third-party processor
4. Tombstones in event logs and runs key shredding
5. Schedules backup expiry and confirms the user's data is gone after the retention window
6. Excludes the user from the next training run
7. Records the deletion in an audit log

## Companies, Laws, and Scandals Mentioned

| Reference | What it illustrates |
|-----------|---------------------|
| GDPR (EU, 2016) | Legal definition of valid consent; data minimization and purpose limitation principles |
| CCPA / state laws | US-side analogues to GDPR |
| GM / FTC action (2025) | Cars sharing precise location and driving behavior without consent |
| Data brokers | Industry that buys, aggregates, analyzes, and resells personal data, mostly for marketing |
| Bankruptcy data sales | Personal data is among the assets sold when a company fails |
| Government data demands | States seeking data via legal compulsion, secret deals, coercion, or theft |
| Schneier — "Data is a toxic asset" | Framing of data as liability |
| Pesce — "Data is the new uranium" | Powerful but hazardous |
| Schneier — "Poor civic hygiene" quote | On building infrastructure that could enable a future police state |

## Consent UX: Done Well vs Done Poorly

### Done Poorly

```
[A 40-page privacy policy in legal language]

[Banner]: "We use cookies to improve your experience."
   [Accept All]   [Manage Preferences]
                       ^ buried 3 levels deep,
                         all toggles default to ON
```

**Problems**:
- "Accept all" is one click; rejection is many clicks (asymmetric friction)
- Pre-ticked boxes — explicitly disallowed by GDPR
- Vague ("improve your experience") and not specific
- No simple revocation
- Continued use treated as consent

### Done Well

```
[Banner]: "We'd like your consent for the following:"

[ ] Strictly necessary cookies (always on, no consent needed)
[ ] Analytics — helps us understand usage. Anonymized.
[ ] Personalization — tailors content to you.
[ ] Advertising — shares data with ad partners.
   [Accept Selected]   [Reject All]   [Save Preferences]

You can change these any time at /privacy. Refusing has no
effect on your access to the service.
```

**Why it works**:
- Each purpose is separate and specific
- "Reject all" is as easy as "accept"
- No pre-ticking
- Clear that refusal has no detriment
- Easy and visible revocation path

## Refactoring Walkthrough: A Recommendation Pipeline

### Before

- Logs every click, scroll, and mouse position from every user
- Joins behavioral data with third-party data broker enrichment
- Trains a personalization model and a separate model sold to advertisers
- 7-year retention "just in case"
- Single ToS checkbox covers all of the above
- "Delete my account" only marks the user inactive

### After

- Logs only the events the recommendation model demonstrably needs (validated via ablation)
- Drops third-party enrichment; uses on-device or first-party signals
- Personalization model trained per-user with opt-in; advertising use removed or separately consented
- 90-day retention with automated purge; aggregated metrics kept longer
- Granular per-purpose consent with easy revocation
- Delete request triggers full cascade including model retraining schedule

### Changes Made

1. **Minimization**: Removed events with no demonstrated value
2. **Purpose separation**: One model per purpose, each with its own consent
3. **Retention**: Shortened, automated, default-delete
4. **Consent UX**: Granular, symmetric, revocable
5. **Erasure**: End-to-end propagation, including derived data
