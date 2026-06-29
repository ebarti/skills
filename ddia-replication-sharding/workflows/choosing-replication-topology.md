# Choosing Replication Topology Workflow

Decide between single-leader, multi-leader, and leaderless replication based on workload, geography, availability, and consistency requirements.

## When to Use

- Designing a new replicated data system
- Re-evaluating an existing topology after scaling pain
- Adding a new region or offline-capable client tier
- Justifying a topology choice in an architecture review

## Prerequisites

- Read/write ratio estimate (rough order of magnitude)
- Knowledge of geographic deployment (single region vs multi-region)
- Understanding of consistency requirements from product/business
- Awareness of failure modes the system must tolerate

**Reference**: `references/single-leader-replication/rules.md`, `references/multi-leader-replication/rules.md`, `references/leaderless-replication/rules.md`

---

## Workflow Steps

### Step 1: Characterize the Workload

**Goal**: Gather inputs that drive topology choice.

- [ ] Write read/write ratio (e.g., 100:1 read-heavy, 1:1 mixed)
- [ ] List regions where writes must originate
- [ ] Identify offline-write requirements (mobile, IoT, edge)
- [ ] Decide consistency tolerance (linearizable, read-your-writes, eventual)
- [ ] Note throughput target and tail-latency budget
- [ ] List external systems that consume DB-generated IDs

**Ask**: "Where do writes happen, and how stale can a read be before users notice?"

---

### Step 2: Default to Single-Leader

**Goal**: Start from the simplest topology that handles ~90% of cases.

- [ ] Assume single-leader unless a hard requirement disqualifies it
- [ ] Confirm one primary region accepts writes; linearizable writes wanted
- [ ] If single-leader fits, skip to Step 5 (sync mode)

**Reference**: `references/single-leader-replication/rules.md`

---

### Step 3: Consider Multi-Leader

**Goal**: Adopt multi-leader only when single-leader cannot meet requirements.

- [ ] Multi-region writes needed for latency or residency? → candidate
- [ ] Devices must read/write while offline (notes, calendar, mobile)? → required
- [ ] Real-time collaboration on shared documents? → required (each tab is a leader)
- [ ] Confirm you are NOT considering multi-leader within a single datacenter (anti-pattern)
- [ ] Pick all-to-all topology unless a specific reason demands circular/star

**Ask**: "Can I answer this with single-leader instead?" If yes, do.

**Reference**: `references/multi-leader-replication/rules.md`

---

### Step 4: Consider Leaderless

**Goal**: Use leaderless when high availability outweighs strong consistency.

- [ ] Need writes during partitions / any-node failures? → candidate
- [ ] Workload matches Dynamo-style key-value (small records, no joins)? → fits
- [ ] Comfortable with quorum-level (not linearizable) consistency? → required
- [ ] Choose `n`, `w`, `r` such that `w + r > n` (e.g., n=3, w=2, r=2)
- [ ] Decide on sloppy quorum + hinted handoff for partition tolerance

**Reference**: `references/leaderless-replication/rules.md`

---

### Step 5: Pick Sync vs Async

**Goal**: Trade durability against write latency and availability.

- [ ] **Sync** (single-leader): durable on follower, but a stalled follower halts writes
- [ ] **Async** (single-leader): fast writes, but failover may lose recent writes
- [ ] **Semisynchronous**: one sync follower + rest async — pragmatic default
- [ ] **Multi-leader**: must be async (sync collapses to single-leader)
- [ ] **Leaderless**: tunable per-request via `w` (higher = durable, slower)
- [ ] Document chosen mode and the failure scenarios it accepts

**Reference**: `references/single-leader-replication/rules.md` (Rule 1)

---

### Step 6: Plan Failover or Quorum Configuration

**Goal**: Define the runtime behavior under node loss.

**If single-leader**:
- [ ] Decide manual vs automatic failover
- [ ] Set timeout (start ~30s, tune from observed behavior)
- [ ] Choose follower with highest LSN; implement fencing to prevent split-brain
- [ ] Use UUIDs (not autoincrement) for IDs shared with external systems

