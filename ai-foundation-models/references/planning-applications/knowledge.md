# Planning AI Applications Knowledge

Core concepts for evaluating, planning, and structuring AI applications built on foundation models.

## Overview

Building a demo with foundation models is easy; building a profitable product is hard. Planning an AI application requires evaluating the use case, defining the role of AI vs humans, considering defensibility, setting realistic expectations, planning for the "last mile", and understanding the engineering stack you must operate.

## Key Concepts

### Use Case Evaluation

**Definition**: The process of deciding whether and why to build an AI application, framed as a response to risks and opportunities.

Three risk levels (high to low):
1. **Existential threat** - Competitors with AI may make you obsolete
2. **Missed opportunity** - Failure to boost profits/productivity
3. **FOMO / strategic exploration** - Avoid being left behind by transformational tech

If AI is an existential threat, build in-house. For productivity gains, "buy" options often beat "build".

### Role of AI in the Application

**Definition**: A classification of how AI fits into a product, taken from Apple's framework.

Three axes:
- **Critical vs complementary** - Does the app work without AI?
- **Reactive vs proactive** - Is AI triggered by users or by opportunity?
- **Dynamic vs static** - Does AI update continuously per user, or periodically with the model?

### Human-in-the-Loop

**Definition**: Involving humans in AI's decision-making processes.

Microsoft's **Crawl-Walk-Run** framework for increasing automation:
1. **Crawl** - Human involvement is mandatory
2. **Walk** - AI interacts directly with internal employees
3. **Run** - Increased automation, including direct interaction with external users

### AI Product Defensibility

**Definition**: The set of moats that protect an AI application from being copied or absorbed.

Three competitive advantages: **technology, data, distribution**. With foundation models, technology converges across companies, distribution favors incumbents, so **data and usage feedback loops** are typically the only viable moat for startups.

### Usefulness Threshold

**Definition**: The minimum quality the AI must reach before it is shown to customers.

Measured across four metric groups: quality, latency (TTFT, TPOT, total), cost per inference, and other (interpretability, fairness).

### Last Mile Challenge

**Definition**: The disproportionate effort required to move an AI product from "good demo" to "production-ready".

The journey from 0 to 60 (or 80) is fast; 60 to 100 (or 80 to 95+) is exceedingly hard. LinkedIn reported one month to reach 80%, four more months to surpass 95%.

### The Three-Layer AI Stack

**Definition**: The architectural layers any AI application sits on.

1. **Application development** (top) - Prompts, context, evaluation, interfaces
2. **Model development** (middle) - Modeling, training, finetuning, dataset engineering, inference optimization
3. **Infrastructure** (bottom) - Serving, data/compute management, monitoring

Application teams typically start at the top and move down only as needed.

### Model Adaptation

**Definition**: Techniques for tailoring a pre-existing foundation model to your use case.

Two categories:
- **Prompt-based** - No weight updates (prompt engineering, context construction)
- **Finetuning** - Updates model weights; needs more data, but enables capabilities prompts cannot reach

## Terminology

| Term | Definition |
|------|------------|
| Crawl-Walk-Run | Microsoft's framework for graduating from manual to autonomous AI |
| TTFT | Time to first token |
| TPOT | Time per output token |
| Autoregressive | Generates tokens sequentially, one at a time |
| Pre-training | Training a model from scratch with random initial weights |
| Finetuning | Continuing training from previously trained weights |
| Post-training | Conceptually equivalent to finetuning, usually performed by the model developer |
| Open-ended output | A response space too large to enumerate ground truths |
| Data flywheel | Usage data feeding back into model and product improvement |
| MMLU | Massive Multitask Language Understanding benchmark |

## How It Relates To

- **ML engineering** - AI engineering evolved from ML engineering; many principles still apply
- **Full-stack engineering** - Increased emphasis on AI interfaces brings AI eng closer to web/full-stack development
- **Evaluation** - Open-ended outputs make evaluation a much bigger problem than in classical ML

## Common Misconceptions

- **Myth**: A great demo means the product is nearly done.
  **Reality**: Demos are weekend projects; products take months to years.

- **Myth**: ML expertise is required to build AI applications.
  **Reality**: With foundation models, ML knowledge is nice-to-have, not must-have.

- **Myth**: "Training" includes feeding examples into a prompt.
  **Reality**: Feeding examples via input is prompt engineering, not training.

- **Myth**: If the technology is the same, big companies always win.
  **Reality**: Calendly, Mailchimp, and Photoroom each won by being a "feature" of a bigger product.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Use case evaluation | Decide why you are building before what you are building |
| Role of AI | Classify on critical/complementary, reactive/proactive, dynamic/static |
| Defensibility | Tech and distribution converge; data flywheel is the moat |
| Usefulness threshold | Quality, latency, cost, and other metrics that gate launch |
| Last mile | Final 20% takes 4x or more the time of the first 80% |
| Three-layer stack | Application dev / model dev / infrastructure |
| Model adaptation | Prompt-based (no weights) vs finetuning (weight updates) |
