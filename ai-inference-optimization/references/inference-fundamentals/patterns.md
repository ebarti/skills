# Inference Performance Diagnostic Patterns

Reusable patterns for diagnosing and reasoning about inference performance.

## Pattern: Bottleneck Triage via MFU/MBU

### Intent

Quickly classify an inference workload as compute-bound or bandwidth-bound so you pick the right optimization lever.

### When to Use

- A model is "too slow" but you don't know which dimension to throw money at.
- Choosing between hardware upgrades (more FLOPs vs more HBM bandwidth).
- Deciding whether quantization is worth the engineering cost.

### Structure

```python
def triage(mfu_pct: float, mbu_pct: float) -> str:
    if mbu_pct >= 60 and mfu_pct < 40:
        return "bandwidth-bound"
    if mfu_pct >= 60 and mbu_pct < 40:
        return "compute-bound"
    return "mixed - profile prefill vs decode separately"
```

### Example

```
Llama-2-70B on A100-80GB, batch=1, decode-heavy workload
Measured: MBU = 78%, MFU = 18%
Triage:   bandwidth-bound
Levers:   quantize (FP16 -> INT8 halves bandwidth),
          chips with more HBM bandwidth, KV-cache compression
```

### Benefits

- Cheap to compute; only needs observed TPS, peak FLOPs, peak bandwidth.
- Maps directly to a small set of fixes.

### Considerations

- Prefill and decode have different bottlenecks - average them only when batched together; otherwise measure per phase.

---

## Pattern: Prefill/Decode Decoupling

### Intent

Run compute-bound prefill and bandwidth-bound decode on different worker pools to maximize utilization of each.

### When to Use

- Workload mixes long prompts (heavy prefill) with long generations (heavy decode).
- One phase is starving the other on the same machine.
- You're chasing higher goodput at the same hardware budget.

### Structure

```
[ requests ]
     |
     v
[ router ] -- prefill --> [ prefill workers (compute-optimized) ]
     |                         | KV cache
     |                         v
     +------- decode -----> [ decode workers (bandwidth-optimized) ]
                                 |
                                 v
                            [ stream tokens ]
```

### Benefits

- Each phase runs on hardware suited to its bottleneck.
- Independent scaling - add decode workers when output is long; add prefill workers when prompts are long.

### Considerations

- KV-cache transfer between machines adds complexity and bandwidth cost.
- Routing logic must account for both queues' depths to avoid head-of-line blocking.

---

## Pattern: Latency Distribution Audit

### Intent

Use percentiles plus input-length plots to find the real source of slowness.

### When to Use

- Average latency looks fine but users complain.
- p99 spikes appear in dashboards.
- New model or prompt shape rolled out.

### Structure

```python
def audit(latencies_ms: list[float], inputs_len: list[int]) -> dict:
    import statistics
    sorted_l = sorted(latencies_ms)
    n = len(sorted_l)
    return {
        "p50": sorted_l[int(n * 0.50)],
        "p90": sorted_l[int(n * 0.90)],
        "p95": sorted_l[int(n * 0.95)],
        "p99": sorted_l[int(n * 0.99)],
        "max": sorted_l[-1],
        "longest_inputs": sorted(zip(inputs_len, latencies_ms),
                                  key=lambda x: -x[1])[:10],
    }
```

### Benefits

- Finds outliers that the mean hides.
- Reveals when long inputs (prefill cost) drive the tail.

### Considerations

- Always pair latency with input length; TTFT scales with prefill tokens.
- Distinguish "model TTFT" from "time to publish" for agentic flows.

---

## Pattern: Online vs Batch Routing

### Intent

Route requests to the cheapest API/worker that still meets the deadline.

### When to Use

- Mixed workload: some user-facing, some offline.
- Cost matters and >=50% of traffic has loose latency requirements.

### Structure

```python
def route(request) -> str:
    if request.deadline_seconds <= 30:
        return "online_api"          # latency-optimized, more expensive
    if request.deadline_seconds <= 3600:
        return "online_api_low_pri"  # batched in flight
    return "batch_api"               # ~50% cheaper, hours of latency
```

### Benefits

- Cuts cost without violating SLOs.
- Lets batch workloads soak up cheaper hardware / off-peak capacity.

### Considerations

- Track per-route SLO compliance separately.
- Batch APIs cannot stream - know your downstream consumer.

---

## Pattern: SLO-First Tuning Loop

### Intent

Tune batching, hardware, and quantization against goodput rather than raw throughput.

### When to Use

- User-facing service with explicit latency SLOs.
- You're tempted to maximize tokens/s on the dashboard.

### Structure

```
1. Define SLO: { ttft_max_ms, tpot_max_ms }.
2. Measure baseline: throughput_tps, p95_ttft_ms, p95_tpot_ms, goodput_rpm.
3. Change ONE thing (batch size, quantization, decoupling).
4. Re-measure goodput.
5. Keep change if goodput went up; revert otherwise.
6. Repeat.
```

### Benefits

- Optimizes for what users actually feel.
- Forces explicit SLO definition.

### Considerations

- Goodput is workload-shape-dependent; re-evaluate after traffic mix changes.

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|---------------------|
| "Why is it slow?" | Bottleneck Triage via MFU/MBU |
| Mixed long prompts and long generations | Prefill/Decode Decoupling |
| Average latency is OK but users complain | Latency Distribution Audit |
| Mixed interactive + offline traffic | Online vs Batch Routing |
| Optimizing a user-facing production service | SLO-First Tuning Loop |
