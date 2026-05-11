# Distributed vs Single-Node Systems Knowledge

Core concepts for choosing between distributed systems, microservices, serverless, and single-node architectures.

## Overview

A distributed system spans multiple machines communicating over a network. While distribution unlocks fault tolerance, scalability, geographic latency reduction, and elastic resource use, it introduces partial failures, network delays, and consistency challenges that single-node systems avoid. Modern hardware and embedded databases (DuckDB, SQLite, KuzuDB) make single-node viable for many workloads.

## Key Concepts

### Distributed System

**Definition**: A system involving several machines (nodes) communicating via a network.

A node is any process participating in the distributed system. Distribution may be inherent (multi-user apps, cloud-to-cloud calls) or chosen (for fault tolerance, scalability, latency, elasticity, specialized hardware, legal compliance, sustainability).

**Key points**:
- Distribution is sometimes unavoidable (multi-device apps, cross-service calls)
- Other times it is a deliberate trade-off vs single-node simplicity
- Cloud-native and microservice systems are inherently distributed

### Partial Failure

**Definition**: A condition where some nodes or network links fail while others continue working, leaving the system in an indeterminate state.

Every cross-network request must handle the possibility that the network drops, the service crashes, or the request times out without a response. The caller cannot tell whether the receiver processed the request, so naive retries may not be safe.

**Key points**:
- Network calls are vastly slower than in-process function calls
- Retries are not always safe (idempotency required)
- Diagnosing a slow distributed system requires *observability* (metrics, tracing)

### Microservices Architecture

**Definition**: An architectural style decomposing a complex application into small, independently deployable services, each with one well-defined purpose, owned by one team, and communicating over network APIs (typically HTTP).

Refinement of service-oriented architecture (SOA). Each service usually owns its own database; sharing databases couples services and turns the schema into a public API.

**Key points**:
- Primarily a *people* solution: lets teams ship independently
- Each service updates, scales, and is monitored on its own
- API evolution requires care (OpenAPI, gRPC help)
- Adds operational complexity (deployment, monitoring, orchestration via Kubernetes)

### Serverless / Function as a Service (FaaS)

**Definition**: A deployment model where the cloud vendor automatically allocates and frees hardware based on incoming requests; you pay only for execution time.

Replaces capacity planning with metered billing for code execution. The term is misleading: code still runs on servers, but each invocation may run on a different one.

**Key points**:
- No explicit instance start/stop decisions
- Time limits on execution and restricted runtimes
- Cold-start latency on first invocation
- Term now also applied to autoscaling, usage-billed services (BigQuery, hosted Kafka)

### Supercomputing / High-Performance Computing (HPC)

**Definition**: Large-scale computing optimized for computationally intensive scientific batch jobs (weather, climate, molecular dynamics, PDE solving) rather than always-on user-facing services.

A different paradigm from cloud computing, with different fault-tolerance, networking, and trust assumptions.

**Key points**:
- Large batch jobs with periodic checkpoints to disk
- On node failure: stop cluster, repair, restart from checkpoint
- Specialized networks (mesh, torus topologies, RDMA, shared memory)
- Assumes trusted users; co-located nodes; different from cloud's mutually-untrusting tenants

## Why Distribution Adds Complexity

| Source of Complexity | Consequence |
|----------------------|-------------|
| Network may drop or delay | Requests may time out with unknown outcome |
| Network calls are slow | Cross-service calls dwarf in-process calls |
| No global clock | Hard to order events across nodes |
| Per-service databases | Cross-service consistency becomes app's problem |
| Many moving parts | Troubleshooting requires observability tooling |
| Distributed transactions rare in microservices | Run counter to service independence |

## Terminology

| Term | Definition |
|------|------------|
| Node | A process participating in a distributed system |
| Partial failure | Some nodes/links failing while others work |
| Observability | Collecting and querying execution data to diagnose systems |
| Tracing | Tracking which client called which server, and how long it took |
| SOA | Service-oriented architecture (predecessor to microservices) |
| FaaS | Function as a service (serverless) |
| HPC | High-performance computing (supercomputing) |
| RDMA | Remote Direct Memory Access (used in HPC networks) |
| Bisection bandwidth | Measure of overall network performance, common in cloud Clos topologies |
| Data residency | Legal requirement that data stay within a jurisdiction |
| Right to be forgotten | GDPR right for individuals to have their data erased |
| Data minimization (Datensparsamkeit) | Principle of collecting only data you need |

## Data Systems, Law, and Society

Data systems are influenced by both technical goals and the human/legal context they operate in. Key regulatory and societal forces:

- **GDPR** (EU, 2018): Personal data control, right to erasure, purpose limitation
- **CCPA** (California): Similar privacy rights
- **EU AI Act**: Restrictions on use of personal data in AI
- **Data residency laws**: Some jurisdictions require data on residents to be stored/processed locally
- **PCI DSS**: Mandatory for payment processors; third-party audited
- **SOC 2**: Increasingly required of software vendors; third-party audited

GDPR deliberately does not mandate technologies; it sets high-level principles open to interpretation. Tension exists between erasure rights and immutable architectures (append-only logs, derived datasets, ML training data).

**Data minimization principle**: Stored data has costs beyond storage bills (liability, reputational damage, legal fines, user safety risks if data reveals criminalized behavior). Sometimes it is reasonable not to store data at all.

## How It Relates To

- **Reliability and Fault Tolerance**: Distribution is a primary tool for redundancy
- **Scalability**: Distribution enables horizontal scale-out beyond a single machine
- **Cloud vs Self-Hosted**: Cloud encourages distributed/microservice architectures
- **Storage Engines**: Single-node databases (DuckDB, SQLite) re-enable single-node designs

## Common Misconceptions

- **Myth**: More nodes always mean more performance.
  **Reality**: A single-threaded program on one machine sometimes outperforms a 100-CPU cluster; moving compute to data beats moving data to compute.

- **Myth**: Microservices are a technical scaling strategy.
  **Reality**: Microservices are mainly a *people* solution for letting teams move independently; small teams rarely benefit.

- **Myth**: "Serverless" means no servers.
  **Reality**: Code still runs on servers; the vendor just manages allocation and bills by execution time.

- **Myth**: Cloud and HPC are the same kind of large-scale computing.
  **Reality**: Different priorities (batch vs always-on), different networks, different trust models, different fault-handling strategies.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Distributed system | Multiple nodes communicating over a network |
| Partial failure | Some parts fail while others keep running |
| Microservices | Independent, team-owned services with private databases |
| Serverless / FaaS | Vendor-managed execution billed by runtime |
| HPC | Batch-oriented scientific computing with checkpoint/restart |
| Data minimization | Store only what you need; deletion is also a strategy |
