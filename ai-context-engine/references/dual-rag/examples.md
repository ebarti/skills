# Dual RAG Examples

Architecture diagrams and inline examples for the dual RAG MAS.

## Architecture: Phase 1 — Data Preparation

```
                ┌──────────────────────┐         ┌──────────────────────┐
                │  Knowledge Data      │         │  Context Data        │
                │  (factual sources)   │         │  (semantic           │
                │                      │         │   blueprints)        │
                └──────────┬───────────┘         └──────────┬───────────┘
                           │ chunk + embed                  │ embed intent only
                           ▼                                ▼
                ┌──────────────────────────────────────────────────────┐
                │                  Embedding Model                     │
                └──────────────────────────────────────────────────────┘
                           │                                │
                           ▼                                ▼
                ┌─────────────────────────────────────────────────────┐
                │                Pinecone Vector Index                │
                │  ┌─────────────────────┐  ┌──────────────────────┐  │
                │  │   KnowledgeStore    │  │   ContextLibrary     │  │
                │  │   (factual chunks)  │  │   (blueprint intents)│  │
                │  └─────────────────────┘  └──────────────────────┘  │
                └─────────────────────────────────────────────────────┘
                                                          │
                                                          ▼
                                           Linked JSON: full blueprint payload
```

**Key points**:
- Two source types feed one shared embedding model
- Knowledge data is **chunked then embedded**; context data has **only its intent description embedded**
- The full blueprint payload sits in a linked JSON object outside the vector index
- Output: one Pinecone index with two strictly separated namespaces

## Architecture: Phase 2 — Runtime Execution

```
                          ┌────────────────────────┐
                          │      User Goal         │
                          │  "Write a suspenseful  │
                          │   story about          │
                          │   Apollo 11"           │
                          └──────────┬─────────────┘
                                     ▼
                          ┌────────────────────────┐
                          │     Orchestrator       │
                          │  (splits goal into     │
                          │   intent + topic)      │
                          └──────┬──────────┬──────┘
                                 │          │
                  intent_query   │          │   topic_query
                  ("suspenseful  │          │   ("Apollo 11")
                   story")       │          │
                                 ▼          ▼
                       ┌────────────┐  ┌────────────┐
                       │  Librarian │  │ Researcher │
                       └─────┬──────┘  └──────┬─────┘
                             │                │
                             ▼                ▼
                  ┌────────────────┐  ┌────────────────┐
                  │ ContextLibrary │  │ KnowledgeStore │
                  │  (semantic     │  │  (factual      │
                  │   search on    │  │   chunks)      │
                  │   intent)      │  │                │
                  └─────┬──────────┘  └──────┬─────────┘
                        │                    │
                  blueprint               facts
                        │                    │
                        └─────────┬──────────┘
                                  ▼
                          ┌──────────────┐
                          │    Writer    │
                          │  (fuses      │
                          │   blueprint  │
                          │   + facts)   │
                          └──────┬───────┘
                                 ▼
                          Final output
```

**Key points**:
- Orchestrator decomposes the goal into two named sub-queries
- Librarian and Researcher run in parallel via the MCP messaging layer
- Writer fuses the blueprint (procedural instructions) with the facts (content)
- Arrows in the original Figure 3.1 show **blueprint** and **facts** flowing into the Writer

## Inline Example: Goal Decomposition

User goal:

```
Write a suspenseful story about Apollo 11
```

Orchestrator output:

```
intent_query = "suspenseful story"      # routed to Librarian → ContextLibrary
topic_query  = "Apollo 11"              # routed to Researcher → KnowledgeStore
```

**Why it works**:
- `intent_query` carries the *style/structure* concern, matching how blueprint intents were embedded
- `topic_query` carries the *subject-matter* concern, matching how factual chunks were embedded
- Two narrow queries retrieve more relevant context than the raw goal would against either index

## Inline Example: Namespace Layout

```
Pinecone index: dual-rag-index
├── namespace: KnowledgeStore
│     vectors: factual chunks (e.g., Apollo 11 mission facts, dates, crew)
│
└── namespace: ContextLibrary
      vectors: blueprint intent descriptions (e.g., "suspenseful story",
               "technical brief", "executive summary")
      linked:  full blueprint JSON objects, retrieved by intent match
```

**Why it works**:
- One index keeps infrastructure simple
- Strict namespace separation guarantees the Librarian and Researcher cannot accidentally cross-contaminate
- Storing the full blueprint outside the vector record keeps embeddings small and search-relevant

## Architectural Trade-Off Table

| Concern | Single RAG | Dual RAG |
|---------|------------|----------|
| Procedural + factual mix | Vectors compete for relevance | Each namespace tuned to its kind of query |
| Update cycles | Tightly coupled | Independent — knowledge or blueprints can change alone |
| Specialist agents | Share one retrieval surface | Each owns its namespace |
| Query routing | One query, hope for the best | Decomposed: `intent_query` + `topic_query` |
| Generation | Generator guesses what's style vs. content | Writer receives blueprint and facts as distinct inputs |
| Operational complexity | Lower | Slightly higher — two embedding flows, two namespaces |

## Refactoring Walkthrough

### Before (single-RAG mindset)

```
User goal ──► single embedding query ──► one mixed index ──► generator
```

Problems:
- Style examples and factual passages compete in the same vector space
- Updating a writing style forces re-evaluating the factual corpus
- The generator must infer which retrieved chunks are instructions vs. content

### After (dual RAG)

```
User goal ──► Orchestrator ──┬─► intent_query  ──► Librarian  ──► ContextLibrary ──► blueprint
                             │                                                          │
                             └─► topic_query   ──► Researcher ──► KnowledgeStore  ──► facts
                                                                                        │
                                                          Writer (blueprint + facts) ◄──┘
```

### Changes Made

1. **Decomposed the goal** into `intent_query` and `topic_query` so each index gets a focused query
2. **Split the index** into `ContextLibrary` (procedural) and `KnowledgeStore` (factual) namespaces
3. **Assigned a specialist** to each namespace (Librarian, Researcher) and ran them in parallel
4. **Centralized fusion** in the Writer, which receives blueprint and facts as distinct inputs instead of a mixed bag of chunks
