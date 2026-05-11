# Finetuning Decision Rules

Rules for deciding whether to finetune, when to choose alternatives, and when to combine finetuning with RAG.

## Core Rules

### 1. Exhaust prompting before considering finetuning

Finetuning is a much higher up-front investment than prompting and is rarely the right first move.

- Systematically version and test prompts
- Make instructions clear and specific
- Use representative few-shot examples
- Define metrics before iterating
- Only after thorough prompting experiments should you consider RAG or finetuning

**Anti-pattern**: "Prompting didn't work" after a handful of unsystematic experiments.

### 2. Diagnose failures: information vs behavior

Before choosing between RAG and finetuning, classify the failure mode.

- **Information-based failure** → use RAG
  - Factually wrong outputs
  - Outdated facts
  - Missing private/internal knowledge
  - Hallucinations about facts the model never saw
- **Behavior-based failure** → consider finetuning
  - Output is correct but irrelevant
  - Wrong format (broken JSON, invalid HTML, etc.)
  - Wrong style or tone
  - Failure on uncommon syntaxes (custom DSLs, rare SQL dialects)
  - Persistent instruction-following gaps

### 3. If both information and behavior fail, start with RAG

RAG is easier to operate (no training data, no model hosting changes) and typically gives a larger boost than finetuning. Only add finetuning if behavior issues persist *after* RAG is in place.

### 4. Start RAG simple before getting fancy

When you adopt RAG:

- Begin with term-based retrieval (e.g., BM25)
- Move to embedding-based retrieval only if simple retrieval underperforms
- Embedding-based retrieval increases inference complexity; finetuning leaves inference unchanged but increases development complexity

### 5. Don't finetune to fix one task at the cost of others

Finetuning on one slice of queries can degrade performance on other slices.

- If you have N task types, finetune on all of them, not just the failing one
- If one model can't satisfy all tasks, use separate models per task
- If serving N models is operationally painful, consider model merging

### 6. Beware "specialized model" reflexes for general domains

General-purpose models often outperform domain-specific finetunes (BloombergGPT vs GPT-4-0314). Before committing $1M+ to a domain-specific finetune, verify a strong general model genuinely fails on your tasks.

### 7. Finetune on the *right* objective

- Use **continued pre-training** (self-supervised on raw domain text) when annotated data is scarce but raw domain text is abundant
- Use **SFT** when you have high-quality (input, output) pairs
- Use **preference finetuning** when you can produce (instruction, winning, losing) triples and want to align with human judgments
- Use **infilling finetuning** for text-editing or code-debugging tasks

### 8. Prefer finetuning a smaller model

Smaller models are easier to finetune, cheaper to serve, and faster at inference. A small finetuned model can beat a much larger out-of-the-box model on a specific task (Grammarly's 60x-smaller Flan-T5 vs GPT-3 variant).

### 9. Establish ongoing model maintenance policy *before* finetuning

You commit to:

- Monitoring drift and quality
- A budget and trigger for re-finetuning
- A policy for switching to newer base models when they outperform yours
- Inference/serving infrastructure for your custom model

If you can't commit to this, don't finetune.

## Guidelines

- Finetuning and prompting are complementary, not mutually exclusive
- Finetuning works best for instruction-following and output structure
- Self-supervised finetuning on cheap raw text is a low-cost intermediate step before SFT
- Prompt-experiment infrastructure (evaluation, annotation, tracking) is a prerequisite for serious finetuning
- With prompt caching now widespread, "shorter prompts via finetuning" is rarely a sufficient justification on its own
- Define and instrument your evaluation pipeline *before* any adaptation step

## Exceptions

- **Bias mitigation**: Finetuning on carefully curated counter-bias data is a legitimate first move when the goal is specifically to reduce a known bias
- **Regulated/private deployments**: When you must self-host and customize for sensitive data, finetuning a smaller model may be required even when a stronger API model exists
- **Custom DSLs / semantic parsing**: Tasks requiring rare syntaxes often need finetuning even when prompting is well-tuned

## When to Combine Finetuning + RAG

Combine when:

- The model has both information gaps *and* persistent behavior gaps
- You've already validated RAG provides a clear win
- You need both up-to-date facts *and* a strict output format/style
- You can afford to maintain both the retrieval system and a finetuned model

Be aware: Ovadia et al. (2024) found combining RAG with finetuning beats RAG alone only ~43% of the time. Validate empirically.

## Recommended Workflow

1. Define evaluation criteria and pipeline
2. Try prompting (with versioning)
3. Add few-shot examples (1–50)
4. Add RAG (start with BM25) if information-based failures
5. Branch:
   - Persistent information failures → embedding-based retrieval
   - Persistent behavior failures → finetuning
6. Combine RAG + finetuning if needed

## Quick Reference

| Rule | Summary |
|------|---------|
| Try prompting first | Finetune only after thorough prompt experiments |
| Diagnose failure mode | Info → RAG, behavior → finetuning |
| Start RAG before FT | RAG is easier and often a bigger win |
| Finetune on all tasks | Avoid degrading other capabilities |
| Prefer small models | Cheaper, faster, easier to operate |
| Pre-commit maintenance | Don't finetune without an upkeep plan |
| Form vs facts | Finetune for form, RAG for facts |
