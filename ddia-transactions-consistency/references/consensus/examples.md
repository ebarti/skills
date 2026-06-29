# Consensus Examples

Real-world consensus tools, their algorithms, and the coordination patterns they enable.

## Coordination Services

### ZooKeeper (Zab)

**What it is**: Apache ZooKeeper, the original general-purpose coordination service modeled on Google Chubby. Uses the Zab protocol.

**Used by**:
- **Hadoop HDFS NameNode HA** — ZooKeeper Failover Controller (ZKFC) elects active NameNode
- **HBase Master election** and region server tracking
- **Apache Kafka (legacy)** — broker registration, controller election, topic config (replaced by KRaft as of Kafka 2.8+)
- **Apache Spark / Flink** — high-availability mode for the master/JobManager
- **Apache Solr / SolrCloud** — collection state, leader election per shard

**Key primitives**:
- `zxid` — monotonic transaction ID, used as a fencing token
- **Ephemeral nodes** — auto-deleted when the creating session dies (powers leader election + failure detection)
- **Watches** — change notifications

```
# ZooKeeper leader election sketch
session = zk.connect()
my_node = zk.create("/election/leader_", myId, EPHEMERAL_SEQUENTIAL)
# Smallest sequence number is the leader
children = zk.get_children("/election")
if my_node == sorted(children)[0]:
    become_leader()
```

### etcd (Raft)

**What it is**: A distributed key-value store using Raft consensus, written in Go. CoreOS / CNCF project.

**Used by**:
- **Kubernetes control plane** — stores all cluster state (pods, services, configmaps, secrets); the API server reads/writes etcd
- **Rook, Patroni** — distributed PostgreSQL leader election
- **CoreDNS, Vitess, M3DB** — config and metadata

**Key primitives**:
- **Lease** — TTL-based, auto-released on client failure
- **Compare-and-Swap (txn)** — atomic conditional writes
- **Watch** — streamed change notifications
- **Revision number** — monotonic, fencing token equivalent

```
# Kubernetes-style leader election with etcd
lease = etcd.lease(ttl=15)
ok = etcd.put("/leader", my_id, lease=lease, only_if_absent=True)
if ok:
    keep_alive(lease)
    do_leader_work()
```

### Consul (Raft)

**What it is**: HashiCorp's coordination service, also Raft-based. Bundles service discovery, health checking, KV store, and ACLs.

**Used by**:
- **HashiCorp Nomad / Vault** — leader election, secret backend coordination
- **Service discovery** in mixed VM/container environments
- **Distributed configuration** with watch-based reloads

**Distinguishing features**:
- First-class **DNS interface** for service discovery
- Built-in **multi-datacenter federation**
- Health checks integrated with the registry (unhealthy nodes drop out automatically)

## Raft Implementations Embedded in Databases

| System | Algorithm | What Raft Manages |
|--------|-----------|-------------------|
| **etcd** | Raft (etcd-io/raft) | All KV writes |
| **Consul** | Raft | KV writes, leader election |
| **CockroachDB** | Raft (per range) | Per-range replication; thousands of Raft groups in a cluster |
| **TiKV / TiDB** | Raft (per region) | Per-region replication |
| **Yugabyte** | Raft (per tablet) | Per-tablet replication |
| **MongoDB** | Raft-like (replica set protocol v1) | Primary election within a replica set |
| **Elasticsearch** | Raft-like (Zen2, since 7.0) | Cluster state coordination |

## Paxos in Production

### Google Spanner

**What**: Globally distributed SQL database. Uses **Paxos per shard (tablet)** to replicate each shard across datacenters.

**Why Paxos per shard**: Running consensus over thousands of nodes is too slow; per-shard consensus keeps quorums small (typically 3 or 5 replicas) while scaling overall throughput by sharding.

### Google Chubby

**What**: The original lock service that inspired ZooKeeper. Uses Multi-Paxos.

**Used for**: BigTable, GFS, MapReduce coordination at Google.

## Apache Kafka: Two Eras

### Kafka with ZooKeeper (legacy)

ZooKeeper stored:
- Broker registration (ephemeral nodes)
- Controller election (one broker is the controller)
- Topic configuration and ACLs
- Partition leader assignments

The controller used ZooKeeper-elected leadership to coordinate partition leader changes.

### Kafka with KRaft (modern, since 2.8 GA in 3.3)

**KRaft = Kafka Raft**. Kafka built its own Raft implementation and removed the ZooKeeper dependency. Metadata is now stored in an internal Kafka topic replicated via Raft, eliminating the operational complexity of running both Kafka and ZooKeeper.

**Lesson**: Even Kafka, which famously used ZooKeeper for years, eventually adopted Raft directly to simplify ops.

## Single-Leader Replication on Top of Consensus

The standard pattern: use consensus for the slow, critical decision (who is leader), and let the leader handle high-throughput writes directly.

### MongoDB Replica Set

1. Replica set members exchange heartbeats
2. On primary failure, secondaries hold an **election** using a Raft-like protocol (terms, log freshness check)
3. New primary handles all writes; secondaries replicate via the oplog
4. Reads can be served from secondaries (eventual consistency) or primary (linearizable)

### CockroachDB

1. Each table range (~512 MiB) is a Raft group with 3 or 5 replicas
2. Within a range, the Raft leader handles writes
3. SQL layer routes queries to the appropriate range leader
4. Result: Raft handles correctness, sharding handles scale

### Patroni / PostgreSQL HA

1. Patroni agents on each Postgres node
2. **etcd or ZooKeeper** holds the "current primary" key with a TTL lease
3. Whichever Postgres holds the lease is primary; others replicate from it
4. If the primary fails, the lease expires and a new election runs in etcd
5. Failover automated, fencing handled by the lease

## Service Discovery Patterns

| Tool | Discovery Mechanism | Linearizable? |
|------|--------------------|--------------:|
| Consul | DNS + HTTP API + health checks | No (cached) |
| etcd | Watch on a key prefix | Yes if direct read |
| ZooKeeper observers | Stale reads from non-voting replicas | No (intentional) |
| Kubernetes Services | etcd-backed, DNS-fronted (kube-dns/CoreDNS) | DNS layer caches |
| Eureka (Netflix) | AP system, no consensus | No (eventually consistent) |

## Anti-Pattern: Hand-Rolled Coordination

```
# Don't do this
def acquire_lock():
    row = db.query("SELECT * FROM locks WHERE name='resource'")
    if row.holder is None or row.expires_at < now():
        db.execute("UPDATE locks SET holder=?, expires_at=? WHERE name='resource'",
                   me, now() + 30)
        return True
    return False
```

**Problems**:
- Race conditions between SELECT and UPDATE
- No fencing token returned
- Process pause after acquiring → lock expires → another holder → split brain on the protected resource
- Database failover loses lock state

**Fix**: use `etcd.lock("resource")` or ZooKeeper recipe; receive a fencing token; pass it to the storage layer.
