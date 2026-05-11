# Production Deployment Knowledge

Core concepts for deploying the glass-box Context Engine as a resilient, observable, scalable service.

## Overview

Productionizing the Context Engine means moving from notebook prototypes to a network-accessible, asynchronous service. The canonical topology splits the API (a thin orchestration layer) from background workers (the engine), connected by a task queue, with centralized secrets, logs, metrics, and traces.

## Key Concepts

### Environment Configuration & Secrets Management

**Definition**: Externalizing all configuration (model names, API keys, endpoints) from code so the same image runs in dev, staging, and production with no source changes.

**Key points**:
- Follows the **Twelve-Factor App** methodology: separate config from code.
- Code reads `os.environ.get(...)` at runtime; `python-dotenv` simulates this locally.
- Sensitive values belong in a centralized secrets manager: AWS Secrets Manager, Azure Key Vault, Google Cloud Secret Manager, or HashiCorp Vault.
- In Kubernetes, sidecar/init containers fetch secrets from the vault and inject them, keeping the application backend-agnostic.

### Production API as Orchestration Layer

**Definition**: A thin, network-accessible service (FastAPI) that receives high-level goals, validates them, and dispatches them — *not* a process that executes the engine inline.

**Key points**:
- **FastAPI + Pydantic + Uvicorn** is the chosen stack: async/await, automatic validation, native OpenAPI docs.
- Decouples *what* the engine does from *how* it is accessed, enabling independent scaling.
- Sits behind an **API Gateway** (AWS API Gateway, Kong, Istio) for AuthN/AuthZ, rate limiting, and SSL termination.
- The endpoint *dispatches* to a queue; it does not block on engine execution.

### Asynchronous Execution & Task Queues

**Definition**: A pattern where the API immediately enqueues work and returns `202 Accepted` with a `trace_id`, while a separate worker pool pulls tasks from the queue and runs the engine.

**Lifecycle**:
1. API receives goal.
2. API validates and pushes task to broker/queue.
3. API returns `HTTP 202 Accepted` with `trace_id`.
4. Worker pulls task and runs the Context Engine (Planner, Agents, Executor).
5. Worker stores trace + final output in a Result Store (Redis or DB), keyed by `trace_id`.
6. Client polls a status endpoint or receives a webhook callback.

**Tooling**:
- **Message brokers**: RabbitMQ, Kafka.
- **Task queues**: Celery (mature, full-featured), Redis Queue / RQ (simpler).

### Centralized Logging & Observability

**Definition**: The combination of structured logs, metrics, and distributed traces that makes a deployed system inspectable end-to-end.

**Three pillars**:
- **Structured logs (JSON)**: every line carries `trace_id` so a request can be reconstructed across services. Aggregated via ELK (Elasticsearch/Logstash/Kibana), AWS CloudWatch, GCP Observability, Splunk, or Datadog. Fluentd ships logs from containers.
- **Metrics**: scraped by **Prometheus** from a `/metrics` endpoint, visualized in **Grafana**. Cover system (CPU, memory, network), application (latency, errors, throughput, queue length), and AI-specific (token consumption, LLM latency, vector DB latency) dimensions.
- **Distributed tracing**: **Jaeger** or **Zipkin** link spans across API gateway, FastAPI, broker, and worker under a shared trace ID, exposing bottlenecks.

### Infrastructure & Containerization

**Definition**: Packaging the engine as a Docker image and orchestrating replicas with Kubernetes so the same artifact runs identically everywhere.

**Key points**:
- **Docker** image bundles Python runtime, libraries, and code; eliminates environment drift.
- The **same image** is used for two roles: API (`uvicorn api:app`) and worker (`celery -A tasks worker`).
- **Kubernetes** resources used: Deployments (replica counts), Services (stable endpoints), ConfigMaps + Secrets (config injection), Ingress (external routing).
- Managed clusters: AWS EKS, Azure AKS, GCP GKE.
- Scaling: **Horizontal Pod Autoscaler** (HPA) scales pods on CPU or custom metrics like queue length; **Cluster Autoscaler** provisions new nodes.

### The Full Production Topology

A single goal flows: **Client -> API Gateway -> FastAPI (validate + enqueue) -> Task Queue (Celery/RabbitMQ) -> Worker Pool (engine) -> LLM API + Vector DB + Secrets Manager + Observability Stack -> Result Store -> Client retrieval by `trace_id`**.

## Terminology

| Term | Definition |
|------|------------|
| Twelve-Factor App | Methodology that separates config from code via environment variables. |
| Orchestration layer | The API service that dispatches goals to workers. |
| Task queue | Broker-backed queue (Celery/RQ) decoupling API from execution. |
| Trace ID | Correlation ID linking logs/metrics/spans for one request. |
| Worker pool | Autoscaling group of containers running the engine. |
| Result Store | Persistent store (Redis/DB) holding outputs keyed by `trace_id`. |
| HPA | Horizontal Pod Autoscaler — scales pods based on metrics. |

## How It Relates To

- **Glass-box engine**: observability is what keeps the engine a *glass box* in production.
- **LLM/Vector DB integrations**: workers (not the API) call OpenAI and Pinecone.
- **Security**: API Gateway + secrets manager together form the perimeter.

## Common Misconceptions

- **Myth**: The API should run the engine directly for simplicity.
  **Reality**: Long-running LLM workflows would block the event loop and exhaust resources. Always dispatch to a worker.

- **Myth**: Kubernetes Secrets are sufficient for enterprise secrets.
  **Reality**: They are often insufficient; use a centralized vault (AWS/Azure/GCP/HashiCorp).

- **Myth**: Plain text logs are fine if you have grep.
  **Reality**: Distributed systems need structured JSON logs with `trace_id` for correlation.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Config | Read from env vars; never hardcode. |
| Secrets | Centralized vault; injected at runtime. |
| API | FastAPI + Uvicorn; async dispatcher only. |
| Queue | Celery + RabbitMQ (or RQ + Redis). |
| Logs | JSON, with `trace_id`, aggregated centrally. |
| Metrics | Prometheus + Grafana. |
| Tracing | Jaeger/Zipkin across all components. |
| Container | One Docker image, two CMDs (API & worker). |
| Orchestration | Kubernetes Deployments + HPA. |
