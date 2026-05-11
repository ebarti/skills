# Data Synthesis Knowledge

Core concepts for generating training and evaluation data programmatically (augmentation and synthesis) for AI models.

## Overview

Data synthesis automates data creation to address scarcity, coverage gaps, privacy constraints, and the cost of human annotation. Modern AI-powered synthesis can produce instruction data, preference data, and entire conversations, while traditional rule-based and simulation methods remain valuable for structured or rare-event data.

## Key Concepts

### Data Augmentation vs Data Synthesis

**Definition**: Augmentation derives new data from existing real data (e.g., flipping a cat image). Synthesis generates data that mimics real data without being derived from it (e.g., simulating mouse movement to detect bots).

**Key points**:
- Both terms are often used interchangeably
- Augmentation preserves the original signal with transformations
- Synthesis creates entirely new samples that match a target distribution

### Why Synthesize Data (Five Drivers)

1. **Quantity** - Produce data at scale; valuable when real data is scarce (rare weather, deep sea, accidents)
2. **Coverage** - Target specific characteristics: short/long text, toxic/safe examples, adversarial inputs, rare classes
3. **Quality** - AI can exceed human consistency on tasks like preference rating, complex math, or tool-use traces
4. **Privacy** - Synthesize patient records, claims, or financial statements without exposing PII
5. **Distillation** - Generate data from a teacher model to train a smaller, cheaper student

### Traditional Synthesis Methods

**Definition**: Procedural generation using predefined rules, templates, or virtual simulators (no AI).

**Two main approaches**:
- **Rule-based**: Templates + random generators (e.g., Faker), simple transformations (rotate, crop, synonym swap), perturbation (adding noise)
- **Simulation**: Virtual environments for self-driving (CARLA, Waymo), robotics, finance, climate, manufacturing defects

### AI-Powered Synthesis

**Definition**: Using foundation models to generate, paraphrase, translate, or back-translate data.

**Common techniques**:
- **Self-play** - Models play themselves to generate trajectories (Dota 2, AlphaGo)
- **Paraphrasing** - Rewrite queries/responses for variety (MetaMath: 15K → 400K examples)
- **Translation** - Cross-language data for low-resource languages; cross-language for code
- **Back-translation** - Translate then translate back to verify fidelity
- **Reverse instruction** - Take high-quality content, generate instructions that would elicit it

### Instruction Data Synthesis

**Definition**: Generating (instruction, response) pairs for supervised finetuning.

**Generation patterns**:
- AI generates instructions, humans write responses
- Humans write instructions, AI generates responses
- AI generates both
- Start from seed examples, topics, or templates and expand

### Data Verification

**Definition**: Quality control for synthetic data using functional checks, AI judges, or heuristics.

**Verification methods**:
- **Functional correctness** - Code execution, unit tests, parsers/linters
- **AI judges** - Score 1-5 or good/bad classification
- **Back-translation** - Check round-trip consistency
- **Heuristic filters** - Length, repetition, keyword, output==input checks
- **Anomaly detection** - Find outliers in synthetic distribution

### Model Distillation

**Definition**: Training a small student model to mimic a larger teacher model using teacher-generated data.

**Key points**:
- Goal is usually a cheaper/faster model with comparable performance
- Student can be trained from scratch (DistilBERT) or finetuned (Alpaca)
- Not all training on synthetic data is distillation - student can exceed teacher (Nemotron-4)
- Many model licenses prohibit using outputs to train competitors

## Limitations of AI-Generated Data

| Limitation | Description |
|------------|-------------|
| Quality control | Garbage in, garbage out; verification is hard |
| Superficial imitation | Student mimics style but not capability; can induce hallucination |
| Model collapse | Recursive training on synthetic data degrades models over iterations |
| Obscure lineage | Hidden copyright/benchmark contamination from teacher's training data |

## Terminology

| Term | Definition |
|------|------------|
| Procedural generation | Algorithmic data creation (vs manual) |
| Self-play | Model generates training data by playing against itself |
| Reverse instruction | Generate prompts that would elicit existing high-quality content |
| Back-translation | Round-trip translation to verify fidelity |
| Sim2Real | Adapting simulation-trained models to the real world |
| Model collapse | Performance degradation from recursive synthetic training |
| Perturbation | Adding noise to existing data to create new variants |

## How It Relates To

- **Instruction Finetuning**: Synthesis produces SFT instruction-response pairs
- **Preference Finetuning**: AI judges generate (prompt, winning, losing) triplets
- **Evaluation**: Synthetic test sets target adversarial cases and rare classes
- **Privacy/Compliance**: Synthesis enables training without sensitive real data

## Common Misconceptions

- **Myth**: Synthetic data is always lower quality than human data.
  **Reality**: For tool use, complex math, and consistent preference rating, AI often exceeds humans.

- **Myth**: All training on synthetic data is distillation.
  **Reality**: Distillation requires teacher to be the gold standard. Students can exceed teachers.

- **Myth**: You can train indefinitely on synthetic data.
  **Reality**: Pure synthetic recursion causes model collapse; mix with real data.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Augmentation | Transform real data into new samples |
| Synthesis | Generate data mimicking real distribution |
| Rule-based | Templates + Faker for structured data |
| Simulation | Virtual environments for rare/dangerous events |
| Self-play | Model generates trajectories against itself |
| Reverse instruction | Generate prompts from existing high-quality content |
| Back-translation | Round-trip verification of fidelity |
| Distillation | Train small student to mimic large teacher |
| Model collapse | Recursive synthetic training degrades performance |
