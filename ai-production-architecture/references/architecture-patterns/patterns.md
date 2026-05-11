# AI Engineering Architecture Patterns

Reusable architecture patterns for production foundation model applications.

## Pattern: Route-Retrieve-Generate-Score

**Intent**: Standard production pipeline - intent dispatching, grounding, generation, quality gating in one consistent order.

**When**: Multi-intent applications, mixed specialized + generalist models, anytime you want quality scoring before responses ship.

```python
def pipeline(query):
    intent = router.predict(query)
    if intent == "out_of_scope":
        return STOCK_RESPONSE
    docs = retriever.search(query, intent)
    response = generator.generate(query, docs)
    if scorer.score(response) < THRESHOLD:
        return fallback_handler(query)
    return response
```

**Notes**: Stock responses skip API calls entirely. Specialized models per intent improve quality and reduce cost. Each step adds latency - parallelize where possible.

---

## Pattern: PII Mask-Generate-Unmask

**Intent**: Send sensitive data through third-party APIs without leaking it, while preserving response usefulness.

**When**: External API calls with user PII; conversational apps where users mention phone/email/SSN/account IDs; internal data that must not leave the org.

```python
masked_prompt, reverse = mask_pii(prompt)
response = external_api.call(masked_prompt)
final = unmask_pii(response, reverse)
```

**Notes**: Eliminates one major class of data leak. Detection is imperfect; combine pattern matching + ML detection. Some prompts become incoherent when masked - test carefully.

---

## Pattern: Parallel Redundant Calls

**Intent**: Reduce user-perceived latency from retries while improving reliability.

**When**: High-stakes responses where one failure is unacceptable; latency budgets that can't tolerate sequential retry; budget allows 2-3x API spend.

```python
responses = await asyncio.gather(
    model.generate(prompt),
    model.generate(prompt),
)
return pick_best(responses)
```

**Notes**: Same latency as single call (best case), N times less likely to fail. Linearly multiplies API cost. Quality picker matters - random pick wastes the redundancy.

---

## Pattern: Gateway-Mediated Fallback Chain

**Intent**: Survive rate limits and outages by automatically falling back to alternative providers/models.

**When**: Production apps where downtime is costly; multi-provider deployments; apps subject to per-model rate limits.

```python
def generate_with_fallback(prompt, chain):
    for model in chain:
        try:
            return gateway.generate(model, prompt)
        except (RateLimitError, APIError):
            continue
    raise AllProvidersFailedError()
```

**Notes**: Decouples app code from per-provider failure handling. Centralized chain config makes provider swaps trivial. Fallback models may differ in capabilities - verify outputs match.

---

## Pattern: Cache Classifier Gate

**Intent**: Decide automatically whether each query is safe and worthwhile to cache.

**When**: Mixed query workload (some user-specific, some generic); risk of leaking one user's data to another via cached responses.

```python
def cached_call(query):
    if is_cacheable(query):
        if cached := cache.get(query):
            return cached
    response = model.generate(query)
    if is_cacheable(query):
        cache.put(query, response)
    return response
```

**Notes**: Prevents the "user X's data returned to user Y" failure. Default to "not cacheable" when classifier is uncertain.

---

## Pattern: Tiered Cache (Exact + Semantic)

**Intent**: Combine fast cheap exact lookup with broader semantic matching for higher hit rates.

**When**: High query volume with both exact repeats and many phrasings; tight latency budget on the common case.

```python
def tiered_lookup(query):
    if hit := exact_cache.get(query):
        return hit
    if hit := semantic_cache.get(query):
        return hit
    return None
```

**Notes**: Common case stays microseconds-fast. Semantic cache only pays vector-search cost on exact-cache miss. Write semantic hits back to exact cache to amortize.

---

## Pattern: Self-Critique Loop

**Intent**: Let the model evaluate its own output and request more context when incomplete.

**When**: Complex multi-step questions; tasks where one retrieval pass is often insufficient; agents that can call tools iteratively.

```python
response = model.generate(query, context)
for _ in range(MAX_ITERS):
    critique = model.critique(query, response)
    if critique["complete"]:
        break
    extra = retriever.search(critique["missing_info"])
    response = model.generate(query, context + extra)
```

**Notes**: Handles questions a single pass would underanswer. N times the cost in worst case - always cap iterations. Critique model may rubber-stamp bad responses.

---

## Pattern: Allowlisted Write Action with Approval

**Intent**: Let agents take real-world actions safely - only approved actions, with human confirmation when irreversible.

**When**: Agents with side-effecting tools (email, payments, DB writes); customer-facing automation that touches money or trust; any production agentic system.

```python
ALLOWED = {"send_email", "create_ticket"}
IRREVERSIBLE = {"send_email", "place_order", "transfer_funds"}

def execute(action):
    if action["type"] not in ALLOWED:
        raise PermissionError()
    if action["type"] in IRREVERSIBLE and not human.approve(action):
        return {"status": "denied"}
    result = TOOLS[action["type"]](**action["params"])
    audit_log(action, result)
    return result
```

**Notes**: Allowlist prevents arbitrary action execution from prompt injection. Human gate stops irreversible mistakes - treat friction as a feature. Keep allowlist narrow.

---

## Pattern Selection Guide

| Situation | Pattern |
|-----------|---------|
| Multi-intent chatbot | Route-Retrieve-Generate-Score |
| Sending PII to external APIs | PII Mask-Generate-Unmask |
| Need redundancy without latency hit | Parallel Redundant Calls |
| Provider outages must not break app | Gateway-Mediated Fallback Chain |
| Mixed user-specific + generic queries | Cache Classifier Gate |
| High volume with FAQ-like patterns | Tiered Cache (Exact + Semantic) |
| Complex multi-step questions | Self-Critique Loop |
| Agent with email/payment/DB writes | Allowlisted Write Action with Approval |
