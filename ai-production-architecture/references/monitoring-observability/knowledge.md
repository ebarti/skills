# Monitoring & Observability Knowledge

Core concepts for monitoring and observing LLM-based AI systems in production.

## Overview

Monitoring tracks a system's information; observability is the whole process of instrumenting, tracking, and debugging the system. For AI applications, observability spans three pillars (metrics, logs, traces) plus drift detection, since open-ended foundation model outputs create many failure modes a traditional monitoring stack will miss.

## Key Concepts

### Metrics

**Definition**: Numerical measurements representing attributes and events, typically aggregated over time.

Metrics aren't the goal — their purpose is to tell you when something is wrong and surface improvement opportunities. Design metrics around the failure modes you want to catch (e.g., if hallucinations matter, measure whether outputs can be inferred from context).

**Key categories for LLMs**:
- **Format quality** (easy to verify): invalid JSON rate, fixable vs. unfixable malformations
- **Open-ended quality**: factual consistency, conciseness, creativity, positivity (often via AI judges)
- **Safety**: toxicity, PII detection, guardrail trigger rate, refusal rate, abnormal queries
- **Conversational signals**: stop-generation rate, turns per conversation, tokens per input/output, output token diversity
- **Latency**: TTFT (time to first token), TPOT (time per output token), total latency
- **Cost**: queries, input/output token volume, tokens per second, requests per second (for rate limits)
- **Component-specific**: e.g., RAG context relevance/precision, vector DB storage and query time

### Logs

**Definition**: An append-only record of events that occur in the system.

Where metrics tell you *that* something went wrong, logs tell you *what* happened. The general rule: **log everything**, because you don't know in advance what you'll need.

**What to log**:
- Configurations: model API endpoint, model name, sampling settings (temperature, top-p, top-k, stopping conditions), prompt templates
- Per-request: user query, final assembled prompt, output, intermediate outputs
- Tool calls and tool outputs
- Lifecycle events: component start/end, crashes
- Tags and IDs identifying log origin in the system

### Traces

**Definition**: Reconstructed timelines linking related events to show a request's full execution path through system components.

A trace shows the entire process from query receipt to final response — actions taken, documents retrieved, prompts sent, time and cost per step. If a query fails, traces let you pinpoint the exact step (bad processing, irrelevant retrieval, wrong generation).

### Drift Detection

**Definition**: Detecting unexpected changes in the system, its inputs, or its underlying models.

Three drift sources in AI applications:

- **System prompt drift**: prompts change without your knowledge (template updates, coworker fixes). Simple equality checks catch these.
- **User behavior drift**: users adapt to the technology (learn to write more concise prompts, find prompt attacks). Causes gradual metric shifts requiring root-cause investigation.
- **Underlying model drift**: API stays stable but the served model is updated by the provider (often undisclosed). Different versions of the same API can cause significant performance changes (e.g., 10% drop reported when switching GPT-3.5-turbo versions).

### AI Pipeline Orchestration

**Definition**: A tool for specifying how multiple components (models, retrievers, tools, evaluators) work together as an end-to-end pipeline.

Operates in two steps:
- **Components definition**: declare models, data sources, tools, evaluation/monitoring hooks
- **Chaining (function composition)**: define the steps from query to response

Distinct from general workflow orchestrators like Airflow or Metaflow.

## Terminology

| Term | Definition |
|------|------------|
| Monitoring | Tracking a system's information |
| Observability | Instrumentation + tracking + debugging the system |
| TTFT | Time To First Token |
| TPOT | Time Per Output Token |
| Spot check | Sampling a subset of requests for evaluation |
| Exhaustive check | Evaluating every request |
| Trace | Linked timeline of one request's path through the system |
| North star metric | Top-level business metric (DAU, session duration, subscriptions) |
| Drift | Unexpected change in prompts, users, or underlying model |
| Chaining | Composing components into a pipeline |

## How It Relates To

- **Evaluation**: monitoring metrics often reuse evaluation methods (AI judges, factual consistency) applied to live traffic
- **RAG/Agents**: each pipeline component (retriever, vector DB, tool) needs its own metrics
- **Inference optimization**: TTFT/TPOT/total latency are the levers optimization targets
- **User feedback**: conversational signals (stops, turn counts) bridge implicit feedback and quality monitoring

## Common Misconceptions

- **Myth**: Standard APM is enough for LLM apps.
  **Reality**: Standard APM misses output-quality, hallucination, drift, and prompt-attack signals unique to AI systems.

- **Myth**: Pick metrics first, then design the system.
  **Reality**: Identify failure modes first; design metrics to catch *those* failures.

- **Myth**: A stable API means a stable model.
  **Reality**: Providers can swap the underlying model without notice — version-pin and monitor for drift.

- **Myth**: Start with an orchestrator (LangChain, LlamaIndex) on day one.
  **Reality**: Orchestrators add complexity and abstract away debugging; build without one first, adopt later if pain justifies it.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Metrics | Aggregated numbers — answer "is something wrong?" |
| Logs | Append-only events — answer "what happened?" |
| Traces | Linked timelines — answer "where did it go wrong?" |
| Drift | Silent change in prompts/users/models |
| Orchestrator | Defines components and chains them into a pipeline |
