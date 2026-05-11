# AI Engineering Architecture Knowledge

Core concepts for building production foundation model applications using a 5-step progressive architecture.

## Overview

A production AI architecture is built incrementally on top of a simple `query -> model -> response` flow. Each step adds components that solve specific problems: context for accuracy, guardrails for safety, routing/gateways for scale and security, caching for cost and latency, and agent patterns for capability. Apply only the steps your application needs.

## The 5-Step Progression

### Step 1: Enhance Context

**Definition**: Give the model access to external data and tools so it can construct the relevant context needed to answer each query.

Context construction is "feature engineering for foundation models" - it provides the necessary information to produce a quality output.

**Mechanisms**:
- Text/image/tabular retrieval (RAG)
- Tool use (web search, APIs, calculators, code execution)
- File uploads through provider APIs

### Step 2: Put in Guardrails

**Definition**: Components that mitigate risks at the edges of the system - protecting against bad inputs and bad outputs.

Two categories: input guardrails and output guardrails.

**Input guardrails** protect against:
- Leaking private information to external APIs
- Executing bad/malicious prompts (prompt hacks)

**Output guardrails** have two functions:
- Catch output failures (quality and security)
- Specify the policy to handle failure modes

### Step 3: Add Model Router and Gateway

**Router definition**: Component (typically an intent classifier) that routes incoming queries to the appropriate model, tool, or human operator based on predicted intent.

**Gateway definition**: An intermediate layer that provides a unified, secure interface to multiple models (third-party and self-hosted).

Routing usually happens *before* retrieval; gateways replace direct model API calls.

### Step 4: Reduce Latency with Caches

**Definition**: System-level caching of model responses, retrieval results, or computations to reduce latency and cost.

Two main mechanisms:
- **Exact caching**: Cache hit only when the request is byte-identical
- **Semantic caching**: Cache hit when the request is semantically similar (uses embeddings + vector search)

### Step 5: Add Agent Patterns

**Definition**: Non-sequential execution flows - loops, parallel execution, conditional branching, and write actions - that enable a system to handle complex tasks autonomously.

A model's outputs can invoke write actions (send email, place order, transfer funds), which dramatically increase capability and risk.

## Terminology

| Term | Definition |
|------|------------|
| Intent classifier | Model that predicts the user's intent so the query can be routed correctly |
| Next-action predictor | Router variant that picks the next tool/action for an agent |
| Model gateway | Unified wrapper providing a single interface across many model APIs |
| Exact cache | Returns cached output only when input matches identically |
| Semantic cache | Returns cached output when input is semantically similar (embedding-based) |
| Scorer | Smaller AI model used to evaluate response quality/safety |
| Stream completion | Streaming tokens to user as generated (complicates output guardrails) |
| Write action | Action that mutates external state (email, payment, DB write) |
| PII reverse dictionary | Mapping that restores masked tokens (e.g., `[PHONE NUMBER]`) to originals |
| False refusal rate | Rate at which guardrails block legitimate requests |

## Input vs Output Guardrails

| Aspect | Input Guardrails | Output Guardrails |
|--------|------------------|-------------------|
| Threats | PII leakage, prompt injection | Hallucinations, malformed output, toxic content, brand risk |
| Trigger | Before sending to model | After response generation |
| Common action | Block query, mask PII | Retry, fall back to human, block response |
| Streaming compatibility | Fine | Difficult - tokens may already be sent |

## Exact vs Semantic Caching

| Aspect | Exact Cache | Semantic Cache |
|--------|-------------|----------------|
| Match criteria | Byte-identical input | Embedding similarity > threshold |
| Backing store | In-memory, Redis, Postgres | Vector database |
| Failure modes | Misses near-duplicates | False hits return wrong answers |
| Cost overhead | Low (hash lookup) | High (embedding + vector search) |
| When to use | Repeated identical queries | High-volume similar queries |

## Router vs Gateway

| Aspect | Router | Gateway |
|--------|--------|---------|
| Purpose | Decide *which* model/action handles a query | Provide unified *access* to all models |
| Implementation | Intent classifier or next-action predictor | API wrapper layer |
| Adds | Intelligence (per-query routing) | Plumbing (auth, rate limit, fallback, logging) |
| Position | Before retrieval typically | Replaces all direct model API calls |

## How Components Compose

The canonical production order: `Router -> Retrieval -> Generation -> Scoring`

Caches sit alongside the model layer; guardrails wrap inputs and outputs; the gateway is the unified access layer underneath everything that talks to a model.

## Common Misconceptions

- **Myth**: You should add all 5 steps from day one.
  **Reality**: Start with the simplest architecture; add components only as concrete needs arise.

- **Myth**: Semantic caching is always better than exact caching.
  **Reality**: Semantic caching is more dubious - many components can fail (embeddings, vector search, threshold tuning). Evaluate cost/risk first.

- **Myth**: More guardrails = better.
  **Reality**: Guardrails add latency and can increase false refusal rate, frustrating users.

- **Myth**: A router and a gateway are the same thing.
  **Reality**: Routers make per-query decisions about *which* model; gateways provide unified *access* to models.

## Quick Reference

| Step | What | Primary Goal |
|------|------|--------------|
| 1. Enhance Context | RAG, tools, file uploads | Output quality |
| 2. Guardrails | Input/output filters | Safety and reliability |
| 3. Router + Gateway | Intent classifier, unified API | Cost, security, complexity management |
| 4. Caching | Exact and semantic | Latency and cost reduction |
| 5. Agent Patterns | Loops, write actions | Capability expansion |
