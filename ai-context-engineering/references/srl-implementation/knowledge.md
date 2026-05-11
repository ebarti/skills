# SRL Implementation Knowledge

Core concepts for building a Semantic Role Labeling (SRL) visualizer in Python that turns sentences into stemma diagrams.

## Overview

An SRL pipeline takes a sentence's components (predicate, agent, patient, etc.), structures them into a labeled dictionary, and renders a stemma graph (verb root + role children with labeled arrows) using matplotlib.

## Key Concepts

### Semantic Roles

**Definition**: Labels that identify the function of each element in a sentence relative to the verb.

**The role set**:
- **Predicate (verb)**: The central action or state of being. Anchor of the structure.
- **Agent (ARG0)**: The "doer" — entity performing the action.
- **Patient (ARG1)**: The entity directly affected/acted upon by the verb.
- **Recipient (ARG2)**: The entity that receives the patient or result of the action.
- **Argument Modifiers (ARGM-)**: Contextual roles that answer when/where/why/how.
  - **Temporal (ARGM-TMP)**: When the action occurred.
  - **Location (ARGM-LOC)**: Where the action occurred.
  - **Manner (ARGM-MNR)**: How the action was performed.

### visualize_srl (main function)

**Definition**: User-facing function that accepts the verb plus role keyword args, builds the `srl_roles` dictionary, and delegates rendering to `_plot_stemma`.

**Signature**: `visualize_srl(verb, agent, patient, recipient=None, **kwargs)`

**Responsibilities**:
- Assemble required roles (Agent, Patient) into `srl_roles` dict.
- Add `Recipient (ARG2)` only if provided.
- Format any `**kwargs` modifier (e.g., `temporal="..."`) as `"Temporal (ARGM-TMP)"` using `f"{key.capitalize()} (ARGM-{key[:3].upper()})"`.
- Hand off `(verb, srl_roles)` to `_plot_stemma()`.

### _plot_stemma (plotting engine)

**Definition**: Internal helper with a single responsibility: draw the stemma. Takes the verb and the roles dict and produces a matplotlib figure.

**Stages**:
1. **Canvas setup**: `plt.subplots(figsize=(10, 6))`, `xlim(0,10)`, `ylim(0,10)`, `axis('off')`.
2. **Style definitions**: `verb_style` (lightblue/blue rounded box) and `role_style` (lightgreen/green rounded box) as dicts.
3. **Root placement**: Verb fixed at `(5, 8.5)` near top-center via `ax.text()`.
4. **Dynamic positioning**: Role x-coords spaced evenly along `y=4.5`.
5. **Drawing loop**: For each role — draw role box, draw `FancyArrowPatch` from verb to role, draw label at arrow midpoint.
6. **Final display**: `fig.suptitle(...)` then `plt.show()`.

### Dynamic Positioning Formula

**Definition**: Even horizontal distribution of N role nodes across the canvas width.

```python
x_positions = [10 * (i + 1) / (num_roles + 1) for i in range(num_roles)]
y_position = 4.5
```

**Effect**: Layout stays clear and balanced regardless of how many components are passed.

## Pipeline Flow

```
User Input (verb + roles)
    -> visualize_srl()  [data structuring]
        -> srl_roles dict
            -> _plot_stemma(verb, srl_roles)  [draw]
                -> Canvas setup
                    -> Dynamic positioning
                        -> Stemma drawing (root + children + arrows + labels)
                            -> Final display
```

## Dependencies

| Library | Use |
|---------|-----|
| `matplotlib.pyplot as plt` | Main plotting interface |
| `matplotlib.patches.FancyArrowPatch` | Directed arrows from verb to roles |
| spaCy + `en_core_web_sm` | Required for the broader notebook environment |
| Graphviz | Required for the broader notebook environment |

## Terminology

| Term | Definition |
|------|------------|
| Stemma | A graph with semantic nodes (verb root + role children) and labeled edges |
| Predicate | The verb anchoring all roles |
| ARG0/ARG1/ARG2 | PropBank-style numbered argument labels |
| ARGM-* | PropBank-style modifier labels (TMP, LOC, MNR, etc.) |
| Semantic Blueprint | The structured map of meaning produced from a flat sentence |

## How It Relates To

- **Context engineering**: SRL adds multidimensional structure to otherwise linear text fed to LLMs.
- **spaCy/NLP parsing**: SRL output can be produced by parsers; the visualizer focuses on rendering.
- **Matplotlib visualization**: The stemma is built entirely with `plt`/`FancyArrowPatch`, no graph libraries required at draw time.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| visualize_srl | User-facing entry; assembles dict, calls plotter |
| _plot_stemma | Draw-only helper that renders the stemma |
| srl_roles dict | Maps "Role (LABEL)" -> text fragment |
| Verb position | Fixed at `(5, 8.5)` |
| Role y-position | `4.5` |
| Role x-positions | Evenly spaced via `10*(i+1)/(N+1)` |
| Modifier formatting | `f"{key.capitalize()} (ARGM-{key[:3].upper()})"` |
