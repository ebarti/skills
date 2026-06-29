# Distributed Time and Clocks Rules

Design rules for handling unreliable clocks and unbounded process pauses in distributed systems.

## Core Rules

### 1. Use Monotonic Clocks for Elapsed Time

For *any* duration measurement — timeouts, response times, retry backoffs, rate limits — use a monotonic clock. Never subtract two wall-clock readings.

- `System.nanoTime()` (Java), `clock_gettime(CLOCK_MONOTONIC)` (Linux), `time.monotonic()` (Python)
- Wall-clock subtraction can produce negative durations or huge gaps when NTP resets

**Example**:
```java
// Bad
long start = System.currentTimeMillis();
doWork();
long elapsed = System.currentTimeMillis() - start;  // can go negative

// Good
long start = System.nanoTime();
doWork();
long elapsedNs = System.nanoTime() - start;
```

### 2. Use Time-of-Day for Timestamps Only, Not for Ordering

Wall-clock timestamps are fine for human-readable logs, scheduled events, and TTLs. They are *unsafe* for deciding which of two events on different nodes happened first.

- For cross-node ordering, use logical clocks (Lamport, version vectors, HLC) or consensus
- Even tightly NTP-sync'd nodes can disagree by milliseconds — enough to invert order of fast successive events

### 3. Don't Use Timestamps for Distributed Locking or Leadership

A lease "valid until 12:00:30" compared against a local wall clock fails when the comparing node's clock is off, *or* when the node was paused between checking validity and acting on it.

- Use **leases + fencing tokens** instead (covered in `distributed-truth/`)
- The receiver of work rejects requests with stale fencing tokens, regardless of clock state

### 4. Beware Process Pauses — Code Can Be Paused for Seconds

Between two adjacent statements, your thread may stop for seconds (GC, VM migration, swap, steal time, SIGSTOP). Never assume "this all runs in a few ms."

- Re-validate any time-based precondition immediately before the action that depends on it
- Better: rely on the *receiver* to reject stale requests (fencing tokens) rather than the sender to self-check
- Treat lease checks the same way you treat network responses: stale by the time you read them

### 5. Tune GC for Response-Time-Critical Workloads

If tail latency or pause-driven failover matters, treat GC explicitly.

- Use a low-pause collector: G1, ZGC, Shenandoah (Java); Go's concurrent collector
- Pre-allocate / pool objects to reduce allocation pressure
- Move large data off-heap
- Treat GC as a planned outage: drain traffic, GC, restart, return to pool
- Periodically restart processes before long-lived object accumulation forces a full GC
- Or use a non-GC language (Rust, Swift, Mojo) for the most pause-sensitive components

### 6. Treat Clock Readings as Intervals, Not Points

A "now" reading has uncertainty — quartz drift since last sync, NTP server uncertainty, network RTT. If your code's correctness depends on time, you need a *bound* on the uncertainty.

- Use TrueTime / ClockBound APIs where available
- Otherwise, monitor offsets across the cluster and declare nodes with excessive skew dead
- Don't trust microsecond digits when your sync source is NTP over the public internet

### 7. Monitor Clock Offset Across the Cluster

Clock failures are silent. A node can drift for weeks before causing visible damage.

- Continuously measure offset between each node and an authoritative source
- Alert on offset > threshold (e.g., 100 ms for typical systems, much tighter for ordering-sensitive systems)
- Remove drifted nodes from the cluster before they corrupt state

## Guidelines

- Always use UTC for stored timestamps; convert at display time. Avoids DST jumps.
- Disable swap on server machines — better to OOM-kill than to thrash and pause for minutes.
- Inside a VM, NTP cannot detect VM-pause-induced clock jumps; use host-provided time when possible.
- For mobile / embedded / user devices, never trust the local clock at all — users set it manually.
- If you need ordering across nodes, prefer logical clocks (HLC) over physical timestamps even when clocks look "good."

## Exceptions

- **Low-stakes use cases**: Cache TTLs, log timestamps, "approximately when" displays — a small wall-clock skew is acceptable; no special handling needed.
- **Single-node databases**: A monotonic local counter is enough for transaction IDs; clock issues only matter when state spans nodes.
- **Real-time systems**: Use an RTOS with bounded scheduling; the rules above are about *not* needing real-time guarantees in normal server software.
- **Spanner-class infrastructure**: With GPS/atomic clocks + commit-wait, wall-clock timestamps *can* safely order events — but you pay for it in hardware and commit latency.

## Quick Reference

| Rule | Summary |
|------|---------|
| Monotonic for durations | Never subtract wall clocks |
| Wall clock not for ordering | Use logical clocks across nodes |
| No timestamp locks | Use leases + fencing tokens |
| Expect pauses | Re-check preconditions; fence at receiver |
| Tune GC | Low-pause collector, drain-and-restart pattern |
| Clocks are intervals | Bound the uncertainty, don't trust precision |
| Monitor offsets | Detect silent drift before it corrupts data |
