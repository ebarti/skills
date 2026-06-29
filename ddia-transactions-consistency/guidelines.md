# DDIA Transactions and Consistency Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use**: Find your situation below, then load ONLY the listed files. For multi-step decisions, prefer a `workflows/` file over loading raw knowledge.

---

## Workflows

| Task | Workflow |
|------|----------|
| Choose database isolation level (read committed, snapshot, serializable) | `workflows/choosing-isolation-level.md` |
| Diagnose a distributed bug (lost write, stale read, race condition) | `workflows/diagnosing-distributed-bug.md` |
| Design a fault-tolerant distributed system | `workflows/designing-fault-tolerant-system.md` |
| Choose consensus / coordination tool (ZooKeeper, etcd, Consul) | `workflows/choosing-consensus-tool.md` |

---

## By Task

### Transaction Design

| What you're doing | Load these files |
|-------------------|------------------|
| Choosing whether to use a transaction | `acid-fundamentals/knowledge.md` |
| Picking an isolation level | Use `workflows/choosing-isolation-level.md` |
| Handling aborts and retries safely | `acid-fundamentals/rules.md`, `acid-fundamentals/examples.md` |
| Reasoning about ACID guarantees a vendor offers | `acid-fundamentals/knowledge.md`, `acid-fundamentals/rules.md` |
| Designing a transaction that spans multiple objects | `isolation-levels/knowledge.md`, `serializability/knowledge.md` |

### Concurrency Bugs

| What you're doing | Load these files |
|-------------------|------------------|
| Diagnosing a lost update | Use `workflows/diagnosing-distributed-bug.md` (or `isolation-levels/knowledge.md`, `isolation-levels/examples.md`) |
| Diagnosing write skew or phantoms | Use `workflows/diagnosing-distributed-bug.md` (or `isolation-levels/knowledge.md`, `serializability/knowledge.md`, `serializability/examples.md`) |
| Choosing between SSI, 2PL, and serial execution | `serializability/knowledge.md`, `serializability/rules.md` |
| Auditing existing code for race conditions | `isolation-levels/rules.md`, `serializability/rules.md` |

### Distributed Coordination

| What you're doing | Load these files |
|-------------------|------------------|
| Implementing a distributed lock | `distributed-truth/knowledge.md`, `distributed-truth/rules.md`, `distributed-truth/examples.md` |
| Picking a consensus library | Use `workflows/choosing-consensus-tool.md` |
| Implementing leader election | `consensus/knowledge.md`, `consensus/examples.md`, `distributed-truth/rules.md` |
| Storing config or service discovery | `consensus/knowledge.md`, `consensus/rules.md` |
| Achieving uniqueness/CAS guarantees | `linearizability/knowledge.md`, `consensus/knowledge.md` |
| Implementing 2PC or cross-shard transactions | `distributed-transactions/knowledge.md`, `distributed-transactions/rules.md`, `distributed-transactions/examples.md` |

### Distributed Failure Modes

| What you're doing | Load these files |
|-------------------|------------------|
| Designing for network unreliability | Use `workflows/designing-fault-tolerant-system.md` (or `distributed-failures/knowledge.md`, `distributed-failures/rules.md`) |
| Choosing timeout values | `distributed-failures/knowledge.md`, `distributed-time/knowledge.md` |
| Reasoning about clock skew or NTP | `distributed-time/knowledge.md`, `distributed-time/rules.md`, `distributed-time/examples.md` |
| Defending against process pauses (GC, VM migration) | `distributed-time/knowledge.md`, `distributed-truth/knowledge.md` |
| Picking a system model (synchronous, partially synchronous, async) | Use `workflows/designing-fault-tolerant-system.md` (or `distributed-truth/knowledge.md`, `distributed-failures/knowledge.md`) |

---

## By Problem/Symptom

