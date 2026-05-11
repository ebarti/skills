# AI Engineering Overview Rules

Guidelines for evaluating AI use cases and approaching FM-based applications.

## Core Rules

### 1. Match the Application to AI's Strengths

AI is well-suited for tasks that are repetitive, communication-heavy, creative, or aggregation-focused. It is poorly suited for tasks requiring physical presence, deep specialized expertise, or high stakes with no human review.

- High-fit tasks: writing, summarization, coding, image/video generation, conversational interfaces, data extraction
- Low-fit tasks: cooking, stonemasonry, athletics, anything requiring a body or moment-to-moment judgement
- Use the "exposure" heuristic: how much of this task could be cut by 50%+ if AI helped?

### 2. Decide on AI's Role: Critical or Complementary

Be explicit about whether the AI is doing the work autonomously or supporting a human.

- **Critical** (autonomous): AI output is the final answer; needs higher accuracy, stronger guardrails, and lower risk profile
- **Complementary** (human-in-loop): AI suggests, human approves; can tolerate more errors because the human filters them
- Default to complementary in early deployments; promote to critical only after evaluation

### 3. Prefer Lower-Risk Internal Use Cases First

Enterprises move faster on internal-facing applications than external-facing ones. Build expertise inside before exposing AI to customers.

- Start: internal knowledge management, document processing, employee tooling
- Then: copilots and product features for power users
- Last: customer-facing chatbots, autonomous decisions

### 4. Prefer Close-Ended Tasks Over Open-Ended Ones When Risk Matters

Open-ended generation is harder to evaluate, which makes risk hard to estimate.

- Classification, extraction, structured output: easy to evaluate, lower risk
- Free-form generation: harder to evaluate, needs more guardrails
- If a task can be reframed as classification or extraction, do it

### 5. Choose the Cheapest Adaptation Technique That Works

Order of effort: prompt engineering → RAG → finetuning. Try each before escalating.

- Prompt engineering: minutes to hours, no infrastructure
- RAG: hours to days, needs retrieval setup
- Finetuning: days to weeks, needs labeled data and training infrastructure

### 6. Buy Before You Build

Adapting a foundation model is dramatically cheaper than building one from scratch (e.g., 10 examples + 1 weekend vs. 1M examples + 6 months).

- Build a custom model only when API costs, latency, privacy, or task-specific accuracy require it
- Task-specific models still win on size, speed, and cost when the task is narrow
- Treat this as a real buy-vs-build decision per use case, not a default

### 7. Plan for the Probabilistic Nature of Outputs

Foundation model outputs are predictions, not deterministic answers. Design accordingly.

- Validate structured outputs; never trust them blindly
- Plan for hallucinations in factual tasks
- Probabilistic = great for creative tasks (variation is a feature)
- Probabilistic = risky for high-stakes tasks (variation is a bug)

### 8. Differentiate Beyond the Base Model

If a foundation model API call is your entire product, anyone can replicate it. Defensibility comes from data, distribution, workflow integration, or proprietary evaluation — not the model itself.

- Don't assume access to the same model is your moat
- Combine the model with proprietary data, UX, integrations, or domain workflows
- Watch for "lunch taken by AI" risk: if an FM does your product's job for free in a chat box, that's an existential threat (e.g., Chegg vs. ChatGPT)

## Guidelines

- A single application can span multiple use case categories — don't over-narrow your framing
- AI helps low-skill workers more than high-skill workers in writing tasks; this can compress quality variance across a team
- AI is currently better at frontend than backend coding; better at documentation than complex logic
- Productivity gains are uneven: 2x for documentation, 25–50% for code generation/refactoring, minimal for highly complex tasks
- Tools that can plan and call external APIs are called **agents**; reach for agents when a task needs multi-step actions and external state

## Use Case Category Rules

Each FM application typically fits one or more of these categories. Each category implies different requirements.

| Category | Key Rule |
|----------|----------|
| Coding | Use when productivity gain is measurable; expect uneven quality across task types |
| Image/Video | Probabilistic variation is a feature; great for creative iteration |
| Writing | High tolerance for errors; user can ignore bad suggestions |
| Education | Personalization is the highest-value lever; one-size-fits-all is the bar to beat |
| Conversational bots | Fast response wins over perfect response in support contexts |
| Information aggregation | Trust depends on faithful summarization; cite sources |
| Data organization | Extraction must be evaluable; prefer structured outputs |
| Workflow automation | Requires tool access; design for failure modes of each tool call |

## Exceptions

When core rules may be relaxed:

- **Creative use cases**: Probabilistic outputs are a feature, not a bug — relax the determinism requirement
- **Internal tooling**: Higher error tolerance because users understand the limits and can correct
- **Demos and prototypes**: Prompt engineering alone is fine; don't pre-optimize with RAG/finetuning
- **High-stakes domains** (medical, legal, financial): Tighten all rules; assume critical role even if labeled complementary

## Quick Reference

| Rule | Summary |
|------|---------|
| Match AI strengths | Pick tasks AI is good at; skip the rest |
| Critical vs complementary | Be explicit about AI's role |
| Internal first | Lower risk, builds expertise |
| Close-ended first | Easier to evaluate |
| Cheapest adaptation | Prompt → RAG → finetune |
| Buy before build | Adapt FMs unless narrow task forces custom |
| Plan for probabilistic | Outputs are predictions, not facts |
| Defensibility beyond model | Data, UX, workflow — not the API call |
