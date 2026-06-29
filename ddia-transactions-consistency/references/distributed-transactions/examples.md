# Distributed Transactions Examples

Real-world scenarios for 2PC, XA, internal distributed transactions, and exactly-once messaging.

## 2PC Happy Path

Coordinator C, participants P1 (orders DB) and P2 (inventory DB).

```
App  ->  C: begin txn, get global txn ID T1
App  ->  P1: write order row tagged T1
App  ->  P2: decrement stock row tagged T1
App  ->  C: commit T1

Phase 1 (prepare):
C    ->  P1: prepare(T1)        ;; P1 fsync writes, votes yes
C    ->  P2: prepare(T1)        ;; P2 fsync writes, votes yes
C: log "commit T1" to disk      ;; <-- COMMIT POINT

Phase 2 (commit):
C    ->  P1: commit(T1)         ;; P1 releases locks, acks
C    ->  P2: commit(T1)         ;; P2 releases locks, acks
```

**Why it works**: every yes vote is a binding promise to be able to commit; the coordinator's logged decision is the single source of truth.

## 2PC Failure Scenarios

### Coordinator crashes after commit point, before notifying P1

```
C: log "commit T1" to disk
C    ->  P2: commit(T1)         ;; P2 commits
C    CRASH
P1: still in doubt, holds locks on T1 rows

(time passes — other queries touching those rows block)

C recovers, reads log: "commit T1"
C    ->  P1: commit(T1)         ;; P1 finally commits
```

**Lesson**: in-doubt window = coordinator downtime. Locks held the whole time.

### Coordinator log lost (orphan)

```
C: log "commit T1" to disk
C: disk failure — log gone
P1, P2: stuck in doubt forever
```

**Recovery**: administrator manually inspects each participant, decides commit or abort, applies uniformly. Heuristic decisions risk atomicity violation.

### Participant votes no

```
C    ->  P1: prepare(T1)        ;; P1 votes yes
C    ->  P2: prepare(T1)        ;; P2 detects constraint violation, votes no
C: log "abort T1"
C    ->  P1: abort(T1)
C    ->  P2: abort(T1)          ;; already aborted locally
```

## XA Example: Tomcat + JTA + DB + JMS Queue

A Java EE application processes a message and writes to a database atomically.

```java
// Coordinator: JTA transaction manager (e.g., Narayana) embedded in Tomcat
UserTransaction utx = (UserTransaction) ctx.lookup("java:comp/UserTransaction");

utx.begin();
try {
    // Participant 1: JMS broker (ActiveMQ via XA-aware JMS driver)
    Message msg = jmsConsumer.receive();   // tagged with global txn ID

    // Participant 2: PostgreSQL (XA-aware JDBC driver)
    try (PreparedStatement ps = jdbcConn.prepareStatement(
            "INSERT INTO orders (id, payload) VALUES (?, ?)")) {
        ps.setLong(1, msg.getLongProperty("orderId"));
        ps.setString(2, msg.getBody(String.class));
        ps.executeUpdate();
    }

    utx.commit();   // triggers 2PC across JMS broker + PostgreSQL
} catch (Exception e) {
    utx.rollback();
}
```

**Wiring**:
- JTA implementation runs as a library inside the Tomcat process; its log lives on the app server's local disk.
- JMS driver and JDBC driver both implement XA callbacks (prepare/commit/abort).
- If Tomcat crashes mid-2PC, both PostgreSQL and ActiveMQ hold the message and rows in doubt until the same Tomcat instance restarts and replays its coordinator log.

**Pain points**:
- That single Tomcat instance is the SPOF. Replicate Tomcat and the coordinator log? Application code is still single-threaded inside one process.
- No deadlock detection across PostgreSQL and ActiveMQ.
- Adding a non-XA participant (e.g., outbound HTTP webhook) breaks the model.

## Spanner / CockroachDB Internal 2PC + Paxos

Cross-shard ACID transaction in CockroachDB.

