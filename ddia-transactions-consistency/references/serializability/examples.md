# Serializability Examples

Real engines, code sketches, and failure modes for serializable isolation.

## Real Engine Map

| Engine | Serializable Isolation Mechanism |
|--------|----------------------------------|
| VoltDB / H-Store | Single-threaded serial execution + stored procedures + sharding |
| Redis | Single-threaded serial execution + Lua scripts |
| Datomic | Single-threaded serial execution + Java/Clojure stored procedures |
| MySQL / InnoDB | 2PL + index-range (next-key) locks |
| SQL Server (default engine) | 2PL |
| Db2 | 2PL (used at repeatable-read level) |
| PostgreSQL (Serializable) | SSI |
| SQL Server In-Memory OLTP / Hekaton | SSI variant |
| HyPer | SSI variant |
| CockroachDB | SSI (distributed) |
| FoundationDB | SSI (distributed; conflict detection sharded across machines) |
| BadgerDB | SSI (embedded) |

## Stored Procedure Sketch (Serial Execution)

A transaction submitted to the database ahead of time, executed entirely server-side:

```javascript
// Conceptual VoltDB-style stored procedure (deterministic)
function transferFunds(fromAccount, toAccount, amount) {
  const from = sql("SELECT balance FROM accounts WHERE id = ?", fromAccount);
  if (from.balance < amount) {
    abort("Insufficient funds");
  }
  sql("UPDATE accounts SET balance = balance - ? WHERE id = ?", amount, fromAccount);
  sql("UPDATE accounts SET balance = balance + ? WHERE id = ?", amount, toAccount);
}
```

**Why it works**:
- Entire flow runs on a single thread without network round-trips
- No locks needed because no other transaction runs concurrently
- Deterministic, so it can be replayed on replicas (state-machine replication)

**Bad alternative (interactive transaction under serial execution)**:

```python
# DO NOT do this against a serial-execution engine
with db.begin():
    row = db.execute("SELECT balance FROM accounts WHERE id = %s", from_id).one()
    # network round-trip 1 — database is idle, blocking everyone
    if row.balance < amount:
        raise InsufficientFunds()
    db.execute("UPDATE accounts SET balance = balance - %s WHERE id = %s", amount, from_id)
    # network round-trip 2 — database still idle
    db.execute("UPDATE accounts SET balance = balance + %s WHERE id = %s", amount, to_id)
```

**Problem**: Throughput dreadful — single thread waits on network for the application between every statement.

## Deadlock Scenario (Two-Resource Cycle, 2PL)

Classic deadlock under 2PL serializable:

```sql
-- Transaction A
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;  -- exclusive lock on row 1
-- ... pause ...
UPDATE accounts SET balance = balance + 100 WHERE id = 2;  -- waits for row 2

-- Transaction B (concurrent)
BEGIN;
UPDATE accounts SET balance = balance - 50 WHERE id = 2;   -- exclusive lock on row 2
-- ... pause ...
UPDATE accounts SET balance = balance + 50 WHERE id = 1;   -- waits for row 1
```

**Outcome**: A holds row 1 and waits for row 2; B holds row 2 and waits for row 1. The database detects the cycle and aborts one transaction. The application must retry the aborted transaction from scratch.

**Mitigation**: Acquire locks in a consistent global order (e.g., always lower account ID first).

## Predicate Lock vs. Index-Range Lock

Meeting room booking — must prevent phantom inserts in the queried time window.

```sql
SELECT * FROM bookings
 WHERE room_id = 123
   AND end_time   > '2026-05-11 12:00'
   AND start_time < '2026-05-11 13:00';
```

**Predicate lock (conceptual)**: Lock matches `room_id = 123` between noon and 1 p.m., even rows that don't exist yet.

**Index-range lock approximations** (any one is safe):
- Lock on `room_id = 123` for any time
- Lock on all rooms between noon and 1 p.m.
- If no usable index: shared lock on the entire `bookings` table (safe but kills concurrency)

