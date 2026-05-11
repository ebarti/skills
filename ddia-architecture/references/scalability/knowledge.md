# Scalability Knowledge

Core concepts for reasoning about a system's ability to cope with increased load.

## Overview

Scalability is a system's ability to cope with increased load — more users, more data, more requests. It is not a binary property: you cannot say "X is scalable" or "Y doesn't scale" in the abstract. Discussing scalability means asking how the system behaves as load grows along specific dimensions, and what options exist to add resources.

## Key Concepts

### Scalability

**Definition**: A system's ability to cope with increased load while keeping performance within SLA targets and minimizing cost.

**Key points**:
- Not one-dimensional — always relative to a specific growth pattern
- Premature scaling investment can lock you into inflexible designs
- Real architecture is highly application-specific; there is no "magic scaling sauce"

### Load

**Definition**: A quantitative description of demand on the system, expressed as a small set of numbers called *load parameters*.

The right choice of load parameters depends on the system. Common parameters:
- Throughput (requests/sec, GB/day, checkouts/hour)
- Peak concurrent users
- Read/write ratio in a database
- Cache hit rate
- Number of items per user (e.g. followers)

### Linear Scalability

**Definition**: Doubling resources lets you handle twice the load at the same performance.

Considered a good outcome. Sub-linear (cost grows faster than load) is more common; super-linear (economies of scale) is rare.

### Vertical Scaling (Scale Up)

**Definition**: Move the workload to a more powerful machine — more CPU cores, more RAM, more disk.

Realized via shared-memory architecture. Cost grows faster than linearly and contention bottlenecks limit gains.

### Horizontal Scaling (Scale Out)

**Definition**: Distribute the workload across many independent machines, coordinating over the network.

Realized via shared-nothing architecture. Has the potential for linear scaling and elasticity.

### Shared-Memory Architecture

**Definition**: A single machine where multiple threads or processes share the same RAM.

- The vertical-scaling endpoint
- High-end machines cost disproportionately more than mid-range ones
- Hard ceiling from a single machine's hardware limits

### Shared-Disk Architecture

**Definition**: Multiple machines with independent CPUs and RAM, sharing storage via NAS or SAN over a fast network.

- Traditionally used for on-premises data warehousing
- Limited by lock contention and coordination overhead
- Distinct from cloud-native "compute + storage service" designs, which use a database-specific storage API instead of NAS/SAN abstractions

### Shared-Nothing Architecture

**Definition**: A distributed system where each node has its own CPUs, RAM, and disks; nodes coordinate only through software over a conventional network.

**Key points**:
- Synonym: horizontal scaling, scaling out
- Can use commodity hardware with the best price/performance ratio
- Can scale across datacenters and regions for fault tolerance
- Requires explicit sharding and incurs distributed-systems complexity

## Terminology

| Term | Definition |
|------|------------|
| Load parameter | A number that quantifies a relevant dimension of demand |
| Linear scalability | Resources scale 1:1 with load |
| Scale up / vertical | Bigger machine |
| Scale out / horizontal | More machines |
| Shared-memory | Single-machine, threads share RAM |
| Shared-disk | Multiple compute nodes, shared NAS/SAN |
| Shared-nothing | Multiple nodes, each owns CPU/RAM/disk |
| Magic scaling sauce | Mythical generic, one-size-fits-all scalable architecture |
| Autoscaling | System adds/removes resources automatically in response to demand |

## How It Relates To

- **Performance**: Scalability is the ability to preserve performance metrics as load grows
- **Reliability**: Scaling decisions affect fault tolerance (shared-nothing across regions)
- **Sharding (Ch. 7)**: Required to make shared-nothing systems work
- **Distributed systems (Ch. 9)**: Complexity inherent to scale-out
- **Microservices**: Same underlying principle — break into smaller independent components

## Common Misconceptions

- **Myth**: A system is either "scalable" or "not scalable"
  **Reality**: Scalability is always relative to a specific growth dimension and load profile

- **Myth**: Plan for massive future scale from day one
  **Reality**: For most early products, simplicity and flexibility beat hypothetical scale; rethink architecture roughly per order of magnitude of load growth

- **Myth**: Shared-nothing is always best
  **Reality**: It introduces sharding and distributed-system complexity; a single-machine database is often preferable when it suffices

- **Myth**: Two systems with the same throughput can use the same architecture
  **Reality**: 100,000 req/s of 1 kB looks nothing like 3 req/min of 2 GB, even at the same MB/s

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Load | A few numbers that describe demand |
| Linear scalability | 2x resources handle 2x load |
| Vertical scaling | Bigger machine, shared memory |
| Horizontal scaling | More machines, shared nothing |
| Shared-disk | Compute nodes, shared SAN/NAS, contention-limited |
| Shared-nothing | Each node owns its hardware; coordinate via network |
