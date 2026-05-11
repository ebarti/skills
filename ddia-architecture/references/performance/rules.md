# Performance Measurement Rules

Best practices for measuring, reporting, and acting on response-time and throughput metrics.

## Core Rules

### 1. Use Percentiles, Not Averages

The mean (arithmetic average) is skewed by outliers and tells you nothing about how many users actually experienced that delay.

- Use the **median (p50)** for "typical" user experience.
- Use **p95, p99, p999** to characterize the tail.
- The mean is acceptable only for estimating throughput limits.

**Example**:
```
// Bad: report only "average response time = 250 ms"
// — hides that 1% of users wait > 5 seconds.

// Good: report p50 = 200 ms, p95 = 800 ms, p99 = 1.5 s
```

### 2. Choose the Right Percentile for the SLO

Match the percentile to the criticality of the path.

- **p50**: typical user experience baseline.
- **p99**: standard for most production SLOs.
- **p999**: critical paths (e.g., Amazon's internal services use p99.9 because their heaviest customers are their most valuable).
- **p9999** is usually too costly to optimize and yields diminishing returns.

### 3. Measure Response Time on the Client Side

Server-side metrics exclude queueing delay before the request is dequeued and exclude network latency.

- Queueing delay is *not* part of service time.
- Head-of-line blocking is invisible from server logs alone.
- The client perspective is the only one that captures the true user experience.

### 4. Define Throughput in "Somethings per Second"

State the unit explicitly: requests/sec, posts/sec, records/sec, MB/sec.

- Pair throughput with the hardware allocation it was measured on.
- Track the ratio of observed throughput to *maximum throughput* — response time degrades sharply as you approach capacity.

### 5. Set SLOs Explicitly

A *Service Level Objective* is a target; an *SLA* is a contract specifying consequences if the SLO is missed.

- Specify **percentile + threshold + window** (e.g., "p99 < 1 s over a rolling 5-minute window").
- Include availability (e.g., "99.9% of valid requests are non-error").
- Make the definition of a "valid request" precise.

**Example SLO**:
```
- Median response time:  < 200 ms
- 99th percentile:       < 1 s
- Availability:          >= 99.9% non-error responses on valid requests
```

### 6. Avoid Averaging Percentiles Across Machines or Time

Averaging percentiles is mathematically meaningless.

- Aggregate by **adding histograms** instead.
- Use libraries that support mergeable histograms: HdrHistogram, t-digest, OpenHistogram, DDSketch.

### 7. Account for Tail Latency Amplification in Fan-Out Systems

When a single end-user request makes N backend calls in parallel, the user waits for the *slowest* of N.

- The chance of hitting at least one p99-slow call grows with N.
- Push tail-latency targets harder for backends that are called many times per request.
- Consider hedged requests, request cancellation, or limiting fan-out.

### 8. Compute Percentiles Efficiently

For dashboards, keep a rolling window (e.g., last 10 minutes) and recompute on each tick.

- Naive: keep all response times, sort, pick percentiles. Works but expensive.
- Production: use approximation algorithms (HdrHistogram, t-digest, DDSketch) that bound CPU/memory.

### 9. Defend Against Retry Storms and Metastable Failure

A loaded system can stay overloaded after the trigger disappears.

- **Client side**: exponential backoff with jitter, circuit breakers, token bucket.
- **Server side**: load shedding (reject requests proactively), backpressure (tell clients to slow down).

## Guidelines

- Report at least **p50 and p99** on every latency dashboard. p999 for critical paths.
- Plot response time *and* throughput together — context matters.
- Investigate outliers; do not just average them away.
- Distinguish "latency" (waiting) from "service time" (processing) when diagnosing.
- Beware coordinated omission in benchmarks: if your load generator stalls when the server is slow, your measured latency understates reality.

## Exceptions

- **Rough capacity planning**: the mean is fine for back-of-envelope throughput math.
- **Internal-only debugging metrics**: averages may be acceptable when the goal is detecting trends, not reporting SLOs.

## Quick Reference

| Rule | Summary |
|------|---------|
| Percentiles over averages | Use p50/p95/p99/p999, not mean |
| Right percentile | p99 default; p999 for critical/high-value paths |
| Client-side measurement | Captures queueing and network delay |
| Throughput units | "Somethings per second" with hardware context |
| Explicit SLOs | percentile + threshold + window |
| Don't average percentiles | Aggregate histograms instead |
| Mind fan-out | Tail latency amplification grows with N backends |
| Approximate at scale | HdrHistogram, t-digest, DDSketch |
| Plan for retry storms | Backoff, circuit breakers, load shedding |
