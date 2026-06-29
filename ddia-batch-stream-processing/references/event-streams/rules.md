# Event Streams Rules

Decision guidance for choosing and operating messaging systems.

## Core Rules

### 1. Choose Log-Based Brokers for Replayable, Durable Workloads

Use Kafka / Kinesis / Pulsar when you need any of:

- ETL pipelines that may need re-running
- Multiple independent consumers reading the same data
- Replayable analytics, debugging, or backfills
- Durable event log as system of record
- High throughput with strict per-key ordering

**Why**: Reading is non-destructive; consumers can rewind to any retained offset.

### 2. Choose Ephemeral Brokers for Task Queues

Use RabbitMQ / ActiveMQ / SQS when:

- Workload is short-lived task queueing (job dispatch)
- Messages are independent (no causal ordering)
- Per-message work is expensive and needs fine-grained parallelism
- You need RPC-like semantics with priority queues
- You don't need replay

**Why**: AMQP/JMS-style brokers parallelize at the message level, not the partition level.

### 3. Make Partition Key Match Ordering Requirements

If a set of events must be processed in order, route them to the same partition.

- Choose partition key from the entity whose order matters (user_id, account_id, device_id)
- Same key → same partition → preserved order
- Different keys may interleave; that is acceptable

**Example**:
```
// Bad: random partitioning destroys per-user order
producer.send(topic, randomPartition, userEvent)

// Good: partition by user_id keeps that user's events ordered
producer.send(topic, key=event.user_id, value=userEvent)
```

### 4. Monitor Consumer Lag as Backpressure Signal

Lag = (latest offset) − (consumer offset). Treat sustained or growing lag as a production alert.

- Set alerts well before lag approaches retention window
- Falling behind retention → permanent message loss for that consumer
- Lag spikes = consumer slowness, not broker problem

### 5. Use Log Compaction When Only Latest Value Per Key Matters

Enable compaction for:

- Per-key snapshots (current state of each user, account, device)
- Change Data Capture (CDC) topics
- Materialized views and derived state stores

**Avoid** for: audit logs, full event history, time-series append.

### 6. Plan For Replay From Day One

Design consumers to be re-runnable:

- Idempotent processing (so duplicates don't corrupt output)
- Output to a separate sink keyed by offset / event id
- Keep retention long enough to cover incident-recovery windows (days, not hours)

### 7. Handle Poison Messages With DLQs

Never let a single bad message block a partition forever.

- Wrap consumer logic in try/catch around deserialization and business logic
- After N failures, route to DLQ topic
- Alert on DLQ depth; review and replay or discard

### 8. Acknowledge Only After Successful Processing

In ephemeral brokers, ack lifecycle is the durability boundary.

- Ack BEFORE processing → message lost on consumer crash
- Ack AFTER processing → may redeliver on crash (handle idempotently)

### 9. Avoid Direct Producer-to-Consumer Messaging for Critical Data

UDP multicast, ZeroMQ, webhooks assume both sides are online and tolerate loss.

- Acceptable: metrics (StatsD), market feeds, fire-and-forget telemetry
- Unacceptable: financial transactions, count-sensitive analytics, audit data

### 10. Right-Size Partition Count

- Too few: parallelism cap (one consumer per partition max)
- Too many: per-partition overhead, rebalance latency
- Rule of thumb: 2–4× target consumer count, leaving room for growth

## Guidelines

- Prefer single-threaded consumer per partition; scale by adding partitions
- Use consumer groups to combine load balancing + fan-out cleanly
- Keep retention time longer than the longest expected outage
- Tier old segments to object storage (Kafka tiered storage, WarpStream) for cheap long retention
- Separate "raw events" topics from "processed/derived" topics

## Exceptions

When these rules may be relaxed:

- **Metrics & telemetry**: UDP-based collection (StatsD) tolerates loss; rule 9 relaxed.
- **Independent messages**: Reordering OK if no causal dependencies; rule 3 relaxed.
- **Strict exactly-once**: Use transactional producers + idempotent consumers; even then, plan for duplicates.
- **Single consumer**: No need for consumer groups; one process consumes all partitions.

## Quick Reference

| Rule | Summary |
|------|---------|
| Log-based for replay | Use Kafka/Kinesis when consumers may re-run |
| Ephemeral for tasks | Use RabbitMQ for fine-grained job parallelism |
| Partition key = order key | Co-locate events that must be ordered |
| Monitor lag | Alert before lag exceeds retention |
| Log compaction | Use when latest-per-key suffices |
| Plan replay | Idempotent consumers, generous retention |
| DLQ for poison messages | Never block a partition forever |
| Ack after processing | Don't lose work on consumer crash |
| Avoid direct messaging for critical data | Use a broker for durability |
| Right-size partitions | 2–4× consumer count |
