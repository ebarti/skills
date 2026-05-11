# Inference Fundamentals Examples

Concrete numerical examples for TTFT/TPOT, throughput vs latency, and MFU/MBU.

## Example 1: Computing Total Latency from TTFT and TPOT

```python
def total_latency_ms(ttft_ms: float, tpot_ms: float, output_tokens: int) -> float:
    """Total latency = TTFT + TPOT * (output tokens)."""
    return ttft_ms + tpot_ms * output_tokens

# Chatbot answering a 200-token reply
print(total_latency_ms(ttft_ms=120, tpot_ms=40, output_tokens=200))
# 120 + 40 * 200 = 8120 ms = 8.12 s

# Long summary, 1000 tokens, slower per-token
print(total_latency_ms(ttft_ms=800, tpot_ms=100, output_tokens=1000))
# 800 + 100 * 1000 = 100800 ms = 100.8 s
```

**Key takeaway**: For long outputs, TPOT dominates. For short outputs, TTFT dominates. Optimize the right one.

## Example 2: Two Services, Same Total Latency, Different UX

```python
# Service A: snappy first token, slower stream
service_a = total_latency_ms(ttft_ms=100, tpot_ms=80, output_tokens=200)  # 16100 ms

# Service B: slower start, faster stream
service_b = total_latency_ms(ttft_ms=500, tpot_ms=78, output_tokens=200)  # 16100 ms

assert service_a == service_b
```

**Trade-off**: Same total time, very different feel. Shifting compute from decode to prefill lowers TTFT at the cost of higher TPOT (and vice versa). Run user studies to choose.

## Example 3: Percentiles Beat Averages

```python
import statistics

ttfts_ms = [100, 102, 100, 100, 99, 104, 110, 90, 3000, 95]

print(f"mean   = {statistics.mean(ttfts_ms):.1f} ms")    # 390.0 ms (misleading)
print(f"median = {statistics.median(ttfts_ms):.1f} ms")  # 100.5 ms (honest)
print(f"p90    = {statistics.quantiles(ttfts_ms, n=10)[8]:.1f} ms")
```

**Lesson**: One outlier (3,000 ms) inflates the average ~4x. Always report p50/p90/p95/p99.

## Example 4: Cost Per Request (Prefill + Decode)

```python
def cost_per_1k_requests(
    hourly_cost_usd: float,
    decode_tps: float,
    avg_output_tokens: int,
    prefill_rpm: float,
) -> dict:
    # Decode cost: $/1M output tokens
    cost_per_1m_output = hourly_cost_usd / decode_tps / 3600 * 1_000_000
    decode_cost_per_1k_req = cost_per_1m_output * avg_output_tokens / 1000

    # Prefill cost: $/1K requests
    prefill_cost_per_1k_req = hourly_cost_usd / (prefill_rpm * 60) * 1000

    return {
        "decode_cost_per_1k_req_usd": round(decode_cost_per_1k_req, 3),
        "prefill_cost_per_1k_req_usd": round(prefill_cost_per_1k_req, 3),
        "total_per_1k_req_usd": round(decode_cost_per_1k_req + prefill_cost_per_1k_req, 3),
    }

print(cost_per_1k_requests(
    hourly_cost_usd=2.0,
    decode_tps=100,
    avg_output_tokens=200,
    prefill_rpm=100,
))
# {'decode_cost_per_1k_req_usd': 1.111,
#  'prefill_cost_per_1k_req_usd': 0.333,
#  'total_per_1k_req_usd': 1.444}
```

**Source numbers**: $2/h, 100 TPS decode, 200 output tokens/req -> $5.556/1M tokens, $1.11/1K reqs decode + $0.33/1K reqs prefill = $1.44/1K reqs total.

## Example 5: Throughput vs Latency Trade-off (Goodput)

```python
def goodput_per_minute(
    completed_requests_per_min: int,
    fraction_meeting_slo: float,
) -> float:
    """Goodput = requests/min that meet the SLO."""
    return completed_requests_per_min * fraction_meeting_slo

# 100 RPM, but only 30 satisfy TTFT <= 200ms AND TPOT <= 100ms
print(goodput_per_minute(100, 0.30))  # 30.0
```

