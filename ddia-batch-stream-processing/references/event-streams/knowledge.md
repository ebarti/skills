# Event Streams Knowledge

Core concepts for transmitting event streams via messaging systems and log-based brokers.

## Overview

Stream processing operates on continuous event streams instead of finite files. Events flow from producers to consumers through messaging systems, which range from ephemeral message brokers (RabbitMQ, ActiveMQ) that delete messages after delivery to durable log-based brokers (Kafka, Kinesis) that retain messages for replay.

## Key Concepts

### Event

**Definition**: A small, self-contained, immutable object containing the details of something that happened at a point in time, usually with a timestamp.

**Key points**:
- Streaming equivalent of a record in batch processing
- Encoded as text, JSON, or binary
- Examples: user actions (page view, purchase), sensor readings, log lines

### Event Stream / Topic

**Definition**: A named, ordered group of related events—the streaming analog of a filename grouping related records.

- Producers append events to a topic
- Consumers subscribe to a topic to read events
- Topics may be sharded into partitions for scalability

### Producer / Consumer

- **Producer** (publisher, sender): Generates and sends events to a topic
- **Consumer** (subscriber, recipient): Reads and processes events from a topic
- One event may be processed by multiple consumers

### Message Broker

**Definition**: A server that mediates between producers and consumers, optimized for handling message streams. Effectively a database tuned for messages.

**Key points**:
- Producers and consumers connect as clients
- Centralizes durability and tolerates client disconnects
- Delivery is asynchronous (producer waits only for broker ack)
- Two families: ephemeral (AMQP/JMS-style) and log-based

### Ephemeral Broker (AMQP/JMS-style)

**Definition**: A broker that deletes messages after they are acknowledged by consumers.

- Standards: JMS (Java), AMQP (cross-language)
- Examples: RabbitMQ, ActiveMQ, HornetQ, IBM MQ, Azure Service Bus, Google Cloud Pub/Sub
- Assumes short queues, small working set
- Not suitable for long-term storage or replay

### Log-Based Broker

**Definition**: A broker that stores messages in an append-only log on disk; consuming is non-destructive.

- Examples: Apache Kafka, Amazon Kinesis Streams, Apache Pulsar, Redpanda
- Messages persist; multiple consumers can replay independently
- Achieves millions of messages/sec via partition sharding + replication

### Partition (Shard)

**Definition**: A single append-only log within a topic, hosted on one machine, totally ordered.

- A topic = group of partitions
- Ordering guaranteed within a partition, not across
- Scaling: more partitions = more parallelism

### Offset

**Definition**: A monotonically increasing sequence number assigned to every message within a partition.

- Records consumer position in the partition
- Analogous to log sequence number in DB replication
- Periodic offset checkpoints replace per-message acks

### Consumer Group

**Definition**: A set of consumers that cooperatively consume a topic; each partition is assigned to one member of the group.

- Combines load balancing (within group) and fan-out (across groups)
- Max parallelism per group = number of partitions

### Acknowledgment

**Definition**: Explicit signal from consumer to broker that a message has been processed and may be removed from the queue.

- Missing ack triggers redelivery (possibly to another consumer)
- Redelivery + load balancing can cause message reordering

### Backpressure

**Definition**: Flow control that blocks producers when consumers cannot keep up.

- Alternative responses: drop messages, buffer in queue
- TCP and Unix pipes use backpressure with fixed buffers

### Log Compaction

**Definition**: A retention policy that keeps only the latest message per key, instead of deleting by age.

- Useful for snapshots: per-user state, change data capture (CDC)
- Allows rebuilding derived state without unbounded log growth

### Dead Letter Queue (DLQ)

**Definition**: A separate queue where un-processable messages are moved to unblock consumers.

- Prevents poison-pill message loops (bad serialization, missing key)
- Operator decides: drop, fix, or replay

## Terminology

| Term | Definition |
|------|------------|
| Event | Immutable record of something that happened |
| Topic | Named group of related events |
| Producer | Generator of events |
| Consumer | Reader/processor of events |
| Broker | Server mediating producers and consumers |
| Partition | Append-only log shard within a topic |
| Offset | Sequence number identifying message position in a partition |
| Consumer group | Cooperating consumers sharing topic load |
| Backpressure | Flow control blocking fast producers |
| Tail-f | `tail -f` — basic streaming primitive |

## How It Relates To

- **Batch processing**: Streaming files = batch; events = records; replay = re-running a job
- **Database replication**: Offset = log sequence number; broker = leader; consumer = follower
- **Storage engines**: Log-based brokers reuse append-only log structure (Chapter 4)
- **Sharding**: Partitions are shards (Chapter 7); partition key controls placement

## Common Misconceptions

- **Myth**: Message brokers are queues that store data forever.
  **Reality**: Ephemeral brokers (AMQP/JMS) delete on ack; log-based brokers retain by time/size policy.

- **Myth**: Log-based brokers always preserve global message order.
  **Reality**: Order is guaranteed only within a partition, not across partitions.

- **Myth**: Adding more consumers always scales throughput.
  **Reality**: In log-based brokers, parallelism is capped at partition count.

- **Myth**: Acknowledgment guarantees exactly-once delivery.
  **Reality**: Lost acks cause redelivery; exactly-once requires atomic commit or idempotency.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Event | Immutable timestamped record of something that happened |
| Producer/Consumer | Sender/receiver of events on a topic |
| Ephemeral broker | Deletes message on ack (RabbitMQ, ActiveMQ) |
| Log-based broker | Append-only log; messages persist (Kafka, Kinesis) |
| Partition | Sharded sub-log; ordering scope |
| Offset | Consumer's position pointer |
| Consumer group | Load-balanced consumers sharing partitions |
| DLQ | Quarantine queue for poison messages |
