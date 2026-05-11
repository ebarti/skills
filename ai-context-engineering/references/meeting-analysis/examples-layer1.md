# Layer 1 Examples — Scope ("the what")

Cells g2 and g3. Layer 1 isolates substantive content from noise (g2) and narrows that content to what is genuinely new since the last meeting (g3, simulated RAG).

Inputs from `examples.md`: `meeting_transcript`, initialized `client`.
Outputs produced here: `substantive_content`, `new_developments`.

## Cell 4: g2 — Isolating Content from Noise

```python
prompt_g2 = f"""
        Analyze the following meeting transcript. Your task is to isolate the substantive content from the conversational noise.
        - Substantive content includes: decisions made, project updates, problems raised, and strategic suggestions.
        - Noise includes: greetings, pleasantries, and off-topic remarks (like coffee).
        Return ONLY the substantive content.
        Transcript:
        ---
        {meeting_transcript}
        ---
        """

from openai import OpenAI
try:
    client = OpenAI()
    response_g2 = client.chat.completions.create(
        model="gpt-5",
        messages=[
            {"role": "user", "content": prompt_g2}
        ]
    )
    substantive_content = response_g2.choices[0].message.content
    print("--- SUBSTANTIVE CONTENT ---")
    print(substantive_content)
except Exception as e:
    print(f"An error occurred: {e}")
```

**Output (`substantive_content`)**:
```
- Project Phoenix timeline: Backend mostly on track, but payment gateway integration is more complex than expected; needs an additional three days.
- Impact: Extra three days would push final testing up against the launch deadline, reducing buffer.
- Mitigation decision: Tom will work over the weekend to catch up (tentatively agreed).
- Front-end status: Ahead of schedule with extra bandwidth.
- Marketing/launch strategy: Initial plan for a big social media push on launch day flagged as risky (potential server load with early bugs). Decision: Use a soft launch (invite-only) for the first week, then execute the big push.
```

## Cell 5: g3 — Identifying NEW Information (Simulated RAG)

```python
previous_summary = "In our last meeting, we finalized the goals for Project Phoenix and assigned backend work to Tom and front-end to Maria."
prompt_g3 = f"""
Context: The summary of our last meeting was: "{previous_summary}"
Task: Analyze the following substantive content from our new meeting. Identify and summarize ONLY the new developments, problems, or decisions that have occurred since the last meeting.
New Meeting Content:
---
{substantive_content}
---
"""

from openai import OpenAI
from google.colab import userdata
try:
    response_g3 = client.chat.completions.create(
        model="gpt-5",
        messages=[{"role": "user", "content": prompt_g3}]
    )
    new_developments = response_g3.choices[0].message.content
    print("--- NEW DEVELOPMENTS SINCE LAST MEETING ---")
    print(new_developments)
except Exception as e:
    print(f"An error occurred: {e}")
```

**Output (`new_developments`)**:
```
- Backend issue: Payment gateway integration is more complex than expected; needs an additional three days.
- Schedule impact: The extra three days compress final testing, pushing it up against the launch deadline and reducing buffer.
- Mitigation decision: Tentative agreement that Tom will work over the weekend to catch up.
- Front-end status: Ahead of schedule with extra bandwidth.
- Launch/marketing decision: Shift from a big day-one social push to a one-week invite-only soft launch, followed by the major push.
```

## Notes

- `previous_summary` simulates RAG. In production this would be retrieved from a vector store, doc, or notes DB.
- The output is automatically scoped to deltas, not absolute state.
- Both g2 and g3 outputs feed Layer 2 and Layer 3 — `substantive_content` fans out to g4 and g5; `new_developments` chains into g6.
