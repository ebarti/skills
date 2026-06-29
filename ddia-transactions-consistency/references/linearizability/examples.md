# Linearizability and Logical Clocks Examples

Concrete scenarios illustrating when linearizability matters, where logical clocks suffice, and the real systems that ship each approach.

## Bad Examples

### Distributed lock without linearizability (split brain)

```
T0: Node A acquires "leader" lease from a follower replica that hasn't replicated
    a recent revoke
T1: Node B acquires the same "leader" lease from the actual leader
T2: Both A and B write to shared storage as "the leader"
    -> data corruption, conflicting updates
```

**Problems**: Lease registry not linearizable; no fencing token at storage; silent corruption.

### Username uniqueness with eventual consistency

```python
# Two replicas, w=1, no read-repair
replica_us.create_user("aaliyah")   # OK
replica_eu.create_user("aaliyah")   # OK
# Async replication later detects the conflict — too late
```

**Problems**: Both writes succeed locally; LWW resolution loses one user's account.

### Cross-channel race (video transcoder)

```
1. Web server uploads video bytes to file storage   (write to leader)
2. Web server enqueues transcode job
3. Transcoder dequeues job and reads video         (read hits a follower)
   -> follower hasn't replicated the upload yet
   -> transcoder either errors or processes empty/old file
```

**Problems**: Message queue races ahead of storage replication; transcoded video permanently inconsistent with original.

### Cassandra LWW with wall-clock timestamps

```
Replica 1 (clock fast 50ms): write "x=1" with ts=1000050
Replica 2 (clock correct):   write "x=2" with ts=1000040  (later in real time!)
Result: x=1 wins because 1000050 > 1000040
```

**Problems**: Clock skew makes ordering arbitrary; real-time-later write silently dropped.

### Lamport timestamp used as a lock

A picks "lowest timestamp wins" — but only knows timestamps it has seen. If B is partitioned, A cannot wait forever to confirm. Fault-tolerant locks need consensus, not logical clocks.

## Good Examples

### Linearizable lock via etcd / ZooKeeper

```python
# etcd v3 — linearizable reads by default
lease = etcd.lease.grant(ttl=10)
acquired = etcd.transaction(
    compare=[etcd.transactions.version("/lock/leader") == 0],
    success=[etcd.transactions.put("/lock/leader", node_id, lease=lease.id)],
    failure=[],
)
if acquired:
    fencing_token = lease.id   # monotonic, pass to storage on every write
    do_leader_work(fencing_token)
```

**Why it works**: Raft consensus gives linearizable CAS; lease ID acts as fencing token.

### Username uniqueness via linearizable CAS

```sql
-- Backed by a single-leader RDBMS or Spanner-class system
INSERT INTO users (username, user_id) VALUES ('aaliyah', :uid);
-- Unique index enforces atomicity; second concurrent insert errors
```

**Why it works**: Single-object CAS on the unique index; Spanner / FoundationDB extend this to strict serializability across regions.

### Lamport timestamps in a chat app

```
Aaliyah counter=0, posts msg → ts=(1, "Aaliyah")
Caleb   counter=0, posts msg → ts=(1, "Caleb")     # concurrent with Aaliyah
Bryce receives both, sets counter=max(0,1)=1
Bryce replies → ts=(2, "Bryce")

Total order: (1,"Aaliyah") < (1,"Caleb") < (2,"Bryce")
```

**Why it works**: Causally consistent (Bryce's reply > messages he saw); cheap; tiebreak by node ID.

### Vector clocks for a shopping cart

```
Cart vector clock: {laptop: 0, phone: 0}

Laptop adds "book"  → {laptop: 1, phone: 0}
Phone  adds "milk"  → {laptop: 0, phone: 1}      # concurrent

Server detects concurrency (neither dominates):
  merged cart = {book, milk}, vc = {laptop: 1, phone: 1}
```

**Why it works**: Concurrency is explicit, so the application can merge instead of overwriting (Dynamo/Riak pattern).

### HLC in CockroachDB / MongoDB

```
Node A physical clock = 1000.000ms, sends write at HLC=(1000.000, 0)
Node B physical clock = 999.500ms, receives → advances HLC to (1000.000, 1)
NTP later jumps Node B physical clock back to 999.800ms
HLC still moves forward → no duplicate timestamps
```

**Why it works**: Wall-clock-readable, monotonic across NTP jumps, causally consistent — no atomic-clock hardware needed.

### CAP example (network partition)

```
Two-region deployment, network between regions cuts:

Single-leader (CP, e.g., Spanner):
  Region without leader → reject writes (unavailable, but consistent)

Multi-leader (AP, e.g., active/active Cassandra):
  Both regions accept writes locally
  When healed → conflicting writes need resolution (LWW or app merge)
```

**Why each fits**: Banking → CP. Shopping cart → AP.

### Linearizable ID generators

```
TiKV timestamp oracle (PD):
  - Single replicated counter (Raft)
  - Allocates batches to amortize replication
  - On crash, advances past batch range (skips, never duplicates)

Snowflake (Twitter/Discord) — NOT strictly linearizable:
  64-bit ID = [timestamp_ms : 41][datacenter : 5][worker : 5][seq : 12]
  Locally generated, no coordination
  Roughly time-ordered if clocks synced
```

**Why each fits**: Timestamp oracle for serializable distributed transactions; Snowflake/ULID for scale when "approximately time-ordered" suffices.

### Real linearizable systems

| System | Mechanism | Notes |
|--------|-----------|-------|
| ZooKeeper | Zab consensus | Linearizable writes; reads need `sync()` |
| etcd | Raft | Linearizable reads default since v3 |
| Spanner | Paxos + TrueTime | Strict serializability across regions |
| FoundationDB | Custom protocol | Strict serializability |
| TigerBeetle | VSR consensus | Strict serializability for accounting |
| CockroachDB | Raft + HLC | Serializable, not strictly linearizable |

## Refactoring Walkthrough

### Before — race between account permission and photo upload

```
User toggles account: public → private    (timestamp ts1, on accounts DB)
User uploads photo                        (timestamp ts2, on photos DB)
ts2 < ts1 because photos DB's HLC was lagging

Viewer reads at ts3 where ts2 < ts3 < ts1:
  Sees photo (uploaded before ts3)
  Sees account as still public (private change at ts1 > ts3)
  → Photo leaked!
```

### After — linearizable ID generator across both writes

```
Both writes go through a single timestamp oracle:
  toggle private → ts1 = oracle.next()
  upload photo   → ts2 = oracle.next()  (guaranteed ts2 > ts1)

Any read at ts3:
  ts3 < ts1: sees old public account, no photo (consistent)
  ts3 ≥ ts2: sees private account and photo (consistent)
```

### Changes Made

1. Replaced per-shard HLC with a linearizable ID source — closes cross-shard ordering gap
2. Real-time order of user actions reflected in DB — no leaked photos
3. Trade-off: ID generator is a single-region bottleneck; mitigate with batched allocation
4. Alternative: keep HLC but have the photos service read account status synchronously before write
