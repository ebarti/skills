# Dataset Curation Checklist

Use before, during, and after curating a finetuning dataset.

## Before You Start

- [ ] You can articulate the target behavior in one sentence.
- [ ] You have written (or located) annotation/evaluation guidelines.
- [ ] You know which finetuning technique you'll use (PEFT vs full).
- [ ] You have a budget for data ($/example) and compute.
- [ ] You have an evaluation set that does NOT overlap with training data.

## Data Quality

- [ ] Every example is **relevant** to the target task and time period.
- [ ] Annotations are **aligned with task requirements** (not just "correct").
- [ ] Annotations are **consistent** across annotators (kappa or equivalent).
- [ ] Examples are **correctly formatted** (no HTML, stray whitespace, inconsistent casing/numerics).
- [ ] Duplicates removed, contamination with eval set checked.
- [ ] **Compliant** with PII rules, licenses, and internal policies.
- [ ] Format tokens match what the model expects (e.g., chat template).

## Data Coverage

- [ ] Diversity axes for this app are explicitly enumerated.
- [ ] Each major axis (topic, length, language, style, turn count, output format) is represented.
- [ ] Distribution roughly mirrors expected production usage (or you have a reason to deviate).
- [ ] Edge cases and adversarial inputs are present.
- [ ] If conversational: single-turn vs multi-turn ratio is intentional.
- [ ] If CoT-relevant: step-by-step reasoning examples are included.
- [ ] If tool use: data captures multi-message-per-turn format.

## Data Quantity

- [ ] Sanity check passed: 50-100 example finetune showed measurable lift.
- [ ] Scaling curve plotted on 25/50/100% subsets.
- [ ] Quantity matches the technique (PEFT: hundreds-thousands; full FT: 10K+).
- [ ] Cost-per-example multiplied by target count fits the data budget.
- [ ] Compute budget remains for the chosen finetuning run.

## Data Acquisition

- [ ] Application/flywheel data leveraged where available.
- [ ] Public dataset sources searched (HF, Kaggle, Google Dataset Search, gov data).
- [ ] Every public dataset has been sampled and inspected manually.
- [ ] Licenses checked - including upstream sources, not just the wrapper.
- [ ] Acquisition channels (public, proprietary, synthetic, manual) combined deliberately.
- [ ] Bootstrapping path considered (self-supervised, less-relevant, synthetic -> real).

## Annotation

- [ ] Annotation guidelines define what "good" means for every score tier.
- [ ] Edge cases (correct-but-unhelpful, refusals, partial answers) are addressed in guidelines.
- [ ] Inter-annotator agreement measured on a calibration set.
- [ ] Re-annotation budget allocated (expect at least one guideline update mid-project).
- [ ] Fact-checking pass planned for factual tasks.
- [ ] AI-assisted annotation considered for consistency on nuanced tasks.
- [ ] For tool/agent data: workflows observed, not just self-reported.

## Red Flags

Stop and fix if you find:

- Eval examples appear in the training set (contamination).
- Inter-annotator agreement is low and no guideline update is planned.
- Public dataset license is ambiguous or upstream sources unverified.
- Finetuning on 50-100 well-crafted examples shows zero improvement (fix data/hyperparams/prompts before adding more).
- One axis dominates >90% of the data when production needs are diverse.
- Annotators are skipping guidelines or adding interpretations not in the spec.
- A "successful" annotation pass produced inconsistent scores on the same examples re-presented.
- PII is present in data the policy forbids using.

## Quick Reference

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| Quality (the six) | All six met | 5/6 with mitigation | <5/6 unmitigated |
| Coverage | Mirrors prod distribution | Major axes covered | Single axis >90% |
| Quantity (sanity) | 50-100 ex shows lift | Lift on 200-500 ex | No lift at any size |
| Quantity (final) | Matches technique | Within 2x of recommended | Mismatched (e.g., PEFT with millions) |
| Annotation | Guidelines first, kappa >0.7 | Guidelines + spot checks | Ad hoc, no agreement check |
| Public data | Inspected + license verified | Inspected, license OK | Used as-is, license unknown |
| Eval contamination | Zero overlap | <0.1% with mitigation | Any meaningful overlap |
