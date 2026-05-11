# Sampling Configuration Checklist

Use when configuring sampling parameters for a new LLM call or auditing an existing one.

## Before You Start

- [ ] Identify the task class: factual, code, creative, chat, reasoning, structured.
- [ ] Identify whether output is parsed by a downstream system (JSON, SQL, regex, etc.).
- [ ] Identify whether the task is online (latency-bounded) or offline (cost-bounded).
- [ ] Confirm whether the model API supports `seed`, `logprobs`, and constrained decoding.

## Temperature

- [ ] Set `T = 0` for any task with a single correct answer.
- [ ] Set `T = 0.7` as default for chat / general assistance.
- [ ] Set `T` in `[0.8, 1.2]` for creative tasks; never above provider cap (usually 2.0).
- [ ] Avoid stacking `T` reductions with aggressive `top_p` / `top_k`.

## Top-k / Top-p

- [ ] Leave `top_p` at provider default (often 0.95 or 1.0) unless you have a reason to change it.
- [ ] Use `top_p` (not `top_k`) when the natural candidate-set size varies by prompt.
- [ ] Set `top_k` only when you need a hard cap on candidate count (e.g., self-hosted compute concerns).

## Stopping Conditions

- [ ] Always set `max_tokens`.
- [ ] For free-form text: pad above the realistic max output to avoid mid-sentence cuts.
- [ ] For structured output (JSON/YAML/SQL): pad generously; truncation = unparseable.
- [ ] Configure `stop` tokens when output has a clear terminator.

## Structured Output

- [ ] Format documented in the prompt with at least one example.
- [ ] Parser/validator implemented for the expected format.
- [ ] Fallback behavior defined when parsing fails (retry, default value, escalate).
- [ ] Considered constrained sampling if validity must be 100%.
- [ ] Considered finetuning if format failures persist at high volume.

## Test Time Compute (when used)

- [ ] N (sample count) chosen based on cost and quality budget.
- [ ] Selection method defined: avg logprob, verifier, majority vote, or heuristic.
- [ ] Outputs diversified by varying T or top-p across calls.
- [ ] Cost monitoring in place; per-call cost roughly N times baseline.

## Inconsistency Mitigation

- [ ] Caching enabled for repeated identical inputs where appropriate.
- [ ] `seed` set when supported and reproducibility matters.
- [ ] `T` set low for inconsistency-sensitive paths.
- [ ] Logged sampling config alongside outputs for debugging.

## Hallucination Mitigation

- [ ] System prompt allows the model to say "I don't know."
- [ ] Retrieval context provided when factuality is critical (RAG).
- [ ] Source citations required in the prompt for fact-bearing claims.
- [ ] Verification step (self-check or second model) added for high-stakes output.
- [ ] Concise responses requested when verbosity is not needed.

## Observability

- [ ] Sampling parameters logged with each request.
- [ ] Logprobs captured (when API allows) for low-confidence-output triage.
- [ ] Format-failure rate measured over a representative sample.
- [ ] Cost per request and per output token tracked.

## Red Flags

Stop and address if you find:

- Temperature > 1.5 in a production factual / structured-output path.
- `max_tokens` too low for the expected output -> truncated structured outputs.
- `T = 0` claimed to guarantee determinism (it does not, due to hardware and provider effects).
- JSON / YAML output parsed without a try/except fallback.
- Test time compute with N > 32 in an online path (cost likely exceeds quality gain).
- No "I don't know" escape hatch on a factual Q&A path.
- Inconsistency complaints with no caching, no fixed seed, and no fixed T.

## Quick Reference

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| Temperature (factual) | 0 | 0.0-0.3 | >0.5 |
| Temperature (chat) | 0.7 | 0.5-0.9 | <0.2 or >1.2 |
| Temperature (creative) | 0.8-1.0 | 0.7-1.2 | >1.5 |
| Top-p | 0.9-0.95 | 1.0 (off) | Stacked aggressively with low T |
| Max tokens (structured) | Generous pad | Tight but safe | Risks truncation |
| Test time N (online) | 1-8 | 8-32 | >32 |
| Test time N (offline) | 8-32 | up to 100 | >400 (gains plateau) |
| Format validation | Always | After-the-fact metric | None |
| Hallucination defenses | RAG + cite + "IDK" prompt | One of the above | None |
