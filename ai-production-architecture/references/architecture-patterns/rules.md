# AI Engineering Architecture Rules

Guidelines for selecting and configuring each layer of a production foundation model application.

## Core Rules

### 1. Start Simple, Add Components Only When Needed

Begin with `query -> model -> response`. Add each architectural step only when a concrete problem demands it.

- Don't add caching before measuring repeat-query patterns
- Don't add a router until you have multiple specialized models
- Don't add a gateway until you have multiple model providers or access-control needs

### 2. Enhance Context Before Tuning Models

When output quality is poor, add context (RAG, tools) before considering fine-tuning. Context construction is "feature engineering for foundation models."

- Use tools when the model needs live data (web search, weather, APIs)
- Use retrieval when grounding in your data is required
- Verify provider-side limits on file uploads and tool execution modes

### 3. Wrap Risk Boundaries with Guardrails

Place guardrails wherever a risk boundary exists - between users and your system, between your system and external APIs, between your system and write actions.

**Input guardrails MUST include**:
- Sensitive data detection (PII, IDs, faces, IP keywords) before sending to third-party APIs
- Either *block* the query or *mask* PII with placeholders backed by a reverse dictionary

**Output guardrails SHOULD catch**:
- Empty responses (easiest failure to detect)
- Malformed responses (e.g., invalid JSON)
- Hallucinations / factual inconsistency
- Toxic content, leaked secrets, brand-risk responses
- Responses that trigger remote tool/code execution

### 4. Track False Refusal Rate, Not Just Block Rate

Over-restrictive guardrails frustrate users. Always measure both:
- True security failure rate (bad output that escaped)
- False refusal rate (legitimate requests that were blocked)

A system that's too secure is also broken.

### 5. Use Retry Before Fallback Before Human

Failure-handling order for cheap mitigation:

1. **Retry** (sequential or parallel) - models are probabilistic, often a re-run succeeds
2. **Parallel-redundant calls** - issue N requests in parallel, pick best (more cost, less latency)
3. **Fallback to alternative model** via gateway
4. **Hand off to human** for sentiment/loop/policy triggers

### 6. Routers Must Be Fast and Cheap

A router runs on every query. If it's slow or expensive, it negates the point.

- Use small models: GPT-2, BERT, Llama-7B-class, or trained-from-scratch classifiers
- Run intent classification before retrieval and generation
- Use stock responses for out-of-scope queries to skip API calls entirely

### 7. Centralize Model Access Through a Gateway

Never hand out raw API keys. Route everything through a model gateway for:

- Centralized auth and per-user/per-app access control
- Rate limiting and cost monitoring
- Fallback policies on API failure or rate limits
- Unified interface (swap providers without touching apps)
- Logging, analytics, sometimes caching and guardrails

### 8. Choose Cache Type by Query Pattern

| Pattern | Use |
|---------|-----|
| Repeated identical queries (summaries, embeddings) | Exact cache |
| Many phrasings of the same question (FAQs) | Semantic cache |
| User-specific data (orders, accounts) | Do NOT cache - data leak risk |
| Time-sensitive (weather, prices) | Do NOT cache, or short TTL |
| Multi-step or expensive operations (CoT, SQL, web search) | Cache aggressively |

### 9. Always Set a Cache Eviction Policy

Unbounded caches degrade performance.

- LRU (Least Recently Used) - default for general-purpose
- LFU (Least Frequently Used) - good when popularity matters more than recency
- FIFO - simplest, use when access patterns are uniform

### 10. Treat Write Actions Like Loaded Weapons

Write actions (email, payment, DB mutation) make the system vastly more capable AND vastly more dangerous.

- Require explicit allowlisting per tool
- Always include human-in-the-loop confirmation for irreversible actions
- Log every write action with full context for audit
- Apply output guardrails specifically tuned for write-triggering responses

## Guidelines

- Routing-retrieval-generation-scoring is the most common pattern - default to it
- Self-hosted models reduce input guardrail needs (no data leaves) but require building out the inference stack
- Stream completion mode breaks output guardrails - choose one or the other consciously
- Don't reinvent caching, gateways, or guardrails - off-the-shelf solutions exist (NeMo Guardrails, Portkey, MLflow Gateway, etc.)
- Train a small classifier to decide what's cacheable vs not when query types are diverse

## Exceptions

- **Latency-critical apps**: May skip output guardrails if SLA cannot tolerate the extra round-trip
- **Self-hosted-only deployments**: May skip PII input guardrails since data never leaves
- **Single-model apps**: Skip the router; gateway alone is enough
- **Low-volume apps**: Skip caching - operational complexity outweighs savings

## Quick Reference

| Rule | Summary |
|------|---------|
| Start simple | Add components only when problems arise |
| Context first | RAG/tools before fine-tuning |
| Guardrail risk boundaries | Wrap inputs and outputs at exposure points |
| Track false refusals | Over-blocking is also failure |
| Retry > fallback > human | Cheapest mitigation first |
| Routers are small | Fast, cheap, run before retrieval |
| Gateway centralizes access | Auth, fallback, logging, cost in one place |
| Cache by pattern | Exact for identical, semantic for similar, never for user-specific |
| Always set eviction | LRU/LFU/FIFO |
| Write actions need approval | Allowlist + human-in-the-loop |
