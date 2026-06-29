# Stream Processing Examples

Concrete examples of windows, joins, and exactly-once patterns across real systems.

## Real Systems Map

| System | Style | Notable feature |
|--------|-------|-----------------|
| Apache Flink | Native streaming | Barrier-triggered checkpoints; rich event-time + watermarks |
| Spark Structured Streaming | Microbatch (or continuous) | ~1s batches; same APIs as batch Spark |
| Kafka Streams | Library on JVM | State in RocksDB, replicated to compacted Kafka topic |
| ksqlDB | SQL on Kafka Streams | Declarative streaming SQL |
| Apache Beam | Unified API | Runs on Dataflow, Flink, Spark; rich windowing model |
| Materialize / RisingWave | IVM databases | SQL queries continuously maintained as materialized views |
| Apache Storm / Trident | Topology-based | Trident's idempotence-based exactly-once |
| Esper / Apama / TIBCO StreamBase | CEP engines | Pattern-matching DSL for standing queries |

## Windows

### Tumbling — Click Counts per Minute

```sql
-- ksqlDB / Flink SQL
SELECT window_start, url, COUNT(*) AS clicks
FROM clicks WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY url;
```

```java
// Flink DataStream
clicks.keyBy(c -> c.url)
  .window(TumblingEventTimeWindows.of(Time.minutes(1)))
  .aggregate(new CountAgg());
```

**Why**: every event in exactly one bucket; output is one row per (window, url).

### Hopping — 5-Minute Average, 1-Minute Slide

```java
// Overlapping 5-min windows, advancing every minute
events
  .keyBy(e -> e.serviceId)
  .window(SlidingEventTimeWindows.of(Time.minutes(5), Time.minutes(1)))
  .aggregate(new AvgLatency());
```

**Why**: smoothed moving average emitted every minute; each event lands in 5 windows.

### Session — Per-User Activity (30-min gap)

```java
clicks
  .keyBy(c -> c.userId)
  .window(EventTimeSessionWindows.withGap(Time.minutes(30)))
  .aggregate(new SessionStats());
```

**Why**: dynamic-length window; ends when the user goes inactive for 30 min.

## Stream Joins

### Stream–Table Enrichment (clicks ⋈ profile via CDC)

```java
// Kafka Streams — KStream of clicks joined with KTable of profiles
KTable<String, UserProfile> profiles =
    builder.table("user-profiles-changelog");   // CDC topic, log-compacted

KStream<String, Click> clicks = builder.stream("clicks");

clicks
  .join(profiles, (click, profile) -> enrich(click, profile))
  .to("enriched-clicks");
```

**Why**: the profile table is held locally (RocksDB), updated by CDC — no per-event remote query. The KTable side has an "infinite window" with last-write-wins.

### Stream–Stream Window Join (search ⋈ click on session, 1h)

```java
searches.join(clicks)
  .where(s -> s.sessionId).equalTo(c -> c.sessionId)
  .window(TumblingEventTimeWindows.of(Time.hours(1)))
  .apply((s, c) -> new SearchClick(s, c));
```

**State cost**: indexes for both sides over the last hour, sharded by sessionId.

### Table–Table (timeline materialized view)

```sql
-- Maintained continuously by the stream processor
SELECT follows.follower_id, posts.id, posts.body, posts.created_at
FROM   posts
JOIN   follows ON follows.followee_id = posts.author_id;
```

Maintenance events:
- New post by `u` — fan out to all followers' timelines.
- Post deleted — remove from all timelines.
- `u1` follows `u2` — backfill `u2`'s recent posts into `u1`'s timeline.
- `u1` unfollows `u2` — remove `u2`'s posts from `u1`'s timeline.

This is the **product rule**: `(posts · follows)' = posts' · follows + posts · follows'`.

## Fault Tolerance Patterns

### Flink Checkpoint + Kafka Transactional Sink (exactly-once)

```java
// 1. Checkpoint state every 10s
env.enableCheckpointing(10_000);
env.getCheckpointConfig().setCheckpointingMode(CheckpointingMode.EXACTLY_ONCE);

// 2. Source: Kafka, offsets committed only on checkpoint
KafkaSource<Event> src = KafkaSource.<Event>builder()
    .setBootstrapServers("kafka:9092").setTopics("events")
    .setStartingOffsets(OffsetsInitializer.committedOffsets()).build();

// 3. Sink: Kafka producer with transactions tied to Flink checkpoints
KafkaSink<Out> sink = KafkaSink.<Out>builder()
    .setBootstrapServers("kafka:9092")
    .setRecordSerializer(...)
    .setDeliveryGuarantee(DeliveryGuarantee.EXACTLY_ONCE)
    .setTransactionalIdPrefix("my-job").build();

env.fromSource(src,
       WatermarkStrategy.forBoundedOutOfOrderness(Duration.ofSeconds(30)), "kafka")
   .keyBy(e -> e.userId).process(new MyProcessor()).sinkTo(sink);
```

**Why**: barriers align with Kafka transactions so source offsets, operator state, and sink output commit atomically. Crash before commit → restart from last checkpoint and discard partial output.

### Idempotent Sink Tagged with Kafka Offset

```java
// Each output row carries the offset of the input message that produced it.
void writeOutput(KafkaRecord in, Result out, JdbcSink sink) {
    sink.upsert(
      "INSERT INTO results(key, value, source_offset) VALUES (?,?,?) " +
      "ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, " +
      "source_offset = EXCLUDED.source_offset " +
      "WHERE results.source_offset < EXCLUDED.source_offset",
      out.key, out.value, in.offset());
}
```

**Why**: the offset acts as a fencing token — duplicates from a retry are silently dropped.

### Watermark + Allowed Lateness for Stragglers

```java
WatermarkStrategy<Event> strategy = WatermarkStrategy
  .<Event>forBoundedOutOfOrderness(Duration.ofSeconds(30))
  .withTimestampAssigner((e, ts) -> e.eventTimeMillis);

events
  .assignTimestampsAndWatermarks(strategy)
  .keyBy(e -> e.key)
  .window(TumblingEventTimeWindows.of(Time.minutes(1)))
  .allowedLateness(Time.minutes(5))         // accept stragglers up to 5 min
  .sideOutputLateData(lateOutputTag)        // too-late events go here
  .aggregate(new MyAgg());
```

**Why**: combines watermark (fire), allowed lateness (update), and a side output for events older than that.

## Refactoring — Per-Event DB Lookup → CDC-Backed Local Join

### Before

```java
// Slow, fragile, overloads the DB
clicks.map(click -> {
    UserProfile p = jdbc.query(
      "SELECT * FROM users WHERE id = ?", click.userId);
    return enrich(click, p);
});
```

**Problems**: a network round-trip per event; throughput capped by DB latency; the DB becomes a bottleneck and a SPOF.

### After

```java
// Profiles delivered via Debezium → Kafka topic, held locally in KTable
KTable<UserId, UserProfile> profiles = builder.table("users-cdc");
KStream<UserId, Click>      clicks   = builder.stream("clicks");

clicks.join(profiles, MyEnricher::enrich).to("enriched-clicks");
```

### Changes Made

1. Replaced remote query with a **local KTable** backed by RocksDB.
2. Profiles stay current via a **CDC stream** of the users table.
3. Joins run at stream-processor speed; the DB leaves the hot path.
4. Recovery: the KTable rebuilds from the log-compacted Kafka topic on restart.
