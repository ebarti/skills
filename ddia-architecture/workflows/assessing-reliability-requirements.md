# Assessing Reliability Requirements Workflow

Define a fault model, identify SPOFs across hardware/software/human dimensions, and map each to a concrete mitigation.

## When to Use

- Designing a new data-intensive system or service
- Reviewing an existing system before scaling, regulatory audit, or incident-triggered re-design
- Producing an SLO/SLA proposal that requires defending an availability number
- Onboarding a new on-call team and validating runbooks against real fault scenarios

## Prerequisites

- Knowledge of system architecture (components, dependencies, deployment topology)
- Access to incident history / postmortems (if any)
- Stakeholder agreement on cost-vs-reliability trade-offs

**Reference**: `references/reliability/rules.md`, `references/reliability/knowledge.md`

---

## Workflow Steps

### Step 1: Define the availability target

**Goal**: Pin a concrete, testable SLO that every later decision flows from.

- [ ] Pick an availability number (99%, 99.9%, 99.99%)
- [ ] Translate to allowed downtime/year (99.9% = 8.76 hr; 99.99% = 52.6 min)
- [ ] Document scope: which endpoints, which user actions, which time window
- [ ] Confirm cost is acceptable to stakeholders (each "9" is ~10x more expensive)

**Ask**: "Is this number defensible against our incident history, or is it aspirational?"

**Reference**: `references/reliability/rules.md` (Rule 1: Define your fault model explicitly)

---

### Step 2: Enumerate hardware fault scenarios

**Goal**: List physical-layer faults the system must survive.

- [ ] Disk failure (single disk, RAID rebuild window, full-node disk loss)
- [ ] RAM failure (ECC errors, full RAM exhaustion)
- [ ] Network failure (NIC, switch, partition between racks/AZs)
- [ ] Power failure (single PSU, rack PDU, full datacenter)
- [ ] Datacenter / AZ / region loss (fiber cut, weather event, fire)
- [ ] At >1000 nodes: assume daily disk failure as baseline

**Reference**: `references/reliability/rules.md` (Rules 3, 5)

---

### Step 3: Enumerate software fault scenarios

**Goal**: List software-layer faults — usually correlated, usually dominant.

- [ ] Application bugs (logic errors, unhandled exceptions, infinite loops)
- [ ] Resource exhaustion (OOM, file descriptors, thread pool, connection pool)
- [ ] Edge-case triggers (leap seconds, timezone shifts, integer overflow, year-2038)
- [ ] Dependency outages (DB, cache, queue, third-party API)
- [ ] Cascading failures (retry storms, thundering herd, slow-shutdown deadlock)
- [ ] Deserialization / format faults (poison pill messages, malformed input)

**Reference**: `references/reliability/rules.md` (Rule 6)

---

### Step 4: Enumerate human fault scenarios

**Goal**: List operator-driven faults — the leading cause of outages in large services.

- [ ] Bad deploy (config typo, regression, missed migration)
- [ ] Misconfiguration (wrong env var, swapped credentials, prod-vs-staging mix-up)
- [ ] Destructive command (accidental DROP, rm -rf, force-push)
- [ ] Capacity miscalculation (under-provisioned, missed seasonality)
- [ ] Runbook drift (instructions out of date, untested recovery steps)

**Reference**: `references/reliability/rules.md` (Rules 7, 8, 9)

---

### Step 5: Map SPOFs to mitigations

**Goal**: For every component, decide whether its fault becomes a system failure — and if so, fix it.

- [ ] For each component, ask: "If this stops, does the system stop?"
- [ ] List every yes-answer as a SPOF
- [ ] Pick a redundancy strategy per fault type (see Decision Tree below)
- [ ] Verify mitigations don't share correlated failure modes (same rack, same code version, same vendor batch)
- [ ] Document remaining accepted-risk SPOFs explicitly

**Reference**: `references/reliability/rules.md` (Rules 2, 5)

#### Decision Tree: Pick Redundancy Strategy by Fault Type

