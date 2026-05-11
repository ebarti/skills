# Reliability Knowledge

Core concepts for reliability and fault tolerance in data-intensive systems.

## Overview

Reliability means "continuing to work correctly, even when things go wrong." A reliable system performs its expected function under load, tolerates user mistakes, and prevents unauthorized access. Reliability is achieved by tolerating faults so they don't escalate into user-visible failures.

## Key Concepts

### Fault vs Failure

**Fault**: A particular *part* of a system stops working correctly (e.g., a single hard drive malfunctions, a single machine crashes, an external dependency has an outage).

**Failure**: The system *as a whole* stops providing the required service to the user — i.e., it does not meet its SLO.

**Key points**:
- Fault and failure are the same kind of event at different levels of the system.
- A drive "failing" is a fault from the perspective of a multi-disk system.
- Fault tolerance is about preventing faults from cascading into system-wide failures.

### Fault Tolerance

**Definition**: A system is *fault-tolerant* if it continues providing the required service in spite of certain faults occurring.

**Key points**:
- Always limited to a *certain number* and *certain types* of faults (e.g., "tolerates two disk failures" or "one of three nodes crashing").
- Tolerating arbitrary faults (e.g., entire planet destroyed) is impossible — define the fault model explicitly.
- A part the system cannot tolerate becoming faulty is a *single point of failure* (SPOF).

### Single Point of Failure (SPOF)

**Definition**: A component whose fault escalates directly to a failure of the whole system.

Eliminating SPOFs is the primary structural goal of reliability work.

### Redundancy

**Definition**: Adding duplicate components so that the failure of one doesn't take down the system.

**Key points**:
- Most effective when component faults are *independent*.
- In practice, faults are often *correlated* (whole rack, whole datacenter, whole software version).
- Forms: RAID disks, dual power supplies, hot-swappable CPUs, backup generators, replicated nodes across availability zones.

### Categories of Faults

| Category | Independence | Typical Mitigation |
|----------|--------------|-------------------|
| Hardware | Mostly independent (weakly correlated) | Redundancy, hot-swap, multi-AZ |
| Software | Highly correlated (same code, same bug everywhere) | Slow rollout, monitoring, isolation |
| Human | Variable; configuration changes dominate outages | Good interfaces, sandboxes, blameless postmortems |

### Hardware Faults

**Definition**: Failures of physical components — disks, SSDs, RAM, CPUs, power supplies, datacenters.

**Key points**:
- Mostly *independent* — one disk failing doesn't usually mean the next one will.
- Correlations still exist (whole rack, whole datacenter, batch of bad hardware).
- At small scale: rare events. At large scale: part of normal operation.

### Software Faults

**Definition**: Bugs, runaway processes, dependency failures, emergent interactions, or cascading failures triggered by the *software* the system runs.

**Key points**:
- *Highly correlated* — same code on every node means the same bug on every node.
- Often dormant until triggered by an unusual circumstance that violates an implicit assumption.
- Cause more system failures than uncorrelated hardware faults.

### Human Errors

**Definition**: Mistakes made by humans designing, operating, or configuring the system.

**Key points**:
- Configuration changes by operators are the *leading cause* of outages in studies of large internet services.
- Hardware faults play a role in only 10-25% of cases.
- "Human error" is a *symptom* of a sociotechnical system problem, not a root cause.

### Fault Injection / Chaos Engineering

**Definition**: Deliberately *increasing* the rate of faults (e.g., randomly killing processes) to continuously exercise fault-tolerance machinery.

**Key points**:
- Many critical bugs come from poor error handling.
- Code paths that are rarely executed in production are often broken.
- *Chaos engineering* is the discipline of running fault-injection experiments to build confidence in fault-tolerance mechanisms.

### Rolling Upgrade

**Definition**: Patching or upgrading a multi-node system one node at a time, without downtime.

Operational benefit of fault tolerance — single-node systems require planned downtime; fault-tolerant ones don't.

## Terminology

| Term | Definition |
|------|------------|
| Fault | A part of the system stops working correctly |
| Failure | The whole system stops meeting its SLO |
| SPOF | A component whose fault becomes a system failure |
| Redundancy | Duplicate components to absorb individual faults |
| Availability zone | Cloud-provider grouping of physically co-located resources |
| Rolling upgrade | Patching one node at a time without service downtime |
| Fault injection | Deliberately triggering faults to test recovery |
| Chaos engineering | Discipline of fault-injection experiments |
| Blameless postmortem | Post-incident review focused on systemic causes, not individual blame |
| Exactly-once semantics | Property where work is neither lost nor duplicated despite faults |

## How It Relates To

- **Performance**: Reliability constrains how aggressive you can be with load shedding and timeouts.
- **Scalability**: Larger systems experience faults more frequently — fault tolerance becomes mandatory at scale.
- **Maintainability**: Rolling upgrades and observability tooling are both reliability and maintainability concerns.
- **Distributed systems**: Replication, consensus, and exactly-once semantics (covered in later chapters) are the building blocks of fault tolerance.

## Common Misconceptions

- **Myth**: A reliable system never fails.
  **Reality**: It tolerates a defined set of faults; everything else can still cause failure.

- **Myth**: Hardware failures are the main cause of outages.
  **Reality**: Software bugs and human configuration errors dominate; hardware is 10-25% in large internet services.

- **Myth**: Redundancy guarantees independence of faults.
  **Reality**: Faults are often correlated (same software, same rack, same datacenter, same bad batch).

- **Myth**: "Human error" is a root cause.
  **Reality**: It's a symptom of a sociotechnical system; blame is counterproductive.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Fault | Local malfunction of a component |
| Failure | System-wide loss of service |
| Fault tolerance | Surviving a defined set of faults without failure |
| SPOF | Component whose fault = system failure |
| Redundancy | Duplicates to absorb faults |
| Chaos engineering | Inject faults to test recovery paths |
| Blameless postmortem | Learn from incidents without scapegoating |
