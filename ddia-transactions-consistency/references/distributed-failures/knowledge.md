# Distributed System Failures Knowledge

Core concepts for understanding why distributed systems fail and what makes them fundamentally different from single-node software.

## Overview

In a single computer, the operation either works or it produces a total failure (kernel panic). In distributed systems, *partial failures* are the norm: some parts work, others don't, and you may not even know which. The network is the only way machines in shared-nothing systems communicate, and that network is fundamentally unreliable.

## Key Concepts

### Partial Failure

**Definition**: A condition where some parts of a distributed system are broken in unpredictable ways while other parts work fine.

**Key points**:
- *Nondeterministic*: same operation may sometimes succeed, sometimes fail
- You may not know whether your operation succeeded
- Makes distributed systems hard, but enables rolling upgrades and fault tolerance

### Network Partition (Split-Brain / Netsplit)

**Definition**: A condition where one part of the network is cut off from the rest due to a network fault.

**Key points**:
- Not fundamentally different from other network interruptions
- Unrelated to data sharding (which is also called "partitioning")
- Can be asymmetric: A↔B works, B↔C works, but A↔C does not
- A node may receive packets but not send them (or vice versa)
- If untested, may deadlock the cluster or cause data loss when the network recovers

### Fail-Stop vs Gray Failure

**Definition**: *Fail-stop* means a node crashes completely and cleanly stops; *gray failure* means a node is partially working — slow, intermittent, or one-directional.

**Key points**:
- Real systems exhibit gray failures more than clean fail-stop
- Examples: NIC drops inbound but sends outbound; node responds slowly due to GC pause
- Gray failures are hardest to detect because the node looks "sometimes alive"

### Timeout

**Definition**: A maximum wait time after which you give up and assume the response will not arrive.

**Key points**:
- The only sure way to detect a fault in an asynchronous network
- Cannot distinguish between "request lost", "response lost", "node crashed", or "node still processing"
- Too short → false positives (declare healthy nodes dead) → cascading failure
- Too long → users wait, slow recovery from real failures

### Fault Detection

**Definition**: Mechanisms to determine whether a remote node is alive, responsive, or dead.

**Sources of feedback**:
- TCP `RST`/`FIN` if process is dead but OS is up
- Crash scripts can notify other nodes (e.g., HBase)
- Switch management interfaces detect link failures
- Routers may send ICMP Destination Unreachable
- Otherwise: timeout + retry is the only signal

### False Positive (Suspecting a Healthy Node)

**Definition**: Incorrectly declaring an alive but slow node as dead.

**Consequences**:
- Action may be performed twice (e.g., email sent twice)
- Load is transferred to other nodes, increasing their load
- Can trigger cascading failure: all nodes declare each other dead
- "When an Overloaded System Won't Recover" — metastable failure

### Asynchronous Packet Network

**Definition**: A network (Ethernet, IP, internet) that gives no guarantees about when or whether a packet will arrive.

**Key points**:
- *Unbounded delays*: no upper limit on packet arrival time
- Packets can be lost, reordered, duplicated, delayed by minutes
- Optimized for *bursty traffic* — variable bandwidth needs

### Synchronous (Circuit-Switched) Network

**Definition**: A network like the traditional telephone system that reserves a fixed bandwidth circuit end-to-end for each call.

**Key points**:
- *Bounded delay*: fixed maximum end-to-end latency, no queueing
- Resource is statically partitioned (16 bits per call per 250µs in ISDN)
- Reliable but expensive — wastes capacity when idle
- Examples: ISDN, ATM, partially InfiniBand

### TCP Limitations

**Definition**: TCP provides reliable byte-stream delivery within a connection, but does not solve the underlying network unreliability.

**What TCP does**: retransmits dropped packets, reorders, checksums, congestion control.

**What TCP does NOT do**:
- Cannot tell if a closed connection processed N or 0 bytes
- Cannot deduplicate across reconnections
- ACK only means kernel received it — application may have crashed
- *Head-of-line blocking*: a single lost packet stalls the entire stream behind it
- Adds queueing delay at the sender (congestion control buffers)

## Terminology

| Term | Definition |
|------|------------|
| Partial failure | Some nodes work, others don't, nondeterministically |
| Netsplit | Network partition cutting a cluster into pieces |
| Unbounded delay | No upper limit on how long a packet may take |
| Bounded delay | Guaranteed maximum end-to-end latency (sync networks) |
| Backpressure | Flow control slowing the sender to avoid overload |
| Jitter | Variability in observed network delays |
| Noisy neighbor | A co-tenant saturating shared resources |
| Phi accrual | Adaptive failure detector based on observed latency |
| Metastable failure | Self-sustaining failure mode that persists after the trigger |

## How It Relates To

- **Distributed Truth**: You can't trust any single node's view; quorums needed
- **Consensus**: Network failures are why consensus is hard (FLP impossibility)
- **Replication & Failover**: Fault detection drives leader election
- **Linearizability**: Network delays make strong consistency expensive

## Common Misconceptions

- **Myth**: TCP makes the network reliable.
  **Reality**: TCP gives reliable byte-stream within a connection. It cannot tell you if the remote application processed your bytes, and dropped connections lose state.

- **Myth**: A working ACK means the request succeeded.
  **Reality**: ACK only confirms the kernel received the packet. The application may have crashed before processing.

- **Myth**: Redundant network gear eliminates faults.
  **Reality**: Studies show human error (misconfigured switches) is a major cause; redundancy doesn't help.

- **Myth**: Network partitions are rare exotic events.
  **Reality**: Studies report ~12 network faults per month in medium datacenters; cloud RTTs of minutes have been observed.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Partial failure | Some nodes work, others don't, you can't tell which |
| Timeout | Best you can do, but cannot distinguish causes |
| Network partition | A↔B works, B↔C works, A↔C does not |
| Async network | No delay guarantees; cheap, high utilization |
| Sync network | Bounded delay via reserved circuits; expensive |
| Phi accrual | Adaptive timeout based on jitter measurements |
