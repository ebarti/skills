# Event Sourcing, CQRS, and DataFrames Examples

Illustrative patterns derived from the conference-management and movie-rating examples in DDIA Chapter 3.

## Event Sourcing: Conference / E-Commerce Domain

### Bad: State-mutation logging

```text
UPDATE bookings SET active = false WHERE id = 4001;
DELETE FROM seat_assignments WHERE booking_id = 4001;
INSERT INTO payments (booking_id, type, amount) VALUES (4001, 'refund', 199.00);
```

**Problems**:
- Intent is lost ("why did this happen?")
- Three coupled mutations could be partial on failure
- Rebuilding history requires sifting through audit columns

### Good: Past-tense event log

```json
{"type": "RegistrationOpened",  "ts": "2026-05-01T09:00Z", "conf": "QCon-26"}
{"type": "SeatsBooked",         "ts": "2026-05-02T14:12Z", "booking": 4001, "attendee": "u-77", "seats": 3, "price": 199.00}
{"type": "BookingCancelled",    "ts": "2026-05-09T08:30Z", "booking": 4001, "reason": "schedule conflict"}
{"type": "RefundIssued",        "ts": "2026-05-09T08:31Z", "booking": 4001, "amount": 199.00}
{"type": "WaitlistOfferSent",   "ts": "2026-05-09T08:32Z", "booking": 4001, "to": "u-204"}
```

**Why it works**:
- Each event is self-contained, immutable, past-tense
- Cancellation does not erase the prior booking; the fact remains
- New downstream behaviors (waitlist offer) chain off existing events
- Event names communicate intent without reading mutation code

## CQRS: Multiple Materialized Views from One Log

### Pattern

```text
                       ┌─► [Booking-Status View]   (per-attendee dashboard)
                       │
[Event Log] ───────────┼─► [Organizer Dashboard]   (capacity, revenue charts)
                       │
                       └─► [Badge Printer Feed]    (attendee names + sessions)
```

Each consumer reads events in log order and writes into a view optimized for its queries (a relational table, a denormalized document, an in-memory map).

### Read-side projection (pseudocode)

```python
def apply(event, view):
    if event["type"] == "SeatsBooked":
        view[event["booking"]] = {
            "attendee": event["attendee"],
            "seats":    event["seats"],
            "status":   "active",
        }
    elif event["type"] == "BookingCancelled":
        view[event["booking"]]["status"] = "cancelled"
```

**Why it works**:
- Pure function of (event, prior view state)
- Deterministic — replaying the log rebuilds the view exactly
- Bug fix? Delete the view, deploy fixed `apply`, replay

## Anti-Pattern: Nondeterministic Projection

```python
# Bad — fetches live exchange rate during projection
def apply(event, view):
    if event["type"] == "PaymentReceived":
        rate = fx_api.current_rate(event["currency"], "USD")  # changes daily!
        view[event["id"]] = event["amount"] * rate
```

**Problem**: Rebuilding the view next month produces different numbers than today.

**Fix**: Embed the rate in the event when the command is processed, OR query an immutable historical-rate service keyed by event timestamp.

## DataFrame: Pivoting Relational to Matrix

### Source: relational ratings table

```text
user   | movie       | rating
-------|-------------|-------
u-1    | Inception   | 5
u-1    | Tenet       | 4
u-2    | Inception   | 3
u-3    | Arrival     | 5
```

### Pandas-style wrangling

```python
import pandas as pd

df = pd.read_sql("SELECT user, movie, rating FROM ratings", conn)

# Pivot to user×movie matrix (sparse where users haven't rated a movie)
matrix = df.pivot(index="user", columns="movie", values="rating")
```

### Result: sparse matrix (users × movies)

```text
         Inception  Tenet  Arrival
u-1         5        4       NaN
u-2         3       NaN      NaN
u-3        NaN      NaN       5
```

**Why DataFrames here**:
- Result may have thousands of movie columns — awkward in a relational table, natural as a matrix
- NumPy / SciPy sparse arrays handle the missing entries efficiently
- Matrix form is the input shape ML algorithms expect

## DataFrame: One-Hot Encoding Categorical Data

```python
movies = pd.DataFrame({"title": ["A", "B", "C"],
                       "genre": ["comedy", "drama", "horror"]})

encoded = pd.get_dummies(movies, columns=["genre"])
```

```text
title  genre_comedy  genre_drama  genre_horror
A           1             0             0
B           0             1             0
C           0             0             1
```

**Why it works**: ML algorithms need numeric input; one-hot encoding represents an unordered categorical without imposing an artificial order. Generalizes to multi-genre movies (multiple 1s per row).

## Real Systems

| System | Category | Notes |
|--------|----------|-------|
| EventStoreDB | Event-sourcing DB | Purpose-built event log + projections |
| MartenDB | Event-sourcing on PostgreSQL | Uses Postgres as the event store |
| Axon Framework | CQRS / event-sourcing (JVM) | DDD-oriented application framework |
| Apache Kafka | Log-based message broker | Common substrate for event-sourced systems; pair with stream processors for views |
| Pandas | DataFrame (Python) | The reference DataFrame library |
| R DataFrames | DataFrame | Original DataFrame model |
| Apache Spark | Distributed DataFrames | Batch + streaming, scales beyond a single machine |
| Apache Flink | Stream processing + DataFrames | |
| Dask | Distributed Pandas-like DataFrames | |
| ArcticDB | DataFrame DB for time-series | Bloomberg / Man Group, financial data |
| NumPy | Sparse / dense numeric arrays | Underlies most Python ML stacks |
| Apache Arrow | In-memory columnar format | Interchange between DataFrame engines |
| TileDB | Array database | Geospatial, medical, scientific arrays |