**If leaderless**:
- [ ] Confirm `w + r > n`; document the tolerated node-loss count
- [ ] Enable read repair + anti-entropy / repair process
- [ ] Set up monitoring for pending hints (proxy for staleness)

**Reference**: `references/single-leader-replication/rules.md` (Rules 5–7), `references/leaderless-replication/rules.md` (Rules 1, 6)

---

### Step 7: Plan Conflict Resolution (Multi-Leader / Leaderless)

**Goal**: Define how concurrent writes converge.

- [ ] Pick strategy: LWW, manual merge, or CRDT
- [ ] Use version vectors (not wall-clock timestamps) for causal ordering
- [ ] For multi-leader: do not rely on cross-leader uniqueness/invariants
- [ ] See `workflows/handling-replication-conflicts.md` and `references/conflict-resolution/`

---

### Step 8: Document Choice + Consistency Model

**Goal**: Make the topology, tradeoffs, and consistency contract explicit for reviewers and on-call.

- [ ] Record chosen topology and why each alternative was rejected
- [ ] Write the acknowledged consistency model (eventual, read-your-writes, monotonic, linearizable)
- [ ] List failure scenarios the design tolerates (and which it does not)
- [ ] Note any external-system coupling risks (e.g., IDs in caches)
- [ ] Cross-reference linearizability/consensus discussion if stronger guarantees are claimed

**Cross-skill reference**: `ddia-transactions-consistency` — linearizability and consensus

---

## Quick Checklist

```
[ ] Step 1: Workload characterized (reads, writes, regions, consistency tolerance)
[ ] Step 2: Single-leader default considered first
[ ] Step 3: Multi-leader evaluated (multi-region / offline / collab only)
[ ] Step 4: Leaderless evaluated (HA over consistency, key-value)
[ ] Step 5: Sync vs async decided
[ ] Step 6: Failover or quorum config defined
[ ] Step 7: Conflict resolution chosen (if multi-leader/leaderless)
[ ] Step 8: Topology + consistency model documented
```

---

## Decision Tree

```
Need offline writes OR real-time collab on shared docs?
  yes -> Multi-leader (each device/tab is a leader; async only)
  no  -> Need writes in multiple regions for latency/residency?
           yes -> Multi-leader (one leader per region, all-to-all)
           no  -> Need writes during ANY node failure (HA > consistency)?
                    yes -> Leaderless (Dynamo-style; w + r > n)
                    no  -> Single-leader (default; semisync recommended)
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Multi-leader inside a single datacenter | Conflict + causality complexity for no latency win | Single-leader + sharding for write throughput |
| Expecting linearizability from `w + r > n` | Sloppy quorums, concurrent ops, clock skew break it | Use single-leader (or consensus) for linearizable reads |
| All followers synchronous | One slow follower halts every write | Use semisynchronous (1 sync + rest async) |
| Wall-clock timestamps for ordering | Clock skew silently drops writes (LWW data loss) | Version vectors for causal order |
| Sharing autoincrement IDs with external systems | Failover discards reuse IDs (GitHub/Redis incident) | UUIDs or globally-unique IDs |
| Sync multi-leader replication | Collapses to single-leader latency without benefits | Always async for multi-leader |
| Skipping conflict resolution design | Concurrent writes silently lost or corrupted | Pick LWW / CRDT / manual merge up front |
| Treating "eventual" as "soon" | Lag can be hours; users hit it in production | Monitor lag explicitly; bound staleness in SLOs |

---

## Exit Criteria

Task is complete when:
- [ ] Topology chosen and documented with rejection reasons for alternatives
- [ ] Sync/async mode decided and failure scenarios listed
- [ ] Failover plan or quorum config written down
- [ ] Conflict resolution strategy chosen (if multi-leader/leaderless)
- [ ] Consistency model published for application developers and on-call

---

## Cross-References

- Within: `references/{single-leader,multi-leader,leaderless}-replication/rules.md`, `references/conflict-resolution/`, `workflows/handling-replication-conflicts.md`
- Other skill: `ddia-transactions-consistency` — linearizability and consensus
