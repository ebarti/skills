# Production Observability Checklist

Use before promoting an LLM application to production and during periodic audits.

## Before You Start

- [ ] Failure modes you cannot tolerate are listed (hallucination, PII leak, cost blowout, latency, refusal, etc.)
- [ ] North-star business metric is identified (DAU, session duration, subscriptions)
- [ ] Model version is pinned (specific snapshot, not floating alias)

## Metrics

- [ ] Format-quality metric per response type (e.g., JSON validity, schema match)
- [ ] Open-ended quality metric (factual consistency or AI-judge score)
- [ ] Safety metrics: toxicity, PII detection, guardrail trigger rate, refusal rate
- [ ] Conversational signals: stop-generation rate, turns/conversation, tokens in/out, output diversity
- [ ] Latency: TTFT, TPOT, total latency, all measured per user
- [ ] Cost: queries/sec, input/output tokens, requests/sec vs. rate limits
- [ ] Per-component metrics (retrieval relevance/precision, vector DB query time, tool error rate)
- [ ] Every metric is labeled with: user, release, prompt/chain version, prompt/chain type, time
- [ ] Spot-check sampling configured for expensive metrics
- [ ] Exhaustive coverage configured for cheap metrics

## Logs

- [ ] Configs logged: API endpoint, model name, temperature, top-p, top-k, stopping conditions, prompt template version
- [ ] User query logged
- [ ] Final assembled prompt logged
- [ ] Model output logged
- [ ] Intermediate outputs logged (preprocessing, retrieval results)
- [ ] Tool invocations and tool outputs logged
- [ ] Lifecycle events logged (component start, end, crashes)
- [ ] Each log has request ID, user ID (or hash), component tag, and timestamp
- [ ] Logs are queryable within 1-2 minutes of emission (no 15-minute delays)
- [ ] Log retention covers your incident-response window
- [ ] AI-powered log anomaly detection enabled (manual review does not scale)

## Traces

- [ ] Every request has a unique trace ID
- [ ] Each pipeline step is a span with input, output, duration, and cost
- [ ] Spans are nested to reflect the call graph
- [ ] A failed query can be pinpointed to a single span
- [ ] Traces are visualized (LangSmith, Langfuse, custom UI)

## Drift Detection

- [ ] System prompt hash check on startup and on every emit
- [ ] User-behavior drift monitored: rolling distribution of input length, topic, language
- [ ] Underlying model drift: fixed golden eval set runs on a schedule, alerts on score delta
- [ ] Drift alerts route to a human, not just a dashboard

## Orchestration

- [ ] Decision made to use or not use an orchestrator (justified, not default)
- [ ] If orchestrator chosen: integration/extensibility, complex-pipeline support, performance evaluated
- [ ] Independent steps run in parallel where latency matters (e.g., routing + PII removal)
- [ ] Orchestrator does not introduce hidden API calls or unmeasured latency
- [ ] Component failures and data-format mismatches between steps surface as alerts

## Operational Hygiene

- [ ] At least one engineer manually reviews live production samples daily
- [ ] Review findings feed back into prompts and evaluation pipelines
- [ ] Metric correlation to north-star metric is reviewed quarterly
- [ ] Cost dashboards visible to the team

## Red Flags

Stop and address if you find:

- Floating model alias (`gpt-4o`, `claude-sonnet-latest`) in production code
- Logs missing the assembled prompt or sampling params
- A single global "quality score" with no breakdown axes
- No drift detector for the system prompt
- Orchestrator added before the application has shipped
- Aggregated metrics only — no traces to debug a single bad request
- AI-judge metrics computed exhaustively at high cost when sampling would do
- Manual log review never happens

## Quick Reference

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| Model versioning | Pinned snapshot | Pinned alias with drift checks | Floating alias |
| Logging | Structured, full context, IDs | Structured outputs only | Final response only |
| Tracing | Per-step spans with cost | Per-step timing | None |
| Metric breakdown | All 5 axes (user/release/version/type/time) | Release + version | Single global value |
| Drift coverage | All 3 (prompt/user/model) | Prompt + model | None |
| Orchestrator | Adopted when justified | Built without one | Added on day one |
| Manual review | Daily with feedback loop | Weekly | Never |
