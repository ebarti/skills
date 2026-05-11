# Model Selection Checklist

Use when shortlisting and finalizing a foundation model for a production application.

## Before You Start

- [ ] Application's evaluation criteria are documented (capability, latency, cost ceilings)
- [ ] Privacy and compliance policies are known (data egress, residency, audit)
- [ ] Deployment target is decided (cloud API / private cloud / on-device)
- [ ] You have a private evaluation set ready for step 3

## Step 1: Hard Attribute Filter

- [ ] Data privacy policy: can data leave your network?
- [ ] Data residency: any country-of-storage requirements?
- [ ] Deployment target: edge / on-device required?
- [ ] License: commercial use allowed?
- [ ] License: MAU threshold respected (e.g., Llama 700M)?
- [ ] License: output reuse allowed if you plan to distill or generate synthetic data?
- [ ] Industry restrictions in license (medical, military, etc.)?
- [ ] Internal IP policy: do you require open training data for audit?
- [ ] Logprobs required for your use case (classification, eval)?
- [ ] Finetuning required, and provider supports the type you need?

## Step 2: Public Benchmark Shortlist

- [ ] Identified 3-6 benchmarks that match your application's capabilities
- [ ] Verified benchmarks are recent (not saturated)
- [ ] Checked benchmark correlations (no triple-counted capability)
- [ ] Selected an aggregation method (weighted sum, mean win rate) and documented weights
- [ ] Checked contamination risk (training-data cutoff vs benchmark publication)
- [ ] Reviewed leaderboards used (HF, HELM, custom)
- [ ] Reduced to 2-4 candidates for private testing

## Step 3: Private Evaluation

- [ ] Same prompts and inputs across all candidates
- [ ] Tested with your real data, not just public examples
- [ ] Measured cost per request at expected scale
- [ ] Measured p50/p95/p99 latency
- [ ] Tested function calling / structured output if needed
- [ ] Tested guardrails for your safety requirements
- [ ] If using same model on multiple APIs (e.g., GPT-4 on OpenAI and Azure), tested both
- [ ] Documented why the chosen model won (which criteria were decisive)

## Step 4: Production Readiness

- [ ] API follows a standard (e.g., OpenAI-compatible) for swap-ability
- [ ] Backup model identified for fallback
- [ ] Monitoring instrumented (latency, error rate, output quality)
- [ ] Process to detect provider-side model changes (versioning policy)
- [ ] User feedback loop in place
- [ ] Re-evaluation cadence scheduled (quarterly or per major release)

## Build vs Buy Scoring

Score each option 1-5 on each axis; total to compare:

- [ ] Data privacy
- [ ] Data lineage / copyright protection
- [ ] Performance (best achievable on your task)
- [ ] Functionality (function calling, structured outputs, logprobs)
- [ ] Cost (API per-call vs engineering + GPU)
- [ ] Control / transparency / versioning
- [ ] On-device / edge feasibility

## Contamination Hygiene

- [ ] Verified each shortlisted model's training cutoff
- [ ] For benchmarks published BEFORE the cutoff, treated scores with skepticism
- [ ] If reporting your own model: disclosed contamination percentage AND clean-subset score
- [ ] Preferred benchmarks with private hold-out sets where possible
- [ ] Used n-gram overlap or perplexity check on key benchmarks if feasible

## Red Flags

Stop and address if you find:

- A model selected only by leaderboard rank without private evaluation
- License terms that conflict with your business model (MAU caps, output reuse)
- A single benchmark dominating your decision
- Strongly correlated benchmarks (r > 0.85) double-counted in your aggregation
- Provider with no published versioning policy for a regulated application
- Self-host plan without dedicated ML/infra talent budgeted
- API plan without a fallback for outages or deprecation
- Benchmark scores that look too high to be true (suspect contamination)

## Quick Reference

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| Hard-attribute filter | Documented and applied first | Applied informally | Skipped |
| Benchmarks used | 3-6, low-correlation, task-relevant | Generic leaderboard average | Single benchmark |
| Contamination | Disclosed, clean subset reported | Not disclosed but recent benchmarks | Old benchmarks at suspicious highs |
| Private evaluation | Real data, real prompts, full pipeline | Public prompts, your data | Skipped |
| License review | Each clause confirmed for your use | Skimmed | "It's open source" |
| Vendor lock-in | OpenAI-compat API + fallback | Single-vendor SDK | Bespoke API, no alternative |
| Re-evaluation | Scheduled cadence | Ad hoc | Never |
