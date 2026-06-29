# Keywords & Crossover Examples

Worked examples of extracting `ats_keywords[]` and building a `crossover_terms` map from a JD — plus a good mirroring example vs. bad over-cloning.

## Sample Job Description (excerpt)

> **Outside Sales Representative.** Drive new B2B revenue and hit quarterly quota.
> Manage the full sales cycle using Salesforce CRM. Build relationships with key
> decision makers and improve client retention. Required: 3+ yrs outside sales,
> CRM proficiency. Preferred: HubSpot, territory planning, SaaS background.

## Extracted `ats_keywords[]`

```
ats_keywords:
  must_have:
    - "Outside Sales Representative"   # title — mirror as objective header
    - "B2B"
    - "quota"                          # outcome term
    - "sales cycle"
    - "Salesforce CRM"                 # exact tool
    - "client retention"               # outcome term
    - "key decision makers"            # how they label people
  nice_to_have:
    - "HubSpot"
    - "territory planning"
    - "SaaS"
```

**Why grouped this way**: title, hard tools (Salesforce CRM), and outcome terms (quota, retention) are must-have and mirrored verbatim; preferred items are nice-to-have.

## `crossover_terms` Mapping Table

Built from a candidate whose background is **retail operations management** targeting this sales role. Each row maps a JD term to a *truthful* equivalent.

| Their term (JD) | Candidate's equivalent | Proof / source |
|-----------------|------------------------|----------------|
| Outside Sales Representative | Outside Sales Representative (objective header) | Mirror exactly; held sales-adjacent role |
| B2B revenue / quota | Drove $1.2M wholesale account revenue | Ran key vendor accounts in retail ops |
| Sales cycle | Managed end-to-end account lifecycle | Sourcing → close → renewal |
| Salesforce CRM | Salesforce CRM | Used daily for pipeline tracking |
| Client retention | Lifted account retention 18% | Reduced churn on top accounts |
| Key decision makers | Key decision makers | Negotiated with regional buyers |
| Territory planning | Multi-store regional coverage | Planned coverage across 6 sites |

Gap left honest: candidate has no SaaS background → **no row** rather than a faked one.

## Good vs. Bad

### Good — Mirroring (truthful, flowing, proven)

```
Areas of Expertise: B2B Sales | Salesforce CRM | Quota Attainment | Client Retention

Experience:
- Drove $1.2M in B2B revenue, exceeding quota by 14%, with full sales-cycle
  ownership in Salesforce CRM.
- Lifted client retention 18% by deepening relationships with key decision makers.
```

**Why it works**:
- Mirrors exact must-have terms (B2B, Salesforce CRM, quota, client retention, key decision makers).
- Each term is *proven* with an outcome, not just listed.
- Crossover-translated retail proof into sales vocabulary — facts unchanged.
- Reads naturally; terms flow.

### Bad — Over-Cloning / Keyword Stuffing

```
Areas of Expertise: Outside Sales Representative, Outside Sales, B2B, B2B revenue,
sales cycle, full sales cycle, Salesforce, Salesforce CRM, CRM, HubSpot, SaaS, SaaS
background, territory, territory planning, quota, quarterly quota, retention, client
retention, key decision makers, decision makers, relationships...

Experience:
- Outside Sales Representative driving B2B revenue with SaaS HubSpot territory quota
  Salesforce CRM client retention key decision makers.
```

**Problems**:
- Copies the ad wholesale and repeats variants (Salesforce / Salesforce CRM / CRM).
- Claims **HubSpot** and **SaaS** the candidate never used — fabrication.
- Keyword wall; no proof, no outcomes, unreadable.
- Nothing here is interview-defendable.

## Before → After (one bullet)

### Before (candidate's core, retail wording)
```
- Oversaw store operations and vendor relationships across the region.
```

### After (crossover into the JD's terms)
```
- Managed the full account lifecycle for regional vendors in Salesforce CRM,
  driving B2B revenue and lifting client retention 18%.
```

### Changes Made
1. "vendor relationships" → "account lifecycle ... B2B revenue" (mirrors JD's sales-cycle/B2B terms).
2. Surfaced **Salesforce CRM** explicitly (must-have tool the candidate genuinely used).
3. Added the **client retention** outcome with a metric — proves the term, doesn't just list it.
