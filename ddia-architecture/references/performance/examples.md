# Performance Examples

Concrete examples illustrating performance concepts, drawn from the social network home-timeline case study and percentile measurement.

## Case Study: Home Timeline (Twitter-style)

Workload assumptions:
- 500 million posts/day = ~5,800 posts/sec average; spikes to 150,000/sec.
- Average user follows 200 people and has 200 followers.
- 10 million users online concurrently.
- Posts must reach followers within ~5 seconds.

### Approach 1: Query on Read (Pull)

Client polls every 5 seconds with a SQL query that joins `users`, `posts`, `follows`.

**Math**:
- 10M online users / 5 s polling = **2 million queries/sec**.
- Each query fans out to 200 followed users = **400 million post lookups/sec**.

**Problems**:
- Crushing read load.
- Worst case is far worse: some users follow tens of thousands of accounts.
- Read latency dominated by the join + sort across many users' posts.

### Approach 2: Precompute on Write (Push / Materialized View)

Maintain a per-user home-timeline cache. Each new post is delivered (fanned out) into every follower's timeline. Reads serve directly from the cache.

**Math**:
- 5,800 posts/sec average × 200 followers = **~1.16 million timeline writes/sec**.
- Reads become a single cache lookup per user.

**Trade-offs**:
- Trades read cost for write cost (writes go up, reads go down).
- During spikes, fan-out work can be enqueued; timelines stay fast to load from cache.
- Edge cases require special handling:
  - **Heavy followers**: a user following thousands of high-volume accounts has too many writes — drop some, sample the timeline.
  - **Celebrities**: posts by accounts with 100M+ followers cannot fan out to every timeline; store separately and merge in at read time.

**Lesson**: Optimize for the dominant operation. Read-heavy systems often benefit from materialization despite higher write cost.

### Comparison

| Approach | Reads | Writes | Failure mode |
|----------|-------|--------|--------------|
| Query on read | 400M lookups/sec | Cheap | Slow reads, expensive joins |
| Precompute (push) | 1 cache hit | ~1.2M writes/sec | Celebrity / heavy-follower edge cases |

## Percentile Examples

### Reading a Distribution

Suppose you record the response time of 100 requests and sort them.

```
Median (p50)    = 200 ms     -> 50 requests faster, 50 slower
95th pct (p95)  = 1.5 s      -> 95 requests faster, 5 slower
99th pct (p99)  = 3.0 s      -> 99 requests faster, 1 slower
99.9th (p999)   = 8.0 s      -> ~999 of 1000 faster
```

The **mean** could be ~350 ms — pulled up by the tail, but unrepresentative of any actual user.

### Why p999 Matters: Amazon's Heavy Customers

Amazon defines internal-service SLOs at the **p99.9** because:
- The slowest requests come from the customers with the most data.
- Those customers are typically the most valuable (most purchase history).
- Slowness for them disproportionately impacts revenue.

p99.99 was deemed too expensive — diminishing returns and dominated by random external events.

### Tail Latency Amplification (Fan-Out)

A single end-user request triggers 10 backend calls in parallel; the user waits for the slowest.

If each backend independently has p99 = 1 s (1% slow):
- Probability all 10 are fast = 0.99^10 ~= 0.904
- Probability at least one is slow = ~9.6%

So **~10% of end-user requests are slow**, even though only 1% of backend calls are.

```
Backend A:  100 ms
Backend B:  120 ms
Backend C:  900 ms   <-- slowest, defines user-perceived latency
Backend D:  150 ms
...
End-user wait = 900 ms
```

## Example SLO Definition

```
Service: timeline-api

SLO (rolling 5-minute window):
  - p50 response time     : < 200 ms
  - p99 response time     : < 1 s
  - p999 response time    : < 3 s   (critical path)
  - Availability          : >= 99.9% non-error on valid requests

Throughput target         : sustain 5,800 req/sec, peak 150,000 req/sec
SLA penalty               : refund tier if monthly availability < 99.9%
```

## Latency Distribution (Textual)

A typical web service distribution looks log-normal-ish: a tall cluster of fast requests with a long right tail.

```
Count
 |
 |  ##
 |  ###
 |  ####
 |  ######  <- bulk near median (~200 ms)
 |  ########
 |    ##########
 |       #########
 |          #######
 |             ######
 |                ####
 |                  ###
 |                    ##  <- tail extends to seconds
 |                     #     (p99, p999 live here)
 +---------------------------------------------> Response time
   0      200 ms              1 s         3 s+
              ^                ^           ^
             p50              p99         p999
```

The mean is pulled to the right by the tail; the median sits at the peak of the bulk.

## Throughput vs. Response Time

As load grows toward hardware capacity, queueing dominates and response time rises sharply (a "hockey stick" curve).

```
Response
 time
   |                                 *
   |                              *
   |                          *
   |                    *
   |          *
   |   *  *
   +-------------------------------------> Throughput
                                  ^
                            max throughput
                            (queueing explodes)
```

Operating near maximum throughput is dangerous: small load increases cause large latency increases, and retries can trigger metastable failure.
