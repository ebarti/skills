# Model Selection Rules

Practical rules for filtering, choosing, and validating foundation models for your application.

## Core Rules

### 1. Always Start by Filtering on Hard Attributes

Eliminate models that violate non-negotiable constraints BEFORE looking at performance.

- License (commercial use? MAU limits? output-reuse for training?)
- Data privacy (can data leave your network?)
- Deployment (must run on-device? in-region?)
- Training data provenance (do you need open data for audit?)

**Why**: Performance comparison is wasted effort if the model can't ship.

### 2. Treat the Workflow as Iterative

The 4-step workflow (filter → public bench → private eval → monitor) is a loop, not a pipeline.

- Be prepared to revisit step 1 (e.g., switch from "open source only" to "commercial APIs" if quality is insufficient).
- Re-run steps when major model releases happen.
- Keep the candidate set narrow; don't try to evaluate everything.

### 3. Read the License Before Picking an Open Source Model

For every open source candidate, answer:

1. Does the license allow commercial use?
2. Are there usage thresholds (e.g., Llama's 700M MAU clause)?
3. Can you use model outputs to train other models? (Critical for distillation, synthetic data.)
4. Are there restrictions on industry, country, or use case?

**Example**: Llama 1 was non-commercial. Llama 2/3 require special licensing above 700M MAU and don't allow output-based training. Mistral originally banned output reuse, then changed.

### 4. Don't Trust Public Benchmarks for Final Selection

Use them ONLY to narrow the candidate pool. Always run your private evaluation before committing.

- Different leaderboards rank models differently (HF and HELM share only 2 of 6/10 benchmarks).
- Aggregation (averaging) treats all benchmarks equally regardless of importance to you.
- Strongly correlated benchmarks bias averages (MMLU/WinoGrande r=0.90).
- Most leaderboards don't include benchmarks for your specific task.

### 5. Detect and Disclose Contamination

Before trusting any benchmark score:

- Use n-gram overlap (e.g., 13-token sequences) if you have training data access.
- Use perplexity comparison if you don't (low perplexity on eval = likely seen).
- For models you train: report performance on full benchmark AND on the clean subset.
- Prefer benchmarks with private hold-out sets.

### 6. Choose Build vs Buy on All Seven Axes

Don't decide on cost alone. Score each option on:

1. **Data privacy** - Can data leave your network?
2. **Data lineage / copyright** - Do you need protection or auditability?
3. **Performance** - Best-in-class is closed; open is "good enough" for many tasks.
4. **Functionality** - Function calling, structured output, logprobs, finetuning.
5. **Cost** - API cost vs engineering cost (talent, optimization, maintenance).
6. **Control / transparency** - Versioning, freezing, customizability.
7. **On-device deployment** - APIs cannot ship to edge devices.

### 7. Prefer Models with Standard APIs

Pick models that follow common API conventions (most providers mimic OpenAI's).

- Easier to swap models without rewriting client code.
- Reduces vendor lock-in.
- Speeds up A/B testing across providers.

### 8. Pick a Model with a Strong Community

For open source choices, prefer well-known models.

- More users = more documented quirks and solutions online.
- Active community means active fixes and ecosystem tooling.
- Avoid obscure models without third-party finetuning/inference support.

## Guidelines

- Start prompt engineering with the strongest available model to test feasibility, then work backward to smaller/cheaper models.
- Start finetuning with a small model to debug your code, then move to the largest that fits your hardware.
- For task-specific use, a smaller open model often suffices; reserve the strongest models for genuinely hard tasks.
- Build a private leaderboard from public benchmarks that match YOUR application's capabilities.
- When the same model is offered through multiple APIs (e.g., GPT-4 on OpenAI vs Azure), test both—performance can differ.
- Watch for benchmark saturation; switch to harder versions (MATH lvl 5 instead of GSM-8K, MMLU-PRO instead of MMLU).
- For privately-deployed commercial APIs (in your VPC), treat the deployment more like self-hosting than like a public API.

## Exceptions

- **Strict privacy or sovereignty**: Skip the open-vs-closed trade-off; you must self-host or use a privately-deployed commercial model.
- **On-device deployment**: APIs are off the table; you must use open weight models.
- **Need for logprobs**: Closed APIs typically don't expose them; choose open weight or an API that does.
- **IP-sensitive industries** (gaming, film): Consider deferring AI use until IP law clarifies, OR use commercial models with contractual indemnification.
- **Defensible contamination**: A team training on benchmark data for production performance is acceptable IF that benchmark is no longer used to evaluate the released model.

## Quick Reference

| Rule | Summary |
|------|---------|
| Filter first | Hard attributes before performance |
| Read the license | Commercial use, MAU, output reuse |
| Iterate the workflow | Steps can revise earlier decisions |
| Don't trust leaderboards | Use only to shortlist |
| Detect contamination | n-gram overlap or perplexity |
| Score 7 axes | Privacy, lineage, perf, function, cost, control, edge |
| Standard API | Mimic OpenAI's interface for portability |
| Community matters | Prefer popular open models |
