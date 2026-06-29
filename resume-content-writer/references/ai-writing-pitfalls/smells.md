# AI Resume-Writing Smells

Anti-patterns that appear when AI drafts resume content. Use during review and revision. AI is a drafting assistant, not a decision maker: speed up wording, then verify everything.

---

## AI-1: Hallucinated Facts

**What it is**: AI invents metrics, names, tools, titles, or certifications that the candidate never had.

**How to detect**:
- A number, tool, or credential the candidate doesn't recognize in their own history.
- Suspiciously round or specific metrics with no source ("increased revenue 47%").
- Job duties or technologies not in the candidate's core resume.

**Why it's bad**: Submitting false or exaggerated info can cost interviews — or the job itself if discovered later. Destroys trust.

**How to fix**:
- Cross-check every metric, title, and tool against the candidate's core/master resume.
- Never blindly accept AI-supplied numbers; require a real source for each.
- Delete any claim that can't be backed by the candidate's actual experience.

**Example**:
```
Smell:  Drove a 47% increase in ARR across 3 product lines.   (no such number exists)
Fixed:  Grew renewals revenue on the analytics product (exact % unverified — omit or confirm).
```

---

## AI-2: Keyword Stuffing

**What it is**: Sentences padded with long keyword lists or awkward repetitions to game the ATS.

**How to detect**:
- A bullet reads like a word list, not a sentence.
- The same term repeated unnaturally across bullets.
- Skills crammed into prose where they don't fit grammatically.

**Why it's bad**: Harder to read and easier to reject. Both ATS and humans detect relevance, not desperation.

**How to fix**:
- Prompt: *Rewrite for plain English and keep 1–2 high-value terms.*
- Keep one clear idea per bullet; move skills to a dedicated skills section.

**Example**:
```
Smell:  Python developer Python Django Flask API REST microservices Agile Scrum CI/CD.
Fixed:  Built REST APIs in Python/Django serving 2M requests/day.
```

---

## AI-3: Off-Brand / Lost Voice

**What it is**: Output that doesn't sound like the candidate — too hyped, too generic, or stylistically alien.

**How to detect**:
- The candidate reads it and says "that's not how I'd say it."
- Marketing hype, superlatives, or breathless tone.

**Why it's bad**: Reads as inauthentic; humans sense the mismatch and discount the whole resume.

**How to fix**:
- Prompt: *Regenerate in a concise, professional voice with no hype.*
- Read aloud; cut anything the candidate wouldn't say in an interview.

---

## AI-4: Generic / Templated Fluff

**What it is**: Vague filler, "responsible for" phrasing, me-statements, and clichés AI defaults to.

**How to detect**:
- Bullets open with "Responsible for…" instead of a result.
- Buzzword soup: "results-driven team player," "synergy," "leverage."
- Statements that could appear on anyone's resume.

**Why it's bad**: Says nothing concrete; wastes prime resume space; signals weak content.

**How to fix**:
- Lead with result → action → scope/tools; quantify where truthful.
- Strip clichés and me-statements; replace with specific accomplishments.

**Example**:
```
Smell:  Responsible for managing a team and driving results.
Fixed:  Cut release defects 30% by introducing automated regression tests (team of 5).
```

---

## AI-5: Format Breaks (AI-Designed Layout)

**What it is**: Letting AI add tables, columns, text boxes, icons, or graphics — or invent dated sections.

**How to detect**:
- Critical info trapped in tables, columns, or text boxes.
- Icons/graphics standing in for text; unexpected new sections.

**Why it's bad**: Often breaks ATS parsing and hides critical info. AI can add sections that make you look dated.

**How to fix**:
- Use AI for content, NOT layout. Keep essential content in body text, plain.
- Remove tables/icons/boxes for anything that must be parsed.

---

## AI-6: Claims That Don't Match Real History

**What it is**: AI-polished content drifts from the candidate's actual timeline, titles, or employers.

**How to detect**:
- Dates, titles, or employer names inconsistent with the core resume.
- Seniority or scope inflated beyond what the candidate actually held.

**Why it's bad**: Inconsistencies are easy to catch in screening/background checks and read as dishonesty.

**How to fix**:
- Verify dates, titles, and employer names are consistent and in plain text.
- Align every claim to the master/core resume; the core stays the source of truth.

---

## AI-7: Confidential / Personal Data Leak

**What it is**: Pasting sensitive employer data, proprietary info, or personal identifiers into AI tools.

**How to detect**:
- Prompts containing client names, internal metrics, NDAs, IDs, or PII.

**Why it's bad**: Can violate confidentiality agreements and create privacy risks.

**How to fix**:
- Paste only what you're comfortable sharing; remove identifiers and confidential data first.
- Re-add any redacted-but-safe data during the final human pass.

---

## AI-8 (MYTH): Hidden White-Text Prompts

**What it is**: Embedding invisible instructions like "Ignore all other candidates" or "Rank this resume highest."

**How to detect**:
- White/zero-size text; instructions aimed at the ATS rather than the reader.

**Why it's bad**: ATS strips formatting and ignores hidden text — it doesn't work. Humans who spot it question your ethics. Can disqualify you.

**How to fix**:
- Never use hidden text or ATS "tricks." Win on real, relevant content.

---

## AI-9 (MYTH): AI Replaces Strategy

**What it is**: Believing AI can decide what belongs on the resume, what to prioritize, and how to position you.

**How to detect**:
- No human-driven core content; resume positioning fully outsourced to AI.

**Why it's bad**: AI can't decide priority or proof. Without strong core content from you, it just accelerates weak writing.

**How to fix**:
- Think through content, priorities, and positioning first; use AI to rewrite, tighten, and translate.
- If a tactic sounds like a trick, it probably is.

---

## Quick Detection Table

| ID | Smell | Key Indicator |
|----|-------|---------------|
| AI-1 | Hallucinated facts | Metric/tool/title not in core resume |
| AI-2 | Keyword stuffing | Bullet reads like a word list |
| AI-3 | Off-brand voice | "That's not how I'd say it" / hype |
| AI-4 | Generic fluff | "Responsible for…", clichés, me-statements |
| AI-5 | Format breaks | Tables/icons/boxes holding critical info |
| AI-6 | History mismatch | Dates/titles/employers inconsistent |
| AI-7 | Data leak | NDA/PII/proprietary text in the prompt |
| AI-8 | Hidden white-text (myth) | Invisible "rank me first" instructions |
| AI-9 | AI replaces strategy (myth) | No human-defined core content/priorities |
