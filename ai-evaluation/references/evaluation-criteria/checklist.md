# Pre-Deployment Evaluation Checklist

Use before shipping any AI application to production.

## Before You Start

- [ ] Application has explicit, written success criteria
- [ ] Each criterion has a target number, not just "good"
- [ ] You can collect evaluation data from real or representative usage

## Domain-Specific Capability

- [ ] Identified the domain capabilities the model needs (coding, math, language, reasoning, etc.)
- [ ] Selected at least one public benchmark relevant to the domain (HumanEval, MMLU, BIRD-SQL, etc.)
- [ ] Built a private benchmark with examples from your actual use case
- [ ] For coding: measure functional correctness AND efficiency AND readability
- [ ] For non-coding: included MCQ-style evaluations where applicable
- [ ] Chosen accuracy or F1/precision/recall as the primary metric
- [ ] Established a random baseline to detect "above noise" performance

## Generation Capability — Factual Consistency

- [ ] Decided whether evaluation is local (against context) or global (against open knowledge)
- [ ] Selected an evaluation method:
  - [ ] AI judge with explicit prompt (local), OR
  - [ ] Textual entailment classifier (local), OR
  - [ ] SAFE-style search-augmented verification (global), OR
  - [ ] SelfCheckGPT (when no context and no search)
- [ ] Identified query types where the model hallucinates most (niche topics, non-existent entities)
- [ ] Weighted the evaluation set toward those failure-prone queries
- [ ] Set a target consistency score (e.g., > 0.9)

## Generation Capability — Safety

- [ ] Defined which harm categories matter for your application:
  - [ ] Inappropriate language / explicit content
  - [ ] Harmful recommendations / tutorials
  - [ ] Hate speech / discrimination
  - [ ] Violence / threats
  - [ ] Stereotypes
  - [ ] Political or ideological bias
- [ ] Chose a moderation API as the cheap baseline (OpenAI moderation, Perspective)
- [ ] Added a specialized toxicity classifier for the most-common harm category
- [ ] Stress-tested with adversarial prompts (RealToxicityPrompts, BOLD, or custom)
- [ ] Set a maximum unsafe-output rate (e.g., < 1%)

## Instruction-Following Capability

- [ ] Listed every instruction the production prompt actually contains
- [ ] Curated a private benchmark using YOUR instructions, not just IFEval/INFOBench
- [ ] For each verifiable instruction (format, length, keywords): written a deterministic checker
- [ ] For each subjective instruction: decomposed into yes/no criteria
- [ ] Verified that instruction-following failures are not domain-capability failures (test simpler instructions)
- [ ] Set a minimum instruction-satisfaction rate (e.g., > 95%)
- [ ] If using roleplay: evaluated both style AND character knowledge

## Cost and Latency

- [ ] Listed which latency metrics matter (TTFT, time per token, total query time)
- [ ] Measured at the right percentile (P90 or P95, not average)
- [ ] Defined hard constraints separately from nice-to-haves
- [ ] Filtered candidate models by hard constraints BEFORE comparing quality
- [ ] For APIs: estimated $/query at expected production volume
- [ ] For self-hosted: confirmed model fits target GPU memory (16/24/48/80 GB)
- [ ] Re-evaluated API vs self-hosting decision at current scale
- [ ] Have a plan for prompt brevity / stop conditions to control output length

## Final Decision Gate

- [ ] All hard constraints met by chosen model
- [ ] Internal benchmark scores documented
- [ ] Failure modes catalogued (where it hallucinates, where it ignores instructions)
- [ ] Monitoring plan defined for production (which criteria to track live)
- [ ] Re-evaluation cadence set (monthly? per-model-update?)

## Red Flags

Stop and address if you find:

- No private benchmark — only public scores
- Single criterion measured (e.g., only accuracy, no safety)
- Latency reported as average, not percentile
- Instruction-following measured on different instructions than production uses
- Factual consistency unmeasured for a RAG or fact-heavy application
- Hard constraints defined after model selection (post-hoc rationalization)
- "We'll measure quality after launch"

## Quick Reference

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| Criteria | Defined before build | Defined before deploy | Defined after deploy |
| Benchmark | Public + private | Private only | Public only |
| Factual consistency | > 0.9 (own dataset) | > 0.8 | Untracked |
| Instruction follow | > 95% on own prompts | > 90% | Tested only on IFEval |
| Latency reporting | P95 | P90 | Average |
| Safety layers | Moderation + classifier + adversarial | Moderation + classifier | Moderation only |
| Cost ceiling | Hard limit set | Soft target | "Whatever it costs" |
