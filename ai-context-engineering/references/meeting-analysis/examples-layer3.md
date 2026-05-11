# Layer 3 Examples — Action ("the what next")

Cells g6 and g7. Layer 3 converts insights into reusable artifacts: a structured summary table (g6) and a polished follow-up email (g7).

Inputs from Layer 1: `new_developments`.
Outputs produced here: `final_summary_table`, `follow_up_email`.

## Cell 8: g6 — Creating the Final, Structured Summary

```python
prompt_g6 = f"""
Task: Create a final, concise summary of the meeting in a markdown table.
Use the following information to construct the table.

- New Developments: {new_developments}

The table should have three columns: "Topic", "Decision/Outcome", and "Owner".
"""
try:
    response_g6 = client.chat.completions.create(
        model="gpt-5",
        messages=[{"role": "user", "content": prompt_g6}]
    )
    final_summary_table = response_g6.choices[0].message.content
    print("--- FINAL MEETING SUMMARY TABLE ---")
    print(final_summary_table)
except Exception as e:
    print(f"An error occurred: {e}")
```

**Output (`final_summary_table`)**:
```
| Topic | Decision/Outcome | Owner |
|---|---|---|
| Backend payment gateway integration | More complex than expected; requires an additional three days | Backend Team |
| Schedule impact | Extra three days compress final testing, reducing buffer before launch | Project Manager |
| Mitigation | Tentative plan: Tom will work over the weekend to catch up | Tom |
| Front-end status | Ahead of schedule with extra bandwidth available | Front-end Team |
| Launch/marketing plan | Shift to a one-week invite-only soft launch, then major day-one push | Marketing + Product |
```

The structured schema (Topic / Decision / Owner) forces clarity and makes the output reusable in emails, reports, or dashboards.

## Cell 9: g7 — Drafting the Follow-Up Action

```python
prompt_g7 = f"""
Task: Based on the following summary table, draft a polite and professional follow-up email to the team (Sarah, Tom, Maria).
The email should clearly state the decisions made and the action items for each person.

Summary Table:
---
{final_summary_table}
---
"""

try:
    response_g7 = client.chat.completions.create(
        model="gpt-5",
        messages=[{"role": "user", "content": prompt_g7}]
    )
    follow_up_email = response_g7.choices[0].message.content
    print("--- DRAFT FOLLOW-UP EMAIL ---")
    print(follow_up_email)
except Exception as e:
    print(f"An error occurred: {e}")
```

**Output (`follow_up_email`)** — final artifact:
```
Subject: Follow-up: Decisions and next steps from today's sync

Hi Sarah, Tom, and Maria,

Thanks for the productive discussion earlier. Here's a quick recap of decisions and the action items for each of us.

Decisions
- Backend payment gateway integration is more complex than expected and will require an additional three days.
- This pushes the schedule by three days and compresses the final testing window, reducing our pre-launch buffer.
- Mitigation: Tom will work over the weekend to help us catch up.
- Front-end is ahead of schedule and has extra bandwidth to support.
- Launch/marketing plan will shift to a one-week invite-only soft launch, followed by the larger day-one push.

Action items
- Tom:
  - Confirm weekend availability and share a brief plan (key milestones, dependencies, and any risks).
  - Proceed with the gateway integration and coordinate early integration testing with Front-end and QA.
  - Provide short daily progress updates and flag blockers immediately.

- Sarah:
  - Update the project timeline to reflect the three-day shift and the compressed QA window.
  - Coordinate with QA on a risk-based test plan that fits the shortened testing period.
  - Align with Marketing/Product on the invite-only soft launch scope, success metrics, and comms; circulate the plan to the team.

- Maria:
  - Reallocate Front-end bandwidth to support the backend integration (payment UI hooks, error handling, instrumentation).
  - Partner with Tom on mocks/stubs as needed to unblock early integration and QA.
  - Ensure front-end readiness for the soft launch (feature flags/toggles, tracking) and share any gaps.

Please reply to confirm your action items and note any constraints or support you need. I'm happy to set up a brief daily check-in while we work through this; propose a time if you have a preference.

Thanks all, and appreciate the quick coordination.

Best,
[Your Name]
```

## What This Final Artifact Demonstrates

The email reads like it was crafted by a diligent project manager. The pipeline:

- **Captures decisions clearly** so there's no ambiguity about what was agreed
- **Assigns ownership** so every task is tied to a responsible person
- **Sets expectations** for timelines, next steps, and accountability
- **Reduces follow-up friction** because the draft is polished enough to send

This is the moment where the LLM stops being a "note-taker" and becomes a creative partner.
