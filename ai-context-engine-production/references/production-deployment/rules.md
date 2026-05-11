# Production Deployment Rules

Rules for deploying the Context Engine as a hardened, scalable service.

## Core Rules

### 1. Never Hardcode Secrets or Config

Secrets and environment-specific values must never live in source code or Git history.

- Read every config value via `os.environ.get(...)`.
- Validate required keys at startup; fail loudly if missing.
- Use `python-dotenv` for local dev only; never ship `.env` files to production.
- Centralize storage in a vault: AWS Secrets Manager, Azure Key Vault, Google Cloud Secret Manager, or HashiCorp Vault.
- Inject secrets via Kubernetes sidecar/init containers — keep app code agnostic to the backend.

**Example**:
```python
# Bad
OPENAI_API_KEY = "sk-abc123..."

# Good
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise ValueError("Essential API keys are missing from environment variables.")
```

### 2. Use FastAPI + Uvicorn for the API Layer

FastAPI is the chosen framework for the orchestration layer; Uvicorn is the ASGI server.

- Use Pydantic models for every request/response (`GoalRequest`, `ExecutionResponse`).
- Endpoints must be `async def` to avoid blocking the event loop.
- If the engine call is synchronous, run it in a thread pool — never call it inline.
- Document via the auto-generated OpenAPI schema.

### 3. Always Decouple API from Execution via a Task Queue

The API must be a dispatcher, not an executor.

- API validates the request, pushes it onto Celery / RabbitMQ (or RQ / Redis), and returns `HTTP 202 Accepted` with a `trace_id`.
- Workers run as separate processes/containers, pulling from the queue.
- Use **Celery** by default; use **RQ** only when Celery's complexity isn't justified.
- Choose **RabbitMQ** or **Kafka** as the broker for durability.

### 4. Log in Structured JSON with a `trace_id`

Production logs must be machine-parseable and correlatable.

- Emit JSON, never free-form text.
- Every log line must include `trace_id` so a request can be reconstructed across services.
- Aggregate via ELK, CloudWatch, GCP Observability, Splunk, or Datadog.
- Ship logs from containers using Fluentd (or equivalent forwarder).

### 5. Expose Metrics on `/metrics` for Prometheus

Quantify system, application, and AI-specific behavior.

- **System**: CPU, memory, network I/O.
- **Application**: request latency, error rate, throughput, queue length.
- **AI-specific**: total token consumption, LLM call latency, vector DB latency.
- Visualize and alert with Grafana.

### 6. Trace Distributed Requests with Jaeger or Zipkin

Every span (gateway, FastAPI, broker, worker) must share the same trace ID so end-to-end latency is visible.

### 7. Build Slim, Reproducible Docker Images

The image is the unit of deployment.

- Base on `python:3.11-slim` (or matching slim variant) for size.
- Set `WORKDIR /app`.
- Copy `requirements.txt` first, then `pip install --no-cache-dir -r requirements.txt`, then copy code — leverages Docker layer caching.
- Pin dependencies in `requirements.txt`.
- `EXPOSE 8000` for the API port.
- Default `CMD` runs Uvicorn for the API role.

### 8. One Image, Two Roles: Separate Worker from API

Reuse the same Docker image; differentiate by start command.

- API container: `uvicorn api:app --host 0.0.0.0 --port 8000`.
- Worker container: `celery -A tasks worker --loglevel=INFO`.
- Deploy as separate Kubernetes Deployments so they scale independently.
- HPA targets each Deployment with its own metrics (e.g., scale workers on queue length).

### 9. Front the API with a Gateway

Place an API Gateway (AWS API Gateway, Kong, Istio) in front of FastAPI for:

- Authentication / authorization (API keys, OAuth, JWT).
- Rate limiting and throttling.
- SSL termination.

### 10. Expose Only Required Ports

Only the API container should expose `8000`. Workers should not expose any public port — they communicate via the broker.

## Guidelines

- Keep the API stateless; all state belongs in the broker, vault, or result store.
- Persist results in Redis or a database keyed by `trace_id`.
- Use Kubernetes ConfigMaps for non-secret config and Secrets for sensitive values.
- Prefer managed Kubernetes (EKS, AKS, GKE) over self-managed clusters.
- Configure both **HPA** (pod scaling) and **Cluster Autoscaler** (node scaling).

## Exceptions

- **Local development**: `.env` + `python-dotenv` is acceptable; vault integration is not required.
- **Synchronous engine calls**: tolerated only if wrapped in a thread pool from the async endpoint.
- **RQ over Celery**: acceptable when workflow complexity is low.

## Quick Reference

| Rule | Summary |
|------|---------|
| No hardcoded secrets | Always `os.environ.get`; vault-backed in prod. |
| FastAPI + Uvicorn | Async, Pydantic-validated, OpenAPI-documented. |
| Queue-decoupled | API dispatches; workers execute. |
| Structured logs | JSON with `trace_id`. |
| `/metrics` | Prometheus + Grafana. |
| Distributed tracing | Jaeger or Zipkin, shared trace ID. |
| Slim Docker | `python:3.11-slim`, layer-cached install. |
| Split API & worker | Same image, different `CMD`. |
| API Gateway | AuthN/Z, rate limit, SSL. |
| Port discipline | Only API exposes 8000. |
