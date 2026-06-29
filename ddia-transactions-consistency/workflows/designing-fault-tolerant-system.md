# Designing a Fault-Tolerant Distributed System Workflow

A step-by-step process for designing a distributed system that survives realistic failures of network, time, and node behavior.

## When to Use

- Designing a new distributed service, replicated store, or coordination layer
- Reviewing an existing system for fault-tolerance gaps
- Hardening a system after an incident caused by a partition, pause, or zombie writer

## Prerequisites

- Functional requirements and SLAs (RTO, RPO, target availability)
- Knowledge of which operations require strong agreement vs. eventual convergence
- Access to chaos / fault injection tooling (or willingness to add it)

**References**: `references/distributed-failures/rules.md`, `references/distributed-time/rules.md`, `references/distributed-truth/rules.md`, `references/consensus/rules.md`, `references/linearizability/rules.md`

---

## Workflow Steps

### Step 1: Pick a System Model

**Goal**: State the timing and node-behavior assumptions explicitly so the rest of the design can be checked against them.

- [ ] Choose timing model: **synchronous** (rare), **partially synchronous** (default), or **asynchronous**
- [ ] Choose node-behavior model: **crash-stop**, **crash-recovery** (default), or **Byzantine** (only if adversarial / safety-critical)
- [ ] Document the chosen model in the design doc
- [ ] Add a `printf-and-exit` handler for any assumed-impossible fault

**Ask**: "What is the weakest model my environment actually satisfies?"

**Reference**: `references/distributed-truth/rules.md` (Rule 8)

---

### Step 2: Enumerate Failure Modes

**Goal**: Make the failure surface explicit before designing mitigations.

- [ ] Network: lost packets, asymmetric partition, slow link, duplicate delivery
- [ ] Nodes: crash, slow / fail-slow ("limping"), restart with stale state
- [ ] Time: clock skew, NTP step, monotonic clock unaffected by NTP
- [ ] Process: GC pause, VM steal time, SIGSTOP, swap thrash
- [ ] Storage: bit rot, fsync lies, partial writes, silent corruption

**Reference**: `references/distributed-failures/rules.md`, `references/distributed-time/rules.md` (Rule 4)

---

### Step 3: Classify Each Failure: Survive / Detect / Accept

**Goal**: Decide the response policy for each failure rather than dealing with each ad hoc in production.

- [ ] **Survive** (transparent): replication, retries, idempotency, quorum reads
- [ ] **Detect** (degrade gracefully): heartbeats, phi-accrual, circuit breakers, alerts
- [ ] **Accept** (out of scope): document as known risk with bounded blast radius

**Ask**: "What is my failure budget — which faults blow the SLA?"

**Reference**: `references/distributed-failures/rules.md` (Rules 4, 5)

---

### Step 4: Design Quorum / Consensus Where Strong Agreement Is Needed

**Goal**: Use voting (not single-node opinion) for any decision that must be globally unique or ordered.

- [ ] Identify operations needing linearizability or single-leader semantics
- [ ] Pick consensus algorithm (Raft, Multi-Paxos, Viewstamped Replication) or off-the-shelf (etcd, ZooKeeper)
- [ ] Size cluster for tolerated failures: `n = 2f + 1` (3→1, 5→2, 7→3)
- [ ] Confirm absolute majority (`> n/2`) is required for any commit

**Reference**: `references/consensus/rules.md`, `references/linearizability/rules.md`, `references/distributed-truth/rules.md` (Rule 1)

---

### Step 5: Add Fencing Tokens to ALL Distributed Locks/Leases

**Goal**: Prevent zombie holders (paused / partitioned / delayed) from corrupting data after their lease expires.

- [ ] Every lock acquisition returns a monotonically increasing token
- [ ] Every protected operation carries the token to the storage layer
- [ ] **Storage rejects writes with a token lower than the highest seen** (CAS, `if-match`, ZooKeeper `zxid`, etcd revision)
- [ ] Do not rely on STONITH alone — use it only as defense in depth

**Reference**: `references/distributed-truth/rules.md` (Rules 2, 3, 4)

---

### Step 6: Use Monotonic Clocks for Elapsed Time; Never Trust Wall-Clock for Ordering

**Goal**: Eliminate a class of bugs caused by NTP steps, drift, and VM-induced clock jumps.

- [ ] All timeouts, retry backoffs, lease durations: monotonic clock (`CLOCK_MONOTONIC`, `time.monotonic()`, `System.nanoTime()`)
- [ ] All cross-node ordering: logical clocks (Lamport, version vectors, HLC) or consensus
- [ ] Treat clock readings as **intervals with uncertainty**, not points
- [ ] Monitor clock offset across cluster; alert and evict drifted nodes

**Reference**: `references/distributed-time/rules.md` (Rules 1, 2, 6, 7)