```
Fault type?
├── Single disk        → RAID (within node)
├── Single node        → Replicate to N nodes (in same AZ)
├── Single rack/AZ     → Multi-AZ deployment + cross-AZ replication
├── Single region      → Multi-region (active/passive or active/active)
├── Software bug       → Gradual rollout + canary + fast rollback
├── Dependency outage  → Circuit breaker + degraded mode + caching
├── Human config error → Sandbox + dry-run + confirmation + audit log
└── Security breach    → PREVENT (fault tolerance does not apply)
```

---

### Step 6: Plan chaos testing and fault injection

**Goal**: Continuously exercise recovery paths so they don't bit-rot.

- [ ] Pick faults from Steps 2-4 to inject regularly
- [ ] Start in staging; promote to production once confidence is high
- [ ] Schedule game days (quarterly minimum)
- [ ] Automate where safe (random pod kills, network latency injection)
- [ ] Track which fault scenarios have NEVER been tested live — those are unknowns

**Reference**: `references/reliability/rules.md` (Rule 10)

---

### Step 7: Define on-call procedures and runbooks

**Goal**: Make recovery a human-feasible operation, not a heroics exercise.

- [ ] Write a runbook per top-N fault scenario
- [ ] Verify each runbook by executing it (in staging or a game day)
- [ ] Define on-call rotation, escalation policy, paging thresholds
- [ ] Schedule blameless postmortem template + cadence
- [ ] Connect monitoring alerts to specific runbook sections

**Reference**: `references/reliability/rules.md` (Rules 8, 9); `references/maintainability/rules.md` (operability)

---

## Quick Checklist

```
[ ] Step 1: Availability target defined with downtime budget
[ ] Step 2: Hardware fault scenarios enumerated
[ ] Step 3: Software fault scenarios enumerated
[ ] Step 4: Human fault scenarios enumerated
[ ] Step 5: SPOFs mapped to mitigations (decision tree applied)
[ ] Step 6: Chaos test plan exists and is scheduled
[ ] Step 7: Runbooks written and verified, on-call rotation defined
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Skipping the explicit fault model | "We tolerate everything" = nothing testable; design becomes wishful thinking | Pick concrete faults: "loses one of three nodes", "loses one AZ" |
| No chaos testing | Recovery code paths bit-rot — run for the first time during a real incident | Inject faults regularly in staging, then production game days |
| Blind retry of non-idempotent operations | Retry storms duplicate writes, double-charge, double-send | Make ops idempotent OR use exponential backoff + circuit breakers |
| Same software version everywhere | A bug becomes a correlated, fleet-wide failure | Stagger rollouts, use canaries, keep last-known-good ready |
| Single-AZ "redundancy" | AZ-wide power/network event takes out all replicas | Spread replicas across AZs (and regions for higher tiers) |
| Treating "human error" as root cause | Blame stops the investigation; the systemic fix is missed | Blameless postmortem; fix the interface/sandbox/process |
| Counting SPOFs only at the app layer | DB, DNS, secret store, CI/CD, identity provider are all candidates | Walk every dependency including infrastructure |
| Ignoring correlated failures in capacity | "We have 3x capacity" but all 3x lives in one rack | Reserve capacity assuming worst correlated outage occurs |

---

## Exit Criteria

Task is complete when:

- [ ] Availability target is documented with a downtime budget and stakeholder sign-off
- [ ] Fault model lists tolerated faults explicitly (and out-of-scope faults are named)
- [ ] Every identified SPOF either has a mitigation, an accepted-risk note, or a planned remediation ticket
- [ ] At least one chaos experiment has run successfully in staging
- [ ] On-call rotation is staffed and runbooks are tested

---

## Related References

- `references/reliability/rules.md` — design rules for fault tolerance
- `references/reliability/knowledge.md` — fault/failure/SPOF concepts
- `references/maintainability/rules.md` — operability and runbooks
- `references/scalability/rules.md` — scale increases fault frequency; reliability becomes mandatory
