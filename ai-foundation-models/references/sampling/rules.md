# Sampling Rules

Guidelines for choosing temperature, top-k, top-p, structured-output methods, and mitigations for hallucination and inconsistency.

## Core Rules

### 1. Choose Temperature by Use Case

- **Factual / deterministic tasks** (classification, extraction, code, SQL, math): use `T = 0` (or as close as the API allows). The provider returns argmax over logits.
- **Balanced default** (chat, general assistant): use `T = 0.7`. Recommended starting point that balances creativity and predictability.
- **Creative tasks** (brainstorming, fiction, marketing copy): use `T` in `[0.8, 1.2]`. Tune upward only if outputs are too generic.
- **Maximum range**: most providers cap at `[0, 2]`. Above ~1.5, coherence often collapses.
- **Rule of thumb**: start at the recommended default for the task class, then experiment.

### 2. Set Only One of Temperature, Top-k, or Top-p Aggressively

Stacking aggressive limits compounds: e.g., `T=0.2 + top_p=0.5` is much more restrictive than either alone. Pick the primary control and leave the others near defaults.

- Default: vary temperature, leave top-p at provider default (often 1.0 or 0.95).
- For deterministic output: set `T=0` and ignore the others.

### 3. Prefer Top-p Over Top-k When Context Varies

- **Top-k** is right when you want a fixed candidate-set size or when minimizing softmax compute matters (you control the model).
- **Top-p** is right when the appropriate candidate set varies by prompt (e.g., "yes/no" vs "what's the meaning of life?"). Default `p` in `[0.9, 0.95]`.

### 4. Always Set a Stopping Condition; Pad the Limit for Structured Output

- Set `max_tokens` to control latency and cost.
- For free-form text, choose a value that won't cut mid-sentence.
- For JSON / YAML / SQL, set `max_tokens` generously. Premature stop produces unparseable output (missing brackets, half-quoted strings).
- Use stop tokens (e.g., `</answer>`, `\n\n`) when output has a clear terminator.

### 5. Pick the Right Structured-Output Method for the Job

In order of cost/effort:

| Method | When to use | When NOT to use |
|--------|-------------|-----------------|
| Prompting | Strong instruction-following model + simple format | Validity must be ~100% |
| Post-processing | Failures are predictable and small (missing `}`, trailing comma) | Errors are arbitrary or structural |
| Test time compute | Format failures are intermittent; budget allows extra calls | Latency-critical paths |
| Constrained sampling | Need strict format guarantee, grammar exists for the format | Format is unusual / no grammar / latency budget tight |
| Finetuning | High volume, format is core to the product, you have data | Few requests, format changes often |

**Combine layers**: prompting + post-processing covers most cases cheaply. Add constrained sampling only when failures are unacceptable.

### 6. Use Test Time Compute When Quality Matters More Than Cost

- Sample N outputs and select via:
  - **Highest avg logprob** (length-normalized) for general best-of-N.
  - **Reward model / verifier** for the largest quality gain (~30x model-size equivalent boost).
  - **Self-consistency / majority vote** for math, multiple choice, exact answers.
  - **App-specific heuristic** (shortest, first-valid SQL, parses cleanly) when you have one.
- Increase sampling diversity by varying temperature/top-p across calls.
- Cap `N` aggressively in production: cost scales linearly, gains plateau (often by N ~= 8-32).

### 7. Mitigate Inconsistency with the Cheapest Tool That Works

In order:
1. **Cache** identical prompts -> identical responses.
2. **Fix sampling vars**: set `T=0` (or low) and `seed` (when supported).
3. **Constrain output format** to reduce surface area for variation.
4. **Self-host** if you need control over the hardware (provider hardware can introduce non-determinism even with fixed seed).

For "slightly different input -> very different output", invest in prompt engineering and few-shot examples; sampling settings alone won't fix brittleness.

### 8. Mitigate Hallucination with Layered Defenses

- **Prompt**: instruct the model to say "I don't know" when unsure. Ask for concise responses (fewer tokens = less room to fabricate).
- **Retrieval (RAG)**: ground responses in retrieved documents.
- **Verification**: ask the model to cite sources for each claim, then check them.
- **Reduced temperature** does NOT eliminate hallucination but reduces drift from the most-likely (and presumably more factual) path.
- **Self-consistency**: sample multiple times, accept only answers that agree.
- **Structured output**: forces the model into a predictable shape, reducing snowballing.
- **Detection**: log low-confidence outputs (low avg logprob) for human review.

## Guidelines

- Use logprobs whenever the API exposes them: classification confidence, debugging, output ranking.
- For latency-critical chat-of-thought tasks, generate multiple responses in parallel and serve the first valid one.
- For batch/offline pipelines, use higher N for test time compute; cost matters less than quality.
- When in doubt, log your sampling config alongside outputs so you can A/B parameter changes.

## Exceptions

- **Adversarial / red-team testing**: deliberately raise temperature to surface failure modes.
- **Creative writing**: relax max_tokens and use higher T even though it raises cost.
- **Research / evaluation**: set T=0 for reproducibility even if the task would normally use a higher T.
- **Provider-specific quirks**: some APIs ignore `seed` or partially apply `top_p`. Verify behavior empirically.

## Quick Reference

| Rule | Summary |
|------|---------|
| Temperature by task | 0 for factual, 0.7 default, 0.8-1.2 for creative |
| One control at a time | Don't stack aggressive T + top-p + top-k |
| Top-p over top-k | When candidate set varies by prompt |
| Stop conditions | Required; pad for structured output |
| Structured output | Prompt -> post-process -> constrain -> finetune (escalate as needed) |
| Test time compute | Verifier > avg-logprob > self-consistency > heuristic |
| Inconsistency | Cache -> fix seed/T -> structure -> self-host |
| Hallucination | RAG + prompt for "I don't know" + verification + low T |
