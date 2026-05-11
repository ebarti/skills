# Semantic Blueprint Rules

Rules for designing context at each level, deciding when to upgrade, and constructing effective semantic blueprints.

## Core Rules

### 1. Engineer Context, Don't Tune Hyperparameters

When outputs are imprecise, do not reach for temperature or other model knobs first. The leverage is in context design.

- Treat hyperparameter tweaks as a last resort
- Fix the input scaffolding before changing the model

### 2. Move Off Level 1 for Anything Non-Trivial

A bare prompt with zero context produces clichés or hallucinations. Use Level 1 only for throwaway exploration.

- If the output must be precise, you are at the wrong level
- "I'm sorry, but without more context, I can't complete this..." is the only honest Level 1 response

### 3. Upgrade to Level 3 the Moment You Have a Goal

Level 2 (linear context) is rarely a destination. The first true context engineering act is stating a goal.

- If you can name what you want the output to *do*, write it as a goal
- A stated goal turns drift into direction

### 4. Use Level 4 When Multiple Entities Interact

When a task involves participants with relationships (protagonist/antagonist, source/target, caller/callee), assign explicit roles.

- Name each participant
- Make their relationship to the action explicit
- Provide preceding action so the model has continuity

### 5. Use Level 5 (Semantic Blueprint) for Repeatable, Reliable Output

When the same task must be executed many times with consistent quality, encode it as a structured semantic blueprint.

- Use machine-parseable format (JSON or similar)
- Include scene_goal, participants, and action_to_complete
- Specify the predicate, agent, and patient explicitly

### 6. Stop Asking, Start Telling

The shift from Level 3 onward is from asking the model to telling it. The director writes the script; the actor performs it.

- Replace open questions with directives
- Replace suggestion with specification

### 7. Build Blueprints from SRL

A semantic blueprint is the operational form of an SRL analysis. Decompose the task into predicate, agent, patient, and other semantic roles before encoding.

- Ask: *Who did what to whom, when, where, why?*
- Map each answer to a field in the blueprint

## Guidelines

- Choose the lowest level that reliably solves the task — don't over-engineer
- Stochastic LLM output means even good contexts vary; structure narrows the variance
- Preserve participant names exactly across the blueprint and the completion target
- Keep the blueprint small enough to be unambiguous but rich enough to constrain output

## When to Upgrade Between Levels

| Symptom | Upgrade To |
|---------|------------|
| Output is a cliché | Level 2 (add a thread) |
| Output is accurate but pointless | Level 3 (add a goal) |
| Output ignores key entities | Level 4 (add roles) |
| Output varies wildly across runs | Level 5 (semantic blueprint) |
| Task will be executed repeatedly | Level 5 (semantic blueprint) |

## How to Construct a Semantic Blueprint

1. **State the task** as a single, unambiguous instruction (e.g., "Generate a single, suspenseful sentence")
2. **Define scene_goal** — the desired effect on the output
3. **List participants** — for each: `name`, `role`, `description`
4. **Specify action_to_complete** — `predicate`, `agent`, `patient`
5. **Provide the literal completion target** (the sentence stub or anchor)

## Exceptions

- **Exploratory creativity**: Lower levels can be useful when divergence is desirable
- **Single-shot trivial tasks**: A Level 1 prompt is fine when correctness doesn't matter
- **Already-structured input**: If upstream tools provide structured data, you may skip ad hoc prose

## Quick Reference

| Rule | Summary |
|------|---------|
| Engineer context first | Don't reach for temperature |
| Skip Level 1 for real work | Bare prompts produce clichés |
| State a goal | Level 3 is the minimum acceptable |
| Name your roles | Level 4 unlocks narrative intelligence |
| Encode as blueprint | Level 5 makes output repeatable |
| Tell, don't ask | Be the director, not the questioner |
| SRL underlies blueprints | Decompose by predicate, agent, patient |
