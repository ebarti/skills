# Exact Evaluation Patterns

Reusable patterns for picking an exact-evaluation method based on task type.

## Pattern: Executable-Output Pattern

### Intent
Use functional correctness whenever the model's output can be *run* against deterministic checks.

### When to Use
- Code generation, SQL / query generation
- Tool-call / API-call generation (dispatch and inspect side effects)
- Game-playing or optimization agents (measurable objective)

### Structure
```python
def evaluate(generated_output, test_cases):
    artifact = build_or_load(generated_output)   # parse, compile, dispatch
    return all(run(artifact, tc.inputs) == tc.expected for tc in test_cases)
```

### Example
```python
# SQL generation: execute and compare result sets
def eval_sql(generated_sql: str, gold_sql: str, db) -> bool:
    return sorted(db.execute(generated_sql)) == sorted(db.execute(gold_sql))
```

### Benefits
- Measures what users actually care about (does it work?)
- Naturally extends to pass@k for sampling-based deployments

### Considerations
- Need a sandbox (timeouts, resource limits) for arbitrary code
- Test cases must cover edge cases or you'll over-credit shallow solutions

---

## Pattern: Canonical-Answer Pattern

### Intent
Use exact match when the task has a tiny, enumerable set of correct answers and you can constrain output format.

### When to Use
- Multiple choice (A/B/C/D)
- Numeric answers with fixed units, trivia / factoid QA
- Account / database lookups

### Structure
```python
def evaluate(generated, references):
    g = normalize(generated)   # strip, lowercase, remove punctuation
    return any(g == normalize(r) for r in references)
```

### Example
```python
def normalize(s: str) -> str:
    return "".join(ch for ch in s.strip().lower() if ch.isalnum())

# Constrain via prompt: "Answer with a single number, nothing else."
```

### Benefits
- Trivial to compute, fully deterministic
- No false positives from paraphrase

### Considerations
- Requires output-format constraint at prompt time
- Avoid the "contains" variant unless only the answer can appear in output

---

## Pattern: Reference-Set + Lexical-Similarity Pattern

### Intent
Use BLEU/ROUGE-style metrics for legacy translation/summarization comparisons where well-curated reference sets exist.

### When to Use
- Translation benchmarks (WMT), captioning (COCO), summarization with multiple references
- Comparing to prior published numbers (apples-to-apples)

### Structure
```python
score = bleu_or_rouge(hypothesis, list_of_references)
```

### Example
```python
from sacrebleu import corpus_bleu
score = corpus_bleu(hypotheses, list_of_reference_lists).score
```

### Benefits
- Standard, reproducible, fast; comparable across papers and systems

### Considerations
- Does NOT track correctness (HumanEval BLEU finding)
- Penalizes correct paraphrases when references are sparse
- Always pair with a semantic or human signal

---

## Pattern: Embedding-Similarity Pattern

### Intent
Use semantic similarity to tolerate paraphrase when a correct answer can be expressed many ways.

### When to Use
- Open-ended QA, summarization quality, paraphrase detection
- Retrieval / RAG (find similar items)
- Deduplication / clustering / anomaly detection

### Structure
```python
emb_g = embed(generated)
emb_r = embed(reference)              # or precomputed from a reference set
verdict = cosine(emb_g, emb_r) >= threshold
```

### Example
```python
from sentence_transformers import SentenceTransformer
import numpy as np
model = SentenceTransformer("all-MiniLM-L6-v2")

def is_close(g: str, refs: list[str], thr: float = 0.75) -> bool:
    embs = model.encode([g, *refs], normalize_embeddings=True)
    return any(float(np.dot(embs[0], r)) >= thr for r in embs[1:])
```

### Benefits
- Accepts paraphrases lexical metrics reject
- Same machinery powers retrieval and clustering downstream

### Considerations
- Score quality bounded by embedding model quality (validate on MTEB-style tasks)
- Embedding compute can dominate runtime — cache reference embeddings
- Threshold needs calibration on held-out data

---

## Pattern: Layered Defense (Hybrid)

### Intent
For high-stakes evaluation, combine methods so each compensates for the others' blind spots.

### When to Use
- Production model regression suites
- Translation / summarization where neither lexical nor semantic alone suffices
- Anything you'll defend to a stakeholder

### Structure
```
1. Functional correctness (if applicable) → ground truth
2. Exact match (where format allows)     → cheap, deterministic
3. Lexical similarity                    → comparability with prior work
4. Semantic similarity                   → paraphrase tolerance
5. Small human-judged sample             → calibration sanity check
```

### Example
```python
def grade(generated: str, refs: list[str], runnable: bool = False) -> dict:
    out = {}
    if runnable:
        out["functional"] = passes_all_tests(generated, ...)
    out["exact"] = exact_match(generated, refs)
    out["bleu"] = corpus_bleu([generated], [refs]).score
    out["semantic"] = max(semantic_similarity(generated, r) for r in refs)
    return out
```

### Benefits
- Catches failures any single method misses
- Disagreement between layers is itself a useful signal

### Considerations
- More compute, more code, more thresholds to tune
- Need a clear combining policy (weighted sum? all-must-pass? majority?)

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|-------------------|
| Output is code / SQL / executable | Executable-Output |
| Output is one short canonical answer | Canonical-Answer |
| Translation with rich reference set | Reference-Set + Lexical |
| Open-ended QA, paraphrases expected | Embedding-Similarity |
| Retrieval / RAG / deduplication | Embedding-Similarity |
| Production regression suite | Layered Defense |
| Game / optimization agent | Executable-Output (objective score) |
| Image captioning / multimodal | Embedding-Similarity (multimodal embeddings) |
