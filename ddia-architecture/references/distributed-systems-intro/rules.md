# Distributed vs Single-Node Systems Rules

Decision guidance for choosing between single-node, distributed, microservice, and serverless architectures, including legal and societal constraints.

## Core Rules

### 1. Scale Up Before You Scale Out

Performing a task on a single machine is often simpler and cheaper than setting up a distributed system. Modern CPUs, memory, and disks have grown larger, faster, and more reliable; many workloads can now run on a single node with engines like DuckDB, SQLite, or KuzuDB.

- Default to a single node until a concrete need forces distribution
- Remember: a single-threaded program can outperform a 100+ CPU cluster in some workloads
- Bring computation to the data rather than data to the computation when possible

### 2. Distribute Only When You Have a Concrete Reason

Choose distribution because of a specific need, not by default. Valid reasons include:

- **Inherent distribution**: multi-user apps, multi-device interaction
- **Cross-service requests**: data lives in one service, processed in another
- **Fault tolerance / high availability**: redundancy across machines, racks, datacenters
- **Scalability**: workload exceeds a single machine's capacity
- **Latency**: serve users from geographically nearby regions
- **Elasticity**: bursty workloads benefit from on-demand provisioning
- **Specialized hardware**: mix CPU-heavy, disk-heavy, GPU-heavy nodes
- **Legal compliance**: data residency requires per-jurisdiction storage
- **Sustainability**: shift work to where/when renewable energy is available

If none apply, prefer single node.

### 3. Treat Every Network Call as Potentially Failing

Network calls can drop, time out, or return unknown outcomes. You cannot tell whether the receiver processed your request.

- Design idempotent operations so retries are safe
- Set explicit timeouts; do not assume responses arrive
- Invest in observability (metrics + tracing via OpenTelemetry, Zipkin, Jaeger)
- Treat cross-service calls as orders of magnitude slower than in-process calls

### 4. Use Microservices for People Problems, Not Just Technical Ones

Microservices are primarily a way for many teams to ship independently. They impose real overhead on small organizations.

- Small company / few teams: prefer the simplest possible monolith
- Large company / many teams: microservices reduce coordination cost
- Each service: one purpose, one owner team, one (or few) databases of its own
- Never share a database across services (turns the schema into an API)

### 5. Plan for API Evolution from Day One

Adding or removing fields can break clients. Failures are often discovered late, in staging or production.

- Use API description standards (OpenAPI, gRPC) to manage client/server contracts
- Version APIs explicitly; never silently change semantics of existing fields
- Test integration against the actual schema, not assumptions

### 6. Match Serverless to Bursty, Stateless, Event-Driven Work

Serverless / FaaS shines for variable load and short-running tasks; it struggles with long-running, latency-sensitive, or stateful work.

- Good fit: irregular traffic, glue code, event handlers, on-demand jobs
- Poor fit: long-running computations beyond vendor time limits
- Poor fit: latency-critical paths sensitive to cold starts
- Watch out: each invocation may run on a different server (no local state)

### 7. Distinguish Cloud Computing from Supercomputing

Do not borrow HPC techniques wholesale for cloud user-facing services, or vice versa.

- HPC: batch jobs, checkpoint/restart, trusted users, specialized networks
- Cloud: always-on services, mutual distrust, IP/Ethernet, geographic spread
- Stopping the whole cluster to repair a node is fine for HPC, not for online services
- Large-scale analytics may share some HPC characteristics; user-facing services usually do not

### 8. Comply with Data Residency and Privacy Law by Design

Some data must stay in specific jurisdictions; some must be deletable on request; some must not be retained beyond its stated purpose.

- Identify applicable regimes early (GDPR, CCPA, EU AI Act, sector-specific rules)
- Plan for the right to erasure even with append-only logs and derived datasets
- For payments: PCI DSS compliance is mandatory; expect third-party audits
- For SaaS vendors: SOC 2 Type 2 is increasingly demanded by buyers

### 9. Apply Data Minimization (Datensparsamkeit)

Storage has hidden costs beyond the bill: legal liability, reputational damage if breached, and real user safety risks when data reveals criminalized behavior.

- Collect data only for a specified, explicit purpose
- Do not repurpose collected data for new uses
- Do not retain data longer than needed
- For sensitive categories (location, identity, behavior), default to *not* storing

## Guidelines

- Use Kubernetes (or similar orchestration) when you have many services to deploy and monitor; it is overkill for a single-service deployment
- When a service is slow, instrument with tracing before guessing where the problem is
- Distributed transactions exist (Chapter 8) but are rarely used in microservices because they undermine service independence
- "Serverless" branding is now used for autoscaling managed services (BigQuery, hosted Kafka), not just FaaS — read the fine print
- Treat ethics and legal awareness as foundational skills, comparable to distributed-systems literacy

## Exceptions

- **Inherent distribution**: when users are on separate devices, single-node is not an option
- **Multi-region latency**: even small workloads may need geographic distribution
- **Regulated jurisdictions**: legal requirements may force distribution regardless of scale
- **HPC-style analytics**: stop-the-world checkpoint/restart is acceptable for batch workloads
- **Small teams adopting microservices**: only if you genuinely have independent deployment cadence per service

## Quick Reference

| Decision | Rule |
|----------|------|
| Should I distribute? | Only if a concrete reason from rule 2 applies |
| Should I use microservices? | Only if you have multiple teams that need to ship independently |
| Should I use serverless? | Only for bursty, stateless, short-running work |
| Should I share a database between services? | No |
| Should I retry a failed request? | Only if the operation is idempotent |
| Where should I store user data? | In jurisdictions that satisfy residency law |
| Should I store this data at all? | Only if its value exceeds liability + safety risks |
