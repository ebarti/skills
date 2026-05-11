# Production Deployment Go-Live Checklist

Use this checklist before flipping traffic to a Context Engine deployment.

## Before You Start

- [ ] Architecture matches the canonical topology: Client -> API Gateway -> FastAPI -> Task Queue -> Worker Pool -> Result Store.
- [ ] API and worker run as separate Deployments backed by the same Docker image.
- [ ] All required runbooks and on-call rotations are in place.

## Environment Variables & Configuration

- [ ] `GENERATION_MODEL` set (defaults documented; e.g. `gpt-4o`).
- [ ] `OPENAI_API_KEY` set.
- [ ] `PINECONE_API_KEY` set.
- [ ] Broker URL (RabbitMQ / Kafka / Redis) set.
- [ ] Result store URL (Redis / DB) set.
- [ ] Startup validation fails loudly when any required key is missing.
- [ ] No `.env` file shipped inside the production image.
- [ ] No secret values committed to Git history.

## Secrets Manager

- [ ] Centralized vault chosen and provisioned (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager, or HashiCorp Vault).
- [ ] Kubernetes sidecar / init container fetches secrets and injects them at startup.
- [ ] Application code is agnostic to the secrets backend.
- [ ] Secret rotation policy documented and tested.

## API Deployment

- [ ] FastAPI app exposes `/api/v1/execute` with Pydantic-validated `GoalRequest` / `ExecutionResponse`.
- [ ] Endpoints are `async def`; synchronous engine calls run in a thread pool.
- [ ] Container started with `uvicorn api:app --host 0.0.0.0 --port 8000`.
- [ ] Container exposes only port `8000`.
- [ ] API Gateway in front handles AuthN/Z, rate limiting, SSL termination.
- [ ] API returns `HTTP 202 Accepted` with `trace_id` for goal submissions.
- [ ] Status / result endpoint available for clients to poll by `trace_id`.

## Worker Deployment

- [ ] Worker Deployment runs the same image with `celery -A tasks worker --loglevel=INFO`.
- [ ] No public ports exposed on worker pods.
- [ ] Workers connect to the same broker as the API.
- [ ] Workers persist final outputs and traces to the Result Store keyed by `trace_id`.
- [ ] HPA configured to scale workers on queue length (or CPU).

## Task Queue / Broker

- [ ] Broker (RabbitMQ / Kafka / Redis) is HA-deployed.
- [ ] Queue durability and acknowledgement settings reviewed.
- [ ] Dead-letter / retry policy in place for failed tasks.

## Observability

- [ ] Logs emitted as structured JSON.
- [ ] Every log line includes `trace_id`.
- [ ] Logs aggregated to central system (ELK, CloudWatch, GCP Observability, Splunk, or Datadog).
- [ ] Fluentd (or equivalent) forwarder running alongside containers.
- [ ] `/metrics` endpoint exposed and scraped by Prometheus.
- [ ] Grafana dashboards live for system, application, and AI-specific metrics (CPU, memory, latency, error rate, queue length, token consumption, LLM latency, vector DB latency).
- [ ] Distributed tracing wired through API gateway, FastAPI, broker, and worker (Jaeger or Zipkin).
- [ ] Alerting rules configured for error rate, queue backlog, latency, and cost-relevant token usage.

## Docker Image

- [ ] Built from `python:3.11-slim` (or matching slim base).
- [ ] `requirements.txt` copied and installed before source for layer caching.
- [ ] `pip install --no-cache-dir -r requirements.txt` used.
- [ ] Image tagged with an immutable version (no `latest` in production).
- [ ] Image published to the production registry.
- [ ] Image scanned for vulnerabilities.
- [ ] Same image powers both API and worker Deployments.

## Kubernetes Resources

- [ ] Deployments defined for API and worker with explicit replica counts.
- [ ] Services expose stable endpoints for the API pods.
- [ ] Ingress configured with the cloud load balancer.
- [ ] ConfigMaps hold non-secret config; Secrets hold sensitive values.
- [ ] HPA configured for both API (CPU) and worker (queue length / custom metric).
- [ ] Cluster Autoscaler enabled to add nodes when capacity is exhausted.
- [ ] Managed cluster (EKS / AKS / GKE) chosen unless self-managed is justified.

## Smoke Tests

- [ ] Submit a real goal end-to-end and confirm `202 Accepted` + `trace_id`.
- [ ] Confirm the worker picks up the task and writes the result.
- [ ] Retrieve the result by `trace_id`.
- [ ] Inspect logs and find the full lifecycle correlated by `trace_id`.
- [ ] Inspect a distributed trace spanning gateway, FastAPI, broker, and worker.

## Red Flags

Stop and address if you find:

- Any secret value visible in code, image, env file in Git, or container logs.
- API endpoints that block on engine execution (no queue dispatch).
- Logs in unstructured text or missing `trace_id`.
- Worker pods exposing public ports.
- A single Deployment hosting both API and worker.
- Missing HPA or no autoscaling metric tied to queue length.
- `latest` tag used for the production image.

## Quick Reference

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| Secrets | Centralized vault, sidecar-injected | K8s Secrets from CI | Hardcoded in code |
| API role | Async dispatcher only | Thread-pooled sync engine | Inline blocking execution |
| Logs | JSON + `trace_id`, central aggregator | JSON locally tailed | Plain text, no correlation |
| Image | Slim base, pinned deps, scanned | Slim base, pinned deps | Latest tag, unscanned |
| Scaling | HPA on queue length + Cluster Autoscaler | HPA on CPU | Static replicas |
