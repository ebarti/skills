# Domain Applications Knowledge

Core concepts for re-tasking the Context Engine to new business verticals (legal, marketing) without rewriting core logic.

## Overview

The glass-box Context Engine is built as a domain-independent reasoning platform. Adapting it to a new vertical requires a curated knowledge base and well-chosen Control Deck templates, not new code in the engine, agents, or registry. The Context Engineer's job shifts from coding to curation, organizational design, and goal articulation.

## Key Concepts

### Domain Independence

**Definition**: The engine's core (Planner, Executor, agent registry, specialist agents) contains no hardcoded domain expertise; expertise is learned dynamically from whichever knowledge base it is given.

**Key points**:
- The same `engine.py` powered both legal compliance and strategic marketing without modification
- Domain capability is the product of (engine + KB + control decks), not engine code
- New verticals stand up "in minutes" because the underlying infrastructure is reusable

### Domain-Specific Knowledge Base

**Definition**: A curated corpus of source documents (legal contracts, brand guides, product specs, etc.) ingested into Pinecone via the same metadata-aware pipeline.

**Key points**:
- Legal KB: Service Agreement, Privacy Policy, NDA + testimony (3 documents)
- Marketing KB: brand guide, product spec, competitor release, social brief, SEO keywords, customer interview, email outline (7 documents)
- Same `Data_Ingestion.ipynb` is duplicated and pointed at a new directory (e.g., `legal_documents` -> `marketing_documents`)
- Metadata (source filename) enables citation and selective sanitization policies

### What Stays The Same vs. What Changes

**Definition**: A clear separation between reusable infrastructure and per-domain assets.

**Stays the same**:
- Engine core: `context_engine()`, `planner()`, `resolve_dependencies()`, ExecutionTrace
- Agent registry: `get_handler()`, `get_capabilities_description()`
- Specialist agents: `agent_researcher`, `agent_librarian`, `agent_summarizer`, `agent_writer`
- Helper functions: `query_pinecone()`, `call_llm_robust()`, moderation wrappers
- Pre-flight and post-flight moderation

**Changes per domain**:
- Source documents and their metadata
- Goal text passed to each Control Deck
- Sometimes: namespace strategy (e.g., `KnowledgeStore-Testimony`)
- Sometimes: standardized summary objectives / blueprints (organizational, not code)

### Domain-Specific Limit Tests

**Definition**: Per-deck stress tests that surface where automation fails and human/organizational judgment must take over.

**Legal limits exposed**:
- Sanitization of legitimate testimony (false positive on `ignore any legal advice`)
- Vague objective ("write a story about it") produces fluent nonsense
- Ambiguous request ("draft a pleading") confuses the planner

**Marketing limit (productive form)**:
- The persuasive pitch test shows synthesis succeeding by linking style guide rules to SEO and email goals across documents

## Terminology

| Term | Definition |
|------|------------|
| Glass-box architecture | Modular, traceable design that exposes every step of reasoning |
| Control Deck | Generic templated workflow (RAG, reduction, grounded reasoning) reused across domains |
| Knowledge base | Pinecone-backed corpus of domain documents plus context library |
| Semantic blueprint | Pre-approved structural template (e.g., `blueprint_for_pleading`) curated with domain experts |
| Data segmentation | Storing risky content in a separate namespace with a different sanitization policy |

## How It Relates To

- **Control Decks**: Domain adaptation reuses the three generic decks; only the `goal` text changes
- **Moderation & Sanitization**: Per-domain content (legal testimony) may demand per-namespace policies
- **Production Deployment**: Multi-domain reuse is the business case for the glass-box investment

## Common Misconceptions

- **Myth**: New domains require new specialist agents (e.g., a `BrandChecker`)
  **Reality**: The marketing chapter explicitly proves no new agents were needed; brand consistency is enforced via the Librarian + brand_style_guide.txt
- **Myth**: Each use case needs its own custom Control Deck
  **Reality**: All marketing use cases reused the three generic decks from Chapter 8
- **Myth**: The Data Ingestion notebook had to be rewritten for marketing
  **Reality**: It was duplicated and pointed at a new directory; logic is data-agnostic
- **Myth**: Hard problems (testimony false positives, vague goals) are solved by more code
  **Reality**: They are solved by organizational design (data segmentation, standardized blueprints, workshops with domain experts)

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Domain independence | Engine + agents are universal; KB + decks are per-domain |
| KB curation | Duplicate the ingestion pipeline, swap source documents |
| Control deck reuse | Same three decks; only the `goal` string changes |
| Limit tests | Each deck has a known failure mode requiring organizational fix |
| Engineer's role | Curator and translator, not engine developer |
