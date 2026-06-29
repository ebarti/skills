# Choosing a Consensus / Coordination Tool Workflow

Select the right consensus tool (ZooKeeper, etcd, Consul, embedded Raft) for leader election, distributed locks, or linearizable configuration — and avoid using consensus where it doesn't belong.

## When to Use

- Designing a system that needs a single authoritative leader
- Adding distributed locks, leases, or fencing tokens
- Storing small, slow-changing, linearizable cluster metadata
- Replacing a hand-rolled coordination scheme

## Prerequisites

- Confirmed need for fault-tolerant agreement (not eventual consistency)
- Node count target (≥3 for fault tolerance)
- Knowledge of failure-domain layout (AZs, racks, regions)

**Reference**: `references/consensus/rules.md`, `references/consensus/knowledge.md`

---

## Workflow Steps

### Step 1: Confirm consensus is actually needed

**Goal**: Avoid paying the consensus cost for a problem it doesn't solve.

- [ ] Use case is leader election, distributed lock, or linearizable config
- [ ] Workload is **not** high-throughput data writes (every op needs quorum → won't scale)
- [ ] Linearizability is required (eventual consistency is unacceptable)
- [ ] Considered cheaper alternatives (DNS, polled file, primary-with-standby)

**Ask**: "Would a 100ms quorum round-trip on every operation be acceptable?"

**If no**: store data in a regular DB; use consensus only for the leader-election step, then let the leader handle writes at full speed.

**Reference**: `references/consensus/rules.md` (Rule 3, Rule 4)

---

### Step 2: Decide deployment model

**Goal**: Pick standalone coordination service vs embedded Raft library.

- [ ] **Standalone service** (ZK/etcd/Consul) if multiple apps share coordination state, or you want ops separation
- [ ] **Embedded Raft library** (hashicorp/raft, etcd-io/raft) if consensus is internal to your product (CockroachDB, TiKV, KRaft pattern)
- [ ] Verified you are **not rolling your own** consensus protocol

**Ask**: "Is consensus a shared infra concern, or part of my product's control plane?"

**Reference**: `references/consensus/rules.md` (Rule 1), `references/consensus/examples.md` (Embedded Raft table)

---

### Step 3: Match against tool strengths

**Goal**: Pick the standalone service whose ecosystem matches your stack.

- [ ] **ZooKeeper (Zab)** — mature, strong ecosystem in Hadoop/HBase/Solr/legacy Kafka; rich recipe library; ephemeral nodes + watches
- [ ] **etcd (Raft)** — Kubernetes-native, gRPC API, simpler ops, lease-based primitives; default if you're already in the K8s/Go world
- [ ] **Consul (Raft)** — service discovery + KV + health checks bundled; first-class DNS interface; multi-datacenter federation
- [ ] **Embedded Raft** — no external dependency, control plane lives in your product binary

**Reference**: `references/consensus/examples.md` (Coordination Services section)

---

### Step 4: Plan operational topology

**Goal**: Cluster sized and laid out for the failure model you need.

- [ ] Cluster size is **3 or 5** nodes (odd number; 3 → 1 fault, 5 → 2 faults)
- [ ] Members spread across **independent failure domains** (AZs/racks)
- [ ] Failure-detection timeouts tuned for the network (WAN needs higher)
- [ ] Backup + disaster-recovery plan for the consensus state (etcd snapshot, ZK transaction log)
- [ ] Coordination cluster runs on **dedicated nodes**, separate from app nodes
- [ ] Reconfiguration procedure documented (don't edit configs and restart)

**Reference**: `references/consensus/rules.md` (Rule 2, Guidelines)

---

### Step 5: Design client API patterns

**Goal**: Use the right primitives so failures degrade safely.

- [ ] **Leader election**: ephemeral sequential nodes (ZK) or lease + CAS-put (etcd)
- [ ] **Locks**: lease-based with auto-release on session/TTL expiry — never use a plain DB row
- [ ] **Watches**: subscribe to changes; don't poll
- [ ] **Sequential ID generation**: use the service's monotonic counter (zxid, etcd revision)
- [ ] Service-discovery reads are **cached with TTL** (or use ZK observers) — don't hammer consensus per lookup

**Reference**: `references/consensus/examples.md` (Key primitives per tool)

---

### Step 6: Plan fencing strategy

**Goal**: Prevent zombie leaders from corrupting state after failover.

- [ ] Every leader/lock acquisition returns a **monotonic fencing token** (zxid, etcd revision, term number)
- [ ] Token is included on every write to the protected resource
- [ ] Storage layer **rejects writes with a stale token**
- [ ] Unclean leader election kept **disabled** unless data loss is explicitly acceptable

**Ask**: "If the old leader wakes up from a 60-second pause and writes, will the storage reject it?"

**Reference**: `references/consensus/rules.md` (Rule 5, Rule 6)

---

### Step 7: Document choice and topology

**Goal**: Capture the decision so future operators understand it.

- [ ] Tool + version recorded
- [ ] Cluster size, member placement (AZ/rack), and timeout values documented
- [ ] Client primitives in use listed (locks, leases, watches, sequential IDs)
- [ ] Fencing token mechanism + storage-layer enforcement documented
- [ ] Backup and reconfiguration runbooks linked

---

## Decision Tree: Use Case to Tool

```
Need fault-tolerant agreement?
├── No  → Use a regular DB / DNS / polled config; STOP
└── Yes → Continue
    │
    ├── High write throughput (>1k QPS)?
    │   └── Yes → Don't store data in consensus. Use it only for leader election; leader writes to a real DB
    │
    ├── Already on Kubernetes / Go stack?
    │   └── Yes → etcd
    │
    ├── Need service discovery + health checks + multi-DC?
    │   └── Yes → Consul
    │
    ├── In Hadoop / HBase / legacy Kafka / Solr ecosystem?
    │   └── Yes → ZooKeeper
    │
    └── Consensus is internal to your product binary?
        └── Yes → Embedded Raft library (hashicorp/raft, etcd-io/raft)
```

---

## Quick Checklist

```
[ ] Step 1: Confirmed consensus is the right tool (not a fast-data store)
[ ] Step 2: Picked standalone service vs embedded Raft
[ ] Step 3: Matched tool to ecosystem strengths
[ ] Step 4: Sized cluster (3/5), spread across failure domains
[ ] Step 5: Designed client API patterns (locks, leases, watches)
[ ] Step 6: Fencing tokens enforced at the storage layer
[ ] Step 7: Decision and topology documented
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Rolling your own consensus | "Infamously difficult"; many shipped systems are broken | Use ZK/etcd/Consul or a Raft library |
| Using consensus for high-throughput writes | Every op needs quorum; adding nodes makes it slower | Consensus elects the leader; leader writes to a regular DB |
| Locks without fencing tokens | Paused old holder wakes up and corrupts the resource | Pair every lock with a monotonic token rejected by storage |
| Even-numbered cluster (2 or 4) | Same fault tolerance as N-1 odd; wasted node | Use 3 or 5 (odd); maximize faults tolerated per node |
| All quorum members in one rack/AZ | Tolerates 0 datacenter failures | Spread across independent failure domains |
| Enabling unclean leader election by default | Silent data loss on failover | Keep off unless you explicitly accept data loss |
| Treating coordination service as a database | Optimized for small, slow-changing data only | Store user/event data elsewhere |
| Polling consensus for service discovery | Burns quorum capacity; doesn't scale | Cache with TTL, or use ZK observers / DNS |
| Editing config files and restarting to reconfigure | Risk of split brain or quorum loss | Use the tool's reconfiguration API |

---

## Cross-References

- **Consensus**: `references/consensus/rules.md`, `references/consensus/knowledge.md`, `references/consensus/examples.md`
- **Distributed truth**: `references/distributed-truth/rules.md` (epochs, fencing, majority decisions)
- **Linearizability**: `references/linearizability/rules.md` (the consistency model consensus implements)

---

## Exit Criteria

Task is complete when:
- [ ] Tool, cluster size, and topology are decided and documented
- [ ] Fencing strategy is designed and enforced at the storage layer
- [ ] Backup, reconfiguration, and DR runbooks exist
- [ ] No part of the design relies on a hand-rolled consensus protocol
