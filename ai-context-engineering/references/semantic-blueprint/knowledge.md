# Semantic Blueprint Knowledge

Core concepts for context engineering and the five levels of context that culminate in the semantic blueprint.

## Overview

Context engineering is the art and science of controlling and directing the informational world an LLM has learned. It transforms the user from a questioner into a director, evolving raw statistical guesses into nuanced, reliable, aligned responses. The journey progresses through five levels of complexity, ending in a fully architected semantic blueprint grounded in Semantic Role Labelling (SRL).

## Key Concepts

### Context Engineering

**Definition**: The discipline of designing the informational environment around an LLM so that responses are intentional, structured, and reliable.

It is the difference between handing an actor a single line versus a full script with character motivations and stage directions. The user is no longer asking for a performance; they are designing it.

**Key points**:
- Better contexts always outperform improvised, undirected prompts
- Solves model variability with structure, not hyperparameter tweaking (e.g., temperature)
- Treats the LLM as an actor and the engineer as the director

### The Five Levels of Context

**Definition**: A progression from zero-context prompts to fully engineered semantic blueprints. Each level adds informational scaffolding that constrains and directs the model.

| Level | Name | What It Adds |
|-------|------|--------------|
| 1 | Basic prompt (zero context) | Nothing — bare instruction |
| 2 | Better context (linear context) | A preceding factual thread |
| 3 | Good context (goal-oriented) | An explicit goal and richer details |
| 4 | Advanced context (role-based) | Defined roles, characters, relationships |
| 5 | Semantic blueprint | Structured plan with semantic roles |

### Level 1: Basic Prompt (Zero Context)

**Definition**: A simple, direct instruction with no background information.

The AI relies entirely on the most common statistical patterns from training data, defaulting to clichéd or hallucinated completions.

### Level 2: Linear Context

**Definition**: A small preceding thread of information that improves factual accuracy but provides no style or purpose.

Output becomes accurate within a micro-narrative but remains undirected — the model still doesn't know what you want.

### Level 3: Goal-Oriented Context

**Definition**: The first true level of context engineering. Provides a clear goal plus richer descriptive details so the LLM co-creates a scene aligned with intent.

This is the first acceptable milestone. Responses become intentional but remain loosely guided.

### Level 4: Role-Based Context

**Definition**: A structured context that explicitly assigns roles to characters, objects, and relationships, giving the model the scaffolding of conflict and motivation.

Transforms asking into telling. The model produces narratively intelligent responses with discipline.

### Level 5: Semantic Blueprint

**Definition**: The ultimate engineered context — a precise, unambiguous plan in a structured format using semantic roles.

The creative act becomes a reliable engineering process. Standard semantic roles include:
- **scene_goal**: the intended effect or purpose
- **participants**: each entity with name, role, description
- **action_to_complete**: predicate, agent, patient
- **agent**: who performs the action
- **patient**: who is most affected by the action

### Semantic Role Labelling (SRL)

**Definition**: A linguistic technique formalized by Lucien Tesnières and Charles J. Fillmore that decomposes a sentence to answer: *Who did what to whom, when, where, and why?*

SRL moves beyond grammar to identify the functional role each component plays relative to a central predicate. Output is a hierarchical map of meaning (a *stemma* or graph), not a linear chain of tokens.

**Key points**:
- LLM sees a chain of tokens; a context engineer sees a stemma
- Every component is assigned a role in relation to the central action
- SRL is the foundational skill of advanced context engineering
- Used both to reconstruct semantic structure and to define blueprints LLMs can follow

## Terminology

| Term | Definition |
|------|------------|
| Context engineering | Designing the informational world around an LLM |
| Zero context | Prompt with no background information |
| Linear context | A preceding thread of facts |
| Goal-oriented context | Context that includes an explicit purpose |
| Role-based context | Context that names participants and their relationships |
| Semantic blueprint | Structured, machine-parseable plan using semantic roles |
| SRL | Semantic Role Labelling — extracts who-did-what-to-whom |
| Predicate | The central action of a sentence |
| Agent | Entity performing the action |
| Patient | Entity most affected by the action |
| Stemma | Graph mapping each word to its semantic role |

## How It Relates To

- **Prompt engineering**: Context engineering subsumes it — prompts are Level 1; engineered contexts are Levels 3–5
- **Multi-agent systems**: Semantic blueprints provide the structured plans agents can execute reliably
- **SRL**: The linguistic theory that makes semantic blueprints constructible from natural language

## Common Misconceptions

- **Myth**: Better outputs come from tuning temperature or other hyperparameters.
  **Reality**: The engineering leverage is in context design, not hyperparameter workarounds.

- **Myth**: A more verbose prompt is the same as a better context.
  **Reality**: Adding words (Level 2) is not the same as adding goals, roles, or semantic structure.

- **Myth**: The LLM understands implicit dramatic structure.
  **Reality**: Without explicit roles, the model infers — and inference is unreliable.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Context engineering | Direct the LLM by designing its informational world |
| Level 1 | Bare prompt — produces clichés or hallucinations |
| Level 2 | Linear thread — accurate but undirected |
| Level 3 | Add a goal — first acceptable milestone |
| Level 4 | Add roles — narratively intelligent output |
| Level 5 | Semantic blueprint — repeatable engineered output |
| SRL | Maps sentences to who-did-what-to-whom structures |