| If you notice... | Load these files |
|------------------|------------------|
| Two updates raced and one was lost | `isolation-levels/knowledge.md`, `isolation-levels/examples.md` |
| Doctor on-call write skew, two users booked same room | `isolation-levels/knowledge.md`, `serializability/knowledge.md`, `serializability/examples.md` |
| Distributed lock failed and two nodes wrote | `distributed-truth/knowledge.md`, `distributed-truth/rules.md` (fencing tokens) |
| Clock skew causing weird ordering | `distributed-time/knowledge.md`, `distributed-time/examples.md` |
| Some replicas show old data | `linearizability/knowledge.md`, `linearizability/rules.md` |
| Need to elect a leader / coordinate config | `consensus/knowledge.md`, `consensus/examples.md` |
| Cross-shard transaction needed | `distributed-transactions/knowledge.md`, `distributed-transactions/examples.md` |
| Network partition and we can't tell | `distributed-failures/knowledge.md`, `distributed-failures/examples.md` |
| Process pauses for 30 seconds | `distributed-time/knowledge.md`, `distributed-time/rules.md` |
| Should I use ZooKeeper, etcd, or Consul? | Use `workflows/choosing-consensus-tool.md` |
| Read-after-write violation | `linearizability/knowledge.md` |
| 2PC coordinator stuck "in doubt" | `distributed-transactions/knowledge.md`, `distributed-transactions/rules.md` |
| Phantoms in a serializable transaction | `serializability/knowledge.md`, `isolation-levels/examples.md` |
| Constraint violation that can't be detected with snapshot isolation | `isolation-levels/knowledge.md`, `serializability/knowledge.md` |

---

## By Topic

Each category has the same three files: `knowledge.md`, `rules.md`, `examples.md`.

| Topic | Directory | Covers |
|-------|-----------|--------|
| ACID fundamentals | `acid-fundamentals/` | Atomicity, consistency, isolation, durability — what they actually mean |
| Isolation levels (weak) | `isolation-levels/` | Read committed, snapshot isolation, lost update, write skew, phantoms |
| Serializability | `serializability/` | Serial execution, 2PL, SSI |
| Distributed transactions | `distributed-transactions/` | 2PC, XA, atomic commit across nodes |
| Distributed failures | `distributed-failures/` | Partial failure, network partitions, faults |
| Distributed time | `distributed-time/` | Wall vs monotonic clocks, NTP, process pauses |
| Distributed truth | `distributed-truth/` | Quorums, leases, zombies, fencing tokens, system models |
| Linearizability | `linearizability/` | Strong consistency, CAP, logical clocks |
| Consensus | `consensus/` | Paxos/Raft, ZooKeeper, etcd, leader election |

---

## Decision Tree

```
START
│
├─► Picking an isolation level
│   ├─► Single-row writes only? → read committed (default in most DBs)
│   │       Load: isolation-levels/knowledge.md
│   ├─► Multi-statement read of moving data? → snapshot isolation / RR
│   │       Load: isolation-levels/knowledge.md, isolation-levels/rules.md
│   ├─► Concurrent updates of same row? → snapshot isolation + SELECT FOR UPDATE,
│   │   atomic compare-and-set, or serializable
│   │       Load: isolation-levels/examples.md (lost update)
│   ├─► Reads-then-writes on a SET of rows (booking, balance check)?
│   │   → serializable (SSI preferred); SI cannot prevent write skew
│   │       Load: serializability/knowledge.md, serializability/examples.md
│   └─► Need cross-shard or cross-system atomicity?
│           Load: distributed-transactions/knowledge.md
│
├─► Choosing a consensus tool
│   ├─► Need to elect a leader / store cluster metadata
│   │   ├─► Already on Kubernetes? → etcd (it's already there)
│   │   ├─► JVM ecosystem, complex coordination? → ZooKeeper
│   │   ├─► Service discovery + KV + DNS? → Consul
│   │   └─► Embedded (no extra service)? → Raft library (e.g., raft.io)
│   │       Load: consensus/knowledge.md, consensus/rules.md
│   ├─► Need linearizable reads/writes on small data → any of above
│   │       Load: linearizability/knowledge.md
│   └─► Need consensus over high-throughput data → don't; shard and use
│       consensus only for control-plane decisions
│           Load: consensus/rules.md
│
└─► Designing a distributed lock
    ├─► Resource is a remote service (file, DB row, billable API)?
    │   → MUST use fencing tokens
    │       Load: distributed-truth/knowledge.md (fencing token), examples.md
    ├─► Resource is local CPU/RAM only? → in-process mutex; lease still
    │   needs fencing if any I/O happens during the critical section
    │       Load: distributed-truth/rules.md
    └─► Single-leader semantics for a shard or partition?
        → use consensus service (etcd/ZK) + leases + fencing tokens
            Load: consensus/knowledge.md, distributed-truth/rules.md
```

