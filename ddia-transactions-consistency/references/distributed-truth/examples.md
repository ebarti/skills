# Knowledge, Truth, and Lies Examples

Real-world scenarios for distributed locking, fencing, BFT, and verification.

## Bad Examples

### HBase distributed lock + zombie writer (the classic)

A real bug that affected HBase in production.

```
// Client 1 acquires lease, then GC pause hits
lease1 = lockService.acquire("region-X")   // lease valid 30s
// ... 45-second GC pause ...
storage.write("region-X", data1)           // ZOMBIE WRITE — lease expired

// Meanwhile, Client 2:
lease2 = lockService.acquire("region-X")   // lock service granted new lease
storage.write("region-X", data2)           // legitimate write
```

**Problems**:
- Storage layer has no way to know client 1's lease expired.
- Both writes succeed; the file is corrupted (split brain).
- STONITH on client 1 wouldn't help if the write packet was already in flight.

### Delayed packet without fencing

```
// Client 1 issues write, then crashes
storage.write("file-x", data1)             // packet delayed 60s on network
// Client 1 dead, lease times out
// Client 2 takes over with new lease and writes data2
// 60 seconds later: client 1's delayed packet finally arrives
// storage applies it — overwrites client 2's correct data
```

**Problems**:
- No process pause involved — pure network delay caused split brain.
- STONITH cannot help here; the client is already gone.

## Good Examples

### Fencing tokens with storage enforcement

```
// Lock service returns monotonic token with each lease
{lease, token: 33} = lockService.acquire("file-x")
// ... pause ...
storage.write("file-x", data1, token=33)   // REJECTED: server saw token 34

// Client 2 acquired in the meantime
{lease, token: 34} = lockService.acquire("file-x")
storage.write("file-x", data2, token=34)   // accepted; server records max=34
```

**Why it works**:
- Storage rejects any token less than the highest seen.
- Zombie writes and delayed packets can't damage data.

### S3 conditional write (precondition)

```python
obj = s3.get_object(Bucket="b", Key="file-x")
etag = obj["ETag"]

s3.put_object(
    Bucket="b", Key="file-x", Body=new_data,
    IfMatch=etag,                          # atomic CAS precondition
)
# Returns 412 Precondition Failed if etag changed
```

**Why it works**:
- S3 enforces the check atomically.
- Equivalent: GCS `x-goog-if-generation-match`, Azure `If-Match` headers.
- If you only write to one CAS-capable store, the store *is* your coordinator.

### ZooKeeper / etcd as distributed coordination

```python
# ZooKeeper ephemeral sequential znode → monotonic IDs
zk.create("/locks/file-x/req-", ephemeral=True, sequence=True)
# returns "/locks/file-x/req-0000000034" → fencing_token = 34
storage.write("file-x", data, token=34)
```

**Why it works**:
- ZooKeeper's `zxid` and `cversion` are monotonic and authoritative.
- Ephemeral znodes auto-release on session loss.
- etcd uses revision number + lease ID for the same purpose.
- Hazelcast's FencedLock API exposes a fencing token explicitly.

### Fencing in leaderless replication (high bits of timestamp)

```
// Embed fencing token in upper bits of timestamp
timestamp = (token << 48) | wallclock_micros

// Client 2 (token 34) writes to all replicas
for r in replicas: r.write("k", v2, ts=(34 << 48) | now)

// Client 1 (token 33, zombie) writes later — ts always smaller
for r in replicas: r.write("k", v1, ts=(33 << 48) | now)

// LWW: any quorum read prefers v2; read-repair fixes lagging replica
```

**Why it works**:
- Token in high bits guarantees new-leaseholder timestamps > old.
- Works even if the zombie reaches a replica the new holder couldn't.

## Byzantine Fault Tolerance Examples

### When BFT IS justified: aerospace

The Boeing 777 flight control system uses BFT across redundant computers — radiation can flip register bits, so the system must outvote any individually-corrupt computer. NASA spacecraft use similar approaches; a wrong response could end the mission or kill people.

### When BFT IS justified: blockchain

Bitcoin and other cryptocurrencies use Byzantine consensus to let mutually distrusting parties agree on transaction history without a central authority. Adversarial participants are expected; supermajority honest assumptions hold the system together.

### When BFT is NOT justified: typical datacenter

Inside a datacenter you control, nodes are trusted. Use traditional auth, encryption, and crash-tolerant consensus (Raft, Paxos) instead. BFT protocols are 10x+ more expensive. Same software on all nodes means same bugs everywhere — BFT can't help.

### Weak-lying defenses (cheap, not full BFT)

```python
# Application-level checksum (catches corruption TCP missed)
payload = serialize(data)
send(payload + crc32(payload))

# NTP with multiple servers — exclude outliers
times = [query(s) for s in ["ntp1","ntp2","ntp3","ntp4","ntp5"]]
consensus_time = exclude_outliers(times)
```

**Why it works**:
- TCP/UDP checksums occasionally miss errors; application checksums catch the rest.
- TLS protects against in-transit corruption AND tampering.
- A misconfigured NTP server appears as an outlier and is excluded.

## Verification Examples

### TLA+ specification (formal methods)

```tla
EXTENDS Naturals, TLC
VARIABLE issuedTokens, requests
Init == issuedTokens = {} /\ requests = 0
GrantToken == requests' = requests + 1
           /\ issuedTokens' = issuedTokens \cup {requests + 1}
Uniqueness == \A t1, t2 \in issuedTokens : (t1 = t2) => (t1 = t2)
```

**Used by**:
- AWS — verified DynamoDB, S3 internals.
- TigerBeetle — TLA+ specs for the OLTP protocol.
- CockroachDB, TiDB, Kafka — caught design bugs before code.
- Original TLA+ spec for viewstamped replication uncovered a data-loss bug hidden in the prose description.

### Jepsen fault injection

```
jepsen test \
  --nodes n1,n2,n3,n4,n5 \
  --workload bank-transfers \
  --nemesis partition,kill,clock-skew \
  --time-limit 600
```

**Found bugs in**: etcd, Consul, MongoDB, Cassandra, Redis Sentinel, Kafka, RabbitMQ, and many more — Jepsen reports are the gold standard for distributed-system honesty.

### Deterministic Simulation Testing

**FoundationDB (application-level)**: built on the *Flow* async library that exposes a deterministic injection point. Tests run thousands of randomized failure scenarios per night against the real database code; any failure is fully replayable.

**TigerBeetle (application-level)**: state-machine + single event loop, mocked clocks/network. Simulates years of operation in minutes; bug hunts run continuously in CI.

**MadSim (Rust runtime-level)**: deterministic Tokio drop-in. Swap async runtime + S3/Kafka libraries with deterministic versions — no application code changes needed.

**Antithesis (machine-level)**: custom hypervisor replaces all nondeterministic OS calls. Run your entire distributed system in containers; the hypervisor branches execution into multiple subexecutions when it discovers rare behavior, exploring more code paths than randomization alone.

**Why DST wins**:
- Tests *real code*, not models.
- Replay any failure exactly.
- Faster than wall-clock (mocked timers fire instantly).
- Explores far more states than handwritten tests or fault injection.
