# Retrieval Optimization Patterns

Reusable patterns for production RAG, organized by use case.

## Pattern: Cheap-Then-Precise Two-Stage Retrieval

### Intent
Combine recall and precision without paying the precision model's cost on every document.

### When to Use
- Corpus too large for a precision reranker on every document
- Need to cap input tokens to the LLM
- Hybrid search combining BM25 + embeddings

### Structure

```python
candidates = cheap_retriever.search(query, top_k=50)   # high recall
top = precise_reranker.rerank(query, candidates, k=5)  # high precision
context = build_prompt(query, top)
answer = llm(context)
```

### Benefits
- Bounded inference cost
- Improves answer quality vs single-stage retrieval

### Considerations
- Reranker latency adds to query time; pick a model sized for your SLA

---

## Pattern: Contextualized Chunks (Anthropic Technique)

### Intent
Make chunks self-contained for retrieval when they lose meaning in isolation.

### When to Use
- Long documents where chunks reference earlier sections (e.g., "this method", "the framework above")
- Technical docs, legal texts, multi-section reports
- Recall is poor for chunks that look generic in isolation

### Structure

```python
for chunk in chunks:
    context = llm(CONTEXTUALIZE_PROMPT.format(doc=full_doc, chunk=chunk))
    augmented = f"{context}\n\n{chunk}"
    index.add(augmented)
```

### Benefits
- Large recall improvement (Anthropic reports significant gains)
- Cheap to apply with prompt caching on the full document

### Considerations
- One LLM call per chunk at index time — use caching aggressively
- Reindex if you change the contextualization prompt

---

## Pattern: Conversational Query Rewriting

### Intent
Make multi-turn queries retrievable by making them self-contained.

### When to Use
- Chatbots with follow-up questions
- Anaphora ("his", "that one", "those")
- Ellipsis ("How about Emily Doe?")

### Structure

```python
standalone_query = rewrite(history)
if standalone_query == "UNRESOLVABLE":
    return ask_user_for_clarification()
docs = retrieve(standalone_query)
```

### Benefits
- Recovers retrieval quality in multi-turn settings
- Centralizes reference resolution

### Considerations
- Add identity resolution (DB lookup) for queries like "his wife"
- Always allow the rewriter to refuse instead of guessing

---

## Pattern: Question-Answer Augmented Index

### Intent
Bridge vocabulary gap between users and documentation.

### When to Use
- FAQs, help center articles, customer support
- Users phrase queries very differently from doc authors

### Structure

```python
for article in kb_articles:
    related_qs = generate_related_questions(article)  # LLM or curated
    payload = "\n".join(related_qs) + "\n\n" + article
    index.add(payload)
```

### Benefits
- Improves recall for natural-language user queries
- Cheap to refresh as new questions are observed in logs

### Considerations
- Keep generated questions diverse (different phrasings, intents)

---

## Pattern: Time-Weighted Reranking

### Intent
Surface fresh content for time-sensitive domains.

### When to Use
- News aggregation
- Email / chat search
- Stock or market analysis

### Structure

```python
final_score = relevance_score * exp(-ln2 * age_days / half_life_days)
ranked = sort(candidates, key=final_score, desc=True)
```

### Benefits
- Naturally ages out stale content
- Tunable via half-life parameter

### Considerations
- Pick half-life per domain (news ~ days, knowledge base ~ months)

---

## Pattern: Entity-Preserving Metadata Index

### Intent
Keep identifiers (error codes, SKUs, named entities) searchable after embedding.

### When to Use
- Technical docs with codes (`EADDRNOTAVAIL`, `HTTP 503`)
- Catalogs with SKUs / part numbers
- Compliance/legal references

### Structure

```python
chunk_meta = {
    "text": chunk,
    "entities": extract_entities(chunk),  # NER or regex
    "embedding": embed(chunk),
}
# Hybrid: keyword match on entities + vector match on embedding
```

### Benefits
- Recovers literal lookups that embeddings miss
- Works with hybrid search

---

## Pattern: Multimodal Joint Embedding (CLIP)

### Intent
Retrieve images, video frames, or audio with a text query in one vector space.

### When to Use
- No reliable metadata for media assets
- "Find this concept" rather than "find this caption"

### Structure

```python
# Index
for asset in assets:
    vec = clip_image(asset) if is_image(asset) else clip_text(asset)
    index.add(vec, payload=asset)

# Query
qvec = clip_text(user_query)
hits = index.search(qvec, top_k=10)
```

### Considerations
- CLIP-class models may underperform on specialized domains; consider domain-tuned models

---

## Pattern: Text-to-SQL with Schema Selection

### Intent
Answer natural-language questions over many tables.

### When to Use
- Tabular RAG over warehouses with too many tables for one prompt
- Analytics chatbots

### Structure

```python
tables = select_tables(query, table_summaries)        # narrow scope
schema = load_schemas(tables)
sql = text_to_sql(query, schema)
rows = db.execute(sql)
answer = synthesize(query, rows)
```

### Benefits
- Scales to large warehouses
- Keeps SQL prompts compact

### Considerations
- Validate generated SQL (read-only, parameterize, syntax check) before executing

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|---------------------|
| Chunks lose context in isolation | Contextualized Chunks |
| FAQ / help center | Question-Answer Augmented Index |
| Multi-turn chatbot | Conversational Query Rewriting |
| Large candidate set | Cheap-Then-Precise Two-Stage |
| News / email / time-sensitive | Time-Weighted Reranking |
| Technical docs with codes | Entity-Preserving Metadata Index |
| Image/video/audio search | Multimodal Joint Embedding (CLIP) |
| Many tables, NL questions | Text-to-SQL with Schema Selection |
