# SRL Implementation Rules

Rules for defining semantic roles, structuring SRL output for visualization, choosing positioning strategies, and knowing when SRL helps.

## Core Rules

### 1. Anchor Every Stemma to a Single Predicate

The verb is the root node — every other role is defined in relation to it.

- Pass the verb as the first positional argument.
- Place it at a fixed position (`(5, 8.5)`) so the diagram has a stable anchor.
- Do not add multiple verbs to the same stemma; build separate stemmas.

### 2. Make Agent and Patient Required, Everything Else Optional

The Agent (ARG0) and Patient (ARG1) are the minimum viable roles.

- `recipient` defaults to `None` and is only added when truthy.
- Modifiers (Temporal, Location, Manner, etc.) come through `**kwargs`.

**Example**:
```python
# Bad: forces every role even when absent
visualize_srl(verb, agent, patient, recipient, temporal, location, manner)

# Good: required roles positional, modifiers via kwargs
def visualize_srl(verb, agent, patient, recipient=None, **kwargs):
    ...
```

### 3. Format Modifier Keys Consistently as ARGM-XXX

Convert any kwarg into a display label using:

```python
role_name = f"{key.capitalize()} (ARGM-{key[:3].upper()})"
```

- `temporal` -> `"Temporal (ARGM-TMP)"`
- `location` -> `"Location (ARGM-LOC)"`
- `manner` -> `"Manner (ARGM-MNR)"`

Pick kwarg names whose first three letters yield the intended ARGM code.

### 4. Keep `_plot_stemma` Single-Responsibility (Draw Only)

The plotting helper only draws — it does not parse, validate, or restructure data.

- Receive a fully-built `srl_roles` dict as input.
- Do not perform NLP work inside the plotter.

### 5. Position Roles Dynamically, Not With Hard-Coded Coordinates

Use the spacing formula so layout adapts to N roles:

```python
x_positions = [10 * (i + 1) / (num_roles + 1) for i in range(num_roles)]
```

- Never hard-code `[2, 5, 8]`-style arrays — they break when role count changes.
- Keep `y_position = 4.5` so all role boxes sit on a single horizontal line.

### 6. Use Style Dictionaries, Not Inline Style Args

Define `verb_style` and `role_style` as dicts so visual changes happen in one place.

```python
verb_style = dict(boxstyle="round,pad=0.5", fc="lightblue", ec="b")
role_style = dict(boxstyle="round,pad=0.5", fc="lightgreen", ec="g")
```

### 7. Draw Three Things Per Role in the Loop

For each role iteration, do exactly:
1. Draw the role node (`ax.text` with `role_style` bbox).
2. Draw the connecting arrow (`FancyArrowPatch` with `shrinkA=15, shrinkB=15`).
3. Draw the arrow label at the arrow midpoint (offset `+0.5` on y).

### 8. Turn Off Axes for Diagrams

```python
ax.axis('off')
```

You are drawing a diagram, not a chart. Axes are noise.

## Guidelines

- Code is teaching-grade: skip heavy control flow / error handling unless productionizing.
- Keep `figsize=(10, 6)` and the `(0,10) x (0,10)` coordinate space — all formulas assume it.
- Use `mutation_scale=20` on arrows so heads remain legible at default font size.
- Use `wrap=True` on role text so long fragments still fit boxes.

## When SRL Helps

- Sentences with a clear single action and identifiable participants.
- Inputs to LLMs where role disambiguation matters (who did what to whom, when, where, how).
- Building structured "semantic blueprints" from linear text.

## When SRL Does Not Help

- Sentences with multiple coordinated verbs (split into multiple stemmas).
- Pure descriptive prose with no action.
- Cases where role boundaries are ambiguous and forcing labels distorts meaning.

## Exceptions

- **Production use**: Add error handling, validation, and proper graph-layout libraries (e.g., Graphviz) instead of manual matplotlib positioning.
- **Many roles (>6)**: The horizontal layout becomes cramped — switch to a multi-row or radial layout.

## Quick Reference

| Rule | Summary |
|------|---------|
| Single predicate | One verb per stemma; fixed at `(5, 8.5)` |
| Required vs optional | Agent + Patient required; rest via defaults/kwargs |
| ARGM formatting | `key[:3].upper()` derives the modifier code |
| Plotter purity | `_plot_stemma` only draws |
| Dynamic x-positions | `10*(i+1)/(N+1)` |
| Style dicts | One source of truth for verb/role visuals |
| Per-role draw | Node, arrow, label — in that order |
| Axes off | Always for diagrams |
