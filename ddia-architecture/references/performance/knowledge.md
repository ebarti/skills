# Performance Knowledge

Core concepts for measuring and reasoning about the performance of data-intensive systems.

## Overview

Performance is one of the principal nonfunctional requirements of any system. It is described primarily through two metrics — response time (what the user perceives) and throughput (how much work the system can process). Because response times vary, they must be analyzed as a distribution using percentiles, not summarized by a single average.

## Key Concepts

### Response Time

**Definition**: The elapsed time from the moment a user makes a request until they receive the answer.

It is what the *client* sees and includes everything: network travel, queueing, and actual service work. Measured in seconds, milliseconds, or microseconds.

### Service Time

**Definition**: The duration during which the service is *actively processing* a request.

Service time is a subset of response time and excludes queueing and network delays.

### Latency

**Definition**: A catchall term for time during which a request is *not being actively processed* — the request is "latent."

*Network latency* (or *network delay*) refers specifically to time spent traveling over the network. Latency and response time are often confused; this book treats them distinctly.

### Throughput

**Definition**: The number of requests per second, or the data volume per second, that a system processes.

Each hardware allocation has a *maximum throughput*. Examples: "posts per second," "records per second," "MB per second."

### Queueing Delay

**Definition**: Time a request waits before being processed because resources (e.g., CPU cores) are busy with earlier requests.

Queueing delay is the dominant source of variability in response times under load. It increases sharply as throughput approaches hardware capacity.

### Head-of-Line Blocking

**Definition**: A small number of slow requests holds up subsequent requests, even if those subsequent requests would themselves have been fast.

Because a server processes only a few things in parallel (limited by CPU cores), a slow request blocks the queue. The client sees a slow overall response time even for inherently quick work.

### Percentiles (p50, p95, p99, p999)

**Definition**: The value below which a given percentage of requests fall when sorted from fastest to slowest.

- **p50 (median)**: half of requests are faster, half slower — the "typical" experience.
- **p95**: 95 of 100 requests are faster than this value.
- **p99**: 99 of 100 are faster (1% slower).
- **p999**: 999 of 1000 are faster (0.1% slower).

### Tail Latency

**Definition**: Response times at the high end of the distribution (p95, p99, p999, etc.).

Tail latencies disproportionately affect user experience. Heavy users (with the most data) often suffer the worst latencies — and they are the most valuable customers.

### Tail Latency Amplification

**Definition**: When one end-user request requires multiple backend calls, the chance of hitting at least one slow call grows with the number of calls.

Even if only 1% of backend calls are slow (p99), an end-user request that fans out to many backends will be slow far more than 1% of the time.

### Metastable Failure

**Definition**: A vicious cycle where high load triggers timeouts, retries cause more load, and the system stays overloaded even after the initial spike subsides.

Mitigations: exponential backoff, circuit breakers, token buckets, load shedding, backpressure.

## Terminology

| Term | Definition |
|------|------------|
| Response time | Total time client observes |
| Service time | Active processing only |
| Latency | Time request is *not* being processed |
| Throughput | Requests or data volume per unit time |
| Jitter | Variation in network delay |
| Outlier | Request that takes much longer than typical |
| Fan-out | Factor by which one request triggers downstream requests |
| Retry storm | Cascading retries that overload a service |

## How It Relates To

- **Scalability**: Performance under increasing load; scalability is the ability to add capacity to maintain performance.
- **Reliability**: Slow systems can be effectively unavailable; availability SLOs use percentile-based measures.
- **Throughput vs. response time**: Related — response time grows as throughput nears capacity due to queueing.

## Common Misconceptions

- **Myth**: The average (mean) response time tells you the typical experience.
  **Reality**: The mean is skewed by outliers and does not say how many users actually experienced that delay. Use the median (p50) instead.

- **Myth**: Latency and response time are the same.
  **Reality**: Response time is what the client sees end-to-end; latency refers to time the request is *not* being actively processed (queueing, network).

- **Myth**: A slow tail (p99, p999) only affects a few users so it does not matter.
  **Reality**: Heavy users hit the tail most often, and end-user requests that fan out to many backends amplify tail latency.

- **Myth**: Averaging percentiles across machines or time windows is fine.
  **Reality**: Averaging percentiles is mathematically meaningless. Aggregate by adding histograms.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Response time | Total client-observed time, including queueing and network |
| Service time | Pure processing time on the server |
| Latency | Time spent waiting (not processing) |
| Throughput | Work processed per second |
| p50 / median | Half of requests are faster |
| p99 / p999 | Tail latency — affects heavy users and fan-out requests |
| Head-of-line blocking | One slow request delays all queued requests |
| Tail amplification | Fan-out makes rare slow calls common end-user slowdowns |
