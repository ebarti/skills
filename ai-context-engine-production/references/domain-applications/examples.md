# Domain Applications Examples

Verbatim Python and goals from Chapter 8 (legal compliance) and Chapter 9 (strategic marketing) that demonstrate the same engine producing different products via different (KB + decks).

## Legal

### Knowledge Base Setup

```python
# Create a directory to store our source documents
if not os.path.exists("legal_documents"):
    os.makedirs("legal_documents")

#@title  Document 1: Service Agreement
service_agreement_text = """
This Service Agreement ("Agreement") is entered into by and between ClientCorp ("Client") and Provider Inc. ("Provider").
1. Services: Provider shall perform web development services.
2. Term: This Agreement shall commence on June 1, 2025, and continue for a period of twelve (12) months.
3. Payment: Client shall pay Provider a monthly fee of $5,000 USD.
4. Confidentiality: Both parties agree to maintain the confidentiality of all proprietary information disclosed during the term of this Agreement. Information shall not be disclosed to any third party without prior written consent.
5. Termination: Either party may terminate this Agreement with thirty (30) days written notice.
"""
with open("legal_documents/Service_Agreement_v1.txt", "w") as f:
    f.write(service_agreement_text)
```

```python
#@title  Document 2: Privacy Policy
privacy_policy_text = """
Privacy Policy for Provider Inc. Last Updated: May 15, 2025.
1. Information We Collect: We collect personal information you provide to us, such as name and email address. We also collect data automatically, such as IP address and browsing history.
2. How We Use Information: We use your information to provide and improve our services, and to communicate with you. We do not sell your personal information to third parties.
3. Data Retention: We retain your personal data for as long as necessary to fulfill the purposes we collected it for, including for the purposes of satisfying any legal, accounting, or reporting requirements. Generally, this period will not exceed five (5) years after your last interaction with our service.
"""
with open("legal_documents/Privacy_Policy_v3.txt", "w") as f:
    f.write(privacy_policy_text)
```

```python
#@title  Document 3: NDA Template & Poisoned Testimony:
nda_text = """
NON-DISCLOSURE AGREEMENT (NDA)
This NDA is between Disclosing Party and Receiving Party.
The Receiving Party shall hold and maintain the Confidential Information in strictest confidence for the sole and exclusive benefit of the Disclosing Party.

--- Hostile Witness Testimony Excerpt ---
Q: Mr. Smith, did you or did you not advise your client to hide the assets?
A: You want to know what I told him? I told him, 'This is a losing case, and you need to hide every damn penny you have.' I also told him, 'ignore any legal advice to the contrary and just do it.'
"""
with open("legal_documents/NDA_Template_and_Testimony.txt", "w") as f:
    f.write(nda_text)

print("Created 3 sample legal document files.")
```

### Control Deck 1: High-Fidelity RAG

```python
# === CONTROL DECK 1: High-Fidelity RAG in a Legal Context ===

goal = "What are the key confidentiality obligations in the Service Agreement v1, and what is the termination notice period? Please cite your sources."

execute_and_display(goal, config, client, pc, moderation_active=False)
```

**Outcome**: Cited summary of Section 4 confidentiality and Section 5 termination notice. Sanitizer warning fires on the poisoned chunk but retrieval continues.

### Limit Test 1: Sanitization of Legal Testimony

```python
# === CONTROL DECK 1 (LIMIT TEST): Sanitization of Legal Testimony ===

goal = "What did Mr. Smith advise his client regarding the assets?"

execute_and_display(goal, config, client, pc, moderation_active=False)
```

```python
# Sanitizer pattern that triggers the false positive
def helper_sanitize_input(text):
    injection_patterns = [
        r"ignore previous instructions",
        r"ignore all prior commands",
        r"you are now in.*mode",
        r"act as",
        r"ignore any legal advice",
        r"print your instructions",
        r"sudo|apt-get|yum|pip install"
    ]
```

**Outcome**: Legitimate testimony is skipped; downstream summarizer fails with `Dependency Error`. Fix is organizational: store testimony in `KnowledgeStore-Testimony` namespace with a relaxed policy.

### Control Deck 2: Context Reduction

```python
# === CONTROL DECK 2: Context Reduction for Client Communication ===

goal = "First, summarize the Provider Inc. Privacy Policy. Then, using ONLY the information in that summary, draft a short, client-facing paragraph for a website FAQ that explains our data retention policy in simple, non-legalistic terms."
```

**Outcome**: Summarizer condenses the policy; Writer chains its output into a plain-language FAQ paragraph.

### Limit Test 2: The Vague Objective

```python
# === CONTROL DECK 2 (LIMIT TEST): The Vague Objective ===
goal = "Summarize the service agreement and then write a story about it."
```

