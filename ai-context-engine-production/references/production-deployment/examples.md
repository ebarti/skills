# Production Deployment Examples

Verbatim Python and Dockerfile snippets that realize the canonical API+worker topology.

## Environment Configuration (Twelve-Factor)

Read every config value from environment variables; fail fast if required keys are missing.

```python
import os
GENERATION_MODEL = os.environ.get("GENERATION_MODEL", "gpt-4o")
PINECONE_API_KEY = os.environ.get("PINECONE_API_KEY")
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")
if not PINECONE_API_KEY or not OPENAI_API_KEY:
    raise ValueError("Essential API keys are missing from environment variables.")
```

**Why it works**:
- Same code base runs in dev, staging, and prod with no source changes.
- Hard failure at startup beats silent misconfiguration in production.
- During local dev, `python-dotenv` can load these from a `.env` file.

## Production API (FastAPI Orchestration Layer)

The API validates the request and dispatches it; it does not run the engine inline. Long-running engine logic must execute in a thread pool (or, ideally, on a worker via the task queue).

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, Optional

# Assume clients (OpenAI, Pinecone) are initialized at startup
# from utils import initialize_clients
# client, pc = initialize_clients()

app = FastAPI(title="Context Engine Service")

class GoalRequest(BaseModel):
    goal: str
    configuration_overrides: Optional[Dict[str, Any]] = None
    require_audit_trace: bool = False # Added for hybrid routing later

class ExecutionResponse(BaseModel):
    status: str
    trace_id: str
    final_output: Optional[str] = None
    metadata: Dict[str, Any]

@app.post("/api/v1/execute", response_model=ExecutionResponse)
async def execute_goal(request: GoalRequest):
    # Main endpoint for executing a goal with the Glass Box engine.
    # For now, it routes directly to the Glass Box execution (ideally via a task queue).
    try:
        # ... (Configuration loading logic) ...

        # The context_engine function needs to be run in a thread pool
        # if it remains synchronous, to avoid blocking the async event loop.
        result, trace = await run_engine_in_threadpool(
            request.goal,
            # ... (pass clients and config) ...
        )

        return ExecutionResponse(
            status=trace.status,
            trace_id=trace.trace_id, # Assuming trace_id is added to ExecutionTrace
            final_output=result,
            metadata={"engine_used": "GLASS_BOX",
                "duration": trace.duration}
        )
    except Exception as e:
        raise HTTPException(status_code=500,
            detail=f"Engine execution failed: {str(e)}")
```

**Why it works**:
- `async def` keeps the event loop free for new requests.
- Pydantic models enforce schema for both input and output.
- Synchronous engine calls are wrapped via `run_engine_in_threadpool` to avoid blocking.
- `trace_id` returned to the client enables status polling and end-to-end correlation.

## Asynchronous Lifecycle (Reference)

The full flow the API+worker split enables:

1. **Request reception** — API receives the goal request.
2. **Dispatch** — API validates and pushes the task onto a message broker / task queue.
3. **Immediate response** — API returns `HTTP 202 Accepted` with `trace_id`.
4. **Execution** — Worker processes (separate from the API server) pull tasks and execute the Context Engine logic.
5. **Result storage** — Worker stores trace + final output in a persistent store (Redis or DB), keyed by `trace_id`.
6. **Retrieval** — Client polls a status endpoint or receives the result via webhook.

## Dockerfile (API Layer)

A minimal `Dockerfile` for the API. The same image is reused for the worker — only the start command changes.

```dockerfile
# Dockerfile
# Use an official Python runtime (slim version for smaller size)
FROM python:3.11-slim

# Set the working directory
WORKDIR /app

# Copy the requirements file
COPY requirements.txt /app/

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code (engine.py, agents.py, api.py, etc.)
COPY . /app

# Expose the API port
EXPOSE 8000

# Run the API server using Uvicorn
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Why it works**:
- `python:3.11-slim` keeps the image small.
- Copying `requirements.txt` *before* the source maximizes Docker layer caching: dependency installs are skipped on code-only changes.
- `--no-cache-dir` keeps the final image lean.
- `EXPOSE 8000` only on the API role — workers don't expose any public port.
- `CMD` uses Uvicorn directly so the container is the API process.

## Uvicorn Start Command (API)

If running outside of the Dockerfile `CMD`, the equivalent invocation is:

```bash
uvicorn api:app --host 0.0.0.0 --port 8000
```

## Worker Start Command (Celery)

The same Docker image starts as a worker by overriding the command:

```bash
# Command to start the worker
celery -A tasks worker --loglevel=INFO
```

**Why it works**:
- Reusing the API image guarantees identical dependencies and code in both roles.
- Workers scale independently of the API via their own Kubernetes Deployment + HPA.

## Logging Setup (Structured JSON)

Logs must be machine-readable and correlated via `trace_id`. Conceptually, every log line carries metadata that lets downstream tools (ELK, Splunk, Datadog) reconstruct the request lifecycle:

```python
import json
import logging
import sys

class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "trace_id": getattr(record, "trace_id", None),
        }
        return json.dumps(payload)

handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JsonFormatter())
logger = logging.getLogger("context_engine")
logger.addHandler(handler)
logger.setLevel(logging.INFO)

# Usage: attach trace_id so logs can be correlated across services
logger.info("Goal dispatched", extra={"trace_id": trace_id})
```

**Why it works**:
- JSON is parseable by aggregators (ELK, CloudWatch, Splunk, Datadog).
- The `trace_id` field links log lines emitted by the API gateway, FastAPI, broker, and worker into a single timeline.
- A Fluentd sidecar can ship these lines to the central store with no app changes.

## Kubernetes Topology (Reference)

| Resource | Purpose |
|----------|---------|
| Deployment (api) | `uvicorn api:app`, e.g. 3 replicas, exposes port 8000 |
| Deployment (worker) | `celery -A tasks worker --loglevel=INFO`, e.g. 5 replicas, no exposed port |
| Service | Stable endpoint for the API pods |
| Ingress | External access via cloud load balancer |
| ConfigMap | Non-secret config (model names, queue URLs) |
| Secret | API keys, vault-injected at runtime |
| HPA | Scale workers on task queue length; scale API on CPU |
