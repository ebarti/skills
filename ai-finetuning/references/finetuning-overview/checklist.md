# "Should I Finetune?" Checklist

Use this checklist before committing time, money, or talent to a finetuning project. If you cannot check most boxes in "Before You Start" and "Diagnosis," do not finetune yet.

## Before You Start

- [ ] You have an evaluation pipeline that measures task-relevant quality
- [ ] You have a representative dataset for evaluation (not just training)
- [ ] You have systematically tried multiple prompts with versioning
- [ ] You have tested with 1–50 few-shot examples that reflect real input distribution
- [ ] Your prompt instructions are clear, specific, and unambiguous
- [ ] Your evaluation metrics are well defined (not just vibe checks)

## Diagnose the Failure Mode

- [ ] You can articulate, with examples, *what* the model gets wrong
- [ ] You have classified failures as information-based or behavior-based
- [ ] **Information-based failures detected** → try RAG first, not finetuning
- [ ] **Behavior-based failures detected** → finetuning may be appropriate
- [ ] **Mixed failures** → start with RAG, then assess remaining behavior gaps

## RAG Considered First

- [ ] You have evaluated whether the model lacks information vs lacks form
- [ ] You have tried simple term-based retrieval (e.g., BM25)
- [ ] You have evaluated whether RAG closes the gap before considering finetuning
- [ ] If both gaps exist, RAG is in place before adding finetuning

## Finetuning Justification

- [ ] You can articulate why prompting + RAG is insufficient
- [ ] The failure is on *form*, *style*, *structure*, or *uncommon syntax*
- [ ] You have considered whether a stronger general model would solve the problem
- [ ] You have quantified expected lift vs cost
- [ ] You have considered finetuning a smaller model rather than a large one

## Data Readiness

- [ ] You can acquire (or already have) high-quality (input, output) pairs
- [ ] Data quality is verified — bad data can worsen hallucinations
- [ ] Data covers *all* task types you serve (not just the failing slice)
- [ ] If raw domain text is abundant, you have considered continued pre-training as a cheaper first step
- [ ] You have a plan for ongoing data curation, not a one-shot dataset

## Operational Readiness

- [ ] You have ML talent (or vendor support) for training, debugging, hyperparameters
- [ ] You understand: optimizers, learning rate, overfitting/underfitting, evaluation cadence
- [ ] You have a serving plan (self-host vs API service) and budget
- [ ] You have a monitoring plan post-deployment
- [ ] You have a refresh cadence for re-finetuning
- [ ] You have a policy for switching to newer/better base models

## Risks Acknowledged

- [ ] You accept that finetuning may degrade orthogonal capabilities
- [ ] You have a plan if a new base model surpasses your finetune
- [ ] You will not finetune to fix a single failing task at the expense of others
- [ ] You have considered model merging if you need multiple specialists

## Red Flags

Stop and reconsider if you find:

- Prompting was abandoned after a handful of unsystematic attempts
- No evaluation pipeline exists
- The "failure" is actually missing information (RAG territory, not finetuning)
- The team plans to finetune on a tiny dataset of a single task type
- No one will own ongoing maintenance
- You're choosing finetuning to look impressive rather than to solve a measured problem
- A strong general-purpose model has not been benchmarked yet
- Data quality is uncertain (low-quality data can *worsen* hallucinations)

## Decision Quick Reference

| Symptom | First Try | Then |
|---------|-----------|------|
| Outputs factually wrong/outdated | RAG (BM25 first) | Embedding retrieval |
| Outputs miss private knowledge | RAG over private data | — |
| Wrong format / broken syntax | Prompt with format examples | Finetune for form |
| Wrong style / tone | Prompt with style examples | Finetune on style data |
| Custom DSL / rare syntax | Few-shot prompting | Finetune (often required) |
| Persistent bias | Targeted prompt + RAG | Finetune on counter-bias data |
| Works but expensive at scale | Smaller model + prompting | Distill via finetuning |
| Mixed: facts + form failures | RAG | Add finetuning if behavior gaps remain |

## Final Gate

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| Prompt experiments | Versioned, metric-driven | A few iterations with notes | "Prompting doesn't work" without evidence |
| RAG tried | Yes, with measurable lift | At least BM25 attempted | Skipped entirely |
| Failure diagnosis | Specific with examples | Categorized info vs behavior | Vague "model is bad" |
| Data | High quality, all task types | Sufficient with known gaps | Small, single-task |
| Maintenance plan | Funded, owned, scheduled | Identified owner | None |
| Base model choice | Benchmarked vs alternatives | One reasonable option | "It's what we always use" |
