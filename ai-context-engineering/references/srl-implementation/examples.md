# SRL Implementation Examples

Worked examples showing input sentence -> SRL definition -> visualization, plus the full reference implementation.

## Reference Implementation

### Imports

```python
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch
```

### Main function: `visualize_srl`

```python
def visualize_srl(verb, agent, patient, recipient=None, **kwargs):
    """
    Creates a semantic blueprint and visualizes it as a stemma.
    This is the main, user-facing function.
    """
    srl_roles = {
        "Agent (ARG0)": agent,
        "Patient (ARG1)": patient,
    }
    if recipient:
        srl_roles["Recipient (ARG2)"] = recipient
    # Add any extra modifier roles passed in kwargs
    for key, value in kwargs.items():
        # Format the key for display, e.g., "temporal" -> "Temporal (ARGM-TMP)"
        role_name = f"{key.capitalize()} (ARGM-{key[:3].upper()})"
        srl_roles[role_name] = value
    _plot_stemma(verb, srl_roles)
```

### Plotting engine: `_plot_stemma`

```python
def _plot_stemma(verb, srl_roles):
    """Internal helper function to generate the stemma visualization."""
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 10)
    ax.axis('off')

    verb_style = dict(boxstyle="round,pad=0.5", fc="lightblue", ec="b")
    role_style = dict(boxstyle="round,pad=0.5", fc="lightgreen", ec="g")

    verb_pos = (5, 8.5)
    ax.text(verb_pos[0], verb_pos[1], verb, ha="center", va="center",
        bbox=verb_style, fontsize=12)

    srl_items = list(srl_roles.items())
    num_roles = len(srl_items)
    x_positions = [10 * (i + 1) / (num_roles + 1)
        for i in range(num_roles)]
    y_position = 4.5

    for i, (role, text) in enumerate(srl_items):
        child_pos = (x_positions[i], y_position)
        ax.text(child_pos[0], child_pos[1], text,
                ha="center", va="center",
                bbox=role_style, fontsize=10, wrap=True)

        arrow = FancyArrowPatch(
            verb_pos,
            child_pos,
            arrowstyle='->',
            mutation_scale=20,
            shrinkA=15,
            shrinkB=15,
            color='gray'
        )
        ax.add_patch(arrow)

        label_pos = (
            (verb_pos[0] + child_pos[0]) / 2,
            (verb_pos[1] + child_pos[1]) / 2 + 0.5
        )
        ax.text(label_pos[0], label_pos[1],
            role, ha="center", va="center",
            fontsize=9, color='black', bbox=dict(boxstyle="square,pad=0.1", fc="white", ec="none"))

    fig.suptitle("The Semantic Blueprint (Stemma Visualization)",
        fontsize=16)
    plt.show()
```

---

## Example 1: Business pitch

### Input sentence

```
Sarah pitched the new project to the board in the morning.
```

### SRL call

```python
print("Example 1: A complete action with multiple roles.")
visualize_srl(
    verb="pitch",
    agent="Sarah",
    patient="the new project",
    recipient="to the board",
    temporal="in the morning"
)
```

### Role mapping

- **Predicate**: `pitch`
- **Agent (ARG0)**: `Sarah`
- **Patient (ARG1)**: `the new project`
- **Recipient (ARG2)**: `to the board`
- **Temporal (ARGM-TMP)**: `in the morning`

### Visualization

A stemma with `pitch` as the root node and four child nodes representing the roles (Figure 1.3).

---

## Example 2: Technical update

### Input sentence

```
The backend team resolved the critical bug in the payment gateway.
```

### SRL call

```python
print("\nExample 2: An action with a location")
visualize_srl(
    verb="resolved",
    agent="The backend team",
    patient="the critical bug",
    location="in the payment gateway"
)
```

### Role mapping

- **Predicate**: `resolved`
- **Agent (ARG0)**: `The backend team`
- **Patient (ARG1)**: `the critical bug`
- **Location (ARGM-LOC)**: `in the payment gateway`

### Visualization

A stemma with `resolved` at the top connected to its three key participants (Figure 1.4). Note: no `recipient` argument is passed, so the dict has only three entries.

---

## Example 3: Project milestone

### Input sentence

```
Maria's team deployed the new dashboard ahead of schedule.
```

### SRL call

```python
print("\nExample 3: Describing how an action was performed")
visualize_srl(
    verb="deployed",
    agent="Maria's team",
    patient="the new dashboard",
    manner="ahead of schedule"
)
```

### Role mapping

- **Predicate**: `deployed`
- **Agent (ARG0)**: `Maria's team`
- **Patient (ARG1)**: `the new dashboard`
- **Manner (ARGM-MNR)**: `ahead of schedule`

### Visualization

A stemma showing how a Manner modifier adds a contextual layer to the core agent-patient relationship (Figure 1.5).

---

## What These Examples Demonstrate

| Example | Demonstrates |
|---------|--------------|
| 1. Business pitch | All core roles + Temporal modifier; full 4-child stemma |
| 2. Technical update | Optional `recipient` omitted; `location` kwarg becomes ARGM-LOC |
| 3. Project milestone | `manner` kwarg becomes ARGM-MNR; minimum viable stemma with one modifier |

The same `visualize_srl` entry point handles all three by leveraging `recipient=None` and `**kwargs` for flexible role composition.
