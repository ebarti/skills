# Weak Isolation Levels Examples

Concrete scenarios showing each anomaly and its mitigation.

## Bad Examples

### Dirty Read: Banking Balance Flicker

```
T1: SET x = 3            -- not committed
T2: GET x  -> 3          -- dirty read!
T1: ROLLBACK             -- T2 saw a value that never existed
```

**Problems**: T2 made decisions on never-committed data. If T2 also wrote, it must abort -> cascading aborts.

### Dirty Write: Used-Car Sale Mismatch

Two writes per buyer (listing + invoice) interleave.

```
T_aaliyah: UPDATE listings SET buyer = 'Aaliyah'
T_bryce:   UPDATE listings SET buyer = 'Bryce'      -- wins
T_aaliyah: UPDATE invoices SET to = 'Aaliyah'       -- wins
T_bryce:   UPDATE invoices SET to = 'Bryce'
```

**Problems**: Sale to Bryce, invoice to Aaliyah. Read committed prevents this via row-level write locks.

### Lost Update: Counter Increment Race

```sql
-- T1
SELECT counter FROM stats WHERE k = 'views';   -- 42
UPDATE stats SET counter = 43 WHERE k = 'views';

-- T2 (interleaved)
SELECT counter FROM stats WHERE k = 'views';   -- 42
UPDATE stats SET counter = 43 WHERE k = 'views';
```

**Problems**: Final counter = 43, should be 44. Read committed does NOT prevent this.

### Read Skew: Money That Vanishes

Aaliyah has $500 + $500, $100 transfer in flight.

```
Reader: SELECT balance WHERE id = 1;   -- 500 (pre-transfer)
Transfer commits: id 1 -> 400, id 2 -> 600.
Reader: SELECT balance WHERE id = 2;   -- 600 (post-transfer)
Observed total = $1100.
```

**Problems**: Acceptable under read-committed but breaks backups/analytics. Snapshot isolation fixes this.

### Write Skew: Doctor On-Call (Canonical Example)

Constraint: at least one doctor must be on call.

```sql
-- Both run under snapshot isolation, both see 2 doctors on call.

-- T_aaliyah                                  -- T_bryce (concurrent)
BEGIN;                                         BEGIN;
SELECT count(*) FROM doctors                   SELECT count(*) FROM doctors
  WHERE on_call AND shift_id = 1234;  -- 2      WHERE on_call AND shift_id = 1234;  -- 2
UPDATE doctors SET on_call = false             UPDATE doctors SET on_call = false
  WHERE name = 'Aaliyah';                       WHERE name = 'Bryce';
COMMIT;                                         COMMIT;
```

**Problems**: Both commit. Zero doctors on call. Two different rows updated -> not a lost update. Snapshot isolation does NOT detect this.

### Phantom: Username Uniqueness Race

```sql
-- T1 and T2 (concurrent, same flow)
SELECT id FROM users WHERE username = 'eloi';  -- empty
INSERT INTO users (username) VALUES ('eloi');
COMMIT;
```

**Problems**: Both see "no row," both insert. `SELECT FOR UPDATE` cannot lock rows that don't exist.

## Good Examples

### Atomic Counter Increment

```sql
UPDATE stats SET counter = counter + 1 WHERE k = 'views';
```

**Why it works**: DB takes exclusive row lock for the duration. No read-modify-write race in app code.

### CAS / Optimistic Locking

```sql
UPDATE wiki
SET content = $new_content, version = version + 1
WHERE id = $id AND version = $expected_version;
-- check rowcount; retry on 0
```

**Why it works**: Update only fires if version unchanged. Note: many MVCC engines have a special exception so the `WHERE` clause sees the latest committed version, not the snapshot.

### Explicit Lock with `SELECT FOR UPDATE`

```sql
BEGIN;
SELECT * FROM doctors
  WHERE on_call = true AND shift_id = 1234
  FOR UPDATE;
-- if count >= 2, proceed
UPDATE doctors SET on_call = false WHERE name = 'Aaliyah';
COMMIT;
```

**Why it works**: Locking the rows from step 1 forces serial execution. Works because the rows being checked already exist.

### PostgreSQL `SERIALIZABLE` vs `REPEATABLE READ`

```sql
-- Snapshot isolation only (write skew possible)
BEGIN ISOLATION LEVEL REPEATABLE READ;

-- True serializable (SSI)
BEGIN ISOLATION LEVEL SERIALIZABLE;
-- commit may abort with SQLSTATE 40001; retry at app layer
```

**Why it works**: PostgreSQL `SERIALIZABLE` adds dependency tracking on top of MVCC; conflicting transactions abort at commit.

## Database Defaults Reference

| Database | Default Isolation | Notes |
|----------|------------------|-------|
| PostgreSQL | Read committed | `REPEATABLE READ` = snapshot isolation; detects lost updates; `SERIALIZABLE` is true SSI |
| Oracle | Read committed | `SERIALIZABLE` actually = snapshot isolation; detects lost updates |
| MySQL/InnoDB | Repeatable read | NOT snapshot isolation; does NOT detect lost updates |
| SQL Server | Read committed | Optional snapshot isolation detects lost updates |
| IBM Db2 | Cursor stability | "Repeatable read" actually = serializable |

## Materialize-Conflicts Walkthrough (Meeting Rooms)

### Before (broken under snapshot isolation)

```sql
BEGIN;
SELECT count(*) FROM bookings
  WHERE room_id = 5 AND end_time > $start AND start_time < $end;
-- if 0, INSERT new booking
COMMIT;
```

Phantom: two concurrent bookings both see 0, both insert.

### After

```sql
-- Pre-populated table: rows for every (room, 15-min slot) for next 6 months.

BEGIN;
SELECT * FROM room_slot_locks
  WHERE room_id = 5 AND slot BETWEEN $start_slot AND $end_slot
  FOR UPDATE;
SELECT count(*) FROM bookings
  WHERE room_id = 5 AND end_time > $start AND start_time < $end;
-- if 0, INSERT new booking
COMMIT;
```

### Changes Made

1. Added a lock-only table whose rows correspond to the search space.
2. Locked relevant rows before checking; phantom turned into a row-level lock conflict.
3. Concurrency mechanism leaks into the schema — last resort; serializable preferred.
