# JD-Match Examples

Worked examples of judging resume↔JD match and ATS-parseability. Examples are resumes/JDs, not code.

## Sample Job Description (with must-haves)

> **Senior Data Analyst** — Acme Retail
> We need a Senior Data Analyst to drive merchandising decisions with data.
>
> **Must-haves:**
> 1. 5+ years in data analysis
> 2. Advanced **SQL**
> 3. **Tableau** dashboard development
> 4. Experience with **A/B testing** / experimentation
> 5. **Retail** or e-commerce domain experience
> 6. Title at the **Senior Data Analyst** level
>
> Nice-to-have: Python, stakeholder presentation skills.

Use these six must-haves as the coverage checklist for the excerpts below.

## HIGH-Match Resume Excerpt

```
Senior Data Analyst                              ← focus line mirrors JD title

Senior Data Analyst with 6 years turning retail data into merchandising
wins. Build executive Tableau dashboards and run A/B tests that lift
revenue.                                         ← summary: scope + value, top third

AREAS OF EXPERTISE
SQL (advanced) | Tableau | A/B Testing | Retail Analytics | Experimentation

EXPERIENCE
Senior Data Analyst – Beta Stores, Austin, TX (Jan 2021 – Present)
• Cut report turnaround 40% by rebuilding 12 Tableau dashboards in SQL.
• Drove $1.2M incremental revenue via 30+ A/B tests on pricing/placement.
```

**Annotation — why it scores HIGH**:
- Coverage: all 6 must-haves present (6+ yrs, SQL, Tableau, A/B testing, retail, Senior title).
- Title alignment: focus line exactly mirrors "Senior Data Analyst."
- Mirrored terminology: uses the JD's exact terms (SQL, Tableau, A/B Testing, Retail).
- Top-third proof: role + skills + a win appear before the fold.
- Keyword proof: Experience substantiates each listed skill with results-first bullets.

## LOW-Match Resume Excerpt (same JD)

```
Objective: Seeking a challenging role where I can grow my career.   ← no title match

Hard-working professional with a passion for numbers and reporting.

SKILLS
Microsoft Excel, data entry, teamwork, communication, spreadsheets

EXPERIENCE
Reporting Associate – Generic Co. (2019–2022)
• Responsible for various reports and ad-hoc data requests.
• Helped the team with day-to-day tasks.
```

**Annotation — why it scores LOW**:
- Coverage: 0 of 6 must-haves (no SQL, Tableau, A/B testing, retail, or Senior title; years unclear).
- Title mismatch: vague "Objective," targets no specific role; "Reporting Associate" ≠ Senior Data Analyst.
- Zero keyword overlap: mentions Excel/spreadsheets, none of the JD's terms.
- Duty-listing: "responsible for," "helped" — no outcomes, no keyword proof.
- Generic "spray and pray" language fails the 6-second glance.

## ATS-Unfriendly Formatting Examples and Fixes

### 1. Two-column layout with a sidebar

**Problem**: Skills and contact info live in a left sidebar / second column. The ATS reads left-to-right across columns, scrambling text, or strips the column entirely — skills and phone number vanish.

**Fix**: Use a single-column layout. Put name, phone, email, city/ST as normal body text at the top; list skills under a standard `Areas of Expertise` heading in the main flow.

### 2. Contact info inside the header/footer; title in a text box / graphic

**Problem**: Many parsers ignore headers, footers, and text boxes. Name, email, and the focus-line title never populate their fields — the resume looks blank to the system.

**Fix**: Move name, contact details, and the focus-line title into the document body as plain text. Delete text boxes and icon graphics; keep essentials in text.

### 3. Skills/experience rendered as a table or with decorative bullets/symbols

**Problem**: Tables can be flattened unpredictably, merging cells into one line; fancy symbols, smart quotes, and em dashes drop out or become garbage characters during parse/paste.

**Fix**: Replace tables with simple bulleted lists. Use plain round bullets and a common font (Calibri, Arial, Aptos, Times New Roman). Use a consistent date pattern like `Jan 2021 – Aug 2025`. Save and upload as `.docx` or PDF.

## Quick Diagnosis Table

| Symptom in resume | Likely outcome | Fix |
|-------------------|----------------|-----|
| Columns / sidebar | Text scrambled or dropped | Single column, body text |
| Header/footer contact | Fields blank | Move to body |
| Table for skills | Cells merged on parse | Bulleted list |
| Fancy symbols/quotes | Garbled characters | Plain bullets, common font |
| "Objective" + no title | Title-filter fail | Focus line mirrors JD title |
| Excel only, no JD terms | Zero keyword match | Mirror exact must-have terms (truthfully) |
