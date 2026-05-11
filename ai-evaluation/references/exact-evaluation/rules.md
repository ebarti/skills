# Exact Evaluation Rules

Guidelines for choosing and applying functional correctness, exact match, lexical similarity, and semantic similarity.

## Core Rules

### 1. Prefer functional correctness when the task has a verifiable outcome

If you can *execute* the output and check the result, do that — it measures what actually matters.

- Code generation → run unit tests (HumanEval / MBPP / pass@k style)
- SQL generation → execute query, compare result sets (Spider, BIRD-SQL, WikiSQL)
- Game bots → measure score
- Optimization (scheduling, routing) → measure objective (cost, energy, latency)

**Example**:
```python
# Good: actually run the generated code
def evaluate_solution(generated_code: str, test_cases: list) -> bool:
    exec(generated_code, namespace := {})
    fn = namespace["candidate"]
    return all(fn(*tc.inputs) == tc.expected for tc in test_cases)

# Bad: compare generated code to a "reference" string with BLEU
score = bleu(generated_code, reference_code)  # Doesn't track correctness
```

### 2. Use exact match only for short, canonical answers

Exact match is binary and unforgiving. Reserve it for tasks with one-or-few correct answers.

- Good fits: arithmetic, trivia, multiple choice, fill-in-the-blank, account lookups
- Bad fits: translation, summarization, open-ended QA, anything paraphraseable

### 3. Be careful with "contains" variants of exact match

Accepting any output that *contains* the reference can pass factually wrong outputs.

- "What year was Anne Frank born?" → reference `1929`. Output `September 12, 1929` contains 1929 but is factually wrong (she was born in June).
- Either constrain the model's output format, or post-process before matching.

### 4. Use lexical similarity (BLEU / ROUGE) for translation/summarization legacy benchmarks — but treat scores skeptically

Lexical metrics measure *overlap*, not *quality*.

- Use when: comparing against well-curated, comprehensive reference sets (WMT, COCO Captions, GEMv2)
- Avoid when: optimizing toward correctness (BLEU does not track HumanEval correctness)
- Always pair with another signal (human review, semantic similarity, or functional check)

### 5. Use semantic similarity when paraphrases must be accepted

When a correct response can be worded many ways, embeddings + cosine similarity tolerate paraphrase that lexical metrics punish.

- Good for: open-ended QA, summarization, translation paraphrase tolerance
- Use BERTScore, MoverScore, or your own embedding model + cosine

### 6. Pick a quality embedding model for semantic similarity

The score is only as good as the embeddings.

- Specialized embedding models (BERT, Sentence Transformers, OpenAI/Cohere embeddings) > intermediate-layer extracts from generative LLMs
- Validate on MTEB-style benchmarks for your task family (classification, retrieval, clustering)
- Watch compute cost — embedding can dominate eval runtime

### 7. Always audit reference data quality

Reference-based metrics are bounded by reference quality and coverage.

- Missing-reference failures: a correct novel response gets 0 (Fuyu / image captioning case)
- Wrong references: WMT 2023 found many bad reference translations
- Mitigation: collect multiple references per input; spot-check; consider reference-free metrics as a sanity check

## Guidelines

- For code: pass@1 reflects single-shot quality; pass@10 reflects "best of N" capability — report both when the deployment uses sampling.
- Keep test cases diverse: edge cases catch failures that the happy path misses.
- For semantic similarity, log raw cosine scores so thresholds can be re-tuned without re-running embeddings.
- If you must use BLEU/ROUGE, also report a semantic-similarity score and a small human-judged sample.

## Exceptions

- **Closed-ended classification tasks**: skip this whole framework; standard accuracy/F1 already covers it.
- **Highly constrained format outputs (JSON/SQL)**: exact match on structured fields can work if you parse first, then compare canonical forms.
- **Deduplication / retrieval / clustering**: semantic similarity is the *primary* tool, not a fallback — use it directly.

## Selection Cheat Sheet

| Task type | Recommended method | Avoid |
|-----------|-------------------|-------|
| Code generation | Functional correctness (pass@k) | BLEU on code |
| SQL generation | Execute + compare result sets | String match on SQL |
| Math / trivia | Exact match (with format constraint) | Lexical similarity |
| Translation | Lexical (BLEU) + semantic (BERTScore) + human | Exact match |
| Summarization | Semantic similarity + human | Exact match |
| Open-ended QA | Semantic similarity or AI-as-judge | Exact match |
| Game / optimization | Objective score | Reference-based metrics |
| Retrieval / RAG | Embedding cosine | Exact match |

## Quick Reference

| Rule | Summary |
|------|---------|
| Functional first | Use it whenever you can execute the output |
| Exact match limits | Only for short canonical answers |
| Avoid loose "contains" | Substring matches accept wrong answers |
| BLEU != correctness | Lexical overlap is not quality |
| Semantic for paraphrase | Use embeddings when wording varies |
| Audit references | Missing/wrong references corrupt scores |
