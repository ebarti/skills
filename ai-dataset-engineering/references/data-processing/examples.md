# Data Processing Examples

Concrete Python examples for inspecting, deduplicating, cleaning, filtering, and formatting training datasets.

## Inspection

### Distribution Statistics

```python
import pandas as pd
from collections import Counter

df = pd.read_json("raw_dataset.jsonl", lines=True)
df["input_len"]  = df["input"].str.split().str.len()
df["output_len"] = df["output"].str.split().str.len()
print(df[["input_len", "output_len"]].describe())

tokens = Counter(t for text in df["input"] for t in text.split())
print("Top 20 tokens:", tokens.most_common(20))
print(df.groupby("source")["output_len"].describe())
print(df.groupby("annotator")["score"].agg(["mean", "std", "count"]))
```

### Inter-Annotator Disagreement

```python
from collections import defaultdict
labels_by_example = defaultdict(list)
for _, row in df.iterrows():
    labels_by_example[row["example_id"]].append(row["label"])
conflicts = {eid: ls for eid, ls in labels_by_example.items() if len(set(ls)) > 1}
print(f"{len(conflicts)} examples have conflicting annotations")
```

### Manual Inspection Sampler

```python
import random
for ex in random.sample(df.to_dict("records"), 20):
    print(f"INPUT:  {ex['input'][:200]}\nOUTPUT: {ex['output'][:200]}\n{'-'*60}")
```

## Deduplication

### Exact Match (Hashing)

```python
import hashlib

def fingerprint(text: str) -> str:
    return hashlib.sha256(" ".join(text.lower().split()).encode()).hexdigest()

seen, unique = set(), []
for ex in dataset:
    fp = fingerprint(ex["input"] + "|" + ex["output"])
    if fp not in seen:
        seen.add(fp); unique.append(ex)
print(f"Removed {len(dataset) - len(unique)} exact duplicates")
```

### Near-Duplicate via MinHash + LSH

```python
from datasketch import MinHash, MinHashLSH

def make_minhash(text: str, num_perm: int = 128) -> MinHash:
    m = MinHash(num_perm=num_perm)
    for token in text.lower().split():
        m.update(token.encode("utf-8"))
    return m

lsh = MinHashLSH(threshold=0.8, num_perm=128)  # 80% Jaccard similarity
keep = []
for i, ex in enumerate(dataset):
    mh = make_minhash(ex["input"])
    if not lsh.query(mh):
        lsh.insert(f"doc_{i}", mh); keep.append(ex)
print(f"Kept {len(keep)} of {len(dataset)} after near-dup removal")
```

### Bloom Filter for Streaming Dedup

```python
from pybloom_live import BloomFilter
bf = BloomFilter(capacity=10_000_000, error_rate=0.001)
unique = []
for ex in stream_examples():
    key = fingerprint(ex["input"])
    if key not in bf:
        bf.add(key); unique.append(ex)
```

## Cleaning

### Strip HTML and Markdown

```python
import re
from bs4 import BeautifulSoup

def clean_text(text: str) -> str:
    text = BeautifulSoup(text, "html.parser").get_text()
    text = re.sub(r"`{1,3}|\*{1,2}|_{1,2}|#{1,6}\s*", "", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    return re.sub(r"\s+", " ", text).strip()

df["input"]  = df["input"].map(clean_text)
df["output"] = df["output"].map(clean_text)
```

### PII Removal

```python
PII_PATTERNS = {
    "email": r"[\w\.-]+@[\w\.-]+\.\w+",
    "phone": r"\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b",
    "ssn":   r"\b\d{3}-\d{2}-\d{4}\b",
}
def redact_pii(text: str) -> str:
    for tag, pat in PII_PATTERNS.items():
        text = re.sub(pat, f"[{tag.upper()}]", text)
    return text

df["input"] = df["input"].map(redact_pii)
df = df.drop(columns=["zip_code", "full_name", "gender"], errors="ignore")
```

### Filter Low-Quality Examples

```python
def is_low_quality(ex) -> bool:
    if len(ex["input"].split()) < 3: return True               # too short
    if len(ex["output"].split()) > 2000: return True           # too long
    if ex["output"].count(ex["output"][:50]) > 3: return True  # repetition
    # Late-session annotator fatigue
    if ex.get("annotator_session_pos", 0) > 0.5 and ex.get("score", 1) < 3:
        return True
    return False

df = df[~df.apply(is_low_quality, axis=1)]
```

## Formatting

### Convert Few-Shot Prompt to Training Rows

```python
exemplars = [("burger", "edible"), ("car", "inedible"), ("mushroom", "edible")]
training_rows = [{"input": f"{item} -->", "output": label} for item, label in exemplars]
```

### Apply a Chat Template (Hugging Face)

```python
from transformers import AutoTokenizer
tok = AutoTokenizer.from_pretrained("meta-llama/Llama-3.1-8B-Instruct")

def to_chat(ex):
    messages = [
        {"role": "system", "content": "You are a food classifier."},
        {"role": "user",   "content": ex["input"]},
        {"role": "assistant", "content": ex["output"]},
    ]
    return tok.apply_chat_template(messages, tokenize=False)

df["text"] = df.apply(to_chat, axis=1)
```

### Inference Prompt Must Match

```python
TEMPLATE = "{item} -->"                       # training format
prompt = TEMPLATE.format(item="apple")        # CORRECT: "apple -->"

bad_1 = "apple"                # missing "-->"
bad_2 = "Item: apple -->"      # extra prefix
bad_3 = "apple --> "           # trailing space
```

## End-to-End Pipeline Skeleton

```python
from pathlib import Path
OUT = Path("data/processed/v1"); OUT.mkdir(parents=True, exist_ok=True)

df = pd.read_json("data/raw.jsonl", lines=True)
df.to_json(OUT / "00_raw.jsonl", orient="records", lines=True)        # snapshot

df = dedupe_exact(df)
df.to_json(OUT / "01_deduped.jsonl", orient="records", lines=True)

df["input"]  = df["input"].map(clean_text).map(redact_pii)
df["output"] = df["output"].map(clean_text)
df = df[~df.apply(is_low_quality, axis=1)]
df.to_json(OUT / "02_cleaned.jsonl", orient="records", lines=True)

df["text"] = df.apply(to_chat, axis=1)
df[["text"]].to_json(OUT / "03_formatted.jsonl", orient="records", lines=True)
```
