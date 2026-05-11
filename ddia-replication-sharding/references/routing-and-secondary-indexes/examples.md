# Request Routing & Secondary Indexes Examples

Real-world systems and their routing & secondary-index implementations.

## Routing Approaches in Real Systems

### Coordination service (ZooKeeper / etcd / Raft)

| System | Coordinator | Notes |
|--------|-------------|-------|
| HBase | ZooKeeper | ZK holds shard-to-node map |
| SolrCloud | ZooKeeper | Same ZK pattern |
| Kafka | Built-in Raft (KRaft) | Replaced ZooKeeper |
| Espresso (LinkedIn) | ZooKeeper-style | Tracks partition assignment |
| Kubernetes | etcd | Service-instance placement (analogous problem) |
| MongoDB | Custom config server + `mongos` routing tier | Equivalent role to ZK |
| YugabyteDB / TiDB / ScyllaDB | Built-in Raft | Self-contained consensus |

### Gossip-based

| System | Notes |
|--------|-------|
| Cassandra | Gossip disseminates ring state; partition-aware drivers compute coordinator |
| Riak | Gossip; tolerates split brain due to leaderless model |

### Routing tier / proxy

| System | Proxy |
|--------|-------|
| MongoDB | `mongos` daemons |
| Couchbase (legacy) | `moxi` |
| Memcached fleets | Twemproxy / Mcrouter |
| Vitess (MySQL sharding) | `vtgate` (external knowledge, similar pattern) |

### Partition-aware client

- Cassandra drivers (DataStax) compute the token from the key and connect directly to the coordinator replica, skipping forwarding.
- ScyllaDB drivers do the same (shard-aware down to the CPU core).

## Local Secondary Index Examples (Document-Partitioned)

Each shard indexes only its own records:

| System | Notes |
|--------|-------|
| MongoDB | Per-shard indexes; mongos scatter-gathers when query lacks shard key |
| Cassandra | SASI / 2i are per-node local indexes |
| Riak | Local SIs |
| Elasticsearch / SolrCloud | Each shard is a Lucene index covering its own docs; coordinator merges hits |
| VoltDB | Per-partition indexes |
| DynamoDB LSIs | Per-partition (Local Secondary Index) |

**Read pattern with partition key known**: hit one shard.
**Read pattern without partition key**: scatter-gather, then merge — bounded by the slowest shard.

## Global Secondary Index Examples (Term-Partitioned)

The SI itself is sharded by the indexed term:

| System | Notes |
|--------|-------|
| DynamoDB GSIs | Async update; reads may be stale |
| CockroachDB | Sync via distributed transactions |
| TiDB | Sync via distributed transactions |
| YugabyteDB | Sync via distributed transactions |
| Riak Search (Solr-backed) | Global term-partitioned index |
| Spanner global indexes | Backed by transactional infrastructure |

## Scatter-Gather (Local SI Read)

Query: `find all cars where color = red` with no partition key.

```
                  ┌────────────────┐
                  │  Coordinator   │
                  └───────┬────────┘
            ┌─────────────┼─────────────┐
            │             │             │
            ▼             ▼             ▼
      ┌──────────┐  ┌──────────┐  ┌──────────┐
      │ Shard 0  │  │ Shard 1  │  │ Shard 2  │
      │ local SI │  │ local SI │  │ local SI │
      └────┬─────┘  └────┬─────┘  └────┬─────┘
           │             │             │
           └─────────────┼─────────────┘
                         ▼
                  ┌────────────────┐
                  │ Merge results  │  <- total latency = max(shard latencies)
                  └────────────────┘
```

Issues:
- Tail latency amplification (one slow shard slows the whole query).
- No throughput improvement from adding shards (every shard still serves every query).

## Global SI Read (Term-Partitioned)

Query: `color = red` against a term-partitioned global SI.

```
   Client ──► Index shard owning "color:red"  ──► postings list of IDs
                                                       │
                                                       ▼
                          fetch records from primary-key shards (may fan out)
```

- Single term lookup: one index shard.
- Fetching the actual rows still requires hitting the primary-key shards owning each ID.

## Global SI Write (Term-Partitioned)

Inserting one car record `{id: 42, color: red, make: ford}`:

```
                     Write {id:42, color:red, make:ford}
                                  │
                                  ▼
              ┌───────────────────┴───────────────────┐
              ▼                   ▼                   ▼
        primary shard      index shard for      index shard for
        for id=42          "color:red"          "make:ford"
        (rows)             (postings list)      (postings list)
```

Each indexed term may land on a different SI shard → multi-shard write.

## DynamoDB: Both Models

DynamoDB exposes both:
- **LSI** (Local Secondary Index) — per-partition; created at table-creation time; sync.
- **GSI** (Global Secondary Index) — term-partitioned; can be added later; **async** so reads may be stale.

## Anti-Pattern: Hand-Rolled SI Over a KV Store

```
// Bad: app maintains color → ids in a separate KV record
client.put("car:42", carJson)
oldList = client.get("idx:color:red")   // race window starts
client.put("idx:color:red", oldList + ["42"])  // partial failure desyncs
```

**Problems**: race conditions between concurrent writers; partial failure leaves index out of sync; no atomic guarantee. Use the database's native SI or wrap in a multi-object transaction.
