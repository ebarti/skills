# Distributed Time and Clocks Knowledge

Core concepts for reasoning about time, clocks, and process pauses in distributed systems.

## Overview

In distributed systems, time is unreliable: each machine has its own clock (typically a quartz crystal that drifts), network delays make event ordering ambiguous, and processes can be paused arbitrarily by GC, VM migration, or page faults. Robust software must treat clocks as approximate, not authoritative, for ordering events across nodes.

## Key Concepts

### Time-of-Day Clock (Wall Clock)

**Definition**: A clock that returns the current calendar date/time, typically as seconds since the Unix epoch (1970-01-01 UTC). Examples: `clock_gettime(CLOCK_REALTIME)`, `System.currentTimeMillis()`.

**Key points**:
- Synchronized via NTP — value is meant to be comparable across machines
- May jump backward or forward when NTP forcibly resets the clock
- Affected by leap seconds and (if not using UTC) DST
- Unsuitable for measuring elapsed time

### Monotonic Clock

**Definition**: A clock guaranteed to only move forward, used to measure durations. Examples: `clock_gettime(CLOCK_MONOTONIC)`, `System.nanoTime()`.

**Key points**:
- Absolute value is meaningless (often nanoseconds since boot)
- Cannot compare values across machines
- NTP can *slew* the rate (up to ~0.05%) but cannot jump it
- Resolution is typically microseconds or finer
- Right tool for timeouts, response time measurement

### Clock Drift

**Definition**: The rate at which a quartz clock runs faster or slower than true time. Google assumes up to 200 ppm — that's ~17 seconds drift per day if not resynchronized.

### NTP (Network Time Protocol)

**Definition**: Protocol that synchronizes a computer's time-of-day clock against external time servers (which often source from GPS or atomic clocks).

**Key points**:
- Accuracy bounded by network round-trip time
- Public internet: ~tens of ms (best), >100 ms under congestion
- Cloud (typical): often 100ms+ skew between nodes
- Local network: down to single-digit ms with care
- Misconfigured NTP / firewalled NTP servers fail silently

### Clock Skew

**Definition**: The difference in time-of-day readings between two machines at the same instant. Even with good NTP, skew of milliseconds is normal; tens to hundreds of ms is common.

### Process Pause

**Definition**: An interval during which a process/thread stops executing despite being "running," for reasons outside the application's control.

**Causes**:
- **GC pauses** — stop-the-world garbage collection (historically minutes; now usually ms with G1/ZGC/Shenandoah)
- **VM pause / live migration** — hypervisor freezes a VM for tens of ms to seconds while moving or scheduling
- **Page faults / swap** — touching a swapped-out page blocks on disk I/O; thrashing can dominate
- **Disk I/O** — synchronous I/O including unexpected lazy classloading
- **Steal time** — another VM/thread is using the CPU
- **SIGSTOP** — Unix Ctrl-Z; resumes on SIGCONT
- **Lid close on laptops** — arbitrary suspension

**Implication**: A node may be paused for seconds without knowing it. The rest of the cluster may declare it dead.

### TrueTime / Confidence Interval

**Definition**: Google Spanner's clock API that returns `[earliest, latest]` instead of a single timestamp, where the actual time is guaranteed to lie in that interval.

**Key points**:
- Backed by GPS receivers and atomic clocks in each datacenter
- Spanner achieves ~7 ms uncertainty
- Spanner *waits out the uncertainty* (commit-wait): blocks until `now > tx_commit.latest` so that any later transaction's interval cannot overlap
- Amazon ClockBound provides similar API for AWS

### Logical vs Physical Clocks

**Physical clocks**: Time-of-day and monotonic clocks — measure actual elapsed time.

**Logical clocks**: Counters (Lamport timestamps, version vectors, HLCs) — measure *relative ordering* of events without depending on wall time. Safer for ordering events across nodes (covered in distributed-truth / consistency references).

### Real-Time System (RTOS)

**Definition**: A system carefully engineered so software responds within hard deadlines. Distinct from "real-time" web/streaming usage. Required for airbags, flight control, etc. — not "high performance."

## Terminology

| Term | Definition |
|------|------------|
| Wall clock | Time-of-day clock |
| Slewing | Gradually adjusting clock rate via NTP |
| Smearing | Spreading a leap second adjustment over a day |
| Steal time | CPU time taken by other VMs on shared host |
| Thrashing | OS spending most time swapping pages |
| LWW | Last Write Wins — timestamp-based conflict resolution |
| Commit-wait | Spanner's wait-out-the-uncertainty technique |
| HLC | Hybrid Logical Clock (physical + logical hybrid) |

## How It Relates To

- **Distributed failures**: Process pauses look identical to node failures over the network — receivers cannot distinguish "slow" from "dead"
- **Distributed truth (leases/fencing)**: Pauses break naive lease-based leadership; fencing tokens are required
- **Linearizability**: Naive timestamp ordering does not give linearizability; need consensus or TrueTime-style intervals
- **Replication**: LWW conflict resolution silently loses writes when clock skew exceeds inter-write delay

## Common Misconceptions

- **Myth**: "Modern NTP is accurate enough to order events by timestamp."
  **Reality**: NTP accuracy is bounded by network RTT; you cannot guarantee clock error < network delay. Cross-node ordering by wall clock is unsafe.

- **Myth**: "GC pauses are a solved problem."
  **Reality**: Modern GCs reduce pauses to ms in good conditions, but pauses still happen — and VM migration, paging, and steal time can pause a process for seconds regardless of GC.

- **Myth**: "Monotonic clocks are useless across machines."
  **Reality**: They are useless for *cross-machine ordering* but indispensable for measuring local elapsed time (timeouts, latencies).

- **Myth**: "Microsecond-precision timestamps mean microsecond accuracy."
  **Reality**: Resolution is not accuracy. The reading may be off by 100ms+ even if printed to nanoseconds.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Time-of-day clock | Wall time, sync'd by NTP, can jump |
| Monotonic clock | Stopwatch, never jumps backward, local-only |
| Clock drift | Quartz inaccuracy, ~200 ppm worst-case |
| Process pause | Code can stop for seconds without warning |
| Confidence interval | `[earliest, latest]` — bounds the real time |
| TrueTime | Spanner's bounded-uncertainty clock API |
| Logical clock | Counter for ordering, no wall-time dependency |
