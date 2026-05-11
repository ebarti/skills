# Prompting Best Practices Checklist

Use this pre-flight checklist before deploying any prompt to production.

## Before You Start

- [ ] You have a defined success metric (accuracy, format conformance, etc.)
- [ ] You have evaluation data — at least 10-30 representative examples
- [ ] You have read the model provider's prompting guide

## Clarity

- [ ] Instructions are unambiguous (scales, formats, edge cases all specified)
- [ ] Behavior on uncertainty is defined ("pick best" vs "say I don't know")
- [ ] No model-specific hacks ("$300 tip", odd punctuation) that may break on other models
- [ ] Persona is specified if the perspective changes the answer

## Examples

- [ ] At least one example for each edge case the model might mishandle
- [ ] Example format is token-efficient (e.g., `-->` over `Input:/Output:`)
- [ ] End-of-prompt marker is included for structured-output tasks
- [ ] End marker is unlikely to appear in user inputs

## Output Format

- [ ] Output structure is specified (JSON keys, max length, etc.)
- [ ] Preambles and pleasantries are explicitly suppressed
- [ ] Long outputs are justified by the task (cost and latency considered)
- [ ] If JSON: keys are listed and example provided

## Context

- [ ] Reference material is provided when the model needs it
- [ ] For closed-context tasks: instruction to use only provided context
- [ ] For closed-context tasks: instruction to quote supporting passages

## Decomposition

- [ ] Prompt is under ~500 tokens (or decomposition is justified)
- [ ] Multi-step tasks are split into chained prompts where beneficial
- [ ] Cheaper model considered for simple steps
- [ ] Intermediate outputs can be monitored/logged

## Reasoning

- [ ] CoT applied for math, logic, or multi-step reasoning
- [ ] Right CoT variant chosen (zero-shot, scripted, one-shot)
- [ ] Self-critique considered for high-stakes outputs
- [ ] Latency cost of CoT/self-critique is acceptable for the use case

## Iteration

- [ ] Prompt has been tested on the held-out evaluation set
- [ ] Prompt has been tested across multiple models (if model-portable)
- [ ] Prompt is versioned (separate from code or in a prompt catalog)
- [ ] Experiment tracking captures prompt version + metric scores
- [ ] Whole-system performance evaluated, not just subtask performance

## Organization

- [ ] Prompt lives outside application code (in `prompts.py` or `.prompt` file)
- [ ] Metadata captured: model, endpoint, sampling params, schemas
- [ ] Prompt catalog used if multiple apps share prompts
- [ ] Changelog or version history is maintained

## Tooling Sanity

- [ ] If using a prompt engineering tool: hidden API call count is monitored
- [ ] Generated prompts have been inspected for typos and template bugs
- [ ] Tool version is pinned (tools change without warning)

## Red Flags

Stop and address if you find:

- Prompt exceeds 1,500 tokens with no decomposition plan
- Same prompt reused across apps via copy-paste (not catalog)
- No evaluation set; you're judging quality by eyeballing outputs
- Model gives wildly different outputs on identical inputs (temperature too high or prompt too ambiguous)
- A prompt engineering tool that you can't read the generated prompts for
- Versioning by file edit only — no commit history or experiment tracker

## Quick Reference

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| Prompt length | <500 tokens | 500-1500 tokens | >1500 with no decomposition |
| Output format | Specified + example | Specified | Free-form when downstream parses |
| Context | Sufficient + quoted | Sufficient | Model relies on internal knowledge |
| Versioning | Catalog + metadata | Separate file in git | Inline in code |
| CoT | Applied where useful | Considered | Always or never (no thought) |
| Tooling | Inspected + monitored | Used carefully | Black-box trust |
| Evaluation | Held-out set + metrics | Spot checks | Eyeball only |
