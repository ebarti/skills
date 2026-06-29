# Unbundling Databases Examples

Concrete tools and code patterns illustrating unbundled, dataflow-style applications.

## Real-World Tools

### Streaming Materialized Views

- **Materialize / RisingWave**: PostgreSQL-compatible streaming databases. `CREATE MATERIALIZED VIEW` against Kafka/CDC; view is incrementally maintained.
- **ksqlDB**: SQL-like stream processing on Kafka with materialized tables.
- **Apache Flink + Table API**: stream operators as continuous SQL.

### Real-Time Analytics Views

- **Apache Druid / Pinot**: Kafka-ingested pre-aggregated indexes for sub-second OLAP — the read-path side of unbundling.
- **ClickHouse with Kafka engine**: materialized views draining a Kafka topic into a columnar table.

### Client-Side Sync Engines (push to UI)

- **Linear, Figma, Notion**: server pushes state deltas over WebSocket; client merges into local replica.
- **Replicache, Liveblocks, Convex, ElectricSQL**: sync-engine frameworks with optimistic mutations and server reconciliation.

### CDC and Federation

- **Debezium**: extracts change streams from Postgres/MySQL/MongoDB into Kafka.
- **Trino, Hoptimator, Xorq**: federated query engines (read-side complement to unbundling).

## Bad Examples

### Tangled writes across many stores

```python
def create_user(u):
    postgres.insert(u)
    elasticsearch.index(u)
    redis.set(f"user:{u.id}", u)
    notify_team_via_slack(u)
```

**Problems**:
- Partial failure leaves stores inconsistent (no cross-system atomicity).
- Each new derived store requires editing the request handler.
- No source-of-truth log → replay is impossible.
- Tight coupling: a slow Slack call slows user creation.

### Polling for state changes

```js
// Client polls every 5s to detect new messages
setInterval(async () => {
  const messages = await fetch('/api/messages');
  render(messages);
}, 5000);
```

**Problems**:
- High latency (up to poll interval) and wasted bandwidth.
- Doesn't scale to many subscribers.
- The browser cache becomes stale between polls.

### Synchronous RPC in the hot path

```python
def process_purchase(p):
    rate = exchange_rate_service.get(p.currency)  # network hop on every purchase
    p.usd_amount = p.amount * rate
    save(p)
```

**Problems**:
- Coupling: outage of exchange-rate service blocks purchases.
- Latency on every purchase.
- No history — can't reprocess at the rate that was active at purchase time.

## Good Examples

### Event log + derived views

```python
# Single write to the source of truth
def create_user(u):
    log.append({"type": "UserCreated", "user": u, "ts": now()})

# Independent consumers maintain their derived views
@consume("user-events")
def index_user(evt):
    if evt["type"] == "UserCreated":
        elasticsearch.index(evt["user"])  # idempotent upsert by user.id

@consume("user-events")
def cache_user(evt):
    redis.set(f"user:{evt['user']['id']}", evt["user"])
```

**Why it works**:
- Atomic single write; derived stores catch up asynchronously.
- Adding a new derived store = adding a new consumer; no app changes.
- Replayable: rebuild Elasticsearch from scratch by resetting the consumer offset.
- Loose coupling: a slow consumer doesn't block writes.

### Stream join replacing synchronous RPC

```python
# Subscribe once; keep local rate up to date
@consume("exchange-rates")
def update_rate(evt):
    local_db.upsert(evt["currency"], evt["rate"])

def process_purchase(p):
    rate = local_db.get(p.currency)  # local lookup, no network
    p.usd_amount = p.amount * rate
    log.append({"type": "Purchased", **p.__dict__})
```

**Why it works**:
- No network hop per purchase; faster and more available.
- Rate-service outage doesn't block purchases.
- For reprocessing, keep historical rates in the local store keyed by time.

### Materialized view: "active users last hour"

```sql
-- ksqlDB / Materialize / RisingWave style
CREATE MATERIALIZED VIEW active_users_last_hour AS
SELECT COUNT(DISTINCT user_id) AS n
FROM user_events
WHERE event_time > NOW() - INTERVAL '1' HOUR;
```

The engine consumes `user_events` from Kafka and incrementally maintains `n`. Reads are O(1) — no scan over the event log per query.

### Pushing state changes to clients

```js
// Server (SSE)
app.get('/stream/board/:id', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  const sub = bus.subscribe(`board:${req.params.id}`,
    evt => res.write(`data: ${JSON.stringify(evt)}\n\n`));
  req.on('close', () => sub.unsubscribe());
});

// Client
const es = new EventSource(`/stream/board/${boardId}`);
es.onmessage = e => store.apply(JSON.parse(e.data));  // local replica + UI re-render
```

**Why it works**:
- Write path extended to the device — UI updates within ~1s.
- Client reconnects resume from last event id (consumer-offset analog).
- Local store doubles as offline cache.

## Refactoring Walkthrough

### Before: monolithic, polling, tangled

```python
# Order service writes to DB, calls inventory, calls billing, returns to UI
def place_order(o):
    db.insert(o)
    inv = inventory_service.reserve(o.items)
    bill = billing_service.charge(o.user, o.total)
    if not (inv.ok and bill.ok):
        db.delete(o)  # best-effort rollback
    return o

# Browser polls /api/orders/:id every 2s for status
```

### After: event log + derived views + push

```python
def place_order(o):
    log.append({"type": "OrderPlaced", "order": o})
    return {"id": o.id, "status": "pending"}

@consume("order-events")
def reserve_inventory(evt):
    if evt["type"] == "OrderPlaced":
        ok = inventory.reserve(evt["order"]["items"])  # idempotent by order id
        log.append({"type": "InventoryReserved" if ok else "InventoryFailed",
                    "order_id": evt["order"]["id"]})

@consume("order-events")
def charge(evt):
    if evt["type"] == "InventoryReserved":
        ok = billing.charge(...)  # idempotent by order id
        log.append({"type": "OrderConfirmed" if ok else "OrderFailed",
                    "order_id": evt["order_id"]})

# WebSocket pushes order-status events to the browser; no polling
```

### Changes Made

1. **Single durable write**: `place_order` only appends to the log; no cross-service synchronous coordination.
2. **Idempotent consumers**: each step keyed by order id; safe to replay.
3. **No distributed transaction**: failures emit compensating events instead of rolling back across services.
4. **End-to-end push**: status changes flow through the log to a WebSocket — UI updates without polling.
5. **Independent teams**: inventory and billing teams evolve their consumers without coordinating with order service deploys.
