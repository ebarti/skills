# Meeting Analysis Examples

Full worked example of the three-layer context-chaining pipeline from the chapter. Setup is shown here; per-layer code is split into separate files to keep each under 200 lines. All prompts and Python code preserved verbatim.

## Pipeline at a Glance

```
meeting_transcript
        │
        ▼
       g2 ── substantive_content ──┬──► g3 ──► new_developments ──► g6 ──► final_summary_table ──► g7 ──► follow_up_email
                                   ├──► g4 ──► implicit_threads (terminal)
                                   └──► g5 ──► novel_solution    (terminal)
```

## File Map

| File | Cells | Layer |
|------|-------|-------|
| `examples.md` (this file) | 1, 2, 3 (setup + transcript) | — |
| `examples-layer1.md` | g2, g3 | Scope ("the what") |
| `examples-layer2.md` | g4, g5 | Investigation ("the how") |
| `examples-layer3.md` | g6, g7 | Action ("the what next") |

## Setup: Cells 1–3

### Cell 1: Installation
```python
!pip install openai
```

### Cell 2: Imports and API Key Setup
```python
# We will use the OpenAI library to interact with the LLM and Google Colab's
# secret manager to securely access your API key.
import os
from openai import OpenAI
from google.colab import userdata
# Load the API key from Colab secrets, set the env var, then init the client
try:
    api_key = userdata.get("API_KEY")
    if not api_key:
        raise userdata.SecretNotFoundError("API_KEY not found.")
    # Set environment variable for downstream tools/libraries
    os.environ["OPENAI_API_KEY"] = api_key
    # Create client (will read from OPENAI_API_KEY)
    client = OpenAI()
    print("OpenAI API key loaded and environment variable set successfully.")
except userdata.SecretNotFoundError:
    print('Secret "API_KEY" not found.')
    print('Please add your OpenAI API key to the Colab Secrets Manager.')
except Exception as e:
    print(f"An error occurred while loading the API key: {e}")
```

### Cell 3: The Full Meeting Transcript
```python
meeting_transcript = """
        Tom: Morning all. Coffee is still kicking in.
        Sarah: Morning, Tom. Right, let's jump in. Project Phoenix timeline. Tom, you said the backend components are on track?
        Tom: Mostly. We hit a small snag with the payment gateway integration. It's... more complex than the docs suggested. We might need another three days.
        Maria: Three days? Tom, that's going to push the final testing phase right up against the launch deadline. We don't have that buffer.
        Sarah: I agree with Maria. What's the alternative, Tom?
        Tom: I suppose I could work over the weekend to catch up. I'd rather not, but I can see the bind we're in.
        Sarah: Appreciate that, Tom. Let's tentatively agree on that. Maria, what about the front-end?
        Maria: We're good. In fact, we're a bit ahead. We have some extra bandwidth.
        Sarah: Excellent. Okay, one last thing. The marketing team wants to do a big social media push on launch day. Thoughts?
        Tom: Seems standard.
        Maria: I think that's a mistake. A big push on day one will swamp our servers if there are any initial bugs. We should do a soft launch, invite-only for the first week, and then do the big push. More controlled.
        Sarah: That's a very good point, Maria. A much safer strategy. Let's go with that. Okay, great meeting. I'll send out a summary.
        Tom: Sounds good. Now, more coffee.
        """
```

## Next: Layer 1

Continue with `examples-layer1.md` for the g2 and g3 prompts that produce `substantive_content` and `new_developments`.
