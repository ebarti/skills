# Distributed Time and Clocks Examples

Real-world clock-related bugs and the techniques used to defend against them.

## Bad Examples

### Cassandra LWW: Silent Write Loss from Clock Skew

In multi-leader replication with last-write-wins conflict resolution, the timestamp comes from the *client's* (or originating node's) wall clock. Cassandra and ScyllaDB historically use this approach.

```
Time   Node 1 clock    Node 3 clock
T0     42.004          42.001
       Client A: x = 1 (ts=42.004)
T1                     Client B: increment x to 2 (ts=42.003)
       (replicated to node 2)

Node 2 receives:
  x = 1 with ts = 42.004
  x = 2 with ts = 42.003

LWW keeps the higher timestamp -> x = 1.
The increment is silently dropped.
```

**Problems**:
- Causally-later write (`x = 2`) has an *earlier* wall-clock timestamp because node 3's clock is behind
- Application sees no error — the write succeeded everywhere, then vanished
- A node with a slow clock cannot overwrite values from a fast node until the skew elapses
- Two nodes can generate the same timestamp at ms resolution; tiebreakers can themselves violate causality

### Naive Lease-Based Leadership (Process Pause Hazard)

```java
while (true) {
    Request request = waitForRequest();
    if (lease.isValid()) {
        // <-- thread pauses here for 15 seconds (GC / VM migration)
        process(request);  // lease has expired; another node is leader now
    }
}
```

**Problems**:
- Relies on cross-node clock synchronization for lease expiry comparison
- Assumes negligible time between `isValid()` check and `process()` call
- A 15-second GC, VM pause, or page fault makes both assumptions wrong
- Two nodes simultaneously believe they are leader; both write; data corrupts

### Treating Clock Reading as a Point

```python
# Bad: assumes clock_gettime returns "the" current time
ts = time.time()
log.write(f"{ts:.6f} event")  # microseconds suggest microsecond accuracy
```

**Problems**:
- The `:.6f` formatting suggests precision the underlying NTP-sync'd clock does not have
- Two events logged at "the same" microsecond on different nodes may be seconds apart in reality
- Downstream consumers may sort by timestamp and produce wrong ordering

### Cloud NTP Reality Check

A typical cloud VM running default NTP against the provider's time service:
- Steady-state offset: tens of ms is common; 100 ms+ under load
- VM live-migration causes the guest clock to jump arbitrarily; the in-VM NTP daemon doesn't see the pause
- Network congestion to the time source can spike error to seconds

**Problem**: Code that "works in dev" with sub-ms localhost NTP fails in production where 100ms skew is normal.

## Good Examples

### Spanner: TrueTime + Commit-Wait

Spanner uses a fleet of GPS receivers and atomic clocks in every datacenter and exposes:

```
TrueTime.now() -> {earliest: T_e, latest: T_l}
// Real time is guaranteed to be in [T_e, T_l]; uncertainty (T_l - T_e) ~ 7 ms
```

When committing a read/write transaction at chosen timestamp `s`:

```
1. Acquire locks, choose commit timestamp s = TrueTime.now().latest
2. Wait until TrueTime.now().earliest > s
   (this is "commit-wait" — block until s is definitely in the past)
3. Release locks; reply to client
```

**Why it works**:
- Any later transaction will see `now().earliest > s`, so its commit interval cannot overlap
- Confidence intervals never overlap across causally-related transactions => correct ordering
- Cost paid in commit latency (~uncertainty width), so Google works hard to keep it small

### Hybrid Logical Clock (HLC) — CockroachDB

HLC combines a physical timestamp with a logical counter to get monotonic, causally-consistent timestamps that stay close to wall-clock time.

```
node_hlc = (physical_time, logical_counter)

On local event:
  pt = max(local_wall_clock, last_hlc.physical)
  if pt == last_hlc.physical: lc = last_hlc.logical + 1
  else: lc = 0
  emit (pt, lc)

On receive message with sender_hlc:
  pt = max(local_wall_clock, last_hlc.physical, sender_hlc.physical)
  // logical counter incremented to break ties as needed
```

**Why it works**:
- Captures causality (like a Lamport clock) — receiver's HLC is always > sender's HLC
- Stays close to wall clock so timestamps remain human-meaningful
- CockroachDB uses HLC + bounded clock skew assumption for transaction ordering, with the tradeoff that exceeding the configured skew bound forces node shutdown

### Drain-and-GC Pattern

```
while true:
  if runtime.gcPressureHigh():
    loadBalancer.drain(thisNode)         // stop accepting new requests
    awaitInFlightRequestsDone()
    runtime.forceGC()                    // pay the pause now, with no traffic
    loadBalancer.rejoin(thisNode)
  serveOneRequest()
```

**Why it works**:
- GC pauses still happen, but during a planned drain — clients see no slow requests
- Pushes GC out of the response-time tail
- Combine with periodic process restarts to avoid long-lived heap fragmentation

### Java GC Pause: Real Numbers and Mitigation

Historically: stop-the-world full GC on a multi-GB CMS heap could pause **15+ seconds**, occasionally minutes. Triggered the original Cassandra leader-flapping problem and many others.

Modern with G1 / ZGC / Shenandoah: typically <10 ms p99 pause, sometimes <1 ms with ZGC on small heaps. Still not zero.

**Mitigation that works**:
- ZGC for sub-ms pauses on multi-GB heaps
- Off-heap storage (DirectByteBuffer, Chronicle Map) for large datasets
- Object pools for hot allocation paths
- Treat GC like a network partition in your design — fence at the receiver

### Use Monotonic Clock for Lease Renewal

```java
// Local check uses monotonic clock — survives wall-clock jumps
long leaseAcquiredNanos = System.nanoTime();
long leaseDurationNanos = TimeUnit.SECONDS.toNanos(30);

while (true) {
    long elapsed = System.nanoTime() - leaseAcquiredNanos;
    if (elapsed > leaseDurationNanos - RENEW_BUFFER_NANOS) {
        renewLease();
        leaseAcquiredNanos = System.nanoTime();
    }
    // Still: every action requires a fencing token — see distributed-truth
}
```

**Why it works**:
- Monotonic clock cannot jump backward, so "elapsed since acquire" is meaningful even if NTP resets
- Does *not* solve the pause problem on its own — the fencing token at the receiver does that

## Refactoring Walkthrough

### Before: Wall-clock duration with a hidden race

```java
long deadline = System.currentTimeMillis() + timeoutMs;
while (System.currentTimeMillis() < deadline) {
    if (tryStep()) return;
}
throw new TimeoutException();
```

### After: Monotonic clock + receiver-side fencing

```java
long deadlineNs = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(timeoutMs);
long fencingToken = leader.acquireToken();
while (System.nanoTime() < deadlineNs) {
    if (tryStepWithToken(fencingToken)) return;  // receiver rejects stale tokens
}
throw new TimeoutException();
```

### Changes Made

1. Replaced `currentTimeMillis()` with `nanoTime()` — wall-clock jumps no longer change the deadline
2. Added a fencing token from the leader so the receiver rejects work from a paused/stale caller
3. Made the timeout local to this thread; cross-node ordering is the receiver's problem to validate
