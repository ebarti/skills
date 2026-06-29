# Diagnosing a Distributed-System Bug Workflow

A systematic process for isolating bugs that only manifest across nodes — stale reads, lost writes, duplicate side effects, deadlocks, out-of-order events.

## When to Use

- A symptom appears only in production / under load / intermittently
- "It works on my machine" but breaks across nodes
- Two clients see contradictory state, or a write seems to vanish
- Side effects (emails, charges, messages) fire twice or zero times
- A leader election produces two leaders, or a lock is held by two holders

## Prerequisites

- Access to logs from all involved nodes (correlated by request/trace ID)
- Knowledge of the system's replication topology and isolation level
- Ability to reproduce or capture a failing instance

**References**: `references/distributed-failures/rules.md`, `references/distributed-time/rules.md`, `references/isolation-levels/rules.md`, `references/linearizability/rules.md`

---

## Workflow Steps

### Step 1: Reproduce Reliably (or Capture One Instance)

**Goal**: Have a concrete failing case, not folklore.

- [ ] Capture timestamps, node IDs, request IDs, payloads from at least one failure
- [ ] If intermittent, try concurrent load (`wrk`, `hey`, parallel test runners)
- [ ] If still not reproducible, plan Jepsen-style nemesis (Step 9)

**Ask**: "Can I point at one transcript and say 'this is wrong'?"

---

### Step 2: Classify the Symptom

**Goal**: Narrow the suspect subsystem before reading code.

| Symptom | Likely subsystem | Load first |
|---------|------------------|------------|
| Stale read after own write | Replication lag / weak consistency | `linearizability/rules.md` |
| Write disappeared | Lost update / dirty write / replica conflict | `isolation-levels/rules.md` |
| Side effect fired twice | Idempotency / retry / failover | `distributed-failures/rules.md` |
| Side effect didn't fire | Timeout misclassified as failure | `distributed-failures/rules.md` |
| Two leaders / two lock holders | Split-brain, expired lease, GC pause | `distributed-time/`, `linearizability/` |
| Events out of order across nodes | Wall-clock ordering | `distributed-time/rules.md` |
| Concurrent updates corrupted state | Write skew / phantom / lost update | `isolation-levels/rules.md` |
| Deadlock / stalled transaction | Locking, partition | `isolation-levels/`, `distributed-failures/` |

---

### Step 3: Check the Obvious

**Goal**: Rule out the boring high-probability causes first.

