# Add Citations / High-Fidelity RAG Workflow

Upgrade the Context Engine's RAG layer to attach source metadata at chunk time and require citations in Researcher outputs.

## When to Use

- Use case requires verifiable claims (legal, medical, scientific, regulatory)
- Stakeholders need to audit where each fact came from
- Building an assistant where hallucinations have legal/safety implications

## Prerequisites

- Working RAG ingestion pipeline
- Working Researcher agent
- Source documents have stable identifiers (URL, doc_id, section header)

**Reference**: `references/high-fidelity-rag/knowledge.md`

---

## Workflow Steps

### Step 1: Prepare source documents with citation anchors

**Goal**: Each source document has a stable, citable identifier.

- [ ] Choose the citation field per source (e.g. `source_url`, `nasa_mission_name`, `case_number`)
- [ ] Decide chunk-level granularity (per page? per section?)
- [ ] Document the schema for chunk metadata: `{text, source, section, ...}`

**Reference**: `references/high-fidelity-rag/examples.md` (Juno + Perseverance source prep), `references/high-fidelity-rag/rules.md` (doc structure rule)

---

### Step 2: Update the ingestion pipeline to attach metadata

**Goal**: Every Pinecone vector carries source metadata.

- [ ] During chunking, attach `source` (and other metadata) to each chunk
- [ ] During upsert, include metadata in the Pinecone payload
- [ ] Re-run ingestion (or migrate existing vectors)

**Reference**: `references/high-fidelity-rag/examples.md` (metadata-aware ingestion)

---

### Step 3: Verify metadata attachment

**Goal**: Probe Pinecone to confirm metadata is queryable.

- [ ] Run a sample query
- [ ] Print returned chunks — verify `source` field populated
- [ ] Check filtering: `filter={"source": "..."}`

**Reference**: `references/high-fidelity-rag/examples.md` (verification probe)

---

### Step 4: Upgrade the Researcher agent

**Goal**: Researcher returns facts AND citations.

- [ ] Update Researcher's system prompt: "Cite the `source` field for every claim"
- [ ] Update output schema: `{facts: [{claim, source}, ...]}`
- [ ] Verify schema in Researcher code

**Reference**: `references/high-fidelity-rag/examples-researcher.md`

---

### Step 5: Update Writer to preserve citations

**Goal**: Final output preserves citations for auditability.

- [ ] Update Writer's system prompt: "Preserve the `source` next to each claim in the output"
- [ ] Choose a citation rendering format (footnotes, inline `[source]`, table)

**Reference**: `references/high-fidelity-rag/patterns.md` (Citations-Mandatory Agent pattern)

---

### Step 6: Run an end-to-end research goal

**Goal**: Verify the full citation chain works.

- [ ] Define a research goal requiring multiple facts
- [ ] Run the engine
- [ ] Verify final output cites every claim
- [ ] Manually verify 2-3 citations point to actual source content
- [ ] Check the trace: each citation traces back to a real chunk

**Reference**: `references/high-fidelity-rag/examples-researcher.md` (NASA control deck + sample trace)

---

### Step 7: Add a citation-quality test case

**Goal**: Regression-test citation behavior.

- [ ] Add a test where the answer is in 2+ documents — verify citation picks the right source
- [ ] Add a test where no source exists — verify Researcher reports negative finding (don't invent)

**Reference**: `references/grounded-reasoning/rules.md` (report negative findings)

---

## Quick Checklist

```
[ ] Step 1: Source docs with citable IDs
[ ] Step 2: Ingestion attaches metadata
[ ] Step 3: Verified via probe query
[ ] Step 4: Researcher returns citations
[ ] Step 5: Writer preserves citations
[ ] Step 6: End-to-end research goal verified
[ ] Step 7: Regression tests for citation quality
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Attaching metadata only to some chunks | Inconsistent retrieval | All-or-nothing |
| Citation = LLM-invented URL | Hallucination | Cite Pinecone metadata only |
| Researcher returns raw text + Writer fakes citations | No real provenance | Researcher must own citation |
| Citing the chunk index instead of source | Useless to humans | Cite human-readable source |
| Skipping the negative-finding test | Hallucination on out-of-scope | Always test "no result" path |

---

## Exit Criteria

- [ ] Every Pinecone vector has source metadata
- [ ] Researcher output schema includes citations
- [ ] Writer preserves citations in final output
- [ ] Manually verified: claims trace to real chunks
- [ ] Negative-finding regression test passes
