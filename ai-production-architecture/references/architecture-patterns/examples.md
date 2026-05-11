# AI Engineering Architecture Examples

Concrete Python implementations of each step in the 5-step production architecture.

## Step 1: Enhance Context

```python
def build_context(query: str, retriever, tools) -> list[dict]:
    """Construct context: retrieved docs + tool outputs."""
    parts = []
    docs = retriever.search(query, top_k=5)
    parts.append({"role": "system", "content": f"Docs:\n{format_docs(docs)}"})

    if needs_live_data(query):
        tool_result = tools["web_search"](query)
        parts.append({"role": "tool", "content": tool_result})

    parts.append({"role": "user", "content": query})
    return parts
```

## Step 2: Guardrails

### Input Guardrail: PII Mask and Unmask

```python
import re

PII_PATTERNS = {
    "PHONE_NUMBER": re.compile(r"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"),
    "EMAIL": re.compile(r"\b[\w.+-]+@[\w-]+\.[\w.-]+\b"),
    "SSN": re.compile(r"\b\d{3}-\d{2}-\d{4}\b"),
}

def mask_pii(text: str) -> tuple[str, dict]:
    """Replace PII with placeholders. Return masked text + reverse dict."""
    reverse = {}
    masked = text
    for label, pattern in PII_PATTERNS.items():
        for i, m in enumerate(pattern.finditer(text)):
            ph = f"[{label}_{i}]"
            reverse[ph] = m.group()
            masked = masked.replace(m.group(), ph)
    return masked, reverse

def unmask_pii(text: str, reverse: dict) -> str:
    for ph, original in reverse.items():
        text = text.replace(ph, original)
    return text
```

### Output Guardrail: Retry on Failure

```python
import json

def call_with_retry(model, prompt: str, max_retries: int = 3) -> dict:
    """Retry on empty or malformed JSON responses."""
    for _ in range(max_retries):
        response = model.generate(prompt)
        if not response.strip():
            continue
        try:
            return json.loads(response)
        except json.JSONDecodeError:
            continue
    raise RuntimeError(f"Failed after {max_retries} attempts")
```

### Parallel Redundant Calls

```python
import asyncio

async def call_redundant(model, prompt: str, n: int = 2):
    """Issue N parallel calls, pick first valid response."""
    responses = await asyncio.gather(*[model.agenerate(prompt) for _ in range(n)])
    valid = [r for r in responses if is_valid(r)]
    return valid[0] if valid else None
```

### Hand-off to Human

```python
def maybe_handoff(conv, sentiment_model, max_turns: int = 5):
    """Transfer to human on anger or after too many turns."""
    if sentiment_model.predict(conv[-1]["content"]) == "angry":
        return route_to_human(conv, reason="anger")
    if len(conv) > max_turns:
        return route_to_human(conv, reason="loop_prevention")
    return None
```

## Step 3: Router and Gateway

### Intent Classifier Router

```python
class IntentRouter:
    def __init__(self, classifier):
        self.classifier = classifier  # small fast model (BERT-class)

    def route(self, query: str) -> dict:
        intent = self.classifier.predict(query)
        if intent == "password_reset":
            return {"handler": "faq", "page": "password_recovery"}
        if intent == "billing":
            return {"handler": "human_operator"}
        if intent == "tech_support":
            return {"handler": "model", "model_id": "tech_specialist"}
        return {"handler": "stock", "text": "I can only help with product questions."}
```

### Model Gateway with Fallback

```python
class ModelGateway:
    """Unified interface to multiple model APIs with fallback."""

    def __init__(self, providers: dict, access_control):
        self.providers = providers
        self.access_control = access_control

    def generate(self, user_id: str, model: str, prompt: str,
                 fallback: list[str] | None = None) -> str:
        if not self.access_control.can_access(user_id, model):
            raise PermissionError(f"{user_id} lacks access to {model}")

        chain = [model] + (fallback or [])
        last_error = None
        for m in chain:
            try:
                return self._provider_for(m).generate(prompt, model=m)
            except (RateLimitError, APIError) as e:
                last_error = e
        raise RuntimeError(f"All providers failed: {last_error}")
```

## Step 4: Caching

### Exact Cache with LRU Eviction

```python
from collections import OrderedDict
import hashlib

class ExactCache:
    def __init__(self, max_size: int = 1000):
        self.cache: OrderedDict[str, str] = OrderedDict()
        self.max_size = max_size

    def _key(self, q: str) -> str:
        return hashlib.sha256(q.encode()).hexdigest()

    def get(self, query: str) -> str | None:
        key = self._key(query)
        if key in self.cache:
            self.cache.move_to_end(key)
            return self.cache[key]
        return None

    def put(self, query: str, response: str) -> None:
        key = self._key(query)
        self.cache[key] = response
        self.cache.move_to_end(key)
        if len(self.cache) > self.max_size:
            self.cache.popitem(last=False)
```

### Semantic Cache with Vector Search

```python
class SemanticCache:
    def __init__(self, embedder, vector_db, threshold: float = 0.95):
        self.embedder = embedder
        self.vector_db = vector_db
        self.threshold = threshold

    def get(self, query: str) -> str | None:
        emb = self.embedder.encode(query)
        results = self.vector_db.search(emb, top_k=1)
        if results and results[0].score >= self.threshold:
            return results[0].metadata["response"]
        return None

    def put(self, query: str, response: str) -> None:
        emb = self.embedder.encode(query)
        self.vector_db.upsert(emb, metadata={"query": query, "response": response})
```

## Step 5: Agent Patterns

### Retrieval Loop (Self-Refining Agent)

```python
def agent_loop(query: str, model, retriever, max_iters: int = 3) -> str:
    context = retriever.search(query)
    response = model.generate(query, context=context)
    for _ in range(max_iters):
        if model.is_complete(query, response):
            return response
        context += retriever.search(f"{query} {response}")
        response = model.generate(query, context=context)
    return response
```

### Write Action with Confirmation

```python
def execute_write_action(action: dict, human_approver) -> dict:
    """Write actions require explicit human approval."""
    ALLOWED = {"send_email", "create_ticket"}
    if action["type"] not in ALLOWED:
        raise ValueError(f"Action {action['type']} not allowlisted")
    if not human_approver.approve(action):
        return {"status": "rejected", "reason": "human_denied"}
    result = TOOLS[action["type"]](**action["params"])
    audit_log(action, result)
    return {"status": "executed", "result": result}
```

## Putting It All Together

```python
def handle_query(user_id: str, query: str, system) -> str:
    safe_query, reverse = mask_pii(query)                       # input guardrail
    route = system.router.route(safe_query)                     # routing
    if route["handler"] == "stock":
        return route["text"]
    if cached := system.cache.get(safe_query):                  # cache lookup
        return unmask_pii(cached, reverse)
    context = build_context(safe_query, system.retriever, system.tools)
    response = system.gateway.generate(                          # gateway call
        user_id, route["model_id"], context, fallback=["gpt-4o-mini"]
    )
    if not passes_output_checks(response):                       # output guardrail
        response = call_with_retry(system.model, context)
    if is_cacheable(safe_query, system.cache_classifier):
        system.cache.put(safe_query, response)
    return unmask_pii(response, reverse)
```
