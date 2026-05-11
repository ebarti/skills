# Single-Leader Replication Knowledge

Core concepts for leader-based (primary-backup, active/passive) replication.

## Overview

In single-leader replication, one replica is designated the leader and accepts all writes; followers receive the write stream and apply it locally. Reads can go to any replica, but writes must go to the leader. This is the most common replication topology in PostgreSQL, MySQL, MongoDB, Kafka, and consensus-based systems like Raft.

## Key Concepts

### Leader (Primary, Source)
**Definition**: The single replica that accepts all client writes and produces the replication log.

- All writes go through the leader first
- Leader writes to its local storage, then forwards changes to followers
- If sharded, each shard has exactly one leader (different shards can have different leader nodes)

### Follower (Read Replica, Secondary, Hot Standby)
**Definition**: A replica that receives the leader's replication log and applies changes in the same order.

- Read-only from the client's perspective
- Each follower keeps a local log of changes received from the leader
- Multiple followers can serve read traffic (read-scaling)

### Synchronous Replication
**Definition**: The leader waits for follower confirmation before reporting write success to the client.

- Guarantees the follower has an up-to-date copy
- A failed/slow synchronous follower blocks all writes
- Impractical to make all followers synchronous

### Asynchronous Replication
**Definition**: The leader sends changes to followers but does not wait for confirmation.

- Writes proceed even if followers are down or lagging
- Confirmed writes can be lost if the leader fails before replicating
- Required for read-scaling architectures with many followers

### Semisynchronous Replication
**Definition**: One follower is synchronous; the others are asynchronous. If the sync follower fails, an async one is promoted to sync.

- Guarantees up-to-date data on at least 2 nodes (leader + 1 sync follower)
- Compromise between durability and availability

### Replication Lag
**Definition**: The delay between a write being committed on the leader and being visible on a follower.

- Normally sub-second; can grow to minutes under load, network problems, or recovery
- Causes apparent inconsistencies (eventual consistency anomalies)

### Eventual Consistency
**Definition**: If writes stop, all replicas will eventually converge to the same state.

- Vague: no upper bound on how long convergence takes
- Affects async-replicated relational DBs too, not just NoSQL

### Read-Your-Writes Consistency (Read-After-Write)
**Definition**: A user always sees their own writes after submitting them, even if other users' writes are stale.

- Makes no promise about other users' updates being visible
- Critical for "I just posted, where's my comment?" UX

### Monotonic Reads
**Definition**: A user never sees data go backward in time across successive reads.

- Stronger than eventual, weaker than strong consistency
- Prevents "I saw a comment, refreshed, and it disappeared"

### Consistent Prefix Reads
**Definition**: If writes happen in a certain order, readers see them in that same order.

- Preserves causal ordering (e.g., question before answer)
- Particularly hard in sharded databases without global write order

## Replication Log Implementations

### Statement-Based Replication
The leader logs each SQL statement (`INSERT`, `UPDATE`, `DELETE`) and followers re-execute it.

- **Compact**, but breaks on nondeterministic functions (`NOW()`, `RAND()`)
- Order-sensitive with autoincrement and `WHERE` conditions
- Side effects (triggers, stored procs) may diverge across replicas
- Used in MySQL pre-5.1; VoltDB requires deterministic transactions

### Write-Ahead Log (WAL) Shipping
The leader ships its byte-level WAL to followers, who reconstruct identical disk files.

- Used in PostgreSQL and Oracle
- **Tightly coupled to storage engine** — leader and follower must run compatible binary versions
- Blocks zero-downtime upgrades

### Logical (Row-Based) Log Replication
A separate replication log records row-level changes (insert: new column values; delete: PK; update: PK + new values).

- Decoupled from storage engine internals
- Survives version mismatches → enables zero-downtime upgrades
- Easier for external systems to parse (used for Change Data Capture)
- MySQL `binlog`; PostgreSQL logical replication decodes WAL

## Terminology

| Term | Definition |
|------|------------|
| Replica | Any node storing a copy of the database |
| Failover | Promoting a follower to leader after leader failure |
| Catch-up | Follower applying backlog of writes after reconnect |
| Split brain | Two nodes both believing they are leader |
| Fencing | Mechanism to shut down old leader during failover |
| LSN | Log Sequence Number — position in PostgreSQL replication log |
| Binlog / GTID | MySQL binary log coordinates / global transaction IDs |
| CDC | Change Data Capture — exporting row changes to other systems |

## How It Relates To

- **Sharding (Ch 7)**: Each shard has one leader; sharding and replication are orthogonal
- **Multi-leader replication**: Alternative model with multiple leaders per shard
- **Consensus (Ch 10)**: Raft elects a leader and replicates a log — single-leader at heart
- **Transactions (Ch 8)**: Strong consistency simplifies the application model

## Common Misconceptions

- **Myth**: Synchronous replication means all followers are synchronous.
  **Reality**: Usually only one is sync; the rest are async (semisync).

- **Myth**: A confirmed write is always durable.
  **Reality**: With fully async replication, a confirmed write can be lost if the leader dies before replicating.

- **Myth**: Eventual consistency is a NoSQL-only concern.
  **Reality**: Async-replicated relational databases are eventually consistent too.

- **Myth**: "Master-slave" is the correct technical term.
  **Reality**: Use "leader-follower" or "primary-secondary"; master-slave is offensive and avoided.

## Quick Reference

| Concept | Summary |
|---------|---------|
| Leader | Sole writer, source of replication log |
| Follower | Replicates leader's log, serves reads |
| Sync replication | Durable but blocks on slow followers |
| Async replication | Fast but writes can be lost on failover |
| Statement-based | Re-runs SQL; breaks on nondeterminism |
| WAL shipping | Byte-level; tied to storage version |
| Logical log | Row-level; cross-version compatible |
| Read-your-writes | See your own writes |
| Monotonic reads | Time doesn't go backward |
| Consistent prefix | Causality preserved across writes |
