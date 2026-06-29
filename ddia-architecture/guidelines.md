# DDIA Architecture Guidelines

Quick reference for finding the right knowledge file for your architecture task.

**How to use**: Find your situation below, then load ONLY the listed files. Each category has `knowledge.md` (concepts), `rules.md` (do's and don'ts), and `examples.md` (good/bad concrete cases).

---

## Workflows

For multi-step decisions, prefer a workflow — it sequences the relevant references for you.

| Task | Workflow |
|------|----------|
| Decide cloud vs self-hosted deployment | `workflows/choosing-cloud-vs-self-hosted.md` |
| Define performance SLOs (latency, throughput, error budget) | `workflows/defining-performance-slos.md` |
| Assess reliability requirements & identify SPOFs | `workflows/assessing-reliability-requirements.md` |

---

## By Task

### Architecture Decisions

| What you're doing | Load these files |
|-------------------|------------------|
| Choosing OLTP vs OLAP storage | `references/operational-vs-analytical/knowledge.md`, `references/operational-vs-analytical/rules.md` |
| Designing the OLTP→warehouse/lake pipeline | `references/operational-vs-analytical/knowledge.md`, `references/operational-vs-analytical/examples.md` |
| Deciding cloud vs on-prem / managed vs self-hosted | `workflows/choosing-cloud-vs-self-hosted.md` + `references/cloud-vs-self-hosted/rules.md` |
| Evaluating a SaaS / managed-service procurement | `workflows/choosing-cloud-vs-self-hosted.md` + `references/cloud-vs-self-hosted/rules.md`, `references/cloud-vs-self-hosted/examples.md` |
| Choosing distributed (microservices, multi-node) vs single-node | `references/distributed-systems-intro/knowledge.md`, `references/distributed-systems-intro/rules.md` |
| Splitting a monolith into services | `references/distributed-systems-intro/rules.md`, `references/distributed-systems-intro/examples.md` |

### Capacity & Performance Planning

| What you're doing | Load these files |
|-------------------|------------------|
| Defining performance SLOs / SLAs | `workflows/defining-performance-slos.md` + `references/performance/rules.md` |
| Choosing response-time percentiles to track | `references/performance/knowledge.md`, `references/performance/examples.md` |
| Choosing a scaling strategy (scale-up vs scale-out) | `references/scalability/knowledge.md`, `references/scalability/rules.md` |
| Picking load parameters / capacity model | `references/scalability/knowledge.md`, `references/scalability/examples.md` |
| Diagnosing tail-latency problems | `references/performance/knowledge.md`, `references/performance/rules.md` |

### Operational Design

| What you're doing | Load these files |
|-------------------|------------------|
| Designing for reliability / fault tolerance | `workflows/assessing-reliability-requirements.md` + `references/reliability/rules.md` |
| Defining a fault model | `workflows/assessing-reliability-requirements.md` + `references/reliability/rules.md`, `references/reliability/examples.md` |
| Designing for operability | `references/maintainability/knowledge.md`, `references/maintainability/rules.md` |
| Reviewing for simplicity / evolvability | `references/maintainability/rules.md`, `references/maintainability/examples.md` |
| Modernizing / replacing a legacy system | `references/maintainability/knowledge.md`, `references/maintainability/examples.md` |

---

## By Problem/Symptom

| If you notice... | Load these files |
|------------------|------------------|
| "How do I choose between OLTP and OLAP?" | `references/operational-vs-analytical/knowledge.md` |
| "Should we go cloud or on-prem?" | `references/cloud-vs-self-hosted/knowledge.md`, `references/cloud-vs-self-hosted/rules.md` |
| "Latency is unpredictable / spiky" | `references/performance/knowledge.md`, `references/reliability/knowledge.md` |
| "p99 looks fine but users complain" | `references/performance/rules.md`, `references/performance/examples.md` |
| "System keeps breaking on deploy" | `references/reliability/knowledge.md`, `references/maintainability/rules.md` |
| "Outages caused by human error" | `references/reliability/rules.md`, `references/maintainability/rules.md` |
| "We need to handle 10x more load" | `references/scalability/knowledge.md`, `references/scalability/rules.md` |
| "Operations team complains about toil" | `references/maintainability/knowledge.md`, `references/maintainability/rules.md` |
| "Microservices vs monolith?" | `references/distributed-systems-intro/knowledge.md`, `references/distributed-systems-intro/rules.md` |
| "Cross-service calls are flaky / slow" | `references/distributed-systems-intro/knowledge.md`, `references/distributed-systems-intro/examples.md` |
| "Analysts blocked by production load" | `references/operational-vs-analytical/knowledge.md`, `references/operational-vs-analytical/examples.md` |
| "Vendor lock-in concerns" | `references/cloud-vs-self-hosted/rules.md`, `references/cloud-vs-self-hosted/examples.md` |

---

## By Topic

### Operational vs Analytical Systems
- **Knowledge**: `references/operational-vs-analytical/knowledge.md`
- **Rules**: `references/operational-vs-analytical/rules.md`
- **Examples**: `references/operational-vs-analytical/examples.md`

### Cloud vs Self-Hosted
- **Knowledge**: `references/cloud-vs-self-hosted/knowledge.md`
- **Rules**: `references/cloud-vs-self-hosted/rules.md`
- **Examples**: `references/cloud-vs-self-hosted/examples.md`

### Distributed Systems Intro
- **Knowledge**: `references/distributed-systems-intro/knowledge.md`
- **Rules**: `references/distributed-systems-intro/rules.md`
- **Examples**: `references/distributed-systems-intro/examples.md`

