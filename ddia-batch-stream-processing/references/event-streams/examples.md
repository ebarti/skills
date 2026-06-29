# Event Streams Examples

Real systems, topology diagrams, and operational examples.

## Real Systems

### Ephemeral Brokers (AMQP / JMS family)

| System | Notes |
|--------|-------|
| RabbitMQ | AMQP 0.9.1; flexible exchange/binding model; mature DLQ support |
| ActiveMQ | Classic JMS broker; XA two-phase commit |
| HornetQ | JMS; merged into ActiveMQ Artemis |
| IBM MQ | Enterprise JMS; transactional |
| Azure Service Bus | Cloud JMS-style; topics + subscriptions |
| Google Cloud Pub/Sub | JMS-style API; log-like internals |
| AWS SQS | Managed task queue; at-least-once |

### Log-Based Brokers

| System | Notes |
|--------|-------|
| Apache Kafka | Reference log-based broker; partitions, consumer groups, compaction |
| Amazon Kinesis Streams | Managed Kafka-like; shards, sequence numbers |
| Apache Pulsar | Tiered storage; supports both log and queue modes; native DLQ |
| Redpanda | Kafka-API-compatible; C++ rewrite; tiered storage |
| WarpStream | Object-storage-backed Kafka API |
| Confluent Freight / Bufstream | Cloud-native, object-storage Kafka variants |
| NATS JetStream | Lightweight log-based persistence over NATS |

### Brokerless / Direct

| System | Notes |
|--------|-------|
| ZeroMQ, nanomsg | Library-based pub/sub over TCP |
| UDP multicast | Stock-market feeds; low latency, lossy |
| StatsD | UDP metrics collection |
| Webhooks | HTTP callbacks for event notifications |

## Topology: Kafka Topic with Partitions

```
Topic: orders
        +------------+------------+------------+
Producer A ─── append ──> Partition 0:  [m0][m1][m2][m3] ...
Producer B ─── append ──> Partition 1:  [m0][m1][m2][m3] ...
Producer C ─── append ──> Partition 2:  [m0][m1][m2][m3] ...

Each box = one message; numbers = monotonic offset within partition.
Ordering guaranteed within a partition; not across partitions.
```

## Topology: Consumer Group (3 Consumers / 6 Partitions)

```
Topic: orders   (6 partitions: P0..P5)

Consumer Group "billing":
   Consumer-1 ── reads ──> P0, P1
   Consumer-2 ── reads ──> P2, P3
   Consumer-3 ── reads ──> P4, P5

Consumer Group "analytics" (independent fan-out):
   Consumer-A ── reads ──> P0, P1, P2
   Consumer-B ── reads ──> P3, P4, P5

Each group sees every message exactly once across its members.
Two groups → message delivered to both groups (fan-out).
```

If Consumer-2 crashes, the broker rebalances:

```
   Consumer-1 ── reads ──> P0, P1, P2
   Consumer-3 ── reads ──> P3, P4, P5
```

## Pattern: Load Balancing vs Fan-Out

```
LOAD BALANCING (one consumer group):
  Producer ──> [Topic] ──> Consumer-1  (gets m0, m3)
                       ──> Consumer-2  (gets m1, m4)
                       ──> Consumer-3  (gets m2, m5)

FAN-OUT (multiple consumer groups):
  Producer ──> [Topic] ──> Group-A: Consumer-A1  (gets m0..m5)
                       ──> Group-B: Consumer-B1  (gets m0..m5)
                       ──> Group-C: Consumer-C1  (gets m0..m5)
```

## Example: Consumer Lag Monitoring

```
Tools:
  - Burrow (LinkedIn)            — Kafka consumer lag monitoring
  - Kafka kafka-consumer-groups  — built-in CLI
  - Datadog / Grafana            — dashboards on lag metric
  - Cruise Control               — auto-rebalancing

Sample CLI check:
  $ kafka-consumer-groups.sh --bootstrap-server kafka:9092 \
        --describe --group billing

  TOPIC   PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG
  orders  0          15234           15240           6
  orders  1          15201           15240           39   <-- watch
  orders  2          12100           15240           3140 <-- ALERT

Alert rules:
  - Lag > 10k for > 5min      → page on-call
  - Lag growing for > 15min    → escalate
  - Consumer offset stale      → check liveness
```

## Example: Log Compaction (Per-Key Snapshots)

A topic of user profile updates, compacted by `user_id`:

```
Append history:
  offset 100: {user_id: 42, name: "Alice",  email: "a@x.com"}
  offset 101: {user_id: 7,  name: "Bob",    email: "b@x.com"}
  offset 102: {user_id: 42, name: "Alice",  email: "alice@x.com"}  // update
  offset 103: {user_id: 7,  name: null}                            // tombstone (delete)
  offset 104: {user_id: 99, name: "Carol"}

After compaction (background process):
  offset 102: {user_id: 42, name: "Alice", email: "alice@x.com"}  // latest for 42
  offset 104: {user_id: 99, name: "Carol"}                        // latest for 99
  // user_id 7 removed by tombstone

Result: a complete snapshot of current state, replayable from offset 0.
```

Used for: CDC topics, materialized views, Kafka Streams state stores, Debezium.

## Example: Dead Letter Queue Pattern

```
Topic: orders          (main)
Topic: orders-dlq      (poison messages)

Consumer pseudo-code:
  for msg in topic("orders"):
      try:
          process(msg)
          commit_offset()
      except DeserializationError, BusinessLogicError:
          publish("orders-dlq", msg, headers={
              "error":      str(e),
              "source":     "billing-consumer",
              "timestamp":  now(),
              "attempts":   msg.attempts + 1,
          })
          commit_offset()  // skip past poison message

Operator workflow:
  1. Alert fires: orders-dlq depth > 0
  2. Inspect DLQ message + error
  3. Decide: drop, fix code, or replay back to "orders"
```

## Example: Replay From Past Offset

```
# Reset a consumer group to reprocess yesterday's data
kafka-consumer-groups.sh --bootstrap-server kafka:9092 \
    --group billing --topic orders \
    --reset-offsets --to-datetime 2026-05-10T00:00:00Z \
    --execute

# Or start a parallel "shadow" consumer with a new group_id
# that writes to a different output sink — original group untouched
```

## Example: Choosing Partition Key

```python
# Bad: random partitioning splits a user's events across partitions
producer.send("orders", value=order)

# Good: partition by user_id preserves per-user order
producer.send("orders", key=str(order.user_id), value=order)

# Result: all events for user 42 land on the same partition,
# processed by the same consumer, in commit order.
```

## Comparison Table: Ephemeral vs Log-Based

| Aspect | Ephemeral (RabbitMQ) | Log-Based (Kafka) |
|--------|---------------------|-------------------|
| Storage model | Queue, delete on ack | Append-only log, retention by time/size |
| Replay | No | Yes — rewind to any offset |
| Multiple readers | Per-message routing | Independent consumer groups |
| Ordering | Per-queue (lost with redelivery) | Per-partition, strict |
| Parallelism | Per-message (fine-grained) | Per-partition (coarse) |
| Throughput | Tens of thousands/sec | Millions/sec |
| Use case | Task queues, RPC | Event sourcing, ETL, analytics |
