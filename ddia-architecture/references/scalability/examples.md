# Scalability Examples

Concrete examples and case studies illustrating scalability concepts from the chapter.

## Load Growth Examples

### User growth

Two example growth patterns the chapter cites as scalability concerns:

- 10,000 concurrent users → 100,000 concurrent users
- 1 million users → 10 million users

In each case, asking "what changes at the new scale?" matters more than the absolute number.

### Throughput as a load parameter

Examples of throughput-based load parameters:

- Number of requests per second to a service
- Gigabytes of new data arriving per day
- Shopping-cart checkouts per hour

### Peak vs. average load

For the social network case study referenced earlier in the chapter:

- The relevant load measure is the **peak** number of simultaneously online users, not the average
- Other relevant statistical characteristics include the number of followers per user (items per user)

## Twitter Timeline Case Study (referenced)

The chapter refers to the social network / Twitter timeline case study introduced earlier in the same chapter as a recurring example of how to choose load parameters. Key load characteristics for that style of system:

- Read/write ratio (timeline reads vs. tweet writes)
- Number of followers per user — extreme cases (celebrities) dominate the bottleneck, not the average user
- Peak concurrent online users
- Cache hit rate on timeline materialization

The point: average values are misleading; the system must be designed for the extreme followers-per-user case, not the median.

## Same Throughput, Different Architectures

Two systems with **identical** total data throughput of 100 MB/second:

| System A | System B |
|----------|----------|
| 100,000 requests/second | 3 requests/minute |
| 1 kB per request | 2 GB per request |

These two systems would look completely different architecturally, even though MB/s matches. Lesson: a single throughput number is not enough to characterize load.

## Architecture Examples

### Shared-memory (vertical scaling)

- A single machine running multiple processes/threads, all sharing the same RAM
- Buy a bigger box, add more cores, more RAM, more disk
- Hits a cost-curve ceiling: a high-end machine with 2x the resources costs *significantly more* than 2x a mid-range machine, and bottlenecks usually prevent it from handling 2x the load anyway

### Shared-disk

- Multiple compute machines with independent CPUs and RAM
- Storage on NAS (network-attached storage) or SAN (storage area network) shared via fast network
- Traditional use case: on-premises data warehousing
- Limited by lock contention and coordination overhead

### Shared-nothing (horizontal scaling)

- Distributed system; each node owns its CPU, RAM, and disks
- All coordination via software over a conventional network
- Examples of advantages cited:
  - Linear scaling potential
  - Cloud commodity hardware with best price/performance
  - Elastic capacity that grows/shrinks with load
  - Fault tolerance across datacenters and regions

### Cloud-native compute + storage service

A modern variant the chapter calls out:

- Multiple compute nodes share access to a single storage service
- Looks superficially like shared-disk, but the storage service exposes a **database-specific API**, not a NAS filesystem or SAN block-device abstraction
- Avoids the legacy shared-disk scalability ceiling

## Linear vs. Non-Linear Scalability

### Linear scalability (good)

- 2x resources → 2x load capacity at the same performance

### Super-linear (rare, possible)

- 2x load handled with **less than** 2x resources
- Causes: economies of scale, better distribution of peak load

### Sub-linear (most common)

- Cost grows faster than load
- Example given: with more data, processing a single write request involves more work — even if the request payload is the same size

## Operational Examples

### Single-machine vs. distributed

- If a single-machine database can do the job, prefer it over a complicated distributed setup
- Saves complexity, operational surprises, and team cognitive load

### Manual vs. autoscaling

- **Autoscaling**: automatically adds/removes resources in response to demand — best when load is unpredictable
- **Manual scaling**: fewer operational surprises when load is fairly predictable

### Service count

- A system with 5 services is simpler than one with 50
- Real architectures are a pragmatic mixture of approaches, not pure one-style designs
