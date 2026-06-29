# Consensus Knowledge

Core concepts for distributed consensus algorithms and the coordination services built on them.

## Overview

Consensus is the problem of getting multiple nodes to agree on a single value despite crashes and network problems. Many seemingly different problems (CAS, shared logs, atomic commit, fetch-and-add, leader election) are all equivalent to consensus. In practice, you don't implement consensus yourself — you use proven algorithms (Paxos, Raft, Zab, Viewstamped Replication) wrapped in coordination services like ZooKeeper, etcd, and Consul.

## Key Concepts

### Consensus

**Definition**: Multiple nodes agree on a single value, satisfying uniform agreement, integrity, validity, and termination.

- **Uniform agreement**: No two nodes decide differently.
- **Integrity**: A node cannot change a decision once made.
- **Validity**: The decided value was proposed by some node.
- **Termination** (liveness): Every non-crashed node eventually decides.

Termination requires a majority of nodes to be functioning. Safety properties (the first three) hold even if a majority fails.

### FLP Impossibility

**Definition**: Fischer-Lynch-Paterson result proving no deterministic asynchronous algorithm can guarantee consensus termination if a node may crash.

In practice, FLP is sidestepped using timeouts to suspect crashes (or randomization). Distributed systems achieve consensus reliably in practice.

### Paxos

**Definition**: Lamport's classic consensus algorithm for single-value consensus.

Most real systems use **Multi-Paxos**, which extends single-value Paxos into a shared log. Uses ballot numbers (epoch numbers) to order leader elections.

### Raft

**Definition**: A consensus algorithm designed for understandability that provides a shared log out of the box.

Uses **term numbers** as epochs. New leader must have a log at least as up-to-date as a majority of followers. Pre-vote phase added to handle unreliable network links.

### Zab (ZooKeeper Atomic Broadcast)

**Definition**: The consensus algorithm underlying ZooKeeper, providing total order broadcast.

### Viewstamped Replication

**Definition**: An early consensus protocol equivalent to Paxos. Uses **view numbers** as epochs.

### Total Order Broadcast (Atomic Broadcast)

**Definition**: A protocol that delivers messages to all nodes in the same order, equivalent to a shared log and to consensus.

### Epoch / Ballot / Term / View Number

**Definition**: A monotonically increasing integer attached to each leader election; the leader with the higher epoch wins conflicts.

Two rounds of voting: (1) elect leader for an epoch; (2) vote on each log entry. Quorums for the two votes must overlap.

### Coordination Service

**Definition**: A distributed system (ZooKeeper, etcd, Consul) that uses consensus to provide locks, leases, fencing tokens, failure detection, and change notifications for other distributed systems.

Modeled after Google's **Chubby** lock service. Holds small, slow-changing data in memory (replicated and durable on disk).

### Service Discovery

**Definition**: Looking up the network endpoint (IP:port) of a service instance, often via a coordination service registry.

Doesn't strictly need consensus — high availability and caching matter more than linearizability. ZooKeeper's **observers** serve stale reads at higher throughput.

### Configuration Management

**Definition**: Storing application/infrastructure config in a coordination service so processes can subscribe to change notifications.

Doesn't need consensus per se, but convenient if you're already running the service.

## Equivalence of Consensus Problems

| Problem | Equivalent To | Notes |
|---------|---------------|-------|
| Single-value consensus | All others | Decide one value from proposals |
| CAS (compare-and-set) | Consensus (number ∞) | Use null + CAS to elect winner |
| Shared log / total order broadcast | Consensus (number ∞) | Most useful in practice |
| Atomic commitment | Consensus | Plus "abort if anyone aborts" |
| Fetch-and-add | Consensus number 2 only | Insufficient for >2 proposers |

A solution to any one is convertible to a solution for the others.

## Terminology

| Term | Definition |
|------|------------|
| Quorum | A majority of nodes; required for progress in consensus algorithms |
| Fencing token | Monotonically increasing ID preventing zombie clients (e.g., ZooKeeper `zxid`) |
| Ephemeral node | ZooKeeper key auto-deleted when the session that created it dies |
| State machine replication | Replicating writes via shared log + deterministic application |
| Split brain | Two nodes both believing they are the leader |
| Unclean leader election | Allowing a stale replica to become leader (Kafka option, sacrifices safety) |
| Reconfiguration | Adding/removing nodes from the consensus group at runtime |
| Pre-vote | Raft extension preventing leadership flapping on bad network links |
| Observer (ZooKeeper) | Read replica that does not participate in voting |

## How It Relates To

- **Linearizability**: Consensus is how you build linearizable systems with fault tolerance.
- **Single-leader replication**: Consensus = "single-leader replication done right" with safe automatic failover.
- **Distributed locks/leases**: Implemented atop the CAS primitive provided by consensus.
- **Atomic commitment / 2PC**: 2PC's coordinator failure is solved by replicating it via consensus.
- **Total order broadcast**: Equivalent formulation of consensus, what most systems actually expose.

## Common Misconceptions

- **Myth**: FLP impossibility means consensus is impossible in practice.
  **Reality**: FLP applies to deterministic asynchronous models without timeouts; real systems use timeouts and achieve consensus reliably.

- **Myth**: Consensus algorithms scale by adding nodes.
  **Reality**: Adding nodes makes consensus *slower* — every operation needs a quorum. Throughput does not increase with cluster size.

- **Myth**: 2PC is a consensus algorithm.
  **Reality**: 2PC needs unanimous agreement and has a single coordinator (not fault-tolerant); consensus needs only a quorum and any node can start an election.

- **Myth**: A coordination service is a general-purpose database.
  **Reality**: It's optimized for small, slow-changing data — leader assignments, locks, config — not high write volume.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Consensus | Get N nodes to agree on one value despite f failures |
| Paxos / Multi-Paxos | Classic consensus + shared log extension |
| Raft | Understandable consensus with built-in shared log |
| Zab | ZooKeeper's total order broadcast protocol |
| Total order broadcast | Equivalent of consensus; most useful API in practice |
| ZooKeeper / etcd / Consul | Coordination services built on consensus |
| Epoch number | Monotonic ID ensuring at most one leader per epoch |
| FLP impossibility | Theoretical result, sidestepped by timeouts in practice |
