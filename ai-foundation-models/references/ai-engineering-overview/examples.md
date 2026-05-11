# AI Engineering Overview Examples

Concrete use cases and decision examples drawn from foundation model applications.

## Foundation Model as a Completion Machine

The simplest mental model: prompt in, completion out.

```python
# A language model treated as a completion machine
prompt = "To be or not to be"
completion = model.complete(prompt)
# -> ", that is the question."
```

**Why it works**: Many tasks reduce to text completion — translation, summarization, classification, code generation.

## Reframing Tasks as Completion

### Translation

```python
prompt = "How are you in French is"
completion = model.complete(prompt)
# -> "Comment ca va"
```

### Classification

```python
prompt = """
Question: Is this email likely spam? Here's the email: {email_content}
Answer:
"""
completion = model.complete(prompt.format(email_content=email))
# -> "Likely spam"
```

**Why it works**: Wrapping the input with framing text turns a generative model into a task-specific tool — no training required.

## Adaptation Technique Examples

### Prompt Engineering

Use case: Generating product descriptions for a retailer.

```python
prompt = f"""
You are a copywriter for {brand_name}.
Brand voice: {brand_voice}

Generate a product description in 80-120 words.
Include 2 customer benefits and 1 differentiator.

Examples of good descriptions:
{few_shot_examples}

Product: {product_specs}
Description:
"""
description = model.complete(prompt)
```

**Why it works**: Detailed instructions plus examples push the general model toward brand-aligned output without any training.

### Retrieval-Augmented Generation (RAG)

Use case: Same retailer, but pull in real customer reviews to ground descriptions.

```python
def generate_description(product):
    reviews = review_db.search(product.id, top_k=5)
    prompt = f"""
    Generate a product description using these real customer reviews:
    {reviews}

    Product: {product.specs}
    Description:
    """
    return model.complete(prompt)
```

**Why it works**: The model gets fresh, specific context it could not have memorized at training time.

### Finetuning

Use case: A writing assistant fluency model (e.g., Grammarly approach).

```python
# Conceptual finetuning loop
training_pairs = [(awkward, polished) for awkward, polished in dataset]
finetuned_model = finetune(
    base_model="foundation-model-v1",
    data=training_pairs,
    epochs=3,
)
```

**Why it works**: When the desired behavior is consistent and high-volume, baking it into weights is more reliable than re-prompting every call.

## Use Case Category Examples

### Coding

| Task | Example application |
|------|--------------------|
| General code completion | GitHub Copilot |
| English to SQL | DB-GPT, SQL Chat, PandasAI |
| Screenshot to code | screenshot-to-code, draw-a-ui |
| Cross-language translation | GPT-Migrate, AI Code Translator |
| Documentation | Autodoc |
| Test generation | PentestGPT |
| Commit messages | AI Commits |

**What makes them work**: Code is structured, has clear correctness signals (compile, run tests), and is well-represented in training data.

### Image and Video

- Midjourney (image generation)
- Adobe Firefly (photo editing)
- Runway, Pika Labs, Sora (video generation)
- AI-generated profile photos for social media and job applications
- Marketing: ad variation generation per season/location, A/B testable creative

**What makes them work**: Probabilistic variation is a creative feature, not a defect. Users iterate quickly and select the best output.

### Writing

- Consumer: tone shifting (angry email -> pleasant), bullets to paragraphs, essay drafts, interactive AI-generated children's books
- Enterprise: SEO content, cold outreach, ad copy, product descriptions, performance reports
- Embedded: Google Docs, Notion, Gmail, Grammarly

**What makes them work**: High error tolerance — users can ignore bad suggestions. Models are trained on text completion, so writing is a natural fit.

### Education

- Personalized lecture plans per student
- Format adaptation (read aloud for auditory learners, code translation for math)
- Quiz generation and grading
- AI debate partner that can present multiple views
- Khan Academy AI tutor

**What makes them work**: Personalization is the high-value lever; AI can deliver it at scale where one human teacher cannot.

### Conversational Bots

- Consumer: general chatbots, AI companions, AI therapists
- Enterprise: customer support, product copilots (insurance claims, taxes, policy lookup)
- Voice: Google Assistant, Siri, Alexa
- 3D / NPCs: Inworld, Convai for game characters

**What makes them work**: Faster response than humans for support; emotional engagement for companions; scriptable behavior for games becomes dynamic.

### Information Aggregation

- Talk-to-your-docs: contracts, disclosures, papers
- Meeting/email/Slack summarization (e.g., Instacart "Fast Breakdown" prompt: facts, open questions, action items)
- Research summarization and paper comparison
- Competitive analysis

**What makes them work**: Distillation reduces management burden; well-defined input/output; faithfulness can be checked against source.

### Data Organization

- Image/video search (Google Photos)
- Generated image search (Google Image Search returning synthesized matches)
- Data analysis: visualization scripts, outlier detection, forecasting
- IDP (intelligent data processing): extract from credit cards, licenses, receipts, contracts

**What makes them work**: Unstructured data + structured query gap. AI bridges it. IDP market estimated at $12.81B by 2030.

### Workflow Automation (Agents)

- Consumer: booking restaurants, refund requests, trip planning, form filling
- Enterprise: lead management, invoicing, reimbursements, customer requests, data entry
- Data synthesis: AI generates labels, humans verify, models improve

**What makes them work**: Multi-step, tool-using behavior unlocks economic value. Requires permissions to external tools (calendar, phone, search).

## Decision Example: Build a Product Description Tool

A retailer wants on-brand descriptions. Walk the adaptation ladder.

**Step 1 — Prompt engineering**
```python
# Detailed instructions + a few brand-voice examples
prompt = build_prompt(brand_voice, examples, product)
out = model.complete(prompt)
```
Cost: minimal. Try this first.

**Step 2 — RAG, if voice still drifts**
```python
# Pull recent on-brand descriptions and reviews
context = vector_db.search(product.category, top_k=5)
out = model.complete(build_prompt(brand_voice, context, product))
```
Cost: moderate. Add only if Step 1 falls short.

**Step 3 — Finetune, if scale justifies it**
```python
# Train on the historical catalog of approved descriptions
finetuned = finetune(base_model, approved_descriptions)
out = finetuned.complete(product.specs)
```
Cost: highest. Use only if Steps 1 and 2 cannot meet the bar at the volume needed.

## Anti-Example: Building Your Own Foundation Model

```python
# Don't do this for an application
model = train_from_scratch(
    architecture="transformer",
    data=[...],         # need millions of examples
    compute="$$$$$",   # need a data center
    time="6 months",
)
```

**Why it fails**: Almost no one needs this. Adapting an existing FM is orders of magnitude cheaper. Build only if you are a research lab, a frontier provider, or have a truly specialized domain that no FM covers.
