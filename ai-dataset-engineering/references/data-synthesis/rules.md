# Data Synthesis Rules

Guidelines for deciding when and how to synthesize data, verify it, and distill models.

## Core Rules

### 1. Synthesize When Real Data Is Scarce, Sensitive, or Skewed

Use data synthesis primarily for these triggers:

- **Scarcity** - Rare classes, edge cases, dangerous-to-collect events (accidents, defects)
- **Privacy** - PII-bound domains like healthcare, insurance, finance
- **Coverage gaps** - Adversarial examples, toxic/safe pairs, long/short text variants
- **Cost** - Annotation budget cannot meet target quantity
- **Distillation** - You need a smaller/cheaper variant of an existing model

Do NOT synthesize just because you can. If real data is abundant and verifiable, prefer it.

### 2. Match the Synthesis Method to the Data Type

Pick the cheapest method that produces verifiable data:

| Data type | Method |
|-----------|--------|
| Structured records (transactions, addresses) | Rule-based templates + Faker |
| Document formats (invoices, tax forms) | Templates with grammar |
| Math/logic problems | Procedural generation (e.g., AlphaGeometry) |
| Image variations | Augmentation (rotate, crop, recolor) |
| Rare physical events | Simulation (CARLA, robotics simulators) |
| Instructions/conversations | AI-powered generation |
| Code | AI generation + execution verification |
| Cross-language data | AI translation + back-translation |

### 3. Always Verify Synthetic Data

Never use unverified synthetic data in training. Apply at least one of:

- **Functional verification** when possible (run code, check parser, run unit tests)
- **AI judges** with bias mitigation (e.g., swap order, require both rounds to agree)
- **Heuristic filters** (length, repetition, output != input, no empty responses)
- **Round-trip checks** (back-translation for translations and code documentation)

**Example**:
```python
# Bad: ship raw model output
synthetic_examples = generate_with_llm(prompts)
train(model, synthetic_examples)

# Good: filter through correctness pipeline
synthetic_examples = generate_with_llm(prompts)
verified = [
    ex for ex in synthetic_examples
    if passes_linter(ex.code)
    and runs_unit_tests(ex.code, ex.tests)
    and not is_repetitive(ex)
]
train(model, verified)
```

### 4. Mix Synthetic With Real Data

Pure recursive synthetic training causes model collapse. Always blend with real data when possible.

- No definitive ratio exists in the literature
- Nemotron-4 used 98% synthetic in instruction/preference finetuning (one iteration only)
- For pre-training, synthetic data is intentionally rarer than for post-training
- Track lineage carefully - if your teacher model was trained on benchmark B, do not evaluate on B

### 5. Mitigate AI Judge Bias

When using AI to score or pick between responses:

- Swap response order and require consistent winner across both runs (NVIDIA pattern)
- Use multiple judges or specialized scorers when stakes are high
- Beware first-position bias and length bias
- Calibrate against a small human-labeled gold set

### 6. Distill Only When You Have License Permission

Before distilling another vendor's model:

- Read the model license - many prohibit training competing models on outputs
- Document your data lineage (which teacher generated which examples)
- Test for benchmark contamination through the teacher

### 7. Use Reverse Instruction for High-Quality Long Outputs

AI hallucinates more on long outputs. When you need long, factual responses:

- Start with existing high-quality long content (books, Wikipedia, papers)
- Use AI to generate the **instruction** that would elicit it
- Train on (AI-generated instruction, human-authored response) pairs

### 8. Bootstrap Iteratively for Capability Improvement

For weak-model bootstrapping (per Li et al. 2023):

1. Train weak model on small seed set
2. Use weak model to generate instructions for high-quality content
3. Finetune the weak model on this new data
4. Repeat until target performance reached

Stop when validation performance plateaus or degrades.

## Guidelines

- Generate from a diverse seed: topic lists, keywords, instruction types, templates
- For instruction data, generate multiple responses per instruction and pick the best
- Use perturbation (1-5% token replacement) to improve robustness, not just quantity
- For low-resource languages, translate from high-resource languages with back-translation
- Code data is easiest to verify functionally - prioritize it for synthesis-heavy pipelines

## Exceptions

- **Pure synthetic at scale**: Acceptable for one finetuning iteration, not for recursive training
- **Skipping verification**: Acceptable only for paraphrase augmentation of already-verified data
- **No licensing review**: Acceptable when distilling your own internal models

## Quick Reference

| Rule | Summary |
|------|---------|
| When to synthesize | Scarcity, privacy, coverage, cost, distillation |
| Method selection | Match technique to data type |
| Always verify | Functional > AI judge > heuristic |
| Mix real + synthetic | Avoid model collapse |
| Bias mitigation | Swap order, multiple judges |
| License check | Required before distilling external models |
| Long outputs | Use reverse instruction |
| Bootstrapping | Iterate weak model with verified data |
