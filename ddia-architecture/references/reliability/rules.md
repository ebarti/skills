# Reliability Rules

Design rules for building fault-tolerant data-intensive systems.

## Core Rules

### 1. Define your fault model explicitly

Decide *which* faults the system must tolerate, and *how many* simultaneously.

- "Tolerates loss of one of three nodes" — concrete and testable.
- "Tolerates one entire availability zone going down" — concrete.
- "Tolerates everything" — meaningless; design for it accordingly.
- Anything outside the fault model is acceptable failure (document it).

### 2. Eliminate single points of failure

For every component, ask: "If this stops working, does the system stop working?"

- If yes, add redundancy or remove the dependency.
- Apply at every level: disk, server, rack, datacenter, region, dependency.
- A SPOF in any single layer defines the maximum reliability of the whole.

### 3. Tolerate hardware faults with redundancy

Add duplicates so individual hardware failures don't bring down the system.

- **Disks**: RAID configurations spread data across drives so a failed disk doesn't lose data.
- **Servers**: Dual power supplies, hot-swappable CPUs, ECC memory.
- **Datacenters**: Backup batteries, diesel generators.
- **Cross-datacenter**: Replicate across availability zones / regions to survive whole-DC loss.

### 4. Prefer software-level fault tolerance over hardware reliability

Cloud-style architectures favor distributed fault tolerance over making single machines bulletproof.

- Lets you tolerate complete outage of a machine, rack, or AZ.
- Enables rolling upgrades — patch one node at a time without downtime.
- Required at scale: at 10,000 disks you get one failure per day on average.

### 5. Account for correlated failures

Redundancy only works when faults are independent, but they often aren't.

- Same software version on every node = same bug on every node.
- Same rack = shared power, network, cooling.
- Same datacenter = shared electrical grid, weather event, fiber cut.
- Same hardware batch = same firmware bug (e.g., SSDs failing at exactly 32,768 hours).
- Use availability zones to identify what's physically co-located.

### 6. Handle software faults defensively

You can't prevent all bugs, but many small habits compound.

- Carefully think through assumptions and interactions.
- Thorough testing — both handwritten and *property testing* on random inputs.
- Process isolation so one bad process can't take down others.
- Allow processes to crash and restart cleanly (let it crash).
- Avoid feedback loops like retry storms.
- Measure, monitor, and analyze production behavior continuously.

### 7. Roll out changes gradually

Configuration and code changes are the leading cause of outages — slow them down.

- Gradual rollouts (canary, percentage-based) — catch bad changes before they hit everyone.
- Rollback mechanisms ready to revert configuration changes quickly.
- Detailed monitoring during rollout to catch regressions early.
- Pair with observability tooling for diagnosing what went wrong.

### 8. Design interfaces that encourage the right thing

Treat humans as part of the system, not as adversaries to control.

- Well-designed APIs make the right action easy and the wrong action hard.
- Sandbox / staging environments where mistakes don't affect users.
- Tools for safe rollback of any change.
- Surface dangerous operations (require confirmation, dry-run mode).

### 9. Run blameless postmortems

After an incident, encourage full disclosure without fear of punishment.

- Focus on the *sociotechnical system*, not the individual.
- Look for missing safeguards, unclear interfaces, conflicting priorities.
- "Bob should have been more careful" is not a fix.
- "We must rewrite in Haskell" is also not a fix — be suspicious of simplistic answers.
- May surface need to change business priorities or invest in neglected areas.

### 10. Apply chaos engineering to test fault tolerance

Deliberately inject faults so the recovery code paths stay exercised.

- Many critical bugs are in poor error handling — exercise those paths.
- Random process kills, network partitions, dependency outages.
- Builds confidence that real faults will be handled correctly.
- Especially valuable for fault paths that are rare in production.

### 11. Prevent (not just tolerate) for security faults

For some classes of fault, prevention is the only option.

- If an attacker exfiltrates data, that fault cannot be undone.
- Fault tolerance is about *recoverable* faults; security typically isn't recoverable.
- Apply the prevention-vs-cure distinction explicitly when designing.

## Guidelines

- At small scale, hardware redundancy may be enough; at large scale, software-level fault tolerance is mandatory.
- Don't trust availability claims — verify with chaos experiments.
- Reliability investments compete with feature work; surface this trade-off explicitly to leadership.
- Make the cost of corner-cutting visible (lost revenue, reputation, real human harm).

## Exceptions

When reliability investment may be reduced:

- **Prototype products in unproven markets**: lower reliability bar may be acceptable, *but be conscious of it and the consequences*.
- **Internal tools with low blast radius**: less aggressive fault tolerance acceptable.
- **Best-effort batch processing**: may tolerate occasional failures with retry.

## Quick Reference

| Rule | Summary |
|------|---------|
| Define fault model | Be explicit about which/how many faults you tolerate |
| Eliminate SPOFs | No component should fail the whole system |
| Hardware redundancy | RAID, dual PSU, ECC, multi-AZ |
| Software-level FT | Tolerate node loss, enable rolling upgrades |
| Account for correlation | Same code/rack/DC = correlated failures |
| Defensive software | Isolation, crash-restart, no retry storms |
| Gradual rollouts | Canary deploys + fast rollback |
| Good interfaces | Make right easy, wrong hard, dangerous explicit |
| Blameless postmortems | Fix the system, not the person |
| Chaos engineering | Inject faults so recovery code stays correct |
| Prevent security faults | Tolerance doesn't apply to data exfiltration |
