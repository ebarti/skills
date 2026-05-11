# Semantic Blueprint Examples

The same sentence-completion task at all five context levels, with verbatim prompts and representative LLM outputs.

## Level 1: Basic Prompt (Zero Context)

### Input

```
Complete this sentence: "The cat played with the...
```

### Outputs

**Gemini 2.5**:
```
... ball of yarn.
Here are a few other ways to complete the sentence:
... toy mouse.
... string.
... cardboard box.
... laser pointer dot.
... other kitten.
```

**Microsoft Copilot**:
```
The cat played with the ball of yarn until it unraveled across the floor."
...crumpled receipt it found under the couch, batting it around like it was the most precious treasure in the kingdom of dust bunnies.
```

**OpenAI GPT-5**:
```
The cat played with the ball of yarn until it unraveled across the floor.
```

**Problems**:
- Output is a cliché — defaults to most predictable completion
- Microsoft Copilot's "creative" version is a hallucination if precision is needed
- All three could honestly have refused: "I'm sorry, but without more context, I can't complete this sentence correctly."

---

## Level 2: Linear Context

### Input

```
Complete this sentence: The ball fell on the floor and it rolled for a few feet. The cat then played with the...
```

### Outputs

**Gemini 2.5**:
```
The ball fell on the floor and it rolled for a few feet. The cat then played with the ball.
```

**Microsoft Copilot**:
```
...ball, pouncing on it with swift little swats and chasing it across the room like it was the most thrilling prey in the world.
```

**OpenAI GPT-5**:
```
The ball fell on the floor and it rolled for a few feet. The cat then played with the ball, batting it back and forth with its paws.
```

**Improvement**: Factual accuracy within the micro-story.
**Still wrong**: No style, purpose, or direction — model continues randomly.

---

## Level 3: Goal-Oriented Context

### Input

```
Goal: Write a short, suspenseful scene for a children's story.
---
Complete this sentence: "The ancient grandfather clock chimed midnight, its shadow stretching like a claw. A red ball, seemingly moving on its own, rolled out from under the dusty armchair. The black cat, Onyx, crouched low, his eyes gleaming. He then played with the..."
```

### Outputs

**Gemini 2.5**:
```
He then played with the... tiny, shimmering thread tied to the ball.
He pounced, but the thread danced away, pulling the red ball with it. The ball didn't just roll; it skittered across the floorboards as if it were alive, a little red mouse being tugged towards the heavy velvet curtains by the window. Onyx let out a low growl, a sound he never made when playing. The ball slipped silently behind the thick, dark fabric. The thread hung in the air for a second, taut and humming, before it too was yanked into the darkness. A tiny whisper, no louder than the rustle of a leaf, echoed from behind the curtain. "Mine."
```

**OpenAI GPT-5**:
```
...ball, batting it across the wooden floor. But instead of stopping, the ball bounced back toward him—as if pushed by an invisible hand. Onyx froze, his tail puffing up, while the clock ticked louder than ever, each tick echoing through the empty room.
```

**Improvement**: Responses become directed, creative, and intentional. First true context engineering.
**Still missing**: Loose guidance — no enforced participant relationships.

---

## Level 4: Role-Based Context

### Input

```
Goal: Write one suspenseful sentence to continue a children's story.
---
BACKGROUND:
- Protagonist: Onyx, a brave black cat.
- Antagonist: An ancient, haunted grandfather clock.
- Catalyst Object: A mysterious red ball.
- Setting: A dark, dusty room at midnight.
- Preceding Action: The clock chimed, and the ball rolled out.
---
Continue the story from this point: "The black cat, Onyx, crouched low... he then played with the...
```

### Outputs

**Gemini 2.5**:
```
...mysterious red ball, batting it gently until a low groan echoed from the clock and its tall, glass door swung open into the darkness within.
```

**Microsoft Copilot**:
```
...ball until it pulsed with a strange glow, and the clock's hands spun wildly backward, unleashing a chilling whisper that slithered across the floor toward him.
```

**OpenAI GPT-5**:
```
The black cat, Onyx, crouched low… he then played with the red ball—only to freeze as the grandfather clock's pendulum creaked on its own, swinging faster and faster in the midnight silence.
```

**Improvement**: Narrative discipline — characters, objects, and conflict all show up. The user has shifted from asking to telling.

---

## Level 5: Semantic Blueprint

### Input

```
TASK: Generate a single, suspenseful sentence.
---
SEMANTIC BLUEPRINT:
{
  "scene_goal": "Increase tension by showing defiance",
  "participants": [
    { "name": "Onyx", "role": "Agent", "description": "black cat" },
    { "name": "Red Ball", "role": "Patient", "description": "mysterious" },
    { "name": "Grandfather Clock", "role": "Source_of_Threat", "description": "ancient, looming" }
  ],
"action_to_complete": {
            "predicate": "play with",
 "agent": "Onyx",
 "patient": "Red Ball"
  }
}
---
SENTENCE TO COMPLETE: "He then played with the..."
```

### Outputs

**Gemini 2.5**:
```
He then played with the red ball, batting it with deliberate slowness directly under the shadow of the looming grandfather clock as its heavy pendulum began the first inexorable swing toward midnight.
```

**Microsoft Copilot**:
```
He then played with the red ball, his shadow flickering defiantly beneath the looming tick of the grandfather clock, as if daring time itself to strike.
```

**OpenAI GPT-5**:
```
He then played with the Red Ball, its echoing bounce defying the relentless tick of the Grandfather Clock that seemed to grow louder with every daring swipe of Onyx's paw.
```

**Why it works**:
- All three models execute a defined plan, not improvisation
- `scene_goal` ("defiance") shows up across all three outputs
- Named participants are preserved verbatim
- Predicate / agent / patient relationships are honored

---

## SRL Foundation Example

A simple sentence to illustrate how SRL underlies blueprints:

```
Sarah pitched the new project to the board in the morning.
```

An LLM sees a chain of tokens. A context engineer sees a *stemma*: the central action `pitched` with every other word assigned a role (agent: Sarah, patient: the new project, recipient: the board, time: in the morning). This is the structure that becomes a semantic blueprint.