```sql
-- Single statement, but data lives on shards (ranges) S1 and S2
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 'alice';   -- on S1
UPDATE accounts SET balance = balance + 100 WHERE id = 'bob';     -- on S2
COMMIT;
```

**Internally**: gateway node coordinates; each shard is a Raft group; prepare = Raft-commit an intent; commit point = coordinator (also Raft-replicated) decides; phase 2 converts intents to committed writes. Isolation via timestamps (Spanner TrueTime, CockroachDB HLCs).

**Why this works where XA fails**: coordinator Raft-replicated (no single-disk SPOF); coordinator and shards talk directly (no app middleman); shards replicated; concurrency control integrated with commit (deadlock detection, SSI).

## Kafka Transactions for Exactly-Once Stream Processing

A Kafka Streams application reads from input topic, writes to output topic, and updates an offset — atomically.

```java
Properties props = new Properties();
props.put("transactional.id", "payment-processor-1");
props.put("enable.idempotence", "true");

KafkaProducer<String, String> producer = new KafkaProducer<>(props);
producer.initTransactions();

while (true) {
    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));

    producer.beginTransaction();
    try {
        for (ConsumerRecord<String, String> rec : records) {
            producer.send(new ProducerRecord<>("payments-out", rec.key(), process(rec.value())));
        }
        // commit offsets inside the same transaction
        producer.sendOffsetsToTransaction(currentOffsets(consumer), consumer.groupMetadata());
        producer.commitTransaction();
    } catch (Exception e) {
        producer.abortTransaction();
    }
}
```

**Why it works**: Kafka's transaction coordinator (broker-internal 2PC) ensures that the output writes and the offset advance commit together. On failure, the output writes are aborted (via the consumer's `read_committed` isolation), and the input offsets are not advanced — so the message is reprocessed cleanly.

**Scope**: exactly-once *within Kafka*. Side effects to external systems (databases, HTTP endpoints) still need idempotency.

## Idempotent Message Handling Pattern

The DDIA-recommended exactly-once approach using only single-DB transactions.

```python
def handle_message(msg, db, broker):
    msg_id = msg.headers["message-id"]    # globally unique

    with db.transaction() as txn:
        # Step 1: dedup check
        if txn.execute("SELECT 1 FROM processed_messages WHERE id = %s", (msg_id,)).fetchone():
            broker.ack(msg)               # already processed; just ack
            return

        # Step 2: record + process atomically
        txn.execute(
            "INSERT INTO processed_messages (id, processed_at) VALUES (%s, NOW())",
            (msg_id,),                    # uniqueness constraint catches concurrent retries
        )
        apply_business_logic(txn, msg)    # writes within the same txn

        # Step 3: commit
        txn.commit()

    # Step 4: ack only after DB commit succeeded
    broker.ack(msg)
```

**Crash analysis**: pre-commit crash -> txn aborts -> redeliver -> reprocess; post-commit pre-ack -> redeliver -> dedup drops it; post-ack -> nothing to do; concurrent retries -> uniqueness constraint forces one to roll back.

**Why it beats XA**: no 2PC, no XA driver, no JTA, no coordinator log; works with any broker (Kafka, RabbitMQ, SQS, NATS); effectively exactly-once with at-least-once delivery. Cleanup: periodically delete old `processed_messages` rows past the broker's max retry horizon.

## Pattern Selection Guide

| Situation | Recommended Approach |
|-----------|---------------------|
| Cross-shard ACID in same DB | Internal distributed txn (Spanner / CockroachDB) |
| Cross-vendor DB + queue, low throughput, must-be-atomic | XA (with eyes wide open) |
| Cross-vendor DB + queue, normal throughput | Idempotent handler + dedup table |
| Exactly-once within Kafka | Kafka transactions (`transactional.id`) |
| Side effects to external HTTP / email | Idempotency keys; never XA (most don't support it) |
| High-throughput stream processing | Idempotency, never 2PC per event |
