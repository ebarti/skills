# Setup Observability Workflow

Wire up metrics, logs, traces, and drift detection for an AI system.

## When to Use

- New AI feature is going to production
- Existing AI feature has no observability
- Production AI degraded silently and you want to catch it earlier

## Prerequisites

- Production AI feature deployed (or about to be)
- Observability infrastructure (logging, metrics, tracing)
- Eval set you can run periodically

**Reference**: `references/monitoring-observability/rules.md`

---

## Workflow Steps

### Step 1: Define Failure Modes First

**Goal**: Design metrics around what can actually go wrong.

- [ ] List failure modes specific to this feature (factual error, refusal, format error, latency spike, cost spike)
- [ ] For each failure mode, identify a measurable signal
- [ ] Map signals to metric names you'll instrument
- [ ] **Don't** start with "measure everything" — start with what fails

**Reference**: `references/monitoring-observability/rules.md`

---

### Step 2: Instrument Metrics

**Goal**: Measure quality, safety, conversational, latency, and cost dimensions.

#### Quality metrics
- [ ] AI judge spot-check rate / score
- [ ] User feedback rate (thumbs up/down)
- [ ] Task success rate (where verifiable)

#### Safety metrics
- [ ] Refusal rate
- [ ] Toxicity / unsafe output rate
- [ ] PII leakage incidents

#### Conversational metrics (if chatbot)
- [ ] Turn count per session
- [ ] Abandonment rate
- [ ] Resolution rate

#### Latency metrics
- [ ] TTFT, TPOT, total latency (p50, p95, p99)

#### Cost metrics
- [ ] Cost per request (with breakdown by model)
- [ ] Cumulative daily cost

- [ ] Add labels: user, release, model version, prompt version, request type, time

**Reference**: `references/monitoring-observability/examples.md`

---

### Step 3: Wire Up Structured Logging

**Goal**: Log everything; you'll wish you had it later.

- [ ] Log per request: input, system prompt hash, model+version, sampling params, output, latency, cost, user ID (with consent), session ID
- [ ] Append-only event log (immutable)
- [ ] Structured (JSON), not free-text
- [ ] Verify logs are queryable (Elastic, BigQuery, etc.)
- [ ] Document retention policy (privacy-aware)

**Reference**: `references/monitoring-observability/rules.md`, `references/monitoring-observability/examples.md`

---

### Step 4: Wire Up Tracing

**Goal**: Reconstruct the path of any single request.

- [ ] Use a tracing system (OpenTelemetry, LangSmith, Phoenix, Langfuse)
- [ ] Trace every component: LLM call, tool call, RAG retrieve, validator
- [ ] Each span: start time, duration, inputs, outputs, errors
- [ ] Link spans to user-visible request ID

**Reference**: `references/monitoring-observability/examples.md`

---

### Step 5: Set Up Drift Detection

**Goal**: Catch silent quality regression.

#### System prompt drift
- [ ] Pin prompt version (hash); alert if hash changes unexpectedly

#### User behavior drift
- [ ] Track distribution of user inputs over time
- [ ] Alert on shifts (volume spike, new query types)

#### Model drift
- [ ] Pin model version (avoid floating aliases like "latest")
- [ ] Run a golden eval set periodically (daily) and alert on regression
- [ ] Chen et al. (2023) found significant cross-version GPT deltas — catch them

**Reference**: `references/monitoring-observability/rules.md`, `references/monitoring-observability/examples.md`

---

### Step 6: Schedule Manual Review

**Goal**: Eyeball samples regularly; metrics miss what humans catch.

- [ ] Daily: read 10-20 random transcripts (Shankar et al. 2024 finding)
- [ ] Weekly: review top failure modes by metric
- [ ] Monthly: refresh the eval set with new edge cases from production
- [ ] Document findings; feed back into prompts/data/model selection

**Reference**: `references/monitoring-observability/rules.md`

---

### Step 7: Walk the Production Checklist

**Goal**: Final verification.

- [ ] Walk every item in `references/monitoring-observability/checklist.md`
- [ ] Document status of each
- [ ] Get sign-off

**Reference**: `references/monitoring-observability/checklist.md`

---

## Quick Checklist

```
[ ] Step 1: Failure modes identified, signals mapped
[ ] Step 2: Metrics instrumented with labels
[ ] Step 3: Structured logging in place
[ ] Step 4: Tracing in place
[ ] Step 5: Drift detection (prompt + user + model)
[ ] Step 6: Manual review scheduled
[ ] Step 7: Production checklist passed
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Output-only logging | Can't reproduce failures | Log inputs, prompts, params, all of it |
| Single global quality score | Hides per-segment regressions | Decompose with labels |
| Floating model alias | Silent quality drift | Pin specific version |
| No manual review | Metrics can't see novel failures | Read 10-20 transcripts daily |
| Premature orchestrator | Adds complexity, hides debugging | Add only when you have multiple pipelines |

---

## Exit Criteria

- [ ] Metrics, logs, traces wired and queryable
- [ ] Alerts configured for failure modes
- [ ] Drift detection running
- [ ] Manual review scheduled and documented
- [ ] On-call playbook with where to look first
