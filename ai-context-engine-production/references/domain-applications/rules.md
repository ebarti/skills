# Domain Applications Rules

Rules for adapting the Context Engine to a new vertical: building the knowledge base, selecting control decks, validating against domain limits, and deciding when domain expertise must reach into prompts.

## Core Rules

### 1. Reuse The Ingestion Pipeline; Never Rewrite It

Duplicate `Data_Ingestion.ipynb`, rename the source directory (e.g., `legal_documents` -> `marketing_documents`), and point the script at the new corpus.

- Delete only the cells that generated the previous domain's `.txt` files
- Keep chunking, embedding, metadata, and upsert logic untouched
- Confirm via `index_fullness` and `vector_count` after ingestion

### 2. Curate Source Documents With Strategic Purpose

Every document in the KB should map to a concrete capability the engine will exercise.

- Legal: Service Agreement (extractable entities), Privacy Policy (interpretive clauses), NDA + testimony (sanitization stress test)
- Marketing: brand guide (style enforcement), product spec (factual transformation), competitor release (analysis), social brief / SEO / customer interview / email outline (multi-source synthesis)

### 3. Always Attach Source Metadata

Every chunk must carry `source: <filename>` so the Researcher can produce citations and so policies can target specific document classes.

**Example**:
```python
# Verifying metadata after ingestion
query_embedding = get_embeddings_batch(["Sum up the NDA agreement"])[0]
# Expected match metadata:
# {'source': 'NDA_Template_and_Testimony.txt', 'text': '...'}
```

### 4. Select The Control Deck By Cognitive Task, Not By Domain

The three generic decks are universal:

- **Deck 1 (High-Fidelity RAG)**: cited research, single-document Q&A
- **Deck 2 (Context Reduction)**: summarize-then-create, dense doc to client copy
- **Deck 3 (Grounded Reasoning)**: out-of-scope honesty, multi-source synthesis

Pick the deck that matches the cognitive shape of the goal; do not invent new decks per use case.

### 5. Run Domain-Specific Limit Tests Before Shipping

Each deck has a known failure mode that surfaces an organizational requirement:

- Deck 1 limit: legitimate domain language matching injection patterns (testimony case)
- Deck 2 limit: vague or nonsensical second-step objectives (story-from-contract case)
- Deck 3 limit: ambiguous requests with no matching blueprint (pleading-from-NDA case)

Document the failure, then fix it organizationally (namespace segmentation, standardized blueprints), not by patching code.

### 6. Solve Ambiguity With Blueprints, Not Code

When users issue vague or out-of-scope requests, expand the Context Library with curated semantic blueprints (e.g., `blueprint_for_pleading`, `blueprint_for_motion_to_dismiss`) defined in workshops with domain experts.

### 7. Use Namespaces To Apply Different Sanitization Policies

If a document class (testimony, adversarial source material) reliably trips the sanitizer, store it in a dedicated namespace such as `KnowledgeStore-Testimony` and let the Researcher apply a more lenient policy when querying it.

### 8. Inform Agent Prompts With Domain Expertise Only When Knowledge Cannot Carry It

The default is to keep agents generic and let the KB + blueprints encode domain knowledge. Touch agent prompts only when:

- A constraint is universal across all goals in the domain (e.g., "always cite by section number")
- The constraint cannot be expressed as a retrievable document or blueprint

For brand voice, marketing did NOT add a `BrandChecker` agent; the Librarian + `brand_style_guide.txt` enforced it.

## Guidelines

- Keep moderation enabled for all domain deployments; do not disable for "creative freedom"
- Validate production safeguards with a simple research goal in the new domain before exercising creative use cases
- Expect probabilistic variation; design traces and warnings as primary debugging surface
- Treat each limit test as a workshop trigger: convene domain experts, ship organizational fix

## Exceptions

- **Adversarial corpora**: Bypass or relax sanitizer for documents stored in dedicated namespaces, never globally
- **High-budget projects**: Optimize latency with state-of-the-art servers and local models; default deployments accept ~70s for complex chains
- **Specialist domains needing structured outputs**: Curate blueprints in advance rather than relying on the Librarian to invent them

## Quick Reference

| Rule | Summary |
|------|---------|
| Reuse pipeline | Duplicate `Data_Ingestion.ipynb`, swap directory only |
| Strategic curation | Each document maps to a capability and a stress test |
| Source metadata | Required for citations and per-class policies |
| Pick deck by task | RAG / Reduction / Grounded Reasoning, not per use case |
| Run limit tests | Each deck has a known failure; document and fix organizationally |
| Blueprints over code | Resolve ambiguity by expanding context library |
| Namespaces for policy | Segment risky data; do not patch sanitizer with exceptions |
| Domain prompts last | Encode expertise in KB and blueprints first |
