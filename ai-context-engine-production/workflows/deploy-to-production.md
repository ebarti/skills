# Deploy to Production Workflow

Take the Context Engine from notebook to a production deployment: env config → FastAPI → async workers → Docker → observability → go-live.

## When to Use

- Engine is hardened (from `ai-context-engine/workflows/harden-engine.md`)
- Moderation gatekeeper is wired (from `add-moderation.md`)
- Stakeholders have signed off on functionality
- Ready for first production users

## Prerequisites

- Hardened, modularized engine in `commons/`
- Moderation in place
- Cloud / infra account (AWS, GCP, etc.) with permissions to deploy

**Reference**: `references/production-deployment/knowledge.md`, `references/production-deployment/checklist.md`

---

## Workflow Steps

### Step 1: Environment configuration + secrets

**Goal**: Twelve-Factor: config in env, secrets in vault.

- [ ] Move ALL config to env vars (`.env` for dev only, never commit)
- [ ] Use a secrets manager in prod (AWS Secrets Manager, Vault, etc.)
- [ ] Document required env vars in `README` or `.env.example`
- [ ] Verify: code has no hardcoded keys

**Reference**: `references/production-deployment/examples.md` (env config)

---

### Step 2: Build the FastAPI orchestration layer

**Goal**: HTTP API that accepts goals + returns trace IDs.

- [ ] Define request schema: `{goal, config, ...}`
- [ ] Define response schema: `{trace_id, status_url}` (async, returns immediately)
- [ ] Endpoint POSTs to a queue, returns 202
- [ ] Add a `GET /trace/{id}` endpoint for status

**Reference**: `references/production-deployment/examples.md` (FastAPI endpoint)

---

### Step 3: Add async execution + task queue

**Goal**: Decouple the API from the engine's deliberate pace.

- [ ] Choose a queue (Celery + Redis, RQ, or cloud-native)
- [ ] Worker process consumes the queue and runs `execute_and_display`
- [ ] Worker writes results back to a result store (Redis, DB)
- [ ] API serves results from the store

**Reference**: `references/production-deployment/knowledge.md` (async lifecycle), `references/production-deployment/examples.md`

---

### Step 4: Add structured logging + observability

**Goal**: Three pillars: logs, metrics, traces.

- [ ] Configure JSON structured logger (per `harden-engine`)
- [ ] Add Prometheus metrics for: requests, latency, queue depth, token counts
- [ ] Add distributed tracing (OpenTelemetry) — one trace per goal
- [ ] Forward all logs to a centralized store (Loki, CloudWatch, etc.)

**Reference**: `references/production-deployment/rules.md` (observability rules), `references/production-deployment/examples.md` (JSON logger)

---

### Step 5: Containerize

**Goal**: One Docker image, two CMDs (API + worker).

- [ ] Write the Dockerfile (slim Python base, copy commons + api.py + worker.py, install pinned deps)
- [ ] Build image, tag with version
- [ ] Test locally: API container + Worker container against local Redis

**Reference**: `references/production-deployment/examples.md` (Dockerfile + Uvicorn / Celery commands)

---

### Step 6: Deploy

**Goal**: Get API + worker + queue running in prod.

- [ ] Deploy API as scalable service (Kubernetes Deployment, ECS service, etc.)
- [ ] Deploy worker as a separate scalable service
- [ ] Deploy queue (managed Redis, etc.)
- [ ] Front API with a gateway (auth, rate limit)
- [ ] Configure log forwarding + metrics scraping

**Reference**: `references/production-deployment/knowledge.md` (Docker + K8s topology)

---

### Step 7: Smoke-test in production

**Goal**: Validate end-to-end before opening to users.

- [ ] Hit the API with a known-safe goal → 202 + trace_id
- [ ] Poll for completion → success
- [ ] Verify logs show the full trace
- [ ] Verify metrics increment
- [ ] Hit with unsafe goal → moderation rejection
- [ ] Hit with concurrent goals → queue absorbs load

---

### Step 8: Run the go-live checklist

**Goal**: Final gate.

- [ ] Env vars set
- [ ] Secrets in vault
- [ ] API + worker deployed and healthy
- [ ] Queue + result store running
- [ ] Logs centralized
- [ ] Metrics scraped
- [ ] Smoke tests pass

**Reference**: `references/production-deployment/checklist.md`

---

## Quick Checklist

```
[ ] Step 1: Env config + secrets vault
[ ] Step 2: FastAPI orchestration layer
[ ] Step 3: Async + task queue
[ ] Step 4: Logs + metrics + traces
[ ] Step 5: Docker image (one image, two CMDs)
[ ] Step 6: Deployed (API + worker + queue)
[ ] Step 7: Production smoke test
[ ] Step 8: Go-live checklist passes
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Hardcoded secrets | Security incident waiting to happen | Vault + env vars |
| Synchronous API call to engine | Slow LLM hops block requests | Async + queue |
| Plain-text logs | Hard to filter at scale | Structured JSON |
| One container with API + worker + queue | Can't scale independently | Separate services |
| Skipping moderation in prod | Compliance failure | Two-stage protocol active |
| Going live without smoke test | First user finds your bugs | Smoke test in prod first |

---

## Exit Criteria

- [ ] All endpoints respond correctly
- [ ] Async lifecycle works (202 → poll → result)
- [ ] Moderation active and tested
- [ ] Logs / metrics / traces visible in dashboards
- [ ] Worker scales horizontally
- [ ] All items in `production-deployment/checklist.md` pass
