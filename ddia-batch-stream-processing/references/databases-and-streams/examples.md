# Databases and Streams Examples

Real CDC tools and worked sync scenarios from the field.

## Anti-pattern: Dual write race condition

```python
# Two concurrent clients both update key X.
# Client 1 wants to set X = A; Client 2 wants X = B.

# Client 1                              # Client 2
db.set("X", "A")                        db.set("X", "B")
search_index.set("X", "A")              search_index.set("X", "B")
```

Possible interleaving observed at each system:

| System | Sees first | Sees second | Final value |
|--------|------------|-------------|-------------|
| Database | A | B | **B** |
| Search index | B | A | **A** |

**Problems**:
- Two systems permanently disagree about the value of X
- No error was raised; nothing in the application logs flags this
- Without version vectors per system, the inconsistency is silent
- Even if both writes succeed, they were applied in different orders

## Good Example: PostgreSQL → Kafka via Debezium

Debezium runs as a Kafka Connect source connector. It reads the Postgres write-ahead log (WAL) and publishes one Kafka topic per table.

```json
// Connector config (POST to Kafka Connect REST API)
{
  "name": "inventory-postgres-source",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "postgres.internal",
    "database.dbname": "inventory",
    "plugin.name": "pgoutput",
    "slot.name": "debezium_slot",
    "publication.name": "debezium_pub",
    "topic.prefix": "inventory",
    "snapshot.mode": "initial"
  }
}
```

Resulting topics: `inventory.public.products`, `inventory.public.orders`, etc. Each message carries `before` and `after` row state plus operation (`c`/`u`/`d`).

**Why it works**:
- App keeps writing to Postgres normally — zero code changes
- DBLog watermarking takes a consistent initial snapshot, then tails the WAL
- WAL ordering is preserved end-to-end
- Search-index, cache, and warehouse consumers all read the same Kafka topics

## Good Example: DynamoDB Streams → Lambda → OpenSearch

```python
# Lambda triggered by DynamoDB Stream (NEW_AND_OLD_IMAGES view type)
import boto3

opensearch = boto3.client("opensearchserverless")

def handler(event, context):
    for record in event["Records"]:
        key = record["dynamodb"]["Keys"]["id"]["S"]
        if record["eventName"] in ("INSERT", "MODIFY"):
            doc = record["dynamodb"]["NewImage"]
            opensearch.index(index="products", id=key, body=doc)
        elif record["eventName"] == "REMOVE":
            opensearch.delete(index="products", id=key)
```

**Why it works**:
- DynamoDB owns the ordering per partition key
- Stream is durable for 24 hours; Lambda checkpoints automatically
- Search index becomes a follower of DynamoDB — no dual write

## Good Example: Materialized cache fed from CDC

```python
# Kafka consumer maintaining a Redis cache of "current user profiles"
from kafka import KafkaConsumer
import redis, json

cache = redis.Redis()
consumer = KafkaConsumer("inventory.public.users",
    bootstrap_servers="kafka:9092", enable_auto_commit=False,
    group_id="user-profile-cache")

for msg in consumer:
    event = json.loads(msg.value)
    user_id = event["after"]["id"] if event["after"] else event["before"]["id"]
    if event["op"] in ("c", "u", "r"):
        cache.set(f"user:{user_id}", json.dumps(event["after"]))
    elif event["op"] == "d":
        cache.delete(f"user:{user_id}")
    consumer.commit()
```

**Why it works**: Cache rebuilds deterministically from any offset; no cache-invalidation logic in app code; consumer crash resumes from last committed offset.

## Good Example: Kafka log compaction in action

```bash
# Create a compacted "current state" topic
kafka-topics.sh --create \
  --topic user-profiles-compacted \
  --partitions 12 \
  --replication-factor 3 \
  --config cleanup.policy=compact \
  --config min.cleanable.dirty.ratio=0.1 \
  --config segment.ms=86400000
```

Sequence of records on the topic for key `user:42`:

```
offset 1  key=user:42  value={"name":"Alice","email":"a@old.com"}
offset 5  key=user:42  value={"name":"Alice","email":"a@new.com"}
offset 9  key=user:42  value={"name":"Alice Smith","email":"a@new.com"}
offset 12 key=user:42  value=null    # tombstone — delete user
```

After compaction:

```
offset 12 key=user:42  value=null    # tombstone retained briefly, then key gone
```

**Why it works**:
- Topic size = number of distinct users, not total writes
- New consumers can read from offset 0 and reconstruct full state
- Tombstones propagate deletes; eventually compacted away

## Good Example: Outbox pattern (decouple internal schema)

```sql
BEGIN;
UPDATE orders SET status = 'shipped', shipped_at = now() WHERE id = 42;
INSERT INTO outbox (aggregate_type, aggregate_id, event_type, payload)
VALUES ('Order', '42', 'OrderShipped',
        '{"orderId":42,"tracking":"1Z..."}');
COMMIT;
```

Debezium captures **only** the `outbox` table. Downstream consumers see a stable `OrderShipped` schema even if the internal `orders` schema changes.

**Why it works**: Both writes are atomic (same DB transaction); internal schema evolves freely; outbox row is the explicit contract.

## Real CDC tools in production use

| Tool | Source databases | Notes |
|------|------------------|-------|
| **Debezium** | MySQL, Postgres, Oracle, SQL Server, Db2, Cassandra, MongoDB | Open source; Kafka Connect ecosystem; DBLog incremental snapshots |
| **Maxwell** | MySQL | Lightweight binlog → JSON producer |
| **AWS DMS** | Most relational + some NoSQL | Managed; can target Kinesis, Kafka MSK, S3 |
| **DynamoDB Streams** | DynamoDB | Native; 24-hour retention; consumed by Lambda or KCL |
| **Kinesis Data Streams (from DDB)** | DynamoDB | Longer retention than native streams |
| **Striim** | Many; oriented at heterogeneous pipelines | Commercial |
| **GoldenGate** | Oracle (and others) | Oracle's enterprise CDC |
| **pgcapture** | Postgres | Logical decoding–based |
| **Confluent Connect** | Many via certified connectors | Managed Kafka Connect |
| **Datastream** | Google Cloud SQL, AlloyDB | GCP-managed CDC |

## Refactoring Walkthrough

### Before (dual write)

```python
def update_product(product_id, changes):
    db.products.update(product_id, changes)
    search.index("products", product_id, changes)   # may race
    cache.delete(f"product:{product_id}")            # may fail
    warehouse.upsert("products", product_id, changes) # may lag
```

### After (CDC fan-out)

```python
def update_product(product_id, changes):
    db.products.update(product_id, changes)
    # That's it. Debezium captures the row change from the WAL
    # and publishes to inventory.public.products. Independent
    # consumers maintain the search index, cache, and warehouse.
```

### Changes Made

1. **Removed downstream writes from app code** — eliminates race condition and partial-failure window
2. **Added Debezium connector for Postgres** — single ordering authority is the WAL
3. **Replaced cache invalidation with a CDC consumer** — cache rebuilds deterministically from the stream
4. **Search and warehouse become independent consumers** — adding a new derived view requires no app changes
