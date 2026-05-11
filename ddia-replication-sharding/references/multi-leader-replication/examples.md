# Multi-Leader Replication Examples

Real systems, use cases, and topology diagrams for multi-leader replication.

## Real Database Systems

### Built-in or supported multi-leader

| System | Notes |
|--------|-------|
| MySQL Group Replication | Built-in multi-leader option |
| Oracle | Multi-leader supported in some configurations |
| SQL Server | Multi-leader supported via peer-to-peer transactional replication |
| YugabyteDB | Distributed SQL with multi-leader options |
| CouchDB | Designed around multi-leader sync; popular for offline-first apps |
| BDR for PostgreSQL | EDB Postgres Distributed; multi-leader add-on |
| pglogical | PostgreSQL multi-leader add-on |
| Redis Enterprise | Active-active geo-distributed via CRDTs |

### Sync engines (client-side multi-leader)

| System | Backend | Notes |
|--------|---------|-------|
| Replicache | Pluggable | Sync engine for web apps |
| Linear | Proprietary | Project management with real-time + offline |
| Notion | Proprietary | Docs with offline editing |
| Figma | Proprietary | Real-time collaborative graphics |
| Google Firestore | Proprietary | Mobile/web sync engine |
| Realm | Proprietary | Mobile-first sync database |
| Ditto | Proprietary | Edge/peer-to-peer sync |
| PouchDB / CouchDB | Open source | Local replica syncing to CouchDB-compatible server |
| Automerge | Open source | CRDT library for local-first software |
| Yjs | Open source | CRDT for shared editing |

## Use Case Examples

### Multi-region geo-distributed database

Two regions, each with a leader and follower; leaders replicate to each other async.

- Bank with branches in US and EU, each writing locally
- Online retailer with regional storefronts
- Compliance/data-residency: writes stay in-region; cross-region sync for analytics

### Calendar app across devices

Phone, laptop, and tablet each have a local replica that accepts writes.

- Add a meeting on the phone in airplane mode
- Edit the same meeting on the laptop while online
- Both changes sync when the phone reconnects; conflict resolution merges them

### Real-time collaboration apps

Multiple users editing the same document; each browser tab is a leader replica.

- Google Docs / Google Sheets
- Notion document editing
- Figma design files
- Linear issue tracking
- Each local edit shows immediately; remote edits stream in async

### Local-first apps via open protocols

Apps where users can switch providers because the protocol is open.

- Git: collaborate via GitHub, GitLab, Codeberg, self-hosted, etc.
- CouchDB-based apps: any CouchDB-compatible server works
- Yjs/Automerge apps: bring-your-own backend

## Topology Diagrams (ASCII)

### Two leaders (only one possible topology)

```
   +---------+              +---------+
   | Leader  |  <-------->  | Leader  |
   |    A    |              |    B    |
   +---------+              +---------+
        |                        |
   +---------+              +---------+
   | Follower|              | Follower|
   +---------+              +---------+
```

### Circular topology (3+ leaders)

```
        Leader 1
       /        \
      v          ^
   Leader 2 --> Leader 3
```

Each node forwards writes to one neighbor. Risk: if Leader 2 fails, the ring breaks until reconfigured.

### Star topology

```
            Leader A (root)
           /    |    \
          v     v     v
      Leader B Leader C Leader D
```

One designated root forwards writes to all others. Risk: root is a single point of failure.

### All-to-all (mesh) topology

```
       Leader 1 <-----> Leader 2
          ^   \         /   ^
          |    \       /    |
          |     v     v     |
          |     Leader 3    |
          |     ^     ^     |
          |    /       \    |
          v   /         \   v
       Leader 4 <-----> [...]
```

Every leader sends to every other. Best fault tolerance; vulnerable to causality bugs from messages overtaking each other.

## Causality Bug Example

```
Client A on Leader 1:  INSERT row r              ----+
                                                     |
Client B on Leader 3:  UPDATE row r SET ...      --+ |
                                                   | |
At Leader 2 (slow path from L1, fast path from L3):| |
                                                   | |
   1. Receives UPDATE r  (row doesn't exist yet) <-+ |
   2. Receives INSERT r  (too late)               <--+
```

The update arrives before the insert it depends on. Wall-clock timestamps cannot fix this reliably; version vectors can.

## Anti-Examples (Don't Do This)

### Multi-leader within a single datacenter for "scaling writes"

Use sharding with single-leader per shard instead. Multi-leader inside one region adds conflict-handling complexity for little gain.

### Relying on autoincrement IDs across leaders

Two leaders can both assign id=42. Use UUIDs, snowflake IDs, or pre-allocated per-leader ranges.

### Enforcing unique usernames across regions with multi-leader

Two regions can both register the same username concurrently. If you need uniqueness, route registrations through a single leader.

### Synchronous multi-leader

If A must wait for B to commit, the configuration is equivalent to single-leader with B as leader. Use async or use single-leader explicitly.

## Cross-Reference

For conflict detection and merge strategies (last-write-wins, CRDTs, version vectors, manual resolution), see `../conflict-resolution/`.
