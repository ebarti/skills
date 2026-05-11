# Data Curation Rules

Practical rules for assessing and improving training datasets along quality, coverage, quantity, acquisition, and annotation.

## Core Rules - Data Quality

### 1. Verify all six quality characteristics
For every dataset, explicitly check: **relevant, aligned with task requirements, consistent, correctly formatted, sufficiently unique, compliant**. Missing any of these can silently sabotage finetuning.

### 2. Prefer fewer high-quality examples over many noisy ones
- 1K-10K well-crafted examples often beat 100K+ noisy ones (LIMA, Yi).
- Start with a small, carefully curated set before scaling.

### 3. Strip formatting noise during ingestion
Remove HTML tags, trailing whitespace, stray newlines, inconsistent casing, and inconsistent numeric formats. Redundant formatting tokens interfere with learning.

### 4. Match annotations to what the task actually requires
Don't default to "correct." If the task wants creativity, score creativity. If it wants concise answers, reject verbose ones. If it requires score + justification, both must appear in annotations.

### 5. Curate to remove bad behaviors, not just add good ones
If users complain about a behavior (e.g., unsolicited rewrites), find and remove the training examples that taught it, then add counter-examples.

### 6. Deduplicate before training
Duplicates introduce bias and risk data contamination with eval sets. The acceptable level of duplication depends on the use case but should be a deliberate decision.

## Core Rules - Data Coverage

### 7. Map your diversity axes before sampling
Different apps need different axes:
- Chatbot: topic, language, style, length, turn count
- Translation: topic, length, register (not language)
- Code assistant: programming languages, task types, output formats

### 8. Mirror real input patterns
If users write with typos, include typos. If they write both terse and verbose prompts, include both. Coverage failures show up as production-only bugs.

### 9. Reflect real user distribution in the data mix
The simplest correct data mix is the one that mirrors actual production usage. Use scaling-law experiments only when you can afford them.

### 10. More heterogeneous data is not always better
"The Data Addition Dilemma" shows it can hurt. Test mixes empirically rather than assuming bigger and more diverse always wins.

## Core Rules - Data Quantity

### 11. Start with 50 examples, then scale based on the curve
Run finetuning on 50-100 well-crafted examples. If you see clear improvement, scale up. If you don't, fix data quality / hyperparameters / prompts before adding more data.

### 12. Match data size to the finetuning technique
- **PEFT (e.g., LoRA)**: a few hundred to a few thousand examples is enough.
- **Full finetuning**: tens of thousands to millions of (instruction, response) pairs.

### 13. Plot the performance curve to forecast ROI
Train on 25%, 50%, 100% of the dataset. A steep slope means doubling data will pay off. A plateau means stop spending on more data.

### 14. Bigger base model + small data; smaller base model + large data
- 100 examples: prefer a more advanced base model.
- 500K examples: smaller models close the gap; full finetuning becomes viable.

### 15. Budget for both data and compute
If $10K budget at $2/example, that caps you at 5K examples. Subtract data spend from compute spend; trade off explicitly.

## Core Rules - Data Acquisition

### 16. Build a data flywheel from your own application
Application data is perfectly distribution-matched to your task. Set up logging, feedback collection, and content reuse pipelines from day one.

### 17. Check available datasets before creating new ones
Look at Hugging Face, Kaggle, Google Dataset Search, Data.gov, ICPSR, UCI ML Repo, OpenML, AWS Open Data, TensorFlow datasets, lm-evaluation-harness.

### 18. Never trust public data without inspection
Always sample, validate, and check provenance. A "commercial-use" license on the wrapper does not guarantee every contained source is commercial-use.

### 19. Combine multiple acquisition channels
A real dataset is typically: public + filtered + manually labeled + synthetic + re-annotated. Plan iterative loops, not a single pass.

### 20. Bootstrap with cheaper data first
Three viable patterns:
- Self-supervised on raw documents -> supervised on (q, a)
- Less-relevant labeled data (e.g., tweets) -> in-domain (e.g., product reviews)
- Synthetic data -> real data

## Core Rules - Annotation

### 21. Write annotation guidelines before annotating
Define explicitly: what makes a response good, when correct-but-unhelpful is unacceptable, the difference between adjacent rating tiers (e.g., 3 vs 4).

### 22. Use the same guidelines for annotation and evaluation
Reuse evaluation guidelines as annotation guidelines (and vice versa). Eval examples can seed synthesis.

### 23. Observe the workflow when annotating tool/agent data
Self-reported descriptions miss steps. Watch experts perform tasks. Beware that human-efficient flows (web UI, copy-paste) differ from AI-efficient flows (APIs).

### 24. Consider AI-assisted annotation for nuanced tasks
Llama 3 found AI-assisted annotation more consistent than humans for nuanced safety policies.

### 25. Plan re-annotation cycles
Expect to update guidelines mid-project, find factually wrong annotations, and need a second annotator pass for fact-checking. Budget time for it.

## Guidelines

- For CoT tasks, ensure training data contains step-by-step responses, not just final answers.
- For tool use, support multi-message-per-turn formats (e.g., Llama 3's message headers).
- For conversational apps, decide explicitly whether you need single-turn, multi-turn, or both.
- High-quality code and math data disproportionately boosts reasoning - consider annealing on it late in training.
- If you have millions of examples, evaluate training from scratch (ossification can hurt finetuning).

## Exceptions

- **Specialized domain models**: Skip public general-knowledge data; weight in-domain corpus higher than its real-world frequency.
- **Safety-critical applications**: Tolerate near-zero duplication; over-invest in coverage of edge cases.
- **Research/prototypes**: A single well-chosen example may suffice (Howard & Whitaker showed LLMs can learn from one).

## Quick Reference

| Rule | Summary |
|------|---------|
| Quality six | Relevant, aligned, consistent, formatted, unique, compliant |
| Quality > quantity | 1K-10K curated > 100K noisy |
| Start small | 50-100 examples, then plot scaling curve |
| Match technique | PEFT = few thousand; full = tens of thousands+ |
| Mix matters | Reflect real distribution or run scaling experiments |
| Flywheel first | Application data beats every other source |
| Guidelines first | Annotation guidelines are the hard part |
| Trust nothing | Inspect every public dataset and license |
