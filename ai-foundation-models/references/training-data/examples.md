# Training Data Examples

Concrete illustrations of training data trade-offs: multilingual behavior, domain-specific use cases, and data composition choices.

## Multilingual Model Behavior

### Under-representation Causing Accuracy Gaps

General-purpose models score noticeably worse in low-resource languages on the same benchmark.

**Observation**: On MMLU, GPT-4 scored substantially higher in English than in Telugu, Marathi, and Punjabi - the three lowest-scoring languages also being among the most under-represented in Common Crawl.

**Why it happens**:
- Training corpus heavily skewed toward English (~46% of Common Crawl)
- Telugu, Marathi, Punjabi each under 0.025% of Common Crawl
- Limited examples mean limited learned patterns

### Translation Round-Trip Information Loss

Translating queries to English, processing, and translating back is a tempting workaround but causes losses.

```python
# Risky pattern: translate to English, process, translate back
query_vi = "Em chao anh"  # Vietnamese with relational pronouns
query_en = translate(query_vi, target="en")  # -> "I greet you"
response_en = llm(query_en)
response_vi = translate(response_en, target="vi")
```

**Problems**:
- Vietnamese relational pronouns (em/anh) collapse to "I"/"you" - speaker relationship lost
- Quality of round-trip depends on translation quality in both directions
- Cultural and grammatical nuance dropped at each translation step

### Cross-Language Safety Inconsistency

Same model, same prompt category, different language - very different refusal behavior.

**Observation**: When NewsGuard prompted ChatGPT-3.5 to produce misinformation about China:
- English: refused 6 out of 7 prompts
- Simplified Chinese: produced false claims 7 out of 7
- Traditional Chinese: produced false claims 7 out of 7

**Implication**: Safety evaluation in English does not guarantee safety in other languages.

### Tokenization Cost Inflation

Same content, vastly different token counts across languages.

```python
text_en = "Where is the nearest hospital?"
text_hi = "..."  # Hindi equivalent
text_my = "..."  # Burmese equivalent

tokens_en = tokenizer.encode(text_en)  # ~7 tokens
tokens_hi = tokenizer.encode(text_hi)  # ~32 tokens
tokens_my = tokenizer.encode(text_my)  # ~72 tokens

# API cost is roughly 10x higher for Burmese
# Latency is roughly 10x longer for Burmese
```

**Trade-off**: A user in Myanmar pays ~10x the cost and waits ~10x longer for the same answer compared to an English user.

## Domain-Specific Model Use Cases

### Drug Discovery (AlphaFold, BioNeMo)

**Why a general model fails**:
- Protein, DNA, RNA sequences follow specific formats
- Data is expensive to acquire and largely absent from public web crawls
- Tasks require structural understanding not learned from text

**Solution**: AlphaFold trained on ~100,000 known protein sequences and 3D structures. NVIDIA's BioNeMo focuses on biomolecular data for drug discovery.

### Medical Q&A (Med-PaLM2)

**Why a general model fails**:
- Clinical accuracy requires medical literature depth beyond general web text
- Medical terminology, dosing, and diagnostic reasoning need specialized data

**Solution**: Combine an LLM with curated medical data to achieve higher accuracy on medical queries.

### Cancer Screening (Specialized Vision Models)

**Why a general model fails**:
- X-rays and fMRI scans are rare due to patient privacy
- General image models are trained on internet photos (cars, animals, scenes)
- Diagnostic features differ fundamentally from natural images

**Solution**: Domain-specific vision models trained on de-identified medical imaging datasets.

### Untapped Domains

The same logic applies beyond biomedicine:
- A model trained on architectural sketches could outperform Stable Diffusion for architects
- A model trained on factory floor plans could optimize manufacturing better than ChatGPT
- Any field with proprietary data and specialized formats is a candidate

## Training Data Composition Trade-offs

### Bad: Use Everything Available

```python
# Naive approach: maximize data volume
training_data = (
    common_crawl_2020_2024  # ~3B pages/month, mixed quality
    + reddit_dump
    + twitter_dump
    + random_pdfs
)
# Result: model trained on misinformation, propaganda, low-quality content
# Performance ceiling capped by noise in the data
```

**Problems**:
- Common Crawl includes clickbait, conspiracy theories, propaganda
- 1,000 most common Common Crawl websites include outlets ranking low on NewsGuard's trustworthiness scale
- Compute spent processing data that hurts model behavior

### Better: Heuristic Filtering

```python
# Heuristic-based filtering (e.g., GPT-2 approach)
training_data = [
    page for page in common_crawl
    if page.is_reddit_link and page.upvotes >= 3
]
```

**Improvement**: Removes pages nobody endorsed.
**Limitation**: Reddit upvotes do not guarantee quality, accuracy, or appropriateness.

### Best: Quality-Curated Specialized Data

```python
# Curated approach: small high-quality dataset
training_data = curated_high_quality_code_corpus  # ~7B tokens
model = train(architecture=Transformer(params=1.3e9), data=training_data)
# Result: 1.3B-parameter model outperforms much larger models on coding benchmarks
```

**Why it works**:
- Quality of examples matters more than raw volume
- Smaller model + better data beats larger model + noisier data
- Reference: Gunasekar et al. (2023) demonstrated this on coding tasks

## Decision Walkthrough

### Scenario: Building a Vietnamese Customer Support Bot

**Naive choice**: Use GPT-4 directly with English-translated prompts.

**Problems**:
- Information loss on Vietnamese pronouns degrades politeness handling
- Higher token cost for Vietnamese inputs
- Cross-language safety inconsistencies

**Better choice**: Use PhoGPT (Vietnamese-specific) or fine-tune a general base on Vietnamese support transcripts.

### Scenario: Drug Interaction Checker

**Naive choice**: Prompt GPT-4 with drug names and ask for interactions.

**Problems**:
- Pharmacological interaction data is sparse on the public web
- Hallucinated interactions can cause real harm
- General model has no specialized training signal here

**Better choice**: Use a domain model like Med-PaLM2 or fine-tune on a curated drug interaction database, with deterministic lookup as a guardrail.

### Scenario: Architectural Design Assistant

**Naive choice**: Use Stable Diffusion or DALL-E for sketch generation.

**Problems**:
- General image models trained on internet photos, not architectural conventions
- Outputs lack structural and code-compliance awareness

**Better choice**: Fine-tune a vision model on architectural sketches or build a domain-specific generator from a curated sketch corpus.
