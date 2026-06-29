# Defining Performance SLOs Workflow

A repeatable process for defining meaningful, measurable, user-centric performance SLOs distilled from DDIA Ch. 2.

## When to Use

- Launching a new user-facing service or critical internal API
- Re-baselining an existing service after a major architecture change
- A latency or availability incident exposed missing or vague performance targets
- Stakeholders disagree on what "fast enough" or "available enough" means

## Prerequisites

- A clear service boundary (what is the "request" you are measuring?)
- Some production or load-test traffic data, or a reasonable estimate of expected load
- Identified stakeholders (product, SRE, on-call engineers, key customers)

**Reference**: `references/performance/rules.md`, `references/performance/knowledge.md`, `references/reliability/rules.md`

---

## Workflow Steps

### Step 1: Identify the User-Perceived Metric

**Goal**: Pin down *what* you are measuring from the *user's* perspective, not the server's.

- [ ] Define one request type per SLO (login, search, checkout, etc.) — do not lump everything together
- [ ] Choose **response time** (client-observed, includes queueing + network), not service time
- [ ] Identify the measurement boundary (browser, mobile app, edge proxy, gateway)
- [ ] Note what counts as a "valid request" (exclude bots, health checks, malformed input)

**Ask**: "If a user complained 'this is slow,' what number would prove or disprove their claim?"

**Reference**: `references/performance/knowledge.md` (Response Time vs Service Time vs Latency)

---

### Step 2: Choose the Right Percentile

**Goal**: Pick the percentile that reflects the user impact you actually care about.

Use this decision tree:

```
Is this the typical-user baseline only?            -> p50 (median)
Standard user-facing production path?              -> p99
High-value customers / heavy users / critical path? -> p999
Internal batch / non-user-facing background work?  -> p95 or mean is fine
Tempted by p9999?                                  -> Stop. Diminishing returns.
```

- [ ] Default to **p99** unless you have a specific reason
- [ ] Use **p999** only when heavy/high-value users disproportionately hit the tail
- [ ] Add a p50 alongside any tail percentile for context
- [ ] Never report only an average

**Reference**: `references/performance/rules.md` Rule 2

---

### Step 3: Set Throughput Targets and Load Patterns

**Goal**: State capacity expectations explicitly so the SLO can be tested.

- [ ] State throughput in **"somethings per second"** (req/sec, posts/sec, MB/sec, records/day)
- [ ] Specify the hardware allocation it was measured on
- [ ] Capture **peak** load (not just average) — peaks are when SLOs break
- [ ] Capture load shape (steady, bursty, daily cycle, viral spike potential)
- [ ] Define the saturation point (% of max throughput where response time degrades)

**Reference**: `references/performance/rules.md` Rule 4

---

### Step 4: Define the Error Budget

**Goal**: Convert the SLO into a budget on-call can reason about.

- [ ] Write the SLO as **percentile + threshold + window**
- [ ] State availability separately (e.g., 99.9% non-error responses)
- [ ] Compute the implied error budget (e.g., 99.9% over 30 days = 43.2 min downtime)
- [ ] Decide the consequence of burning the budget (freeze releases? page on-call?)

**Example SLO**:
```
- p50 response time:  < 200 ms over rolling 5 min
- p99 response time:  < 1 s   over rolling 5 min
- Availability:       >= 99.9% non-error on valid requests over 30 days
- Throughput target:  500 req/sec sustained, 2000 req/sec peak
```

**Reference**: `references/reliability/rules.md`

---

### Step 5: Plan Measurement and Instrumentation

**Goal**: Decide *where* and *how* the SLO will actually be measured.

- [ ] Instrument **client-side** (or as close to the user as possible) — server logs miss queueing
- [ ] Use mergeable histograms (HdrHistogram, t-digest, DDSketch) — never average percentiles
- [ ] Tag metrics by request type, region, customer tier
- [ ] Account for **fan-out**: backends called N times per request need tighter tail SLOs
- [ ] Watch for coordinated omission in load tests (load generator stalls hide real latency)

**Reference**: `references/performance/rules.md` Rules 3, 6, 7, 8

---

### Step 6: Plan Reporting Cadence and Alerting

**Goal**: Make the SLO actionable, not just observable.

- [ ] Pick dashboard refresh window (typically rolling 5-10 min for latency, 30 days for availability)
- [ ] Set alert threshold at a **burn rate** (e.g., page if 2% of monthly budget burned in 1 hour)
- [ ] Decide who is paged and what runbook they follow
- [ ] Plan periodic SLO review cadence (monthly or quarterly)
- [ ] Plot response time **and** throughput together — context matters

**Reference**: `references/performance/rules.md` (Guidelines section)

---

### Step 7: Document and Review with Stakeholders

**Goal**: Get explicit agreement so the SLO is a shared contract, not a wish.

- [ ] Write the SLO in a single, visible document (one page max)
- [ ] Include: scope, percentile, threshold, window, throughput, availability, error budget, consequence
- [ ] Review with product (does this match user expectations?)
- [ ] Review with SRE / on-call (can we measure and defend it?)
- [ ] Review with key customers if it becomes part of an SLA
- [ ] Record the review date and the next review date

---

## Quick Checklist

```
[ ] Step 1: User-perceived metric identified (response time, client-side)
[ ] Step 2: Percentile chosen (p99 default; p999 for critical paths)
[ ] Step 3: Throughput + peak load + hardware context stated
[ ] Step 4: SLO written as percentile + threshold + window + error budget
[ ] Step 5: Client-side instrumentation + mergeable histograms planned
[ ] Step 6: Reporting cadence + burn-rate alert + runbook owner set
[ ] Step 7: Documented, reviewed, and dated
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Averaging percentiles across machines or time | Mathematically meaningless; hides tail | Aggregate histograms (HdrHistogram, t-digest) |
| Reporting only the mean response time | Skewed by outliers; hides 1% slow users | Report p50 + p99 (and p999 for critical paths) |
| Measuring on the server only | Misses queueing delay and head-of-line blocking | Instrument client-side or at the edge |
| Setting a single SLO for all request types | Login and image upload have different needs | One SLO per request type |
| Ignoring tail latency amplification in fan-out | A 1% slow backend becomes much slower at user level | Push tail targets harder for high-fan-out backends |
| Targeting p9999 by default | Diminishing returns; massive cost | Stop at p99 or p999 unless justified |
| Defining only average load | Peaks are when SLOs break | Capture peak load and burst shape |
| SLO written but never reviewed | Drifts out of sync with reality | Schedule periodic stakeholder review |
| No error budget consequence | SLO becomes aspirational, not enforced | Define what happens when budget burns |
| Coordinated omission in load tests | Measured latency understates reality | Use open-loop load generator |

---

## Exit Criteria

Task is complete when:
- [ ] One SLO document exists per critical request type
- [ ] Each SLO specifies percentile + threshold + window + throughput + availability + error budget
- [ ] Client-side measurement is instrumented and feeding a dashboard
- [ ] Burn-rate alerts are wired to on-call with a runbook
- [ ] Stakeholders have signed off and the next review date is on the calendar
