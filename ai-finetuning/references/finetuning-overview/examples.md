# Finetuning Decision Examples

Concrete cases illustrating when finetuning is the right choice, when it is not, and when to combine it with RAG.

## When Finetuning Helps

### Example 1: Rare SQL dialect

**Situation**: A text-to-SQL model handles standard SQL well but fails on a customer's proprietary SQL dialect.

**Decision**: Finetune on (text, dialect-SQL) pairs.

**Why finetuning wins**:
- The failure is a *behavior/form* issue (model needs to output a specific syntax)
- The pattern is internalizable from examples
- Hard to fix robustly via prompt engineering alone

```python
# Finetuning data format
training_examples = [
    {"input": "Get sales for Q3", "output": "SELECT * FROM sales WHERE q='Q3';"},
    # ... hundreds more in the customer's dialect
]
```

### Example 2: Structured output for a domain DSL

**Situation**: You need outputs in a custom configuration DSL for an internal tool. Off-the-shelf models invent invalid syntax.

**Decision**: Finetune (semantic parsing).

**Why**: Strong models handle JSON/YAML/regex well, but rare DSLs lack training-data exposure. Form failure → finetuning.

### Example 3: Bias mitigation

**Situation**: Model assigns CEO roles disproportionately to male-sounding names.

**Decision**: Finetune on a curated dataset including many female CEOs (Wang & Russakovsky, 2023). Garimella et al. (2022) showed similar work for gender and racial biases in BERT-style models.

**Why**: Targeted finetuning can systematically counteract a measurable bias when prompt-based mitigation is insufficient.

### Example 4: Distillation for cost

**Situation**: GPT-4-class quality is required but inference cost is prohibitive at scale.

**Decision**: Use the large model to generate training data, then finetune a small open model on it.

**Why it works**: Grammarly finetuned Flan-T5 on 82,000 (instruction, output) pairs. The result outperformed a GPT-3 variant 60x its size on writing-assistant tasks.

```python
# Distillation data generation pseudocode
prompts = load_real_user_prompts()
teacher_outputs = [call_teacher_model(p) for p in prompts]
training_data = list(zip(prompts, teacher_outputs))
# Then SFT a small model on training_data
```

## When Finetuning Is the Wrong Choice

### Example 5: "Prompting doesn't work" — but wasn't really tried

**Situation**: A team insists on finetuning because prompting "fails."

**Investigation reveals**:
- Instructions are unclear and ambiguous
- Few-shot examples don't represent real input distribution
- Metrics are not defined
- No prompt versioning

**Decision**: Don't finetune. Tighten the prompt-experiment process first. In most cases prompt quality alone becomes sufficient.

### Example 6: "Bloomberg-style" general-domain specialization

**Situation**: Bloomberg trained BloombergGPT (50B params, 1.3M A100 hours, ~$1.3M–$2.6M compute) for finance.

**Outcome**: GPT-4-0314 (zero-shot) significantly beat it on financial benchmarks shortly after release.

| Model | FiQA F1 | ConvFinQA accuracy |
|-------|---------|---------------------|
| GPT-4-0314 (zero-shot) | 87.15 | 76.48 |
| BloombergGPT | 75.07 | 43.41 |

**Lesson**: Before committing to massive specialized training, benchmark strong general models. They may already win.

### Example 7: Outdated factual knowledge

**Situation**: Users ask "How many studio albums has Taylor Swift released?" The model says 10; the answer is 11.

**Decision**: Don't finetune. Use RAG to fetch current info. Finetuning to update facts is brittle (you'll repeat it for every fact update) and can degrade other capabilities.

### Example 8: Single-task finetuning that breaks other tasks

**Situation**: A support model handles three query types: product recommendations, order changes, and general feedback. It works well on two but fails on order changes. The team finetunes on order-change data only.

**Outcome**: Order-change handling improves; the other two regress.

**Better decision**: Either
1. Finetune on all three task types together, or
2. Use separate models per task (optionally merged later)

## RAG vs Finetuning Comparison (Ovadia et al., 2024)

Performance on knowledge-intensive tasks — RAG with the base model often beat finetuned variants:

| Model | Base | Base + RAG | FT-reg | FT-par | FT-reg + RAG | FT-par + RAG |
|-------|------|-----------|--------|--------|--------------|--------------|
| Mistral-7B | 0.481 | 0.875 | 0.504 | 0.588 | 0.810 | 0.830 |
| Llama 2-7B | 0.353 | 0.585 | 0.219 | 0.392 | 0.326 | 0.520 |
| Orca 2-7B | 0.456 | 0.876 | 0.511 | 0.566 | 0.820 | 0.826 |

**Takeaway**: For info-heavy tasks, RAG dominates and finetuning can hurt. Add finetuning only if a clearly behavioral gap remains.

## When to Combine Finetuning + RAG

### Example 9: Domain QA with strict report format

**Situation**: A medical QA system needs:
- Up-to-date guideline citations (information)
- Strict structured output (behavior)

**Decision**:
- RAG for retrieval over current guidelines (facts)
- Finetuning for the report template the institution requires (form)

```python
# Pipeline shape
def answer(query: str) -> str:
    docs = retrieve_guidelines(query)            # RAG
    context = format_context(docs)
    prompt = build_prompt(query, context)
    return finetuned_model.generate(prompt)      # Finetuned for format
```

### Example 10: Technical specification generation

**Situation**: Outputs are factually correct but lack the level of detail engineering teams need.

**Decision**: Finetune on well-defined technical specs to teach the expected detail and structure. Add RAG if specs need to reference live design documents.

**Why finetuning**: This is a *form/relevance* gap, not a fact gap.

### Example 11: HTML generator that won't compile

**Situation**: Asked to write HTML, the model emits code that fails to parse.

**Decision**: Finetune with more HTML examples. The model lacks sufficient HTML exposure — a behavioral/syntactic gap.

## Workflow Walkthrough

### Before

A team jumps straight to finetuning a 70B model on customer support transcripts because "out-of-the-box models don't understand our tone."

Result: Months of work, unclear evaluation, expensive serving, and the next base model release outperforms their custom model.

### After

The team follows the staged workflow:

1. Build evaluation pipeline with representative tasks
2. Iterate on prompts with versioning
3. Add 10 few-shot examples per task
4. Add BM25 retrieval over their support knowledge base
5. Measure: information failures dropped, but tone is still off
6. Finetune on (query, ideal-tone-response) pairs covering all task types
7. Combine RAG + finetuning, evaluate on the same pipeline

### Changes Made

1. Defined evaluation *first* — every step is measurable
2. Exhausted cheap options before committing to finetuning
3. Used RAG for the information gap, finetuning for the behavior gap
4. Trained across all task types to avoid one-task regression
5. Pre-committed to maintenance plan before going to production
