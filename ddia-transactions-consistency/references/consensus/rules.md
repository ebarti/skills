# Consensus Rules

Decision rules for when to use consensus algorithms and coordination services, and when not to.

## Core Rules

### 1. Don't roll your own consensus

Consensus is "infamously difficult to get right" — many systems have shipped broken implementations. Always use a proven algorithm via a battle-tested library or service.

- Use **ZooKeeper, etcd, or Consul** as a coordination service
- Use a **Raft library** (e.g., hashicorp/raft, etcd-io/raft) if you need to embed consensus
- Never invent your own leader election or quorum protocol

**Example**:
```
// Bad: hand-rolled "leader election" using a database row + timestamp
// Good: zk.create("/leader", myId, EPHEMERAL) — atomicity guaranteed by ZooKeeper
```

### 2. Always plan for majority-quorum requirements

Consensus algorithms require a strict majority of nodes to be reachable to make progress.

- 3 nodes tolerate 1 failure
- 5 nodes tolerate 2 failures
- A network partition isolates the minority side; only the majority side keeps working
- Choose **odd numbers** (3 or 5) to maximize fault tolerance per node

### 3. Use consensus for the right things

Consensus is right when you need linearizable agreement that survives failures:

- **Leader election** for single-leader systems (database primary, scheduler primary)
- **Distributed locks and leases** with automatic release on client failure
- **Configuration that must be linearizable** (e.g., shard ownership, cluster membership)
- **Fencing tokens** (monotonic IDs preventing zombie writes)
- **Service registry** when failure detection matters

### 4. Don't use consensus for high-throughput data writes

Every consensus operation requires quorum communication — you can't shard your way to higher throughput by adding nodes (more nodes = slower).

- Don't store user data, time-series, or fast-changing state in ZooKeeper/etcd
- For replicated data writes, use **single-leader replication built on top of consensus**: consensus elects the leader, then the leader handles writes at full speed
- Use BookKeeper or a regular database for fast-changing state

**Example**:
```
// Bad: writing every metric event to etcd
// Good: store metrics in a regular DB; use etcd only to elect which node is the metrics primary
```

### 5. Always use fencing tokens after consensus failover

After a consensus-based failover, the old leader may still be alive (paused, partitioned). Without fencing, it can corrupt data when it wakes up.

- Acquire a **monotonically increasing token** (`zxid` in ZooKeeper, revision in etcd) when you become leader
- Include the token on every write to the shared resource
- Storage layer must reject writes with a stale token
- Defends against split brain even when consensus thinks it's solved

### 6. Don't enable unclean leader election unless you accept data loss

Allowing a non-up-to-date replica to become leader (Kafka's `unclean.leader.election.enable=true`) violates the shared log's append-only property.

- Only consider this when you'd rather lose data than be unavailable
- Default safe choice: keep unclean election **disabled**
- Asynchronous replication has the same risk; use sync replication if you need the safety

## Guidelines

- Tune **failure-detection timeouts** carefully: too short → leader election storms; too long → slow recovery. WAN/multi-region deployments need larger timeouts.
- Use Raft's **pre-vote** extension (or Paxos with leader leases) to avoid leadership flapping on a single bad link.
- For **service discovery**, prefer **caching with TTL** over hitting the consensus service on every lookup; use ZooKeeper observers for high-throughput stale reads.
- Use **reconfiguration** features to add/remove nodes safely; never just edit config files and restart.
- Run the coordination service on a **dedicated, fixed cluster** (3 or 5 nodes); separate it from the application nodes that depend on it.
- Place quorum members in **independent failure domains** (different racks/AZs) — a 3-node cluster all in one rack tolerates 0 datacenter failures.

## Exceptions

- **Configuration management** can use consensus, but a polled file/URL works fine and avoids the dependency.
- **Service discovery** is often better served by DNS or a non-consensus registry — availability and cache freshness usually beat strict linearizability.
- **Two-node systems** where one is clearly preferred can use a simpler primary-with-standby scheme; consensus needs ≥3 nodes to actually tolerate a failure.
- **Single-region, latency-critical** systems may prefer leaderless protocols (EPaxos) over leader-based ones to avoid leader bottlenecks.

## Quick Reference

| Rule | Summary |
|------|---------|
| No DIY consensus | Use ZooKeeper, etcd, Consul, or a Raft library |
| Majority quorum required | 3 nodes → 1 fault; 5 nodes → 2 faults |
| Right uses | Leader election, locks, linearizable config, fencing |
| Wrong uses | High-throughput writes, large data, per-request linearizability |
| Always fence | Use monotonic tokens after consensus failover |
| Unclean election | Off by default; only on if data loss is acceptable |
| Tune timeouts | Balance recovery speed vs election storms |
| Cache discovery | Service discovery rarely needs strict linearizability |
| Dedicated cluster | Separate coordination service from app nodes |
| Spread failure domains | Distribute quorum across AZs/racks |
