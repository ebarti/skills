# Monitoring & Observability Examples

Concrete Python examples of metrics, logs, traces, and drift detection for LLM applications.

## Bad Examples

### Logging Only the Final Output

```python
def chat(user_query: str) -> str:
    response = llm.generate(build_prompt(user_query))
    logger.info(f"response={response}")
    return response
```

**Problems**:
- No record of the assembled prompt, model name, or sampling params — irreproducible
- No request ID, no tool calls, no latency or cost
- A bad output cannot be traced to its cause

### A Single Aggregated Quality Metric

```python
quality_score = evaluate_all_responses_today()
prometheus.gauge("quality_score").set(quality_score)
```

**Problems**:
- Cannot break down by release, prompt version, or user cohort
- A 5% drop hides which version or segment regressed
- No way to correlate to business metrics

### No Drift Detection on Hosted Model

```python
client = OpenAI()
response = client.chat.completions.create(
    model="gpt-4o",  # provider may swap underlying weights silently
    messages=[...],
)
```

**Problems**:
- Underlying model can change without notice (Chen et al., 2023 measured significant cross-version deltas)
- No fixed eval set running on a schedule to catch the change

## Good Examples

### Structured Per-Request Logging

```python
import json
import time
import uuid
from typing import Any

def chat(user_query: str, user_id: str) -> str:
    request_id = str(uuid.uuid4())
    config = {
        "model": "gpt-4o-2024-08-06",
        "temperature": 0.2,
        "top_p": 0.95,
        "stop": ["</done>"],
        "prompt_template_version": "v3.2",
    }
    prompt = build_prompt(user_query)
    start = time.perf_counter()
    response = llm.generate(prompt, **config)
    latency_ms = (time.perf_counter() - start) * 1000

    logger.info(json.dumps({
        "request_id": request_id,
        "user_id": user_id,
        "release": RELEASE_SHA,
        "config": config,
        "user_query": user_query,
        "final_prompt": prompt,
        "output": response.text,
        "input_tokens": response.usage.prompt_tokens,
        "output_tokens": response.usage.completion_tokens,
        "latency_ms": latency_ms,
        "ts": time.time(),
    }))
    return response.text
```

**Why it works**:
- Every field needed to reproduce, debug, and slice metrics is present
- IDs and tags enable correlation across the system
- Cost and latency captured per request

### End-to-End Tracing for a RAG Pipeline

```python
from contextlib import contextmanager

@contextmanager
def span(trace_id: str, name: str, parent: str | None = None):
    span_id = str(uuid.uuid4())
    start = time.perf_counter()
    try:
        yield span_id
    finally:
        logger.info(json.dumps({
            "trace_id": trace_id,
            "span_id": span_id,
            "parent": parent,
            "name": name,
            "duration_ms": (time.perf_counter() - start) * 1000,
        }))

def rag_chat(query: str) -> str:
    trace_id = str(uuid.uuid4())
    with span(trace_id, "rag_chat") as root:
        with span(trace_id, "preprocess", parent=root):
            cleaned = preprocess(query)
        with span(trace_id, "retrieve", parent=root):
            docs = vector_db.search(cleaned, k=5)
        with span(trace_id, "generate", parent=root):
            return llm.generate(build_prompt(cleaned, docs))
```

**Why it works**:
- Every step has timing tied to a single trace_id
- A failed query can be pinpointed to preprocess, retrieve, or generate
- Adding cost per span is a one-line change

### Decomposable Metrics with Tags

```python
from prometheus_client import Counter, Histogram

LATENCY = Histogram(
    "llm_request_latency_ms",
    "End-to-end latency",
    labelnames=["release", "prompt_version", "model", "endpoint"],
)
TOKENS_OUT = Counter(
    "llm_output_tokens",
    "Output tokens emitted",
    labelnames=["release", "prompt_version", "model"],
)

LATENCY.labels(
    release=RELEASE_SHA,
    prompt_version="v3.2",
    model="gpt-4o-2024-08-06",
    endpoint="chat",
).observe(latency_ms)
```

**Why it works**:
- Prometheus labels let you slice by any axis post-hoc
- A regression in one prompt version is visible without re-instrumenting

### Drift Detection: System Prompt Hash

```python
import hashlib

EXPECTED_PROMPT_HASH = "a17b9c..."  # checked into config

def assert_prompt_unchanged(prompt: str) -> None:
    actual = hashlib.sha256(prompt.encode()).hexdigest()
    if actual != EXPECTED_PROMPT_HASH:
        alert("system_prompt_drift", expected=EXPECTED_PROMPT_HASH, actual=actual)
        raise RuntimeError("System prompt drift detected")
```

### Drift Detection: Underlying Model

```python
EVAL_SET = load_jsonl("eval/golden_set.jsonl")  # fixed inputs + expected outputs

def daily_model_drift_check() -> None:
    scores = []
    for item in EVAL_SET:
        out = llm.generate(item["prompt"])
        scores.append(score(out, item["expected"]))
    avg = sum(scores) / len(scores)
    if abs(avg - BASELINE_SCORE) > 0.03:  # 3-point delta threshold
        alert("model_drift", baseline=BASELINE_SCORE, current=avg)
```

### AI-Judge Quality Metric (Spot Check)

```python
def sample_and_judge(rate: float = 0.05) -> None:
    for log in stream_recent_requests():
        if random.random() > rate:
            continue
        verdict = judge_llm.evaluate(
            query=log["user_query"],
            context=log.get("retrieved_docs", []),
            output=log["output"],
            criteria=["factual_consistency", "conciseness"],
        )
        emit_metric(
            "judge_score",
            value=verdict["factual_consistency"],
            tags={"prompt_version": log["config"]["prompt_template_version"]},
        )
```

## Refactoring Walkthrough

### Before

```python
def answer(q):
    return openai.chat.completions.create(
        model="gpt-4o", messages=[{"role": "user", "content": q}]
    ).choices[0].message.content
```

### After

```python
def answer(q: str, user_id: str) -> str:
    request_id = str(uuid.uuid4())
    cfg = {"model": "gpt-4o-2024-08-06", "temperature": 0.2}
    start = time.perf_counter()
    resp = openai.chat.completions.create(
        messages=[{"role": "user", "content": q}], **cfg
    )
    text = resp.choices[0].message.content
    latency_ms = (time.perf_counter() - start) * 1000

    logger.info(json.dumps({
        "request_id": request_id, "user_id": user_id, "config": cfg,
        "query": q, "output": text,
        "input_tokens": resp.usage.prompt_tokens,
        "output_tokens": resp.usage.completion_tokens,
        "latency_ms": latency_ms,
    }))
    LATENCY.labels(model=cfg["model"]).observe(latency_ms)
    return text
```

### Changes Made

1. Pinned the exact model snapshot (`gpt-4o-2024-08-06`) — defeats silent provider drift
2. Added request/user IDs for correlation across logs and metrics
3. Logged config, query, output, token counts, and latency in one structured record
4. Emitted a labeled latency metric so post-hoc slicing is possible
