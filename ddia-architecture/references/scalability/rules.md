# Scalability Rules

Design rules and guidelines for scaling decisions, capacity planning, and architecture choice.

## Core Rules

### 1. Characterize load with the right parameters

You cannot reason about growth until you can describe current load quantitatively.

- Pick parameters that match the *access pattern*, not just gross volume
- Common parameters: requests/sec, GB/day, peak concurrent users, read/write ratio, cache hit rate, items per user (e.g. followers)
- Decide whether the average case or the extreme cases dominate cost
- Two systems with the same total throughput can have wildly different load profiles

### 2. Frame scalability as questions, not labels

Never say "X is scalable" or "Y doesn't scale." Instead ask:

- If the system grows in *this specific way*, what are our options?
- How can we add resources to handle additional load?
- Given current growth projections, when do we hit limits of the current architecture?

### 3. Don't scale prematurely

For new products with few users, simplicity and flexibility beat hypothetical scale.

- Premature scaling investment is, at best, wasted effort
- At worst, it locks you into an inflexible design that's hard to evolve
- Wait until bottlenecks are observed and growth is real before optimizing

### 4. Scale up before scaling out

A single-machine setup is simpler than a distributed one. Prefer it when it works.

- Vertical scaling (bigger machine, shared memory) is the simplest move
- Shared-nothing brings sharding plus full distributed-systems complexity
- Use scale-out when single-machine ceilings, cost curves, or fault tolerance demand it

### 5. Choose shared-nothing for elasticity, fault tolerance, and price/performance

Shared-nothing (horizontal scaling) is the right choice when you need:

- **Linear scalability potential** beyond a single machine
- **Best price/performance** from commodity cloud hardware
- **Elastic capacity** that grows and shrinks with demand
- **Multi-datacenter / multi-region** fault tolerance

Trade-offs you accept:
- Explicit sharding (see Ch. 7)
- All the complexity of distributed systems (see Ch. 9)

### 6. Avoid traditional shared-disk for new high-scale workloads

Shared-disk (NAS/SAN) suffers from lock contention and coordination overhead.

- Traditionally fine for on-premises data warehousing
- Cloud-native "separation of storage and compute" designs are different — they use a database-specific storage API, not generic NAS/SAN, and avoid the old scalability problems

### 7. Re-architect roughly per order of magnitude of load

An architecture appropriate for one level of load probably won't cope with 10x.

- Plan at most one order of magnitude ahead
- Expect to redesign as you grow
- Don't over-engineer for two or three orders of magnitude in advance

### 8. Break the system into independent components

The general principle behind nearly every scaling technique.

- Underlies microservices, sharding, stream processing, and shared-nothing
- The hard part is choosing the seams — what stays together vs. what gets separated
- Components that scale independently are far easier to operate

### 9. Don't make things more complicated than necessary

Complexity has operational cost; only spend it where it pays for itself.

- A single-machine database is preferable to a distributed setup when it suffices
- A system with 5 services is simpler than one with 50
- Autoscaling is great when load is unpredictable; manual scaling has fewer surprises when load is steady
- Real-world good architectures are a pragmatic mixture of approaches

## Guidelines

- Always tie scaling decisions back to an SLA target and a cost budget — both performance and cost matter
- Watch out for sub-linear scalability: cost typically grows faster than linearly with load (more data means more work per write)
- Sometimes super-linear gains exist (economies of scale, smoothed peak load) — measure to find out
- Treat the choice between average-case and tail-case bottlenecks as an explicit decision

## Exceptions

- **Known hyperscale target**: If you are *certain* you'll need horizontal scale (e.g. building infrastructure with proven 10x growth), some early shared-nothing investment is justified
- **Predictable load**: Manual scaling can beat autoscaling when traffic is highly predictable
- **Cost-driven**: Sometimes a cheaper, slower architecture is fine if it still meets the SLA

## Quick Reference

| Rule | Summary |
|------|---------|
| Characterize load | Pick the right load parameters before discussing growth |
| Frame as questions | Never label a system "scalable" in the abstract |
| Don't scale early | Simplicity beats hypothetical scale for new products |
| Scale up first | Vertical is simpler than horizontal |
| Choose shared-nothing | When elasticity, fault tolerance, or price/performance demand it |
| Avoid shared-disk | For new high-scale workloads (legacy NAS/SAN model) |
| Per-OoM redesign | Re-architect roughly every 10x of load |
| Decompose | Independent components are the underlying scaling principle |
| Keep it simple | 5 services beat 50; manual beats auto when load is predictable |
