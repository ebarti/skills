# Choosing Cloud vs Self-Hosted Workflow

Decide where a system should run by scoring requirements against cloud and self-hosted strengths, then documenting the tradeoffs.

## When to Use

- Greenfield system: picking initial deployment target.
- Migration decision: moving an existing system to or from the cloud.
- New workload added to an existing platform with mixed deployment options.

## Prerequisites

- Stakeholder access (product, ops, security/compliance, finance).
- Rough load profile (baseline + peak) and growth projection.
- Known compliance, sovereignty, and latency constraints.

**Reference**: `references/cloud-vs-self-hosted/rules.md`, `references/cloud-vs-self-hosted/knowledge.md`

---

## Workflow Steps

### Step 1: Gather Requirements

**Goal**: Capture the inputs that drive the cloud-vs-self-hosted tradeoff.

- [ ] Document load profile: baseline RPS/QPS, peak, peak/baseline ratio, burstiness.
- [ ] Document dataset size today and 12-month projection.
- [ ] Document hard latency targets (p50/p99) and any hardware-specific needs (GPU, RDMA, custom NICs).
- [ ] List compliance, sovereignty, and data-residency constraints (GDPR, HIPAA, sector-specific, country-specific).
- [ ] Capture budget shape: capex tolerance vs opex preference, expected horizon.
- [ ] Inventory team skills: do you already operate this class of system?

**Ask**: "Which of these requirements are non-negotiable vs nice-to-have?"

**Reference**: `references/cloud-vs-self-hosted/rules.md` (Rules 1-8)

---

### Step 2: Score Against Cloud Strengths

**Goal**: Quantify how well cloud fits the requirements.

- [ ] Peak/baseline ratio > 3x or load is bursty/unpredictable -> +cloud.
- [ ] Team lacks operational expertise for the system -> +cloud.
- [ ] Need rapid scale-up/scale-down or short time-to-market -> +cloud.
- [ ] Workload is commodity (not a competitive differentiator) -> +cloud.
- [ ] Higher-level managed service exists that matches the use case -> +cloud.
- [ ] Dataset and operations small enough that idle compute is cheap -> neutral.

**Ask**: "Is this a core competency or routine plumbing?"

**Reference**: `references/cloud-vs-self-hosted/rules.md` (Rules 1, 3, 4, 13)

---

### Step 3: Score Against Self-Hosted Strengths

**Goal**: Quantify how well self-hosting fits the requirements.

- [ ] Load is predictable and steady (machine count stable) -> +self-host.
- [ ] Team already operates this system class with depth -> +self-host.
- [ ] Hard latency target needs full hardware control (e.g., HFT) -> +self-host.
- [ ] Hardware-specific dependencies cloud cannot offer -> +self-host.
- [ ] Regulatory/sovereignty/trust constraints exclude the provider -> +self-host.
- [ ] Vendor lock-in risk (no compatible alt API, geopolitical exposure) is unacceptable -> +self-host.
- [ ] Workload is a strategic differentiator worth tuning -> +self-host.

**Ask**: "What requirement, if cloud cannot meet it, is a deal-breaker?"

**Reference**: `references/cloud-vs-self-hosted/rules.md` (Rules 1, 2, 5, 6, 7, 8)

---

### Step 4: Decide (Cloud, Self-Host, or Hybrid)

**Goal**: Pick a deployment posture from the scores in Steps 2-3.

**If cloud strengths clearly dominate**:
- [ ] Choose managed cloud service at the highest abstraction that fits.
- [ ] If designing new: separate storage from compute; build on object storage, not virtual block devices.
- [ ] Plan quotas, cost monitoring, and a vendor-exit strategy.

**If self-hosted strengths clearly dominate**:
- [ ] Choose on-prem or dedicated hardware; lift-and-shift to IaaS only as a transitional step.
- [ ] Confirm operational staffing and runbooks exist.

**If neither dominates (mixed scores or conflicting constraints)**:
- [ ] Split the system: keep the constrained/differentiating part self-hosted; put commodity/bursty parts in cloud.
- [ ] Define the boundary: which data crosses, what latency budget, what failure modes.
- [ ] Verify the hybrid does not double operational burden without payoff.

**Reference**: `references/cloud-vs-self-hosted/rules.md` (Rules 9-13, Exceptions); `references/operational-vs-analytical/rules.md` for storage choice (OLTP vs OLAP layout differs).

---

### Step 5: Document the Decision

**Goal**: Record the criteria, the chosen posture, and the tradeoffs accepted so the decision is auditable.

- [ ] Write a short ADR (Architecture Decision Record) capturing:
  - Requirements from Step 1 (load, latency, compliance, budget, skills).
  - Scoring summary from Steps 2-3.
  - Chosen posture (cloud / self-host / hybrid) and the boundary if hybrid.
  - Rejected alternatives and why.
  - Tradeoffs accepted (e.g., vendor lock-in, capex, operational load).
  - Triggers that would force re-evaluation (load grows 10x, regulation changes, vendor exits market).
- [ ] Circulate to product, ops, security, finance for sign-off.
- [ ] Store in the team's decision log.

---

## Decision Tree

```
Start
  |
  v
Hard latency / custom hardware / sovereignty deal-breaker?
  | yes -> SELF-HOST (or sovereign cloud)
  | no
  v
Load predictable AND team has deep ops skill for this system?
  | yes -> SELF-HOST is likely cheaper
  | no
  v
Load bursty OR peak/baseline > 3x OR no in-house ops skill?
  | yes -> CLOUD (managed service at highest fitting abstraction)
  | no
  v
Mixed signals (some constraints favor each)?
  | yes -> HYBRID: self-host the constrained part, cloud the rest
  | no  -> Default to CLOUD; revisit if cost or lock-in becomes a problem
```

---

## Quick Checklist

```
[ ] Step 1: Requirements gathered (load, latency, compliance, budget, skills)
[ ] Step 2: Scored against cloud strengths
[ ] Step 3: Scored against self-hosted strengths
[ ] Step 4: Posture chosen (cloud / self-host / hybrid)
[ ] Step 5: ADR written and signed off
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Assuming cloud is always cheaper | False for predictable load with in-house skill; idle capacity in self-host can still beat per-second cloud billing | Score against Rule 2 before defaulting to cloud |
| Lift-and-shift and call it cloud-native | Misses elasticity, durability, and scale benefits; you pay cloud prices for on-prem architecture | Redesign to separate storage from compute, build on object storage |
| Ignoring vendor lock-in until renewal time | Forced migration when vendor shuts down, raises price, or removes a feature | Treat lock-in as a first-class risk in Step 4; prefer compatible APIs; plan an exit |
| Treating local instance disks as durable | Data loss when instance fails or is resized | Store durable state in object storage / managed storage service |
| Skipping ops planning because "cloud handles it" | Customer-side ops (cost, security, integration, quotas) is still required | Staff for DevOps/SRE; plan quotas and cost monitoring up front |
| Choosing low-level building blocks when a SaaS fits | More code, more ops, slower delivery for no benefit | Pick the highest abstraction that matches the use case |
| Hybrid by accident | Doubles operational burden without a clear boundary | Only adopt hybrid when Step 4 shows mixed scores; define the boundary explicitly |

---

## Exit Criteria

Decision is complete when:
- [ ] Requirements (load, latency, compliance, budget, skills) are documented.
- [ ] Cloud and self-hosted scoring is recorded.
- [ ] A posture is chosen: cloud, self-host, or hybrid (with boundary defined).
- [ ] Tradeoffs accepted and re-evaluation triggers are written into the ADR.
- [ ] Stakeholders (product, ops, security, finance) have signed off.
