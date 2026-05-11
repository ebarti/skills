# AI Foundation Models Guidelines

Quick reference for finding the right knowledge file for your task.

**How to use**: Find your situation below, then load ONLY the listed files.

---

## By Task

### Planning a New AI Application

| What you're doing | Load these files |
|-------------------|------------------|
| Evaluating whether to use AI/FMs at all | `references/ai-engineering-overview/rules.md`, `references/ai-engineering-overview/patterns.md` |
| Choosing AI vs human role (critical/complementary) | `references/planning-applications/rules.md`, `references/planning-applications/examples.md` |
| Defining defensibility for an AI product | `references/planning-applications/rules.md`, `references/planning-applications/checklist.md` |
| Setting milestones and expectations | `references/planning-applications/rules.md`, `references/planning-applications/checklist.md` |
| Pre-launch readiness check | `references/planning-applications/checklist.md` |

### Choosing or Sizing a Model

| What you're doing | Load these files |
|-------------------|------------------|
| Understanding what FMs are | `references/ai-engineering-overview/knowledge.md` |
| Choosing transformer vs alternative architecture | `references/model-architecture/rules.md`, `references/model-architecture/patterns.md` |
| Sizing a model (Chinchilla scaling) | `references/model-architecture/rules.md`, `references/model-architecture/examples.md` |
| Picking multilingual vs language-specific | `references/training-data/rules.md`, `references/training-data/examples.md` |
| Picking domain-specific vs general | `references/training-data/rules.md`, `references/training-data/examples.md` |

### Configuring Sampling

| What you're doing | Load these files |
|-------------------|------------------|
| Setting temperature/top-k/top-p | `references/sampling/rules.md`, `references/sampling/patterns.md` |
| Implementing structured outputs | `references/sampling/rules.md`, `references/sampling/examples.md` |
| Diagnosing inconsistency or hallucination | `references/sampling/rules.md`, `references/sampling/checklist.md` |
| Quick lookup for sampling by use case | `references/sampling/checklist.md` |

### Understanding Model Training

| What you're doing | Load these files |
|-------------------|------------------|
| Understanding pretraining vs post-training | `references/post-training/knowledge.md` |
| Designing SFT data | `references/post-training/rules.md`, `references/post-training/examples.md` |
| Choosing between SFT, DPO, RLHF | `references/post-training/patterns.md` |
| Understanding training data composition | `references/training-data/knowledge.md` |

---

## By Symptom/Problem

| If you notice... | Load these files |
|------------------|------------------|
| Model output too random / not random enough | `references/sampling/rules.md` |
| Model returning malformed JSON | `references/sampling/examples.md` (structured outputs) |
| Same input → different outputs (inconsistency) | `references/sampling/rules.md`, `references/sampling/checklist.md` |
| Model fabricating facts (hallucination) | `references/sampling/rules.md`, `references/sampling/checklist.md` |
| Multilingual quality much worse than English | `references/training-data/examples.md` |
| Model can't fit in available memory | `references/model-architecture/rules.md`, `references/model-architecture/examples.md` |

---

## By Topic (Direct Index)

### AI Engineering Overview
- `references/ai-engineering-overview/knowledge.md` — Concepts, definitions, evolution to AI engineering
- `references/ai-engineering-overview/rules.md` — Rules for evaluating use cases
- `references/ai-engineering-overview/examples.md` — Use case examples (coding, writing, etc.)
- `references/ai-engineering-overview/patterns.md` — Use case evaluation patterns

### Planning Applications
- `references/planning-applications/knowledge.md` — Use case eval, defensibility, AI stack, AI vs ML eng
- `references/planning-applications/rules.md` — Planning rules (HITL, defensibility, milestones)
- `references/planning-applications/examples.md` — Concrete planning examples
- `references/planning-applications/checklist.md` — Pre-launch checklist

### Training Data
- `references/training-data/knowledge.md` — Training data, multilingual, domain-specific
- `references/training-data/rules.md` — When to use multilingual/domain-specific
- `references/training-data/examples.md` — Multilingual gaps, domain examples

### Model Architecture
- `references/model-architecture/knowledge.md` — Transformer, attention, model size, scaling
- `references/model-architecture/rules.md` — Architecture choice, Chinchilla ratios, memory
- `references/model-architecture/examples.md` — Llama specs, attention math, scaling examples
- `references/model-architecture/patterns.md` — Sizing patterns

### Post-Training
- `references/post-training/knowledge.md` — SFT, RLHF, DPO, reward models
- `references/post-training/rules.md` — When to use each method
- `references/post-training/examples.md` — Data formats, pipelines
- `references/post-training/patterns.md` — Pipeline patterns

### Sampling
- `references/sampling/knowledge.md` — Temperature, top-k, top-p, structured outputs
- `references/sampling/rules.md` — Configuration rules
- `references/sampling/examples.md` — Sampling examples by use case
- `references/sampling/patterns.md` — Configuration patterns
- `references/sampling/checklist.md` — Quick reference checklist

---

## Decision Tree

```
What are you doing?
│
├─► Planning an AI app
│   ├─► Use case eval → ai-engineering-overview/rules.md
│   ├─► Architecture/role → planning-applications/rules.md
│   └─► Pre-launch check → planning-applications/checklist.md
│
├─► Picking a model
│   ├─► Architecture choice → model-architecture/rules.md
│   ├─► Multi-lingual question → training-data/rules.md
│   └─► Sizing → model-architecture/patterns.md
│
├─► Configuring an LLM call
│   ├─► Sampling params → sampling/rules.md + sampling/checklist.md
│   ├─► Structured output → sampling/examples.md
│   └─► Reducing hallucination → sampling/rules.md
│
└─► Understanding how it works
    ├─► Training process → post-training/knowledge.md
    └─► What FMs are → ai-engineering-overview/knowledge.md
```

---

## Common Combinations

| Scenario | Files to load |
|----------|---------------|
| Starting a new AI project | `ai-engineering-overview/rules.md` + `planning-applications/checklist.md` |
| Building a JSON-output service | `sampling/rules.md` + `sampling/examples.md` |
| Explaining FMs to a stakeholder | `ai-engineering-overview/knowledge.md` + `model-architecture/knowledge.md` |
| GPU sizing decision | `model-architecture/rules.md` + `model-architecture/examples.md` |