### Performance
- **Knowledge**: `references/performance/knowledge.md`
- **Rules**: `references/performance/rules.md`
- **Examples**: `references/performance/examples.md`

### Reliability
- **Knowledge**: `references/reliability/knowledge.md`
- **Rules**: `references/reliability/rules.md`
- **Examples**: `references/reliability/examples.md`

### Scalability
- **Knowledge**: `references/scalability/knowledge.md`
- **Rules**: `references/scalability/rules.md`
- **Examples**: `references/scalability/examples.md`

### Maintainability
- **Knowledge**: `references/maintainability/knowledge.md`
- **Rules**: `references/maintainability/rules.md`
- **Examples**: `references/maintainability/examples.md`

---

## Decision Tree

```
What are you doing?
│
├─► Picking storage architecture
│   ├─► Need point queries on latest state → operational-vs-analytical/knowledge.md (OLTP)
│   ├─► Need aggregates over history → operational-vs-analytical/knowledge.md (OLAP)
│   └─► Both → operational-vs-analytical/examples.md (warehouse/lakehouse pipelines)
│
├─► Picking deployment model
│   ├─► Is this core competency? → cloud-vs-self-hosted/rules.md
│   ├─► Need elastic scale / fast provisioning → cloud-vs-self-hosted/knowledge.md (cloud-native)
│   └─► Compliance / cost / lock-in concerns → cloud-vs-self-hosted/examples.md
│
├─► Deciding to distribute
│   ├─► Single machine sufficient? → distributed-systems-intro/rules.md (prefer single-node)
│   ├─► Need fault tolerance / geographic latency → distributed-systems-intro/knowledge.md
│   └─► Splitting a monolith → distributed-systems-intro/examples.md
│
├─► Setting nonfunctional targets
│   ├─► Performance / SLOs → performance/knowledge.md, performance/rules.md
│   ├─► Reliability / fault tolerance → reliability/knowledge.md, reliability/rules.md
│   ├─► Capacity / scale → scalability/knowledge.md, scalability/rules.md
│   └─► Long-term operability → maintainability/knowledge.md, maintainability/rules.md
│
└─► Diagnosing a problem
    ├─► Tail latency → performance/rules.md
    ├─► Outages / faults → reliability/examples.md
    ├─► Load growth → scalability/examples.md
    └─► Operational toil → maintainability/examples.md
```

---

## File Index

Complete list of all reference files (21 total):

### Operational vs Analytical
| File | Purpose |
|------|---------|
| `references/operational-vs-analytical/knowledge.md` | OLTP vs OLAP definitions, warehouses, lakes, lakehouses, ETL/ELT, system of record vs derived data |
| `references/operational-vs-analytical/rules.md` | Rules for separating analytical from operational workloads |
| `references/operational-vs-analytical/examples.md` | Concrete OLTP/OLAP architectures, good/bad pipelines |

### Cloud vs Self-Hosted
| File | Purpose |
|------|---------|
| `references/cloud-vs-self-hosted/knowledge.md` | Deployment spectrum, IaaS/PaaS/SaaS, cloud-native vs on-prem trade-offs |
| `references/cloud-vs-self-hosted/rules.md` | Build-vs-buy decision rules, when to use managed services |
| `references/cloud-vs-self-hosted/examples.md` | Cloud-native vs on-prem architecture examples |

### Distributed Systems Intro
| File | Purpose |
|------|---------|
| `references/distributed-systems-intro/knowledge.md` | Distributed system definition, partial failure, microservices/serverless concepts |
| `references/distributed-systems-intro/rules.md` | When to distribute vs stay single-node; cross-service call rules |
| `references/distributed-systems-intro/examples.md` | Monolith/microservice/serverless examples |

### Performance
| File | Purpose |
|------|---------|
| `references/performance/knowledge.md` | Response time, throughput, latency, percentiles, tail latency |
| `references/performance/rules.md` | Rules for measuring and reporting performance; percentile choice |
| `references/performance/examples.md` | Good/bad performance metrics and SLO formulations |

### Reliability
| File | Purpose |
|------|---------|
| `references/reliability/knowledge.md` | Fault vs failure, fault tolerance, hardware/software/human faults |
| `references/reliability/rules.md` | Rules for fault models and reliability engineering |
| `references/reliability/examples.md` | Reliability failure modes and mitigations |

### Scalability
| File | Purpose |
|------|---------|
| `references/scalability/knowledge.md` | Scalability, load parameters, scale-up vs scale-out, shared-nothing |
| `references/scalability/rules.md` | Rules for capacity planning and scaling strategy |
| `references/scalability/examples.md` | Concrete load-parameter and scaling examples |

### Maintainability
| File | Purpose |
|------|---------|
| `references/maintainability/knowledge.md` | Operability, simplicity, evolvability, legacy systems |
| `references/maintainability/rules.md` | Rules for operable, simple, evolvable systems |
| `references/maintainability/examples.md` | Maintainability good/bad examples |

---

## Common Combinations

Frequently used together:

| Scenario | Files to load |
|----------|---------------|
| Greenfield architecture review | `operational-vs-analytical/knowledge.md` + `cloud-vs-self-hosted/knowledge.md` + `distributed-systems-intro/knowledge.md` |
| Setting all nonfunctional targets | `performance/knowledge.md` + `reliability/knowledge.md` + `scalability/knowledge.md` + `maintainability/knowledge.md` |
| Capacity / SLO definition | `performance/rules.md` + `scalability/rules.md` |
| Reliability + ops review | `reliability/rules.md` + `maintainability/rules.md` |
| Build vs buy proposal | `cloud-vs-self-hosted/rules.md` + `cloud-vs-self-hosted/examples.md` |
