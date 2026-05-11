# Planning AI Applications Examples

Concrete examples of use case evaluation, defensibility, milestone planning, and stack layering.

## Use Case Risk Levels

### Level 1: Existential threat (build in-house)

Industries highly exposed to foundation models per the OpenAI "GPTs are GPTs" study:
- Financial analysis
- Insurance underwriting
- Document processing
- Advertising and copywriting
- Web design
- Image production

In these industries, AI-native competitors can disintermediate incumbents. Outsourcing AI to a vendor would mean handing the moat to a competitor.

### Level 2: Productivity opportunity (often buy)

Common targets where buying beats building:
- User acquisition (copy, descriptions, promo visuals)
- Customer support and retention
- Sales lead generation
- Internal communication, market research, competitor tracking

### Level 3: Strategic exploration (R&D)

A budget line in R&D for understanding the technology, justified only at companies large enough to absorb it.

## Role of AI: Three-Axis Classification

| Feature | Critical/Complementary | Reactive/Proactive | Dynamic/Static |
|---------|----------------------|-------------------|----------------|
| Face ID | Critical | Reactive | Dynamic |
| Gmail Smart Compose | Complementary | Reactive | Static |
| Google Maps traffic alerts | Complementary | Proactive | Static |
| ChatGPT (with memory) | Critical | Reactive | Dynamic |
| Google Photos object detection | Complementary | Reactive | Static |

Implications:
- Critical features need a higher accuracy and reliability bar
- Reactive features need low latency; proactive features can be precomputed
- Proactive features need a higher quality bar to avoid being seen as intrusive
- Dynamic features need per-user finetuning or memory; static features need versioned releases

## Human-in-the-Loop Spectrum (Customer Support Chatbot)

| Stage | Behavior |
|-------|----------|
| Crawl | AI shows several candidate responses; human agents pick and edit |
| Walk | AI handles simple tickets autonomously for internal users; routes complex tickets to humans |
| Run | AI responds directly to external users for the full ticket scope |

Promotion criterion: at Walk, if 95% of AI-suggested responses to simple tickets are accepted verbatim by human agents, customers can interact with AI directly for those simple tickets.

## Defensibility Decisions

### Bad: A feature dressed as a product

A startup builds a PDF-parsing app on top of ChatGPT, assuming ChatGPT will never parse PDFs well at scale. When the assumption breaks, the product is subsumed.

**Problem**: No moat. Three engineers at the model provider can replicate it.

### Good: The same feature with a different moat

The same PDF parser, but built on top of an open source model and targeted at customers who need to host models in-house for compliance reasons.

**Why it works**: The customer's hosting requirement is the moat, not the parsing capability.

### Good: Features that became companies

| Company | Could have been a feature of |
|---------|------------------------------|
| Calendly | Google Calendar |
| Mailchimp | Gmail |
| Photoroom | Google Photos |

These companies won by going deep on a feature that an incumbent overlooked, then using product velocity and usage data to outpace the incumbent's response.

## Milestone Planning: The Last Mile

LinkedIn generative AI product timeline:
- Month 1: 80% of target experience
- Months 2 through 5: incremental work to surpass 95%

Pattern: each 1% gain after 80% is slower and more discouraging than the last. Time spent is dominated by hallucinations and product kinks, not new capability.

## The Three-Layer AI Stack

```
+-----------------------------------------------------------+
| APPLICATION DEVELOPMENT                                   |
| - Evaluation (selection, benchmarking, monitoring)        |
| - Prompt engineering and context construction             |
| - AI interface (web, browser ext, chat plug-in, voice)    |
+-----------------------------------------------------------+
| MODEL DEVELOPMENT                                         |
| - Modeling and training (architectures, finetuning)       |
| - Dataset engineering (dedup, tokenization, retrieval)    |
| - Inference optimization (quantization, distillation)     |
+-----------------------------------------------------------+
| INFRASTRUCTURE                                            |
| - Model serving                                           |
| - Data and compute management                             |
| - Monitoring                                              |
+-----------------------------------------------------------+
```

Where investment is going (per the author's 2024 GitHub analysis): infrastructure grew slowly because resource management, serving, and monitoring needs are stable. Application development grew the fastest after Stable Diffusion and ChatGPT.

## Model Development Importance Shift

| Category | Traditional ML | Foundation Models |
|----------|---------------|-------------------|
| Modeling and training | ML knowledge required | ML knowledge nice-to-have |
| Dataset engineering | Feature engineering on tabular data | Dedup, tokenization, retrieval, quality control on unstructured data |
| Inference optimization | Important | Even more important (autoregressive, large) |

## Application Development Importance Shift

| Category | Traditional ML | Foundation Models |
|----------|---------------|-------------------|
| AI interface | Less important | Important |
| Prompt engineering | Not applicable | Important |
| Evaluation | Important | More important |

## AI Engineering vs ML Engineering vs Full-Stack

| Dimension | ML Engineering | AI Engineering | Full-Stack Engineering |
|-----------|---------------|---------------|----------------------|
| Model origin | Train your own | Use someone else's | Vendor API |
| Primary work | Training, modeling | Adaptation, evaluation | Interface, integration |
| Compute scale | Often modest | Large clusters, many GPUs | Trivial |
| Output style | Mostly close-ended | Open-ended | N/A |
| Build order | Data -> model -> product | Product -> model -> data | Product first |
| Languages | Python-centric | Python plus JS (LangChain.js, Vercel AI SDK, OpenAI Node) | JS/TS-centric |

## Prompt-Engineering Impact: Gemini vs GPT-4 on MMLU

Same model, different prompting technique, very different scores:

| Model | Technique | MMLU |
|-------|-----------|------|
| Gemini Ultra | CoT@32 | 90.04% |
| Gemini Ultra | 5-shot | 83.7% |
| GPT-4 | CoT@32 (via API) | 87.29% |
| GPT-4 | 5-shot (reported) | 86.4% |

Lesson: evaluation results are not comparable unless the prompting technique is held constant. This is also the case study for why prompt engineering belongs in the application development layer.

## Build Order Inversion (Python sketch)

```python
# Traditional ML order
def traditional_ml_project():
    data = gather_and_label_data()      # months
    model = train_model(data)            # weeks
    product = build_product(model)       # last
    return product

# AI engineering order
def ai_engineering_project():
    product = build_demo_with_api()      # days
    if product.shows_promise():
        data = gather_usage_data(product)        # ongoing
        model = adapt_model(data)                # only if needed
    return product
```

The inversion lets full-stack engineers iterate on AI products as quickly as on any other web product, and is why product instinct is now an AI engineering skill.
