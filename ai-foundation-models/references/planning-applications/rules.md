# Planning AI Applications Rules

Guidelines for planning, scoping, and structuring AI application projects on foundation models.

## Core Rules

### 1. Start with "why", not "how"

Before writing code, classify the business motivation: existential threat, productivity gain, or strategic exploration. The motivation dictates whether to build in-house or buy.

- Existential threat -> build in-house; do not outsource your moat
- Productivity gain -> evaluate buy options first; they often win on time and cost
- FOMO -> R&D budget only, with explicit learning goals

### 2. Classify the AI's role on three axes

For every feature, decide where it lands on:

- Critical vs complementary
- Reactive vs proactive
- Dynamic vs static

This determines accuracy bar, latency budget, and update strategy.

**Example**:
```
# Bad: "We will add AI to our app."
# Good: "Smart Compose is complementary, reactive, and dynamic per user.
#        Latency budget = 200ms; quality bar = lower than Face ID."
```

### 3. Define the human-in-the-loop boundary explicitly

State up front whether AI suggests, decides on simple cases, or decides on everything. Use Crawl-Walk-Run to graduate automation only after measured acceptance rates justify it.

- Start at Crawl when capability is unproven
- Promote to Walk only after internal acceptance rate is high
- Promote to Run only after Walk metrics hold at scale (e.g., >95% verbatim acceptance)

### 4. Build a defensibility hypothesis before building the product

If a competitor with the same model and three engineers can replicate your product in two weeks, you do not have a product, you have a feature. Identify which moat applies:

- Technology (rare with shared foundation models)
- Data (the realistic moat for most startups, via a usage flywheel)
- Distribution (usually owned by incumbents)

### 5. Define the usefulness threshold before launch

Pick measurable thresholds across four groups: quality, latency, cost, and other (interpretability, fairness). The product does not ship until all thresholds are met.

**Example**:
```
# Customer support chatbot thresholds
quality_threshold      = "CSAT >= 4.0/5 on simple tickets"
latency_threshold      = {"TTFT": "<800ms", "total": "<5s"}
cost_threshold         = "<$0.02 per resolved ticket"
fairness_threshold     = "no demographic group >5% below mean CSAT"
```

### 6. Map business metrics to AI metrics, both ways

Every AI metric must trace to a business metric and every business metric must decompose into AI metrics you can measure during evaluation.

### 7. Plan for the last mile from day one

Assume 80% of capability arrives in 20% of the time and budget the remaining 80% of time for the final 20% of capability. Do not commit launch dates from demo velocity.

### 8. Treat maintenance as a first-class workstream

Foundation model APIs, prices, capabilities, and regulations change monthly. Bake versioning, evaluation infrastructure, and a swap-the-model exercise into the roadmap, not into a future quarter.

### 9. Choose the lightest adaptation technique that meets the threshold

Order of escalation: prompt engineering -> context construction -> finetuning -> training from scratch. Each step costs more data, compute, and complexity. Do not skip steps.

### 10. Start at the top of the stack and move down only when forced

Default order: application development -> model development -> infrastructure. Do not invest in custom infra or custom models until prompt-and-context approaches have been proven insufficient.

## Guidelines

- Track customer satisfaction, not just message volume
- Re-evaluate buy vs build every quarter; provider prices keep falling
- Avoid IP-sensitive use cases until your jurisdiction's IP-and-AI rules stabilize
- If you depend on one GPU vendor, model provider, or third-party tool, write the swap plan now
- Frontend and product instincts are now an AI engineering competency, not a separate role

## Exceptions

When these rules may be relaxed:

- **Hackathons and learning projects**: Skip use-case evaluation, defensibility, and thresholds. Build to learn.
- **Internal R&D probes**: A "FOMO" project can ship without a defensibility moat as long as the learning goal is explicit.
- **Crawl-stage tools**: Quality bars can be lower because every output is reviewed by a human.

## When AI Engineering Is the Right Discipline

Use **AI engineering** when:
- You are adapting a pre-existing foundation model
- The output is open-ended (chat, generation, summarization, code)
- Differentiation must come from prompts, context, evaluation, and interface
- You need to move from idea to demo in days

Use **ML engineering** when:
- You must train a custom model from scratch (close-ended task, tabular data, latency or cost requires a small specialist model)
- You are doing pre-training, deep architecture work, or specialized inference optimization
- The team owns the model, not an API

Use **full-stack engineering** when:
- The hard problem is interface, integration, plug-ins, or embedding into existing products
- You can satisfy AI requirements with a vendor API and prompt engineering only

In practice, modern AI teams blend all three.

## Quick Reference

| Rule | Summary |
|------|---------|
| Why first | Classify the business motivation before scoping |
| Role on three axes | Critical/complementary, reactive/proactive, dynamic/static |
| Human-in-the-loop | Use Crawl-Walk-Run; promote on data |
| Defensibility | Identify the moat before the build |
| Usefulness threshold | Quality, latency, cost, fairness gates before launch |
| Business <-> AI metrics | Every AI metric traces to a business metric |
| Last mile | Budget 4x time for the final 20% |
| Maintenance | Versioning and model swaps are first-class |
| Adaptation order | Prompt -> context -> finetune -> train |
| Stack order | App layer first; descend only when forced |