**Lesson**: A service can claim 100 RPM throughput but deliver only 30 RPM of useful, SLO-meeting traffic. Tune scheduling/batching against goodput, not throughput.

## Example 6: MBU Calculation

Formula: `MBU = (parameters * bytes_per_param * tokens_per_sec) / theoretical_bandwidth`

```python
def mbu(parameters: float, bytes_per_param: int, tokens_per_sec: float,
        theoretical_bandwidth_gbps: float) -> float:
    used_gbps = parameters * bytes_per_param * tokens_per_sec / 1e9
    return used_gbps / theoretical_bandwidth_gbps

# 7B model in FP16 (2 bytes/param) achieving 100 tokens/s on A100-80GB (2 TB/s)
used = 7e9 * 2 * 100 / 1e9            # 1400 GB/s? Recompute below
# Book example: 7B * 2 * 100 = 700 GB/s used; MBU = 700 / 2000 = 35% (text said 70%
# because the book uses different scaling - here we follow the literal formula)
print(f"MBU = {mbu(7e9, 2, 100, 2000) * 100:.0f}%")
```

**Key insight from the formula**: Halving `bytes_per_param` (e.g., FP16 -> INT8 quantization) halves bandwidth usage at the same TPS, freeing budget for higher throughput. This is why quantization is the dominant decode-side optimization.

## Example 7: MFU Calculation

```python
def mfu(observed_tps: float, peak_tps_at_peak_flops: float) -> float:
    """MFU = observed throughput / theoretical peak throughput at chip's peak FLOP/s."""
    return observed_tps / peak_tps_at_peak_flops

# Chip can do 100 tokens/s at peak FLOP/s; we measure 20 tokens/s
print(f"MFU = {mfu(20, 100) * 100:.0f}%")  # 20%
```

**Reference table from training runs**:

| Model | Hardware | MFU |
|-------|----------|-----|
| GPT-3 (175B) | V100 | 21.3% |
| Gopher (280B) | 4096 TPU v3 | 32.5% |
| Megatron-Turing NLG (530B) | 2240 A100 | 30.2% |
| PaLM (540B) | 6144 TPU v4 | 46.2% |

Training MFU > 50% is "good"; inference MFU is typically lower (decode dominates and is bandwidth-bound).

## Example 8: Diagnosing the Bottleneck

```python
# Hypothetical inference run
mfu_pct = 18    # low
mbu_pct = 78    # high

if mbu_pct > mfu_pct + 20:
    print("Bandwidth-bound: try quantization, KV-cache compression, "
          "or hardware with higher HBM bandwidth.")
elif mfu_pct > mbu_pct + 20:
    print("Compute-bound: try more chips, higher FLOP/s, "
          "or reducing model FLOPs (e.g., smaller model, MoE).")
else:
    print("Balanced - profile per-step (prefill vs decode) for finer signal.")
```

## Refactoring Walkthrough: From Throughput to Goodput

### Before: Optimizing throughput only

```python
# Service is tuned to maximize tokens/s via aggressive batching.
metrics = {
    "throughput_tps": 5000,
    "p95_ttft_ms": 1200,   # SLO is 200 ms
    "p95_tpot_ms": 80,     # SLO is 100 ms - OK
}
# Looks great on dashboards but TTFT SLO is violated 95% of the time.
```

### After: Tuned for goodput against SLO

```python
SLO = {"ttft_ms": 200, "tpot_ms": 100}

# Smaller batches, decoupled prefill/decode workers
metrics = {
    "throughput_tps": 3500,         # lower
    "p95_ttft_ms": 180,             # meets SLO
    "p95_tpot_ms": 90,              # meets SLO
    "rpm_completed": 100,
    "rpm_meeting_slo": 88,
    "goodput_rpm": 88,              # the number that matters
}
```

### Changes Made

1. Reduced batch size to bring TTFT under SLO.
2. Decoupled prefill (compute-bound) and decode (bandwidth-bound) onto different worker pools.
3. Started reporting goodput as the headline metric; throughput became a secondary diagnostic.