- [ ] **Isolation level** of this txn? (Don't trust the name — check DB docs)
- [ ] Read going to a **lagging replica**? Force primary, retry.
- [ ] **Timeouts** on each hop? Any infinite waits? Chained budget exceeded?
- [ ] **Retry policy** amplifying duplicates without idempotency?

**Reference**: `references/isolation-levels/`, `references/distributed-failures/`

---

### Step 4: Check Clocks

**Goal**: Eliminate clock-based reasoning errors.

- [ ] Any logic comparing **wall-clock timestamps** from different nodes?
- [ ] Lease checked against a local wall clock?
- [ ] Durations measured with **monotonic** clock, not wall clock?
- [ ] NTP offset > 100 ms on implicated nodes?

**If yes to wall-clock ordering**: replace with logical clock (Lamport / HLC) or fencing tokens.

**Reference**: `references/distributed-time/rules.md`

---

### Step 5: Check Network

**Goal**: Detect partition, slow link, or asymmetric failure.

- [ ] **Timeouts** clustered on one node / direction (asymmetric partition)?
- [ ] **Slow nodes** (gray failures) — high p99 without errors?
- [ ] Correlated deploy, scale event, or AZ failure?
- [ ] Bug manifest during a **recovery** phase (re-replication, re-election)?

**Reference**: `references/distributed-failures/rules.md` (rules 1, 2, 5)

---

### Step 6: Check Process Pauses

**Goal**: Rule out the silent killer — code stopped running for seconds.

- [ ] **GC logs** showing stop-the-world pauses?
- [ ] **Swap** activity (should be disabled on servers)?
- [ ] **VM migration** or **steal time** spikes?
- [ ] Debugger or `SIGSTOP` (common in staging)?

**If a pause is suspect**: any pre-pause time check is now stale. Fix at receiver with fencing tokens.

**Reference**: `references/distributed-time/rules.md` (rules 4, 5)

---

### Step 7: Check for Race Conditions

**Goal**: Identify the specific concurrency anomaly.

- [ ] **Lost update**: two read-modify-write cycles, last writer wins?
- [ ] **Write skew**: two txns read overlapping rows, write disjoint, break invariant?
- [ ] **Phantom**: `WHERE` predicate's result set changed mid-txn?
- [ ] **ORM read-modify-write** where an atomic op would do?

**Reference**: `references/isolation-levels/rules.md` (rules 3, 4, 7)

---

### Step 8: Check Coordination

**Goal**: Verify the consensus / locking layer.

- [ ] **Fencing tokens** propagated to the storage layer?
- [ ] Quorum: `R + W > N`? `W` actually achieved before ack?
- [ ] Leader election consensus-backed (etcd/ZooKeeper), not homegrown timestamps?
- [ ] ZooKeeper read called `sync()` first for linearizability?

**Reference**: `references/linearizability/rules.md` (rules 1, 2, 10), `references/distributed-truth/`

---

### Step 9: Reproduce in Test

**Goal**: A test that fails before the fix and passes after.

- [ ] Deterministic concurrency test (controlled scheduler) if possible
- [ ] Else **Jepsen-style nemesis**: drop packets, partition, kill leader, pause GC
- [ ] Verify test fails on unfixed code
- [ ] Test the **recovery phase**, not just the fault

**Reference**: `references/distributed-failures/rules.md` (rule 5)

---

### Step 10: Fix at the Right Layer

**Goal**: Eliminate the root cause; don't paper over it.

- [ ] Missing **idempotency key** → add one; retries become safe
- [ ] Missing **fencing token** → add it; receiver rejects stale work
- [ ] Wrong **isolation level** → raise it (or use atomic op / CAS)
- [ ] Wall-clock ordering → switch to logical clock (HLC)
- [ ] Homegrown leader election → replace with consensus (etcd)
- [ ] **Anti-pattern**: do NOT mask with retry loop, longer timeout, or `time.sleep()`

**Verify**: test from Step 9 passes; recovery scenarios still pass.

---

## Quick Checklist

```
[1] Reproduced  [2] Symptom classified  [3] Obvious ruled out
[4] Clocks      [5] Network             [6] Pauses
[7] Races       [8] Coordination        [9] Failing test
[10] Fixed at root cause; test now passes
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Blame the network without checking clocks | A bad clock looks identical to a partition; you fix the wrong layer | Check NTP offset and GC pauses first |
| Add retry to mask a race | Amplifies duplicates and hides the anomaly | Make the op idempotent; fix the race |
| Bump timeouts to "make timeouts stop" | Hides slow-node gray failures, raises tail latency | Adaptive timeouts (Phi accrual); find the slow path |
| Trust the isolation level name | "Repeatable read" means different things in each DB | Verify lost-update detection in your DB's docs |
| Compare wall-clock timestamps across nodes | Skew inverts ordering of fast events | Use Lamport / HLC for cross-node ordering |
| Skip testing the recovery phase | Bugs cluster in re-election, re-replication, catch-up | Inject the fault, watch the heal |
| Use `time.sleep()` to "wait for replication" | Lag is unbounded under load; flaky tests follow | Read from primary, or read-your-writes session |
| Treat timeout as "failed" | Work may still be in flight — retry duplicates | Treat as "unknown"; verify with idempotent lookup |

---

## Exit Criteria

Bug is resolved when:
- [ ] Root cause identified at a specific layer (replication / clock / network / pause / race / coordination)
- [ ] Failing test exists that reproduced the bug
- [ ] Fix is at the right layer — not a retry-loop, not a sleep, not a longer timeout
- [ ] Test now passes; recovery / partition tests also pass
- [ ] Postmortem notes which class of bug this was (so the team recognizes it next time)
