# Build Production Architecture Workflow

The 5-step AI engineering architecture from "AI Engineering" Chapter 10. Layer in only the steps you need.

## When to Use

- Designing a new production AI system
- Refactoring an existing AI system into something maintainable
- Scaling from prototype to production

## Prerequisites

- Working AI feature (prompt + LLM call works)
- Defined SLOs (latency, cost, quality)
- Production infrastructure (compute, observability)

**Reference**: `references/architecture-patterns/rules.md`

---

## Workflow Steps

### Step 1: Start Simple

**Goal**: Get the simplest possible version working before adding layers.

- [ ] Direct LLM call: input → API → output
- [ ] No router, no cache, no agent yet
- [ ] Validate that the simple version meets some baseline
- [ ] **Don't pre-optimize** — add layers only when measured pain demands them

**Reference**: `references/architecture-patterns/rules.md`

---

### Step 2: Enhance Context

**Goal**: Add context (RAG, tools) when the model lacks information.

- [ ] If facts are needed: add RAG (`ai-rag-and-agents/workflows/build-rag.md`)
- [ ] If actions are needed: add tools
- [ ] If memory is needed: add short-term + long-term memory
- [ ] Verify context tuning before next layers

**Skip if**: model already has the info it needs.

**Reference**: `references/architecture-patterns/examples.md`

---

### Step 3: Add Guardrails

**Goal**: Wrap risk boundaries with input/output validation.

#### Input guardrails
- [ ] PII detection / masking
- [ ] Abuse classification
- [ ] Off-topic / out-of-scope detection
- [ ] Mask before sending; unmask in output

#### Output guardrails
- [ ] Toxicity / safety classifier
- [ ] Schema validation (if structured)
- [ ] Secret detection
- [ ] Retry on failure → fallback → human handoff

**Reference**: `references/architecture-patterns/rules.md`, `ai-prompt-engineering/workflows/audit-prompt-security.md`

---

### Step 4: Add Model Router and Gateway

**Goal**: Route traffic by intent; abstract provider.

#### Router (intent → model)
- [ ] Classify the request (cheap classifier or rules)
- [ ] Route to the right model (different sizes, different specializations)
- [ ] Trade off: latency saved by routing vs latency added by classification

#### Gateway (provider abstraction)
- [ ] Single entrypoint for all model calls
- [ ] Centralize retries, timeouts, fallbacks
- [ ] Centralize cost tracking and rate limiting
- [ ] Centralize secrets / API keys
- [ ] Easy to swap providers without app changes

**Reference**: `references/architecture-patterns/rules.md`, `references/architecture-patterns/examples.md`

---

### Step 5: Add Caches

**Goal**: Reduce latency and cost on repeated work.

#### Exact caching
- [ ] Cache identical prompts (request hash → response)
- [ ] Use LRU or TTL-based eviction
- [ ] Best for: deterministic queries, FAQs, system prompts

#### Semantic caching
- [ ] Cache by query embedding similarity
- [ ] Use a similarity threshold (e.g., cosine > 0.95)
- [ ] Best for: paraphrased queries; **risky** if precision matters

#### Prompt caching (provider-side)
- [ ] Cache the system prompt prefix at the model provider (Anthropic, Gemini)
- [ ] Best for: long system prompts (>500 tokens)
- [ ] Anthropic: 79% TTFT reduction, 90% cost reduction on cached prompts

**Reference**: `references/architecture-patterns/rules.md`, `ai-inference-optimization/references/service-optimization/examples.md`

---

### Step 6: Add Agent Patterns (if needed)

**Goal**: Add agentic loops only when one-shot LLM isn't enough.

- [ ] Reflect-and-retry loop (self-critique)
- [ ] Plan-then-execute (validated planning)
- [ ] Tool-using agent with approval gates for write actions
- [ ] Use sparingly — agents add complexity, latency, and cost

**Reference**: `references/architecture-patterns/patterns.md`, `ai-rag-and-agents/workflows/build-agent.md`

---

### Step 7: Wire Up Observability

**Goal**: Make the system debuggable.

- [ ] Run `setup-observability.md` workflow

**Reference**: `workflows/setup-observability.md`

---

## Quick Checklist

```
[ ] Step 1: Simple version works
[ ] Step 2: Context (RAG/tools/memory) added if needed
[ ] Step 3: Input + output guardrails
[ ] Step 4: Router + gateway
[ ] Step 5: Caches (exact / semantic / prompt)
[ ] Step 6: Agent patterns if needed
[ ] Step 7: Observability wired up
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Building all 5 layers upfront | Premature complexity | Add layers as pain emerges |
| No guardrails on user-facing | Safety incidents | Always add input + output guardrails |
| Direct provider calls everywhere | Hard to swap, hard to track cost | Centralize via gateway |
| Cache without eviction | Stale data forever | LRU or TTL |
| Semantic cache too loose | Wrong answers cached | High similarity threshold |
| Agent for simple tasks | Slow, expensive, unstable | One-shot LLM is often enough |

---

## Exit Criteria

- [ ] All needed layers in place (only the ones you need)
- [ ] SLOs met (latency, cost, quality)
- [ ] Guardrails verified end-to-end
- [ ] Observability gives you root-cause for failures
- [ ] Provider can be swapped via gateway
