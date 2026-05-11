# Predictive Analytics, Bias, and Accountability Rules

Guidelines for engineers and architects building or reviewing systems that make algorithmic decisions about people.

## Core Rules

### 1. Don't Treat ML Output as Objective

A model's output looks rigorous because it's a number, but it inherits every bias in its training data and every assumption in its labels.

- Never describe a scoring or classification system as "neutral," "objective," or "unbiased" in product copy or to stakeholders
- "Machine learning is like money laundering for bias" — assume bias is present until proven otherwise
- Expose the input features and label provenance to anyone who must explain a decision

### 2. Require Human Review and Appeal for Consequential Decisions

When the decision affects credit, employment, housing, parole, insurance, or access to public services, a human must be in the loop and an appeal path must exist.

- Provide an appeal mechanism before launch, not after a complaint
- Make it easy to reach — credit-bureau-style "we make it nearly impossible" is the anti-pattern
- The reviewer must have authority to override the model and the data to do so meaningfully

### 3. Audit for Disparate Impact Across Protected Classes

A facially neutral feature (postal code, IP, "shops at brand X") can be a near-perfect proxy for race or class.

- Measure outcome rates per protected class on hold-out data, before and after deployment
- Investigate any feature that correlates strongly with a protected trait
- Removing the protected column does not remove the discrimination — proxies remain

### 4. Detect and Break Feedback Loops

Predict-then-act-on-prediction creates self-fulfilling data: more patrols → more arrests → "model was right" → more patrols.

- Map the full sociotechnical system before launch (systems thinking, not just code)
- Hold out a control group whose treatment is independent of the model's prediction
- Periodically retrain on data that does not reflect the model's prior decisions
- Watch for downward spirals affecting the people the model already disadvantaged

### 5. Document Model Lineage and Decision Criteria

If a decision is challenged in court or by a regulator, you must be able to explain how it was made.

- Record training data sources, snapshot dates, label definitions, and known limitations
- Record feature definitions and feature-importance for production decisions
- Record the model version, its evaluation metrics, and known failure modes
- "We don't know why the model said no" is not an acceptable answer

### 6. Avoid ML for Decisions Where Wrong Answers Cause Irreversible Harm

Probabilistic outputs will be wrong in individual cases; design for that being unacceptable in some domains.

- Prefer rules-based logic (with audit trail) over ML for liberty, safety, and survival decisions
- If you must use ML, set the operating point to favor caution and pair with human judgment
- A model "correct on average" is not correct enough when one mistake destroys a life

## Guidelines

- Prefer features about *the individual's actual conduct* over features about *people like them*
- Make refusal reasons human-readable — vague "you do not meet our criteria" frustrates appeal
- Treat your training data as a record of past human decisions, not as ground truth about the world
- Engage affected communities during design — ethics is participatory, not a checklist
- Remember the cost asymmetry: a missed sale is cheap to the operator; an "algorithmic no" is enormous to the subject

## Exceptions

When these rules may be relaxed:

- **Non-consequential predictions** (weather, demand forecasting, equipment failure): the human-review and appeal rules apply less directly
- **Aggregate analytics** (population-level health, traffic): individual-level harms are reduced, though feedback-loop and bias rules still apply
- **Internal experimentation** with no production effect on users: relax appeal/review until you ship

## Quick Reference

| Rule | Summary |
|------|---------|
| Not objective | ML output reflects training-data bias; never market it as neutral |
| Human + appeal | Consequential decisions need a reviewer with override power and a published appeal path |
| Audit disparate impact | Measure outcome rates by protected class; investigate proxy features |
| Break feedback loops | Use control groups; don't retrain only on data shaped by the model |
| Document lineage | Be able to reconstruct any decision: data, features, version, criteria |
| Avoid irreversible harm | Don't use ML where a wrong answer destroys someone's life |
