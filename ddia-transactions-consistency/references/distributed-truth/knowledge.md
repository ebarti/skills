# Knowledge, Truth, and Lies in Distributed Systems

Core concepts for reasoning about correctness when nodes cannot directly observe each other's state.

## Overview

A node in a distributed system cannot *know* anything about other nodes — it can only guess from the messages it receives (or doesn't). Truth is established by quorum, leases protect mutual exclusion, fencing tokens stop zombies, and system models bound the assumptions an algorithm relies on.

## Key Concepts

### Quorum (Majority)

**Definition**: A minimum number of votes required to make a decision; most commonly an *absolute majority* (more than half the nodes).

A majority quorum tolerates a minority of faulty nodes (3 nodes tolerate 1, 5 nodes tolerate 2). It is *safe* because two majorities cannot exist simultaneously, so conflicting decisions are impossible. Even node-death decisions require a quorum: a node declared dead by a quorum must step down, even if it feels alive.

### Distributed Lock and Lease

**Definition**: A *lease* is a lock that times out and can be reassigned if the holder stops responding. Used to enforce "only one of X" properties (single leader per shard, single writer per resource, single processor per file).

Leases are commonly granted by a consensus-based lock service (ZooKeeper, etcd, Chubby). The danger: if the holder pauses (GC, scheduler) past the lease timeout, a new holder is granted the lease while the old one still believes it's the owner — *split brain*.

### Zombie Process

**Definition**: A former leaseholder that has not yet learned it lost the lease and continues acting as the current holder.

Zombies cannot be eliminated (you can't reliably notify a paused or partitioned node). They can also arise from delayed network packets — a write sent before the crash arrives at storage *after* the lease was reassigned. Solution: *fence them off* so their writes are rejected.

### Fencing Token

**Definition**: A monotonically increasing number returned by the lock service every time a lease is granted. Every write must include the current token; storage rejects writes whose token is lower than the highest seen.

Storage must enforce the check, or use atomic compare-and-set (CAS) preconditions. Equivalent constructs: Chubby *sequencers*, Kafka *epoch numbers*, Paxos *ballot numbers*, Raft *term numbers*, ZooKeeper `zxid`/`cversion`, etcd revision number.

### Byzantine Fault

**Definition**: A node sends arbitrary, faulty, or maliciously deceptive messages — possibly contradictory votes, fake tokens, or invented state.

The *Byzantine Generals Problem*: n generals must agree despite traitors among them sending false messages. A system is *Byzantine fault-tolerant* (BFT) if it works correctly when some nodes lie. BFT typically requires a *supermajority* (>2/3 of nodes honest).

### Weak Lying

**Definition**: Defenses against unintentional corruption (hardware glitches, OS bugs, misconfiguration) — not full BFT, but cheap and pragmatic.

Examples: application-level checksums (TCP/UDP checksums occasionally miss errors), TLS, input sanitization, NTP clients comparing multiple servers and excluding outliers.

### System Model

**Definition**: The set of assumptions an algorithm makes about timing and node failure modes.

**Timing models**:
- **Synchronous** — bounded delay, pauses, and clock drift. Unrealistic for most real systems.
- **Partially synchronous** — usually synchronous, but timing assumptions may be violated occasionally and arbitrarily. Realistic for most systems.
- **Asynchronous** — no timing assumptions, no clock, no timeouts. Very restrictive.

**Node-failure models**:
- **Crash-stop** (fail-stop) — a failed node never returns.
- **Crash-recovery** — nodes may crash and later recover, with stable storage preserved (in-memory state lost).
- **Degraded performance / fail-slow / gray failure / limping node** — node responds but is too slow or partially broken.
- **Byzantine** — nodes may behave arbitrarily.

For modeling real systems, use **partially synchronous + crash-recovery**.

### Safety vs Liveness

**Safety** = "nothing bad happens." If violated, you can point to the moment it broke; the violation is permanent and cannot be undone (e.g., duplicate fencing tokens issued).

**Liveness** = "something good *eventually* happens." May not hold now but can still be satisfied later (e.g., availability — eventually a response arrives). Often contains the word "eventually" — *eventual consistency* is a liveness property.

Distributed algorithms typically require safety to **always** hold (even if all nodes crash) and allow caveats on liveness (e.g., "if a majority survives and the network eventually recovers").

### Formal Methods

**Definition**: Mathematical specification and proof techniques to show an algorithm satisfies its properties under its system model.

Specifications written in **TLA+**, **Gallina**, or **FizzBee** focus on protocol behavior without implementation details. Used by AWS, FoundationDB, TigerBeetle, CockroachDB, TiDB, Kafka.

### Model Checking

**Definition**: Tools that systematically explore an algorithm's state space to verify invariants hold across all reachable states.

Cannot prove infinite-state algorithms in general — must approximate or bound execution length. Risk: model and implementation drift apart over time.

### Fault Injection

**Definition**: Inject failures (network partitions, crashes, disk corruption, process pauses) into a running system and observe behavior.

Netflix's **Chaos Monkey** popularized injection in production (*chaos engineering*). **Jepsen** is the standard framework — has found critical bugs in many widely-used systems. Limitation: lacks fine-grained replay control.

### Deterministic Simulation Testing (DST)

**Definition**: Run the actual code (not a model) inside a simulator that controls all sources of nondeterminism (network, I/O, clocks, scheduling), enabling exhaustive randomized exploration with exact replay on failure.

Three strategies for determinism:
- **Application-level** — designed in (FoundationDB's Flow, TigerBeetle's state-machine + event loop).
- **Runtime-level** — patch the runtime (FrostDB patches Go's scheduler; Rust's MadSim swaps Tokio).
- **Machine-level** — custom hypervisor (Antithesis) replaces all nondeterministic OS calls.

Faster than wall-clock, replayable, and explores far more states than fault injection.

## Terminology

| Term | Definition |
|------|------------|
| Quorum | Minimum vote count for a decision (usually > n/2) |
| Lease | Time-bounded lock that can be reassigned |
| Zombie | Former leaseholder still acting as holder |
| Fencing token | Monotonic number stamped on every write |
| Split brain | Multiple nodes simultaneously believe they hold a lock |
| STONITH | "Shoot The Other Node In The Head" — forced shutdown to fence; insufficient on its own |
| Byzantine fault | Arbitrary or malicious node behavior |
| BFT | Byzantine fault tolerance (needs >2/3 honest) |
| Safety property | Bad things never happen; permanent if violated |
| Liveness property | Good things eventually happen |
| Partially synchronous | Mostly synchronous, occasionally not |
| Crash-recovery | Nodes can crash and return; stable storage survives |
| TLA+ | Specification language for formal verification |
| DST | Deterministic Simulation Testing |
| Chaos engineering | Production fault injection |

## How It Relates To

- **Consensus** (Ch 10) — quorums and fencing tokens are the building blocks
- **Replication** (Ch 6) — quorum reads/writes use the same majority math
- **Process pauses** — the prime cause of zombies and lease expiry
- **Optimistic concurrency control** — fencing is OCC made permanent

## Common Misconceptions

- **Myth**: STONITH eliminates zombies.
  **Reality**: It can't stop in-flight delayed packets, and racing nodes may shoot each other.
- **Myth**: A lock service alone is enough for mutual exclusion.
  **Reality**: Without fencing tokens enforced at the storage layer, a paused holder will corrupt data.
- **Myth**: BFT protects against bugs and attackers.
  **Reality**: Same code on all nodes = same bug everywhere; same compromise everywhere.
- **Myth**: Stronger system models are safer.
  **Reality**: Stronger models give more guarantees but are harder to satisfy in reality — pick the weakest model your environment satisfies.
