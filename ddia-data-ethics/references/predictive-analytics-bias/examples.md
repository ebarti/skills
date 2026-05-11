# Predictive Analytics, Bias, and Accountability Examples

Real-world scenarios from the chapter and adjacent algorithmic-accountability literature, illustrating bias, feedback loops, and accountability failures.

## Bad Examples (Harm in Production)

### Recidivism Scoring (COMPAS-style)

A model predicts whether a defendant will reoffend; courts use the score in bail and sentencing.

**Problems**:
- Trained on arrest records, which themselves reflect biased policing patterns
- Higher false-positive rates for Black defendants on the same actual outcomes
- Defendants and their lawyers cannot inspect the proprietary model
- A wrong "high risk" prediction means lost liberty — irreversible harm

### Predictive Policing (PredPol-style)

A model predicts where crime will occur; patrols are dispatched there.

**Problems** — the canonical self-fulfilling prophecy:
- Initial training data: arrests, which depend on where police already patrol
- Model says "patrol neighborhood X" → police find more incidents in X (because they're looking)
- Those incidents become next month's training data → model "confirms" X is high-crime
- Feedback loop: patrol density compounds independently of actual crime rates
- Disparate impact on already over-policed communities

### Credit Scoring Used for Hiring

Employer screens applicants by credit score.

**Problems** — downward-spiral feedback loop from the chapter:
- A medical emergency causes missed payments and a credit drop
- Lower score → fewer job offers → joblessness → poverty → worse score
- The model's "prediction" of poor performance becomes the cause of poor outcomes
- No connection between credit history and actual job performance

### Hiring Algorithms Trained on Past Hires

Resume screener trained on "who succeeded here before."

**Problems**:
- Past hiring was biased; model learns "people like our existing hires get through"
- Even with the gender field removed, proxies (sports, language patterns, schools) carry the signal
- Disparate impact on women, minorities, non-traditional candidates
- "Money laundering for bias" — discrimination now appears to be a math result

### Postal-Code Lending

Loan model uses ZIP code as a feature; race column is excluded.

**Problems**:
- ZIP code in segregated neighborhoods is a near-perfect race proxy
- Model produces racially disparate denial rates
- Removing the protected attribute did nothing; the proxy carried the bias
- Subjects cannot appeal because the criteria are opaque

### Algorithmic Pricing Collusion (German Gas Stations)

Competing gas stations adopt algorithmic pricing.

**Problems** (from the chapter):
- Algorithms learn from each other's prices in near-real-time
- Tacit coordination emerges without any explicit agreement
- Consumer prices rise; competition decreases
- No human "decided" to collude — accountability vanishes into the system

### Recommendation Echo Chambers

Recommender optimizes engagement on content the user already agrees with.

**Problems**:
- Users are shown progressively narrower viewpoints
- Misinformation, polarization, and stereotypes are amplified
- Documented impact on election campaigns
- Feedback loop: each click confirms the narrower model

## Good Examples (Accountable Design)

### Decisions Based on the Individual's Own Conduct

Replace "people like you defaulted" with "your actual borrowing history" — closer to a traditional credit report's premise.

**Why it works**:
- Avoids stereotyping by group membership
- Subject can identify and contest specific factual errors
- Links the decision to the person's own behavior, not statistical neighbors

### Published Appeal Path with Human Reviewer

A loan denial includes the top contributing factors and a one-click route to a human reviewer with override authority.

**Why it works**:
- Closes the accountability gap — a named human owns the final decision
- Forces the operator to maintain an explanation pipeline
- Surfaces real-world failures that retraining alone would miss

### Disparate-Impact Audit Before Launch

Hold-out evaluation reports false-positive and false-negative rates split by protected class. Launch is gated on parity within a documented threshold.

**Why it works**:
- Catches proxy-driven discrimination before it affects users
- Documents the fairness criteria in writing — auditable later
- Forces investigation when a feature drives the disparity

### Control Group to Detect Feedback Loops

A small fraction of cases is decided independently of the model. The model's predictions on the control group are tracked over time.

**Why it works**:
- Provides feedback-loop-free training data
- Reveals when the model's deployment is changing reality
- Allows comparison of outcomes "with model" vs "without model"

## Refactoring Walkthrough

### Before: Opaque, Feedback-Driven Hiring Filter

A model trained on past hires auto-rejects 80 percent of applicants. Recruiters never see them. The applicant gets a form email; no reason given. Next year's training data is built from this year's interviews.

### After: Accountable Hiring Pipeline

The model produces a *ranked queue*, not a reject decision. Recruiters review top-N and a random sample of the rest. Rejections include a human reviewer's name and an appeal address. Disparate-impact metrics are reported per quarter to a designated owner. A control group of randomly admitted candidates feeds future model evaluation.

### Changes Made

1. Removed the auto-reject step — model assists, humans decide
2. Added human-readable refusal reasons and an appeal channel
3. Added quarterly disparate-impact audit by protected class
4. Added a randomly-selected control group to break the feedback loop
5. Documented model lineage so any decision can be reconstructed for review
