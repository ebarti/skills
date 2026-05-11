# Modes of Dataflow Knowledge

Core concepts for how encoded data flows between processes that don't share memory.

## Overview

Whenever two processes exchange data, one encodes it and another decodes it. The three primary modes of dataflow are databases (writer-to-future-reader), services (synchronous request/response), and asynchronous messaging (broker-mediated events). Each has different compatibility requirements and operational trade-offs.

## Key Concepts

### Dataflow Through Databases

**Definition**: The writing process encodes data; the reading process decodes it, possibly years later.

**Key points**:
- Backward compatibility required (future self must read past writes)
- Forward compatibility required when newer code writes data later read by older instances (rolling upgrades)
- *Data outlives code*: schema evolution lets storage hold many historical encodings
- LSM compaction and `null`-default columns are deferred migrations
- Archival snapshots are typically rewritten in the latest schema (Avro container files, Parquet)

### Dataflow Through Services (REST and RPC)

**Definition**: Clients send requests over the network to servers exposing an application-specific API.

**Key points**:
- Service = API exposed by server; restricts inputs/outputs unlike a database query language
- Goal of microservices: independent deployability of teams; assume version skew
- Backward compat on requests, forward compat on responses (servers usually upgrade first)
- Cross-organization APIs may need indefinite compatibility (provider can't force client upgrade)

### REST

**Definition**: Service design philosophy built on HTTP principles (URLs as resources, content negotiation, caching, auth via HTTP features).

API following REST principles is "RESTful". Typically uses JSON. IDL: OpenAPI/Swagger (YAML/JSON).

### RPC (Remote Procedure Call)

**Definition**: Model that makes a remote network call look like a local function call (location transparency).

The abstraction is fundamentally flawed — networks are unpredictable. Modern RPC frameworks (gRPC, Avro RPC) embrace the difference rather than hide it. Predecessors: EJB, RMI, DCOM, CORBA, SOAP/WS-*.

### Service Mesh

**Definition**: Sidecar/in-process load balancer deployed at both client and server, combining load balancing + service discovery.

Examples: Istio, Linkerd. Centralizes TLS, observability, and traffic policy.

### Service Discovery

**Definition**: How a client finds the network address of a service instance.

Approaches: hardcoded IP, DNS, software/hardware load balancer, registry (etcd, ZooKeeper), service mesh.

### Durable Execution / Workflow Engine

**Definition**: A framework that orchestrates a graph of *tasks* (a *workflow*) with checkpointed state, providing exactly-once semantics across failures.

Examples: Temporal, Restate, Cadence. Logs all RPCs and state changes to a write-ahead log; on retry, skips already-completed steps and replays prior results. Tasks are also called *activities* or *durable functions*.

### Message Broker

**Definition**: Intermediary that stores messages temporarily, decoupling sender from recipient.

Examples: Kafka, RabbitMQ, ActiveMQ, NATS, Redpanda, SQS, Kinesis, Pub/Sub. Two patterns:
- **Queue**: one consumer of many receives each message
- **Topic (pub/sub)**: every subscriber receives each message

### Distributed Actor Framework

**Definition**: Concurrency model where logic is encapsulated in isolated *actors* that communicate by asynchronous messages; the framework transparently routes messages across nodes.

Examples: Akka, Erlang/OTP, Microsoft Orleans. Combines a message broker with an actor programming model. Location transparency works better than RPC because the model assumes message loss anyway.

## Terminology

| Term | Definition |
|------|------------|
| Service | Application-specific API exposed by a server |
| Web service | Service using HTTP as transport |
| IDL | Interface Definition Language (OpenAPI, Protocol Buffers) |
| Workflow | Graph of tasks orchestrated by an engine |
| Task / activity | Single step in a workflow |
| Orchestrator | Schedules workflow tasks |
| Executor | Runs workflow tasks |
| Queue | Broker pattern: one consumer wins each message |
| Topic | Broker pattern: every subscriber receives each message |
| Schema registry | Stores valid message schemas + checks compatibility |
| Idempotence | Safe to retry — same effect regardless of repeated execution |

## How It Relates To

- **Encoding formats**: Each dataflow mode inherits compat properties of its encoding (Protobuf, Avro, JSON)
- **Rolling upgrades**: Drive the need for forward+backward compatibility
- **Distributed systems**: Network failure modes (Ch. 9) are why RPC's location-transparency abstraction leaks

## Common Misconceptions

- **Myth**: A remote call is just a slower local call.
  **Reality**: Networks fail, time out, retry-duplicate, and serialize references differently. The mismatch is fundamental.

- **Myth**: Async messaging is always more complex than REST.
  **Reality**: Brokers buffer load, decouple deployment, and remove service discovery from senders — often simpler at scale.

- **Myth**: Durable execution makes any code exactly-once for free.
  **Reality**: External APIs must still be idempotent; code must be deterministic; reordering calls breaks replays.

## Quick Reference

| Mode | Sender waits? | Compat needed | Typical use |
|------|--------------|---------------|-------------|
| Database | N/A | Backward + forward | Persistent state |
| REST/RPC | Yes (sync) | Backward on req, forward on resp | Internal/external APIs |
| Workflow engine | Engine manages | Versioned workflow defs | Multi-step transactional flows |
| Message broker | No (async) | Both directions | Decoupled, buffered events |
| Actor framework | No (async) | Both directions | Stateful concurrent entities |
