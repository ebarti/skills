# Distributed System Failures Examples

Real-world incidents, fault patterns, and detection algorithms illustrating distributed failure modes.

## Famous Network Partition Incidents

### Heroku — EU↔US Partition Triggering Data Loss

In 2013, a network partition between Heroku's EU and US regions caused a Postgres cluster to elect two leaders simultaneously. Both sides accepted writes during the split. On reconnection the system could not reconcile divergent histories, and data was lost.

**Lesson**:
- Single-leader replication without quorum-based failover is dangerous under partition
- Always require a majority (>N/2) to elect a leader
- "If software is put in an unanticipated situation, it may do arbitrary unexpected things"

### GitHub — 24-Hour Degradation from MySQL Failover

In October 2018, a 43-second WAN partition caused GitHub's MySQL primary in the US East to be demoted while the US West replica was promoted. Recovery required reconciling 954 writes that diverged in those 43 seconds; the site was degraded for over 24 hours.

**Lesson**:
- Brief partitions cascade into hours of recovery work
- "Even a brief network interruption can have repercussions that last for much longer"
- Failover policy needs to account for asymmetric WAN partitions

### AWS — DynamoDB 2015 Cascade

A storage subsystem behind DynamoDB metadata experienced a network event; nodes started timing out, retried aggressively, saturated the network further, and triggered a cascading metastable failure across the region. Recovery required throttling external traffic.

**Lesson**:
- Aggressive retries during a brownout amplify the failure
- Need backpressure and admission control to prevent retry storms
- This is "When an Overloaded System Won't Recover" in practice

## TCP Head-of-Line Blocking

```
TCP stream: [pkt 1] [pkt 2] [pkt 3] [pkt 4] [pkt 5]
                        ^^ LOST
Receiver application:
  reads pkt 1 -> OK
  reads pkt 2 -> OK
  blocks waiting for pkt 3 (even though 4, 5 arrived)
  ... 200ms RTO ...
  pkt 3 retransmitted, then 4, 5 delivered
```

**Effect**:
- Application sees a 200ms+ stall even though only one packet was lost
- Other independent messages multiplexed on the same connection ALL stall
- This is why HTTP/2 (multiplexed over TCP) suffers under loss
- HTTP/3 / QUIC moves to UDP precisely to avoid this

**Mitigation**:
- Use separate TCP connections for unrelated streams
- Switch to QUIC for multiplexed workloads with packet loss
- Don't conflate TCP "reliability" with low-latency delivery

## Timeout Misconfiguration Scenarios

### Scenario 1: Too Short — Cascading Failure

```yaml
# Bad: 1s timeout against a service whose p99 = 1.2s
upstream_timeout: 1s
retry_attempts: 3
```

**What happens**:
- Under load, p99 routinely exceeds 1s → false positives
- Each request becomes 3 retries, tripling load on the upstream
- Upstream slows further → more timeouts → more retries
- Self-sustaining outage even after the original trigger is gone

### Scenario 2: Too Long — Unresponsive UI

```yaml
# Bad: 30s timeout on a user-facing path
search_timeout: 30s
```

**What happens**:
- A dead backend is not detected for 30 seconds per user
- Connection pool exhausts; healthy users wait too
- The user-facing TTFB blows past acceptable budgets
- Operators believe "the network is slow" rather than "node X is dead"

### Scenario 3: Asymmetric Timeouts

```
Client timeout:  5s
Server timeout: 10s
```

**What happens**:
- Server still working on request after client gives up
- Client retries, server now processes the same request twice
- Without idempotency, side effects (charges, emails) duplicate
- Always: client timeout > server processing budget + safety, or use idempotency keys

## Phi Accrual Failure Detector (Cassandra / Akka)

Instead of a binary alive/dead based on a hard timeout, the Phi accrual detector outputs a continuous *suspicion level* (phi).

```python
# Pseudocode of the algorithm
class PhiAccrualDetector:
    def __init__(self, threshold=8.0, window=1000):
        self.arrival_intervals = SlidingWindow(size=window)
        self.last_heartbeat = now()
        self.threshold = threshold

    def heartbeat(self):
        interval = now() - self.last_heartbeat
        self.arrival_intervals.add(interval)
        self.last_heartbeat = now()

    def phi(self):
        # Probability that a heartbeat arrives later than now,
        # given the observed distribution
        elapsed = now() - self.last_heartbeat
        mean = self.arrival_intervals.mean()
        stddev = self.arrival_intervals.stddev()
        # Higher phi = more suspicious
        return -log10(probability_late(elapsed, mean, stddev))

    def is_suspect(self):
        return self.phi() > self.threshold
```

**Why it works**:
- Adapts automatically to network jitter — no manual tuning
- A node on a high-variance network gets more grace before suspicion
- Phi=1 means "10% chance still alive", phi=8 means "10⁻⁸ chance still alive"
- Used in Cassandra (gossip), Akka cluster membership

## Network Congestion in Microservices (Cascading Failure)

```
[client]
    |
    v
[service A] -----> [service B] -----> [service C]
                                          |
                                          v
                                    (slow query, 500ms)
```

**Cascading failure scenario**:

1. Service C develops 500ms latency (slow query)
2. Service B's connection pool to C fills up — all threads blocked waiting
3. Service B's pool to A's callers fills — A's requests start to time out
4. A retries 3x → traffic to B triples
5. B's CPU spikes handling failed connections, can't process the few good responses
6. Service A times out — clients retry → load amplifies further
7. The whole chain locks up; restarting C alone doesn't help because the retry storm continues

**What prevents it**:
- Circuit breakers on B → stop calling C entirely until C recovers
- Bulkheads: separate thread pools per downstream so one slow dep doesn't starve others
- Backpressure: B sheds load (returns 503) when its queue exceeds threshold
- Retry budgets (e.g., 10% of requests max) so retries can't dominate traffic
- Adaptive concurrency limits (e.g., Netflix concurrency-limits / TCP Vegas-style)

## Asymmetric and One-Way Failures

Real failures observed in production:

| Failure | Symptom |
|---------|---------|
| NIC drops inbound | Outbound traffic flows; node cannot receive requests, looks dead to peers |
| NIC drops outbound | Inbound flows; node thinks all peers are dead, tries to elect itself leader |
| A↔B + B↔C, A⊥C | Triangle inequality violated; gossip protocols can mask, point-to-point fails |
| Switch loop after upgrade | Packets delayed by minutes (observed during topology reconfig) |
| BGP misroute | Cross-region RTT jumps from 80ms to several minutes |

**Lesson**: A single direction working tells you nothing about the reverse direction. Bi-directional health checks required.

## Quick Reference

| Pattern | Fix |
|---------|-----|
| TCP head-of-line blocking | Use QUIC, separate connections per stream |
| Timeout too short | Adaptive timeout, Phi accrual detector |
| Timeout too long | Bounded by user SLO; circuit breakers |
| Retry storm | Retry budget, exponential backoff + jitter |
| Cascading slowness | Bulkheads, backpressure, circuit breakers |
| Asymmetric partition | Bi-directional health checks, quorum-based decisions |
