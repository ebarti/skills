# Exact Evaluation Examples

Python examples for functional correctness, exact match, lexical similarity, and semantic similarity.

## Functional Correctness (HumanEval style)

### pass@k for code generation

```python
import signal

def _timeout(_s, _f): raise TimeoutError
signal.signal(signal.SIGALRM, _timeout)

def passes_all_tests(code: str, check_src: str, timeout_s: int = 3) -> bool:
    """Execute candidate code, then run the `check(candidate)` test fn."""
    ns: dict = {}
    try:
        exec(code, ns)        # defines `candidate`
        exec(check_src, ns)   # defines `check`
        signal.alarm(timeout_s)
        ns["check"](ns["candidate"])
        signal.alarm(0)
        return True
    except Exception:
        signal.alarm(0)
        return False

def pass_at_k(samples: list[str], check_src: str) -> bool:
    """Problem solved if ANY of k samples passes."""
    return any(passes_all_tests(c, check_src) for c in samples)

# HumanEval-style problem `has_close_elements`
candidate_code = """
from typing import List
def candidate(numbers: List[float], threshold: float) -> bool:
    for i, a in enumerate(numbers):
        for b in numbers[i+1:]:
            if abs(a - b) < threshold: return True
    return False
"""

check_src = """
def check(candidate):
    assert candidate([1.0, 2.0, 3.9, 4.0, 5.0, 2.2], 0.3) == True
    assert candidate([1.0, 2.0, 3.9, 4.0, 5.0, 2.2], 0.05) == False
    assert candidate([1.0, 2.0, 5.9, 4.0, 5.0], 0.8) == False
"""

solved = pass_at_k([candidate_code], check_src)  # True
```

**Why it works**: actually executes the candidate and verifies behavior — no surface-level proxy.

## Exact Match

### Strict and "contains" variants

```python
def exact_match(generated: str, references: list[str]) -> bool:
    g = generated.strip().lower()
    return any(g == r.strip().lower() for r in references)

def contains_match(generated: str, references: list[str]) -> bool:
    g = generated.lower()
    return any(r.strip().lower() in g for r in references)

exact_match("5", ["5"])                              # True
exact_match("The answer is 5", ["5"])                # False (strict)
contains_match("The answer is 5", ["5"])             # True

# Pitfall of `contains`: factually-wrong but contains the year
contains_match("September 12, 1929", ["1929"])       # True, but answer is WRONG
```

**Why it works (and breaks)**: strict match is reliable for canonical answers. `contains_match` rewards outputs that *include* the right token alongside wrong context.

## Lexical Similarity

### Token overlap (smallest possible BLEU-ish score)

```python
def token_overlap(generated: str, reference: str) -> float:
    ref_tokens = reference.lower().split()
    gen_tokens = set(generated.lower().split())
    if not ref_tokens:
        return 0.0
    matched = sum(1 for t in ref_tokens if t in gen_tokens)
    return matched / len(ref_tokens)

reference = "My cats scare the mice"
token_overlap("My cats eat the mice", reference)              # 0.8
token_overlap("Cats and mice fight all the time", reference)  # 0.6
```

### Edit distance (fuzzy matching)

```python
def edit_distance(a: str, b: str) -> int:
    """Levenshtein: insertion, deletion, substitution = 1 each."""
    if not a: return len(b)
    if not b: return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        curr = [i] + [0] * len(b)
        for j, cb in enumerate(b, 1):
            curr[j] = min(prev[j] + 1, curr[j-1] + 1, prev[j-1] + (ca != cb))
        prev = curr
    return prev[-1]

edit_distance("bad", "bard")   # 1
edit_distance("bad", "cash")   # 3
```

### BLEU and ROUGE via libraries

```python
# pip install sacrebleu rouge-score
from sacrebleu import corpus_bleu
from rouge_score import rouge_scorer

hypotheses = ["The cat sat on the mat."]
references = [["A cat is sitting on the mat."]]  # list of reference lists
bleu = corpus_bleu(hypotheses, references).score   # 0–100

scorer = rouge_scorer.RougeScorer(["rouge1", "rougeL"], use_stemmer=True)
rouge = scorer.score(references[0][0], hypotheses[0])
# rouge["rouge1"].fmeasure, rouge["rougeL"].fmeasure
```

**Caveat**: scores reflect overlap, not correctness — pair with semantic or human signal.

## Semantic Similarity (Embedding Cosine)

### Cosine similarity from scratch

```python
import math

def cosine_similarity(a: list[float], b: list[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    norm_a = math.sqrt(sum(x * x for x in a))
    norm_b = math.sqrt(sum(y * y for y in b))
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return dot / (norm_a * norm_b)

cosine_similarity([0.11, 0.02, 0.54], [0.10, 0.03, 0.55])   # ~0.9999
```

### Embedding similarity with Sentence Transformers

```python
# pip install sentence-transformers numpy
from sentence_transformers import SentenceTransformer
import numpy as np

model = SentenceTransformer("all-MiniLM-L6-v2")  # 384-d embeddings

def semantic_similarity(text_a: str, text_b: str) -> float:
    emb = model.encode([text_a, text_b], normalize_embeddings=True)
    return float(np.dot(emb[0], emb[1]))   # cosine since normalized

semantic_similarity("What's up?", "How are you?")               # high
semantic_similarity("the cat sits on a mat", "AI research is fun")  # low
```

### BERTScore (drop-in for translation/summarization)

```python
# pip install bert-score
from bert_score import score
P, R, F1 = score(cands=["The cat is on the mat."],
                 refs=["A cat sits on the mat."], lang="en")
print(F1.item())   # higher = more semantically similar
```

## Edge Cases & Gotchas

### Lexical similarity rewards wrong-but-similar outputs
```python
ref = "Paris is the capital of France."
token_overlap("Paris is the capital of Germany.", ref)  # ~0.83 — WRONG but high
token_overlap("France's capital city is Paris.", ref)   # ~0.50 — CORRECT but low
```

### Missing references penalize correct novel answers
```python
exact_match("How is it going?", ["How are you?", "How is everything?"])  # False, but correct paraphrase
```
Mitigate via semantic similarity backstop or expanded reference set.

### `pass@1` vs `pass@k`
```python
pass_at_k([candidate_code], check_src)        # pass@1
pass_at_k([candidate_code] * 10, check_src)   # pass@10 >= pass@1 always
```
Report which k you used; don't compare pass@1 vs pass@10.
### Embedding model choice changes the score
Same texts under different embedding models give different cosines. Pick ONE embedding model and fix it across the campaign.
