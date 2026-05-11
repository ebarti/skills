# Adapt the Engine to a New Domain Workflow

Reuse the Context Engine for a new vertical (legal, medical, marketing, finance, etc.) by swapping the knowledge base and control decks — engine code stays the same.

## When to Use

- An existing engine works in domain A; you want to add domain B
- Building a multi-tenant or multi-vertical product
- Validating the "domain adaptation" pattern (same engine, different inputs)

## Prerequisites

- Working, hardened Context Engine
- Domain knowledge: what documents, what use cases, what limits
- Domain SME available for KB curation

**Reference**: `references/domain-applications/knowledge.md`, `references/domain-applications/patterns.md`

---

## Workflow Steps

### Step 1: Identify what stays vs what changes

**Goal**: Confirm the engine code itself is reusable.

- [ ] What stays: engine, agents, registry, hardening, helpers, MCP, RAG ingestion code
- [ ] What changes: knowledge base content, control decks, sometimes specific agent prompts
- [ ] Document the adaptation surface (1-page)

**Reference**: `references/domain-applications/knowledge.md` (domain independence)

---

### Step 2: Curate the domain knowledge base

**Goal**: Populate the KB with domain-relevant documents.

- [ ] Work with SME to choose canonical sources (regulations, product docs, etc.)
- [ ] Decide chunking granularity (legal = per clause; marketing = per asset)
- [ ] Decide metadata schema (case_number, asset_id, regulation_section, etc.)

**Reference**: `references/domain-applications/rules.md`, `references/domain-applications/examples.md` (Legal + Marketing source examples)

---

### Step 3: Run the ingestion pipeline for the new namespace

**Goal**: Domain documents in Pinecone, isolated from other domains.

- [ ] Use a NEW namespace per domain (e.g. `legal-knowledge-base`)
- [ ] Run the same ingestion pipeline (chunk → embed → upsert)
- [ ] Verify count + smoke-test retrieval

**Reference**: `ai-context-engine/workflows/setup-rag-pipeline.md`

---

### Step 4: Write domain-specific control decks

**Goal**: Each use case gets a control deck.

- [ ] Identify the 2-4 main use cases for this domain
- [ ] For each, pick a template (high-fidelity RAG / context reduction / grounded reasoning)
- [ ] Parametrize: goal, configuration (incl. namespace), moderation flag
- [ ] Document each control deck

**Reference**: `references/control-decks/examples.md`, `references/control-decks/patterns.md`

---

### Step 5: Customize agent prompts (only if needed)

**Goal**: Domain-specific phrasing without rewriting agents.

- [ ] If domain has unusual terminology → tweak Researcher's system prompt
- [ ] If output format is highly stylized → tweak Writer's system prompt
- [ ] DO NOT add new agents unless absolutely necessary

**Reference**: `references/domain-applications/rules.md` (blueprint-over-code rule)

---

### Step 6: Define limit tests

**Goal**: Prove the engine handles domain-specific edge cases.

- [ ] Domain-specific safe goal → success
- [ ] Domain-specific edge case (vague objective, ambiguous request, sensitive content)
- [ ] Domain-specific moderation case (e.g. legal testimony with PII)
- [ ] Out-of-scope query → grounded reasoning kicks in

**Reference**: `references/domain-applications/examples.md` (limit tests for legal + marketing)

---

### Step 7: Validate end-to-end

**Goal**: Run the full engine on each control deck.

- [ ] Run each control deck — verify output quality
- [ ] Run each limit test — verify expected behavior (rejection, negative finding, etc.)
- [ ] Have SME review 5+ outputs for accuracy

---

## Quick Checklist

```
[ ] Step 1: Adaptation surface documented
[ ] Step 2: KB content curated
[ ] Step 3: New namespace ingested
[ ] Step 4: Control decks written
[ ] Step 5: Agent prompts tweaked (only if needed)
[ ] Step 6: Limit tests defined
[ ] Step 7: End-to-end validation with SME review
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Forking engine code per domain | Maintenance nightmare | Same engine, different KB + decks |
| Sharing one namespace across domains | Cross-domain leakage | One namespace per domain |
| Adding new agents per domain | Defeats the adaptation pattern | Use existing agents with new prompts |
| Skipping SME review | Hallucinations or inaccurate output | Always have SME validate |
| Same control decks across domains | Misses domain-specific value | Decks ARE the domain customization |

---

## Exit Criteria

- [ ] New namespace populated and verified
- [ ] 2-4 control decks written and tested
- [ ] Limit tests defined and passing
- [ ] SME has signed off on output quality
- [ ] Engine code is unchanged (or only prompt tweaks)