---

### Step 7: Add Checksums and End-to-End Verification

**Goal**: Catch silent data corruption from disks, network, RAM, and "weak lying" by faulty nodes.

- [ ] Application-level checksums on all stored objects (TCP/UDP miss errors)
- [ ] TLS for all in-transit data (including internal services)
- [ ] Validate inputs at every service boundary
- [ ] Quorum-of-clocks for NTP (multiple servers, exclude outliers)
- [ ] Periodic background scrub of stored data

**Reference**: `references/distributed-truth/rules.md` (Rule 7)

---

### Step 8: Plan for Testing

**Goal**: Force-test the failure assumptions before production does.

- [ ] **Chaos / fault injection** (Jepsen-style): packet loss, partitions, asymmetric splits, slow nodes
- [ ] Test the **recovery phase** — bugs cluster there, not just at fault onset
- [ ] **Formal methods** (TLA+, FizzBee) for any custom consensus / coordination protocol
- [ ] **Deterministic simulation testing** (FoundationDB Flow, TigerBeetle, Antithesis) if data integrity is critical
- [ ] CI-level chaos gates so regressions surface before deploy

**Reference**: `references/distributed-truth/rules.md` (Rule 10), `references/distributed-failures/rules.md` (Rule 5)

---

### Step 9: Document the System Model and Failure Budget

**Goal**: Make assumptions auditable and the operating envelope explicit for on-call.

- [ ] Written system model (timing + node-behavior + storage assumptions)
- [ ] Tolerated failure list (`f` crashed nodes, partition of X duration, etc.)
- [ ] Out-of-scope failures (BFT, total power loss, simultaneous DC failure) noted
- [ ] Safety vs. liveness listed separately — safety holds *always*; liveness may have caveats

**Reference**: `references/distributed-truth/rules.md` (Rules 8, 9)

---

## Decision Tree: Failure Type → Mitigation

| Failure Type | Primary Mitigation | Secondary |
|---|---|---|
| Lost packet | Idempotent retry + bounded backoff | Circuit breaker |
| Network partition | Quorum / consensus on critical path | Read-only degraded mode |
| Slow node ("gray failure") | Adaptive failure detector (phi-accrual) | Hedged requests |
| Process pause (GC, VM) | Fencing tokens + receiver-side rejection | Low-pause GC, drain-restart |
| Clock skew | Monotonic clock for durations; logical clock for order | Cluster-wide offset monitor |
| Disk corruption | Application checksums + scrub | Replication + repair from quorum |
| Zombie leaseholder | Fencing token enforced at storage | STONITH as defense in depth |
| Double-delivered message | Idempotency key on every operation | Exactly-once via dedup table |

---

## Quick Checklist

```
[ ] Step 1: System model chosen and documented
[ ] Step 2: Failure modes enumerated
[ ] Step 3: Each failure classified survive / detect / accept
[ ] Step 4: Consensus / quorum used for strong-agreement paths
[ ] Step 5: Fencing tokens on every lock, enforced at storage
[ ] Step 6: Monotonic clocks for durations; logical clocks for order
[ ] Step 7: Checksums + end-to-end verification in place
[ ] Step 8: Chaos / DST / formal methods plan exists
[ ] Step 9: System model + failure budget documented
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---|---|---|
| No fencing tokens on locks | Zombie holder writes after lease expiry → silent corruption | Monotonic token enforced at storage (CAS) |
| Wall-clock subtraction for elapsed time | NTP step / drift produces negative or huge durations | `CLOCK_MONOTONIC` / `time.monotonic()` |
| Wall-clock timestamps to order cross-node events | Synced clocks differ by ms; reorders fast events | Logical clocks (Lamport, HLC) or consensus |
| Treating "at least once" as "exactly once" | Duplicate side effects (double-charge, double-send) | Idempotency keys + dedup table |
| Trusting timeout = "request failed" | Could be lost request, lost response, or still running | Treat as unknown; verify via follow-up read |
| Single-node "X is dead" decision | Split brain, two leaders | Quorum vote, majority rules |
| BFT for in-house datacenter system | Massive cost, doesn't defend against shared bugs | Crash-recovery + traditional security |
| Hardcoded constant timeouts | Breaks under traffic shift / noisy neighbor | Phi-accrual / adaptive detectors |
| Testing fault onset only, not recovery | Recovery bugs corrupt data after the "fault is over" | Chaos test full cycle including heal |
| STONITH as primary fencing | Cannot stop in-flight delayed packets | Fencing tokens; STONITH as defense in depth |

---

## Exit Criteria

Done when: system model + failure budget written; every distributed lock has a fencing token enforced at storage; every cross-node ordering uses logical clocks or consensus; every protected operation is idempotent; chaos tests cover documented failure modes including recovery; safety holds under every modeled fault; liveness caveats documented.
