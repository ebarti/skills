# Modes of Dataflow Rules

Guidelines for choosing and using databases, services, workflows, and messaging as data conduits.

## Core Rules

### 1. Assume Version Skew at All Times

During rolling upgrades, old and new code run together. All wire formats must be both backward AND forward compatible. Never deploy a change that requires lockstep upgrade across services.

- Test new readers against old data and old readers against new data
- Preserve unknown fields when republishing or relaying messages

### 2. Treat the Database as a Long-Lived Reader/Writer Pair

Data outlives code. A row written 5 years ago must still decode correctly today.

- Use schema evolution (add nullable columns) in place of in-place rewrites
- Defer migrations to background compaction (LSM-tree style) where possible
- For archival snapshots, rewrite once into the latest schema (Avro/Parquet)

### 3. Pick REST for External/Long-Lived APIs, RPC for Internal High-Performance

REST + JSON + OpenAPI is the lingua franca for cross-organization and public APIs — clients you can't force to upgrade.

- gRPC + Protobuf for internal microservice traffic where you control both sides
- For public APIs, expect to maintain multiple versions side-by-side indefinitely

### 4. Never Pretend a Network Call Is a Local Call

RPC's location transparency is a leaky abstraction. Anticipate the failure modes:

- Requests/responses can be lost; build retries with timeouts
- Timeouts are ambiguous — you don't know if the call ran
- Make every retry-able operation idempotent (use unique request IDs)
- Latency is wildly variable — don't assume sub-ms response
- Datatypes don't always translate across languages (e.g., JS numbers > 2^53)

### 5. Use Message Brokers When You Need Decoupling, Buffering, or Fan-out

Choose async messaging over sync RPC when:

- Recipient may be down or overloaded (broker buffers)
- Multiple consumers should see the same event (pub/sub)
- Sender shouldn't know recipient identity (avoid service discovery in sender)
- Work is genuinely asynchronous (sender doesn't need a response)

### 6. Use Durable Execution for Multi-Step Transactional Workflows

Choose Temporal/Restate/Cadence when:

- Workflow spans multiple services and must complete exactly once
- You can't wrap the steps in a single DB transaction
- Failure mid-flight (after partial side effects) is unacceptable
- You need automatic retry with checkpointed progress

### 7. Make Workflow Code Deterministic

Durable execution replays history. Nondeterminism corrupts replay.

- Don't call `random()`, `now()`, or read environment in workflow code
- Use the framework's deterministic substitutes
- Don't reorder activity calls in an existing workflow — deploy as a new version
- External services called from activities must accept idempotency keys

### 8. Versioning Strategy Must Be Explicit for REST APIs

There is no consensus, but pick one and stick to it:

- URL path version (`/v2/users`)
- HTTP `Accept` header version
- Per-client version stored server-side, toggled administratively (Stripe model)

### 9. Use a Schema Registry With Message Brokers

Brokers don't enforce data models. Bolt on schema management.

- Confluent Schema Registry, AsyncAPI, etc.
- Validate compatibility (forward + backward) on publish
- Reject incompatible schema evolutions at registration time

## Guidelines

- Prefer software load balancers (NGINX, HAProxy) for simple deployments
- Use service mesh (Istio, Linkerd) when running on Kubernetes with high service churn
- Use service discovery (etcd, ZooKeeper) over DNS when service instances change frequently
- Default to JSON over the wire for external APIs; Protobuf/Avro for internal high-throughput
- For event sourcing, configure brokers to retain messages indefinitely

## Exceptions

- **Single-language internal RPC**: Avro RPC or gRPC fine; you control all clients
- **Lockstep deploy possible (small team, single service)**: Compat rules can relax
- **Read-mostly archival data**: One-time rewrite into latest schema beats forever-evolution

## Quick Reference

| Decision | Pick | Avoid |
|----------|------|-------|
| Public API | REST + OpenAPI | Custom RPC |
| Internal microservice RPC | gRPC + Protobuf | SOAP, CORBA |
| Async work / buffering | Kafka / RabbitMQ | Sync RPC w/ retries |
| Multi-step transactional | Temporal / Restate | Hand-rolled saga |
| Stateful concurrent entities | Akka / Orleans | Threads + locks |
| Service discovery (dynamic) | etcd / ZooKeeper / mesh | Hardcoded IPs |
| Service discovery (stable) | DNS / hardware LB | Custom registry |