---

## File Index

Complete list of all 27 knowledge files:

### ACID Fundamentals
| File | Purpose |
|------|---------|
| `acid-fundamentals/knowledge.md` | What atomicity, consistency, isolation, durability really mean |
| `acid-fundamentals/rules.md` | Do/don't rules around aborts, retries, ACID claims |
| `acid-fundamentals/examples.md` | Concrete transaction scenarios |

### Isolation Levels
| File | Purpose |
|------|---------|
| `isolation-levels/knowledge.md` | Read committed, snapshot isolation, lost update, write skew, phantoms |
| `isolation-levels/rules.md` | When each level is safe; when to escalate |
| `isolation-levels/examples.md` | Concrete race conditions and their fixes |

### Serializability
| File | Purpose |
|------|---------|
| `serializability/knowledge.md` | Serial execution, 2PL, SSI implementation strategies |
| `serializability/rules.md` | When to choose each strategy; trade-offs |
| `serializability/examples.md` | Write skew under SI vs serializable; SSI in action |

### Distributed Transactions
| File | Purpose |
|------|---------|
| `distributed-transactions/knowledge.md` | Atomic commit, 2PC phases, XA, coordinator failure |
| `distributed-transactions/rules.md` | When to use 2PC; when to avoid it |
| `distributed-transactions/examples.md` | Cross-shard and DB+queue commit examples |

### Distributed Failures
| File | Purpose |
|------|---------|
| `distributed-failures/knowledge.md` | Partial failure, network partitions, asymmetric faults |
| `distributed-failures/rules.md` | Defensive coding, timeouts, retries |
| `distributed-failures/examples.md` | Real-world failure modes and how to handle them |

### Distributed Time
| File | Purpose |
|------|---------|
| `distributed-time/knowledge.md` | Wall vs monotonic clocks, NTP, process pauses, clock skew |
| `distributed-time/rules.md` | Which clock to use when; safety bounds on timeouts |
| `distributed-time/examples.md` | Bugs caused by clock confusion; correct patterns |

### Distributed Truth
| File | Purpose |
|------|---------|
| `distributed-truth/knowledge.md` | Quorums, leases, zombies, fencing tokens, Byzantine, system models |
| `distributed-truth/rules.md` | Always-fence, always-quorum rules; system-model commitments |
| `distributed-truth/examples.md` | Fencing tokens in storage; HBase incident pattern |

### Linearizability
| File | Purpose |
|------|---------|
| `linearizability/knowledge.md` | Strong consistency, CAP, logical clocks (Lamport, vector) |
| `linearizability/rules.md` | When linearizability is required vs. wasteful |
| `linearizability/examples.md` | Read-after-write, uniqueness, lost-update via CAS |

### Consensus
| File | Purpose |
|------|---------|
| `consensus/knowledge.md` | Paxos/Raft, FLP, equivalence of leader election & atomic broadcast |
| `consensus/rules.md` | When to use a consensus service; when not to |
| `consensus/examples.md` | ZooKeeper/etcd usage, leader election, distributed locks |

---

## Common Combinations

Frequently used together:

| Scenario | Files to load |
|----------|---------------|
| Building a safe distributed lock | `distributed-truth/knowledge.md` + `distributed-truth/rules.md` + `consensus/knowledge.md` |
| Diagnosing write skew | `isolation-levels/knowledge.md` + `serializability/knowledge.md` + `serializability/examples.md` |
| Reviewing a cross-shard transaction | `distributed-transactions/knowledge.md` + `distributed-transactions/rules.md` + `linearizability/knowledge.md` |
| Auditing for distributed-system assumptions | `distributed-failures/knowledge.md` + `distributed-time/knowledge.md` + `distributed-truth/knowledge.md` |
| Choosing strong vs. eventual consistency | `linearizability/knowledge.md` + `linearizability/rules.md` + `consensus/knowledge.md` |
