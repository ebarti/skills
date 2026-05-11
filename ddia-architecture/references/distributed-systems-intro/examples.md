# Distributed vs Single-Node Systems Examples

Concrete systems, scenarios, and case studies illustrating distributed-systems trade-offs, drawn from the chapter.

## Systems Mentioned

### Single-Node Databases (Re-enabling Single-Machine Designs)

| System | Notes |
|--------|-------|
| DuckDB | Embedded analytical database |
| SQLite | Embedded relational database |
| KuzuDB | Embedded graph database |

These engines, combined with growing CPU/memory/disk capacity and reliability, mean many workloads no longer need a cluster.

### Microservices Infrastructure

| System | Role |
|--------|------|
| Kubernetes | Orchestration framework for deploying and managing services |
| OpenAPI | API description standard for HTTP/REST APIs |
| gRPC | RPC framework with schema-based API descriptions |

### Observability and Tracing

| Tool | Purpose |
|------|---------|
| OpenTelemetry | Tracing standard and instrumentation |
| Zipkin | Distributed tracing system |
| Jaeger | Distributed tracing system |

These let you see which client called which server for which operation and how long each call took.

### Microservice Example: Amazon S3

S3 is cited as a service with one well-defined purpose: file storage. Each service in a microservices architecture exposes an API and is owned by one team.

### "Serverless" Beyond FaaS

| System | Why "serverless" |
|--------|------------------|
| BigQuery | Autoscaling, usage-billed analytics |
| Various hosted Kafka offerings | Autoscaling, pay-by-usage messaging |

The label has expanded beyond FaaS to mean "autoscaling and usage-billed."

## Scenarios from the Chapter

### Scenario: Inherent Distribution

A messaging or collaboration application where two users on separate devices communicate. The system *must* be distributed because the devices are physically separate and connected only by a network. There is no single-node option.

### Scenario: Cross-Service Request

Data lives in one cloud service and is processed in another. Transferring the data over the network between services is unavoidable. Cloud-native and microservice architectures inherit distribution from this pattern.

### Scenario: Fault Tolerance via Redundancy

The application must survive the loss of a machine, several machines, the network, or an entire datacenter. Multiple machines provide redundancy: when one fails, another takes over.

### Scenario: Geographic Latency

Users are spread around the world. Servers are deployed in multiple regions so each user is served from a nearby region, avoiding round-trip delays of packets crossing the planet.

### Scenario: Elastic Cloud Workload

Application is busy at certain times and idle at others. A cloud deployment scales up during peaks and down during troughs, billed only for active resources. A single machine would have to be provisioned for peak load even when mostly idle.

### Scenario: Specialized Hardware Mix

- **Object store**: machines with many disks but few CPUs
- **Data analysis system**: machines with lots of CPU and memory, no disks
- **ML training**: machines with GPUs (much more efficient than CPUs for deep neural networks)

A distributed system lets each part run on hardware tuned to its workload.

### Scenario: Data Residency Compliance

A service has users in multiple countries with data residency laws (some apply only to medical or financial data, others are broader). Data about residents of each jurisdiction must be stored and processed within that country, forcing distribution across regions.

### Scenario: Sustainable Scheduling

Workloads with flexible timing run when and where renewable electricity is plentiful, avoiding peak grid strain and cutting carbon emissions.

## Failure Scenarios

### Network Timeout with Unknown Outcome

A request crosses the network and never returns a response. The caller does not know whether:
- The receiver never got the request, or
- The receiver processed it but the response was lost.

Naive retry may double-process the operation. Solution: idempotent operations so retries are safe, plus explicit timeouts.

### Slow System, Unknown Cause

A distributed system responds slowly. Without observability tooling, finding the offending hop is extremely hard. Tracing tools (OpenTelemetry, Zipkin, Jaeger) reveal which client called which server, for which operation, and how long each call took.

### Cross-Service Data Inconsistency

Each microservice has its own database. When a transaction must touch multiple services' data, maintaining consistency becomes the application's problem. Distributed transactions exist but are rarely used in microservices because they undermine service independence, and many databases do not support them.

### More Nodes Are Slower

In some cases, a simple single-threaded program on one computer significantly outperforms a cluster with over 100 CPU cores. Moving large volumes of data over the network costs more than co-locating compute with data.

### Microservice API Evolution Breaking Clients

A developer adds or removes a field in a service API to meet new business needs. Clients that depended on the old shape break. The breakage is often discovered late, in staging or production. OpenAPI and gRPC schemas help catch this earlier.

## Microservice Trade-Off Case

Decomposing an application into services brings:

**Advantages**:
- Each service updates independently — less cross-team coordination
- Each service gets the hardware resources it needs
- Implementation hidden behind an API — owners can change internals freely
- Per-service databases prevent schema coupling and noisy-neighbor query effects

**Disadvantages**:
- Testing requires running every dependent service
- Each service needs deployment, scaling, logging, monitoring, alerting infra
- API evolution is risky and discovered late
- Microservices in a small company are usually unnecessary overhead

Net guidance: microservices are a people solution for large companies; small companies should prefer the simplest implementation.

## Cloud vs Supercomputing Contrast

| Aspect | Supercomputing (HPC) | Cloud |
|--------|---------------------|-------|
| Workload | Scientific batch (weather, climate, molecular dynamics, PDE solving) | Online services, business data |
| Failure handling | Stop cluster, repair, restart from checkpoint | Service must stay available |
| Communication | Shared memory, RDMA | IP / Ethernet |
| Network topology | Multidimensional mesh, torus | Clos topology (high bisection bandwidth) |
| Trust model | Trusted users | Mutually untrusting tenants — VMs, encryption, auth |
| Geography | Co-located nodes | Multi-region |

## Law and Society Examples

### GDPR Right to Be Forgotten vs Immutable Logs

GDPR grants individuals the right to have their data erased. Many data systems use append-only logs as a foundational immutable construct. Tension: how do you delete data in the middle of an immutable file? How do you remove data from derived datasets such as ML training data? These create new engineering challenges with no settled answers.

### Compliance Standards in Practice

- **PCI DSS**: required for payment processors; frequent independent audits
- **SOC 2 Type 2**: increasingly required of software vendors; third-party audits

### Safety Risk from Stored Data

Data revealing criminalized behavior creates real safety risks for users — for example, in jurisdictions that criminalize homosexuality, or US states criminalizing seeking an abortion. A simple log of IP addresses can reveal approximate location over time and indicate visits to sensitive places (e.g., an abortion clinic). Sometimes the right answer is not to store the data at all.

### Data Minimization vs "Big Data"

Data minimization (Datensparsamkeit) — collect only what you need, only for a stated purpose, only for as long as needed — runs counter to the "store everything in case it's useful later" philosophy of big data. GDPR codifies the minimization stance.
