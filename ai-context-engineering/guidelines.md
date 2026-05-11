# AI Context Engineering Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use:** Find your situation below, then load ONLY the listed files. For multi-step tasks, use a workflow.

---

## Workflows

| Task | Workflow |
|------|----------|
| Build a layered (scope→investigation→action) analysis pipeline end-to-end | `workflows/build-3-layer-pipeline.md` |

---

## By Task

### Designing Context for an LLM

| What you're doing | Load these files |
|-------------------|------------------|
| Choosing prompt vs context approach | `semantic-blueprint/knowledge.md`, `semantic-blueprint/rules.md` |
| Constructing a semantic blueprint (Level 5) | `semantic-blueprint/rules.md`, `semantic-blueprint/examples.md` |
| Comparing the same task across context levels | `semantic-blueprint/examples.md` |

### Implementing SRL

| What you're doing | Load these files |
|-------------------|------------------|
| Implementing visualize_srl | `srl-implementation/knowledge.md`, `srl-implementation/examples.md` |
| Defining semantic roles for a sentence | `srl-implementation/rules.md` |
| Adding new SRL examples | `srl-implementation/examples.md` |

### Building a Document / Meeting Analysis Pipeline

| What you're doing | Load these files |
|-------------------|------------------|
| Designing a 3-layer pipeline | `meeting-analysis/knowledge.md`, `meeting-analysis/patterns.md` |
| Writing layer prompts (g2-g7) | `meeting-analysis/rules.md`, `meeting-analysis/examples-layer1.md` (or layer2/3) |
| Composing scope → investigation → action | `meeting-analysis/patterns.md` |

---

## By Code Element

| Working with... | Primary | Secondary |
|-----------------|---------|-----------|
| Prompt strings | `semantic-blueprint/rules.md` | `semantic-blueprint/examples.md` |
| matplotlib stemma diagram | `srl-implementation/examples.md` | `srl-implementation/knowledge.md` |
| Multi-step LLM pipeline | `meeting-analysis/patterns.md` | `meeting-analysis/examples.md` |

---

## By Problem / Symptom

| If you notice... | Load these files |
|------------------|------------------|
| LLM output is generic / off-target | `semantic-blueprint/rules.md` (consider upgrading context level) |
| Pipeline steps lose context between calls | `meeting-analysis/rules.md` (pipe outputs verbatim) |
| Prompt mixes role + task + constraints + output | `semantic-blueprint/knowledge.md`, `meeting-analysis/rules.md` (one purpose per prompt) |

---

## File Index

### semantic-blueprint
| File | Purpose |
|------|---------|
| `knowledge.md` | 5 context levels, semantic blueprint, SRL theory |
| `rules.md` | Per-level design rules, when to upgrade |
| `examples.md` | Verbatim prompts/outputs across all 5 levels |

### srl-implementation
| File | Purpose |
|------|---------|
| `knowledge.md` | Roles, visualize_srl, plotting architecture |
| `rules.md` | 8 rules covering predicates, roles, plotting |
| `examples.md` | Full implementation + 3 worked examples |

### meeting-analysis
| File | Purpose |
|------|---------|
| `knowledge.md` | 3-layer model, context chaining, branching |
| `rules.md` | One-purpose-per-prompt, pipe outputs verbatim, schemas |
| `examples.md` | Index + setup (cells 1-3) |
| `examples-layer1.md` | g2/g3 verbatim with outputs |
| `examples-layer2.md` | g4/g5 verbatim with outputs |
| `examples-layer3.md` | g6/g7 verbatim with full email |
| `patterns.md` | Scope→Investigation→Action, Differential RAG, Branch-Then-Join |

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| Brand-new context engineering project | `semantic-blueprint/knowledge.md` + `semantic-blueprint/rules.md` |
| Build a meeting summarizer end-to-end | `meeting-analysis/knowledge.md` + `meeting-analysis/patterns.md` + the 3 layer example files |
| Visualize prompt structure for review | `srl-implementation/knowledge.md` + `srl-implementation/examples.md` |