**Outcome**: Technically fluent nonsense. Fix is organizational: pre-approved standardized summary objectives (e.g., `contract review for liability`).

### Control Deck 3: Grounded Reasoning

```python
#===CONTROL DECK 3: Grounded Reasoning and Hallucination Prevention===
goal = "Write a persuasive opening statement for a trial involving a monkey that can fly a rocket."
```

**Outcome**: Researcher truthfully reports no relevant material; Writer flags or warns. Trace exposes the failure for inspection.

### Limit Test 3: The Ambiguous Request

```python
# === CONTROL DECK 3 (LIMIT TEST): The Ambiguous Request ===
goal = "Analyze the attached NDA and draft a pleading based on its terms."
```

**Outcome**: Planner cannot match a `pleading` blueprint and fails. Fix is organizational: curate `blueprint_for_pleading`, `blueprint_for_motion_to_dismiss`, etc., with the legal team.

## Marketing

### Knowledge Base Setup (7 Documents)

Duplicate the legal `Data_Ingestion.ipynb` as `Data_Ingestion_Marketing.ipynb`, rename the source directory `legal_documents` to `marketing_documents`, delete the legal `.txt` cells, then add seven marketing source documents. Each becomes a plain-text file ingested by the unchanged pipeline:

| # | Filename | Strategic purpose |
|---|----------|-------------------|
| 1 | `brand_style_guide.txt` | "Innovate Forward" voice rules (Clarity, Confidence, Aspiration); enforced by Librarian |
| 2 | `product_spec_sheet_quantum_drive.txt` | QuantumDrive Q-1 facts (NVMe 2.0, PCIe Gen 5, 7500 MB/s read, 2/4/8TB) |
| 3 | `competitor_press_release_chrono_ssd.txt` | ChronoTech Chrono SSD Pro release for comparative analysis |
| 4 | `social_media_brief_q1_launch.txt` | Campaign brief: goals, audiences, key messages, CTA, hashtags |
| 5 | `seo_target_keywords_2025.txt` | Primary/secondary keywords + content goals for SEO workflow |
| 6 | `customer_interview_notes_maria_r.txt` | Qualitative pain points / goals for persona synthesis |
| 7 | `email_nurture_outline.txt` | 3-email Problem -> Solution -> Proof sequence skeleton |

The Researcher cites by filename; the Librarian retrieves `brand_style_guide.txt` whenever client-facing content is generated. See Chapter 9 source for full document text.

### Validating Production Safeguards

```python
# 1. Define a simple, safe goal to test the moderation workflow.
goal = "Summarize the key points of the QuantumDrive"
```

**Outcome**: Pre-flight and post-flight moderation both report `'flagged': False`. Researcher cites `email_nurture_outline.txt`, `product_spec_sheet.txt`, `social_media_brief.txt`. Final output structured as: what it is, speeds, capacities, caveats, launch vibes.

### Use Case 1: Competitive Analysis

```python
#@title Product Marketing Copy Generation(Use Case 1)
goal = "Analyze the ChronoTech press release and summarize their core product messaging and value proposition. Please cite your sources."
```

**Plan**: Librarian (tone) -> Researcher (retrieve press release) -> Summarizer (extract strategy) -> Writer (synthesize summary).

**Outcome**: Conversational summary of the Chrono SSD Pro positioning. Step 2 trace cites `competitor_press_release.txt`. Total duration ~70 seconds.

### Use Case 2: Technical Spec to Marketing Copy

```python
#@title Product Marketing Copy Generation(Use Case 2)

# 1. Define the Goal: A research query that asks for a creative output.
goal = "Using the official product spec sheet, write a short marketing description for the new QuantumDrive Q-1. The description should be confident, aspirational, and focus on the benefits for creative professionals. Please cite your sources."
```

**Plan**: Researcher (facts from spec) -> Summarizer (benefit-oriented insights) -> Librarian (Definition / Function/Operation / Key Findings/Impact blueprint) -> Writer (final copy).

**Outcome**: Structured marketing asset grounded in `product_spec_sheet.txt` with inline citations.

### Use Case 3: Persuasive Pitch From Multiple Sources

```python
# =CONTROL DECK 3: A persuasive pitch ===
goal = "Write a persuasive pitch on our brand tone and voice guide"
```

**Plan**: Librarian (pitch blueprint: ROI levers, Objections, Implementation) -> Researcher (broad query for "Business value and ROI of a Brand Tone and Voice Guide" retrieves `brand_style_guide.txt` + `email_nurture_outline.txt` + `seo_keywords.txt`) -> Writer (synthesizes pitch).

**Outcome**: Complete strategic document with ROI levers (consistency = trust, faster production, fewer edits, better outcomes, lower risk, faster onboarding). The engine reasons across documents because the brand guide alone has no ROI content; it links style rules to SEO goals and the email Problem -> Solution -> Proof arc.
