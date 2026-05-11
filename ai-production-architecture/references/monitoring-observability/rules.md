# Monitoring & Observability Rules

Guidelines for what to monitor, log, and trace in LLM applications, plus drift detection and orchestration.

## Core Rules

### 1. Design Metrics Around Failure Modes, Not the Other Way Around

Identify the failure modes you cannot tolerate first; pick metrics that detect those failures.

- Don't hallucinate => measure whether output is inferable from context
- Don't burn API credit => track input/output tokens per request, cache hit rate, cache cost
- Don't leak PII => detect sensitive data in inputs and outputs

### 2. Track the Full Metric Stack

Cover quality, safety, latency, and cost — at minimum.

- **Quality**: format validity (e.g., JSON), factual consistency, AI-judge scores
- **Safety**: toxicity rate, guardrail trigger rate, refusal rate, abnormal query rate
- **Conversational**: stop-generation rate, turns/conversation, tokens in/out, output diversity
- **Latency**: TTFT, TPOT, total latency (track per user)
- **Cost**: queries/sec, input/output tokens, requests/sec for rate-limited APIs

### 3. Log Everything

You cannot predict which logs you'll need during a future incident.

- Configs: API endpoint, model name, temperature, top-p, top-k, stopping conditions, prompt template
- Per-request: user query, final prompt, output, intermediate outputs, tool calls, tool outputs
- Lifecycle: component start, end, crashes
- Always attach tags and request/component IDs for correlation

### 4. Make Logs Readily Available

If logs lag behind metrics, debugging stalls.

- A 15-minute log delay means you cannot debug a 5-minute-old metric spike
- Stream logs into a queryable store; don't rely on batched daily exports

### 5. Trace Every Request End-to-End

Every query should be reconstructable step-by-step.

- Capture each step's inputs, outputs, latency, and cost
- On failure, you must be able to point at the exact bad step (preprocessing, retrieval, generation)

### 6. Make Metrics Decomposable

Aggregate metrics hide the regression — break them down.

- By user, release, prompt/chain version, prompt/chain type, time window
- Without breakdown, you can't isolate which release or prompt version caused the drop

### 7. Combine Spot Checks with Exhaustive Checks

Use both for balanced coverage.

- **Spot checks**: sample a subset for fast iteration on expensive metrics (e.g., AI judges)
- **Exhaustive checks**: cover every request for cheap metrics (latency, token counts, format validity)

### 8. Detect All Three Drift Types

Build separate detectors for each.

- **Prompt drift**: hash the system prompt; alert on change
- **User drift**: monitor input distribution shifts (length, topic, query patterns) over rolling windows
- **Model drift**: pin model versions; if not possible, run a fixed eval set on a schedule and alert on score deltas

### 9. Inspect Production Data Manually, Daily

Automated metrics miss novel failure modes.

- Sample real traffic daily to refresh your intuition for "good" vs. "bad" outputs
- Use observations to update prompts and evaluation pipelines (per Shankar et al., 2024)

### 10. Don't Reach for an Orchestrator on Day One

Build without LangChain/LlamaIndex first; adopt only when complexity demands it.

- Orchestrators abstract away the details you need to debug
- Migrate to one only when components, branching, or extensibility justify the abstraction tax

## Guidelines

- Correlate every metric to a north-star business metric (DAU, session duration, subscriptions); if a metric correlates with nothing, ask whether to keep tracking it
- Use AI-powered log anomaly detection — manual analysis at scale is impossible
- For latency-critical pipelines, run independent steps in parallel (e.g., routing and PII removal at the same time)
- When evaluating an orchestrator, score it on integration/extensibility, support for complex pipelines (branching, parallelism, error handling), and ease of use/performance/scalability
- Avoid orchestrators that make hidden API calls or introduce unmeasured latency

## Exceptions

- **Tiny single-prompt apps**: full tracing infrastructure may be overkill — basic logs plus latency/cost metrics can be enough
- **Strict-budget exhaustive checks**: if AI-judge cost is prohibitive, fall back to spot checks plus cheap deterministic checks on every request
- **Pinned-version model**: drift detection for model changes can be relaxed when you control the model artifact (self-hosted, frozen weights)

## Quick Reference

| Rule | Summary |
|------|---------|
| Failure-mode-first | Pick metrics from failures, not vice versa |
| Log everything | Configs, queries, prompts, outputs, tool I/O, lifecycle |
| Trace end-to-end | Every step's input/output/latency/cost |
| Decompose metrics | By user, release, version, type, time |
| Spot + exhaustive | Cheap checks on all, expensive checks on samples |
| Three drifts | Prompt, user, underlying model |
| Daily manual review | Read live data to refresh intuition |
| No premature orchestrator | Start without LangChain/LlamaIndex |
