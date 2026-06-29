# Distributed System Failures Rules

Design guidelines for building services that survive an unreliable network.

## Core Rules

### 1. Assume the Network Is Unreliable

Every RPC, every cross-node read, every replication message must be designed to fail. There is no "stable" network — only one that has not failed *yet*.

- Treat every remote call as: may be lost, delayed, duplicated, or partially processed
- Design idempotent operations so retries are safe
- Never assume a connection that worked a moment ago still works
- "Suspicion, pessimism, and paranoia pay off"

**Example**:
```python
# Bad: assumes the call either succeeds or raises
result = remote_service.charge_card(amount)
mark_paid(order_id)

# Good: idempotent + verify outcome
idempotency_key = uuid4()
try:
    result = remote_service.charge_card(amount, idempotency_key)
except (Timeout, ConnectionError):
    result = remote_service.lookup_charge(idempotency_key)
if result.succeeded:
    mark_paid(order_id)
```

### 2. Use Timeouts, but Recognize Their Ambiguity

A timeout never tells you whether the request was lost, the response was lost, the node crashed, or the work is still in flight. Plan for all four.

- Always set timeouts on outbound RPCs (no infinite waits)
- Treat timeout as "unknown outcome", not "failure"
- Make actions idempotent so a duplicate retry is safe
- Verify state via a follow-up read when the original outcome is unknown

### 3. Don't Manually Tune Timeouts — Adapt

Constant timeouts break the moment traffic shifts. Measure RTT distributions and let the system adapt.

- Measure RTT distribution (p50, p95, p99) over many machines and time
- Use adaptive failure detectors (Phi Accrual — Akka, Cassandra) that score suspicion based on jitter
- Re-derive timeouts from observed latency, not gut feel
- If you must use a constant, multiply observed p99 by a safety factor

**Example**:
```python
# Bad: hardcoded timeout, breaks under noisy neighbor load
client.set_timeout(seconds=2)

# Good: adaptive, learned from observed jitter
detector = PhiAccrualDetector(threshold=8.0)
detector.heartbeat()  # called on every successful response
if detector.phi() > threshold:
    suspect_node(node_id)
```

### 4. Use Heartbeats and Leader Leases

Don't rely on a single timeout to declare death — combine periodic heartbeats with bounded leases that expire.

- Heartbeats: lightweight liveness signals at known intervals
- Leases: a leader's authority expires unless renewed; prevents two leaders
- Lease duration must exceed expected pause (GC, VM steal time) plus clock skew
- A lost heartbeat is suspicion; multiple lost heartbeats is action

### 5. Build Network Partitions Into Your Test Plan

If you have not deliberately tested partition handling, your system probably misbehaves under one. Studies and real incidents prove this.

- Run chaos engineering: drop packets, sever links, asymmetric partitions
- Test the *recovery* phase, not just the partition itself — bugs cluster there
- Verify no data loss, no split-brain writes, no permanent deadlock
- Test slow nodes, not just dead ones (gray failures)

## Guidelines

- Prefer asynchronous, idempotent designs over synchronous request/response when possible
- Use circuit breakers to stop hammering a failing dependency
- Set per-RPC timeouts shorter than the user-facing timeout, leaving budget for retries
- Bound retries (max attempts, exponential backoff with jitter)
- Distinguish "node down" from "node slow" — both need different responses
- Reserve capacity headroom; queues empty fast with slack, build up fast under load

## Exceptions

- **Internal LAN with QoS**: if you have control of the switches and apply QoS/admission control, you can approximate bounded delay (e.g., InfiniBand HPC clusters)
- **VoIP / streaming**: prefer UDP — retransmission is worthless if data is stale
- **Best-effort fire-and-forget**: telemetry, metrics, logs may safely drop without retry

## Quick Reference

| Rule | Summary |
|------|---------|
| Network is unreliable | Every RPC may fail; design idempotent retries |
| Timeouts are ambiguous | Cannot tell lost, crashed, or still-running |
| Adapt timeouts | Use Phi accrual, not constants |
| Heartbeats + leases | Bound leader authority, detect liveness |
| Test partitions | Chaos-engineer net splits and recovery |