**Why over-approximation is safe**: Any write matching the original predicate also matches the broader approximation, so phantoms remain blocked.

## SSI — True Conflict (Stale MVCC Read)

Two transactions where T43's write depends on a premise that T42 invalidated:

```
Time -->
T42:  begin --- UPDATE doctors SET on_call=false WHERE name='Aaliyah' --- commit
T43:  begin -- read doctors (sees Aaliyah on_call=true, ignores T42's uncommitted write)
                                    -- decides "two doctors on call, OK to go off"
                                    -- UPDATE doctors SET on_call=false WHERE name='Bob'
                                    -- COMMIT  ABORT (T42 committed in the meantime)
```

**Result**: T43 aborts at commit because the write it ignored under MVCC has now committed; its premise ("two doctors on call") is no longer true. Application retries T43.

## SSI — Detecting Writes That Affect Prior Reads (Tripwire)

Both transactions read the same range, then both try to write within it:

```
Time -->
T43: read shift 1234  (index-range tripwire records: T43 read shift_id=1234)
T42: read shift 1234  (tripwire records: T42 read shift_id=1234)
T43: write to shift 1234   --> notifies T42 its read may be stale
T42: write to shift 1234   --> notifies T43 its read may be stale
T42: commit  -- succeeds (T43's write hasn't committed yet)
T43: commit  -- aborts (T42's conflicting write has committed)
```

**Key**: SSI's "lock" is a tripwire — it does NOT block; it just records that a read happened so commit-time can detect the conflict.

## SSI — False Positive (Unnecessary Abort)

SSI tracks reads at index-range granularity. If two transactions touch the same index entry but logically don't conflict (e.g., different rows that happen to share an index page or range), SSI may abort one anyway.

**Tradeoff**: Coarser tracking = faster bookkeeping but more false-positive aborts. Finer tracking = fewer aborts but heavier overhead. PostgreSQL applies extra theory to suppress some unnecessary aborts.

## Real-World Performance Notes

- **VoltDB cross-shard throughput**: ~1,000 writes/sec — orders of magnitude below single-shard, and cannot be improved by adding machines.
- **VoltDB single-shard throughput**: Scales linearly with CPU cores when each shard runs on its own core.
- **2PL latency**: Unstable, especially at high percentiles, when contention exists. A single big read can block all writers for the duration of the read.
- **2PL deadlock rate**: Much higher under serializable than under read-committed.
- **SSI overhead**: Small relative to plain snapshot isolation; debate continues whether it justifies the cost in low-contention workloads (some say always use SSI; others say snapshot isolation is enough).
- **FoundationDB**: Distributes SSI conflict detection across machines, scaling beyond a single CPU core unlike serial execution.

## Refactoring Walkthrough — Interactive Transaction to Stored Procedure

### Before (interactive, latency-bound, won't work under serial execution)

```python
with db.begin():
    seats = db.execute("SELECT seat_id FROM seats WHERE flight=%s AND status='available'", flight)
    chosen = pick_seat(seats.all())   # application logic
    db.execute("UPDATE seats SET status='booked', passenger=%s WHERE seat_id=%s", pid, chosen)
```

### After (stored procedure, serial-execution-friendly)

```sql
CREATE PROCEDURE book_seat(flight INT, passenger INT)
LANGUAGE plpgsql AS $$
DECLARE chosen INT;
BEGIN
  SELECT seat_id INTO chosen FROM seats
   WHERE flight = book_seat.flight AND status = 'available'
   ORDER BY seat_id LIMIT 1 FOR UPDATE;
  IF chosen IS NULL THEN RAISE 'no_seats'; END IF;
  UPDATE seats SET status='booked', passenger=book_seat.passenger
   WHERE seat_id = chosen;
END $$;
```

### Changes Made

1. Whole flow moved server-side — no network round-trips between statements
2. Selection logic deterministic (`ORDER BY seat_id LIMIT 1`) so it can be replicated
3. No application-side decision inside the transaction window
