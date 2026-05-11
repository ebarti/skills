# Meeting Analysis Knowledge

Core concepts for layered, context-chained analysis of meeting transcripts (and similar long-form documents).

## Overview

Meeting analysis with LLMs is structured as a **three-layer context-chaining pipeline**: scope (what), investigation (how/why), and action (what next). Instead of one massive prompt, the workflow becomes a controlled sequence of focused prompts where each step's output feeds the next, producing precise, debuggable, and progressively richer results.

## Key Concepts

### Context Chaining

**Definition**: A multi-step LLM workflow where each prompt has a single purpose and its output becomes the clean input for the next step.

LLMs have no true memory or long-term focus. A single monolithic prompt with a complex multi-step task causes the model to lose the primary goal, drift into irrelevant details, and produce muddled output. Chaining solves this by transforming a complex task into a controlled, step-by-step dialogue.

**Three critical advantages**:
- **Precision and control** — guide the AI's *thought process* at each stage
- **Clarity and debugging** — failures are isolated to a single prompt
- **Building on insight** — narrative flow lets each step refine the previous one

### Layer 1: Scope (the "what")

**Definition**: Establishes the factual surface area of the analysis by separating signal from noise and identifying what is genuinely new.

- Cell **g2** isolates substantive content (decisions, updates, problems, proposals) from noise (greetings, small talk).
- Cell **g3** simulates RAG by comparing against a `previous_summary` to extract only **new developments** since last meeting.

### Layer 2: Investigation (the "how/why")

**Definition**: Moves from extracting facts to generating insights — reading between the lines and synthesizing.

- Cell **g4** uncovers **implicit threads**: hesitation, tension, mood, unstated dynamics.
- Cell **g5** generates a **novel solution** by combining two separate threads from the meeting into something new.

### Layer 3: Action (the "what next")

**Definition**: Converts raw insights into reusable, communicable artifacts.

- Cell **g6** compiles new developments into a **structured summary table** (Topic, Decision/Outcome, Owner).
- Cell **g7** drafts a **professional follow-up email** from the summary table — the loop from insight to action.

### Branching Workflow

The output of g2 (`substantive_content`) is the predecessor for **three parallel branches**: g3, g4, and g5. Only the g3 → g6 → g7 branch chains further; g4 (`implicit_threads`) and g5 (`novel_solution`) are terminal final outputs.

## Terminology

| Term | Definition |
|------|------------|
| Context chaining | Sequenced prompts where output(n) → input(n+1) |
| Substantive content | Decisions, updates, problems, proposals (signal) |
| Noise | Greetings, pleasantries, off-topic remarks |
| Implicit threads | Subtext: hesitation, tension, mood |
| Novel solution | A new idea synthesized from disparate facts |
| Cell gN | Notebook cell labels (g2–g7) for each pipeline step |

## How It Relates To

- **Semantic blueprint**: chaining is the structural macro-pattern that the semantic blueprint formalizes
- **RAG**: g3 simulates RAG by injecting a `previous_summary` for differential analysis
- **Context Engine**: later chapters build an engine to manage these step relationships automatically

## Common Misconceptions

- **Myth**: A more powerful model removes the need for chaining.
  **Reality**: Even GPT-5 loses focus in a single monolithic prompt; chaining provides control and debuggability regardless of model size.

- **Myth**: Chaining is just splitting one prompt into many.
  **Reality**: Chaining branches and composes — g2 fans out to g3/g4/g5, and only g3 chains onward into g6/g7.

- **Myth**: The final output is "just a summary."
  **Reality**: The pipeline produces multiple distinct artifacts (new developments, implicit dynamics, novel solution, structured table, action email) — the LLM functions as a creative partner, not a note-taker.

## Quick Reference

| Layer | Purpose | Cells | Final Outputs |
|-------|---------|-------|---------------|
| 1. Scope | What happened | g2, g3 | substantive_content, new_developments |
| 2. Investigation | How / why it matters | g4, g5 | implicit_threads, novel_solution |
| 3. Action | What next | g6, g7 | final_summary_table, follow_up_email |
