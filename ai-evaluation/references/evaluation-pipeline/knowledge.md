# Evaluation Pipeline Knowledge

Core concepts for designing an end-to-end evaluation pipeline for AI applications.

## Overview

An evaluation pipeline is the system that lets you reliably differentiate good outcomes from bad outcomes for an AI application. Building one requires three steps: (1) evaluate every component (not just final output), (2) create unambiguous evaluation guidelines, and (3) define methods, data, and iteration practices. This chapter focuses on open-ended tasks; close-ended task pipelines are simpler and can be inferred from this process.

## Key Concepts

### Component-Level Evaluation

**Definition**: Evaluating each intermediate output of a multi-step system independently, in addition to the end-to-end result.

Without per-component evaluation you cannot localize failures. A two-step resume-employer extractor (PDF-to-text, then text-to-employer) needs separate scores for text similarity and extraction accuracy.

### Turn-Based vs Task-Based Evaluation

**Turn-based**: Evaluates the quality of each output (a turn may contain multiple steps/messages).
**Task-based**: Evaluates whether the system completes the full user task and how many turns it took.

Task-based is more important (users care about task completion), but harder because task boundaries are fuzzy in conversation.

### Evaluation Guideline

**Definition**: The written specification of what the application should do, what it should not do, the criteria, the scoring rubrics, and worked examples.

The most important step in pipeline construction. Ambiguous guidelines produce ambiguous (misleading) scores. A correct response is not always a good response.

### Evaluation Criteria

**Definition**: The specific dimensions on which a response is judged (e.g., relevance, factual consistency, safety).

LangChain's State of AI 2023 found teams use ~2.3 criteria per application on average. Criteria are derived by playing with real user queries and labeling outputs as good/bad.

### Scoring Rubric

**Definition**: A scoring system (binary, 1-5, 0-1, ternary, etc.) plus worked examples showing what each score looks like and why.

Validate rubrics with humans (you, coworkers, friends). If humans cannot follow it, refine until unambiguous. The rubric is reusable later for training data annotation.

### Business Metric Mapping

**Definition**: Translating evaluation scores into business outcomes (automation rates, revenue, stickiness).

Example: factual consistency 80% -> automate 30% of support; 90% -> 50%; 98% -> 90%. Define a usefulness threshold below which the app is unusable.

### Evaluation Methods

**Definition**: Concrete techniques used to compute scores: classifiers, semantic similarity, AI judges, logprob-based confidence, human evaluation.

Methods can be mixed (cheap classifier on 100% of data + expensive AI judge on 1%). Use logprobs when available; they signal confidence and enable perplexity-based metrics.

### Slice-Based Evaluation

**Definition**: Splitting evaluation data into subsets and reporting performance per slice (tiers, traffic source, input length, topic).

Avoids Simpson's paradox (model A beats B per-slice but loses overall) and surfaces biases against minority groups.

### Bootstrap Reliability Check

**Definition**: Resampling the evaluation set with replacement to test result variance.

If bootstrap runs swing wildly (e.g., 70% vs 90%), the evaluation set is too small.

## Terminology

| Term | Definition |
|------|------------|
| Turn | One application output (may contain multiple internal steps) |
| Task | A full user goal that may span multiple turns |
| Rubric | Scoring scale plus annotated examples per score |
| Logprobs | Log-probabilities of generated tokens (confidence signal) |
| Bootstrap | Sampling with replacement to estimate metric variance |
| Slice | A subset of evaluation data sharing some attribute |
| Stickiness | DAU/WAU/MAU type business metrics |
| Engagement | Conversation count, session duration metrics |

## How It Relates To

- **AI as Judge**: One method invoked by the pipeline; needs rubric + temperature=0.
- **Dataset Engineering (Ch. 8)**: Annotation guideline doubles as finetuning instruction guide.
- **User Feedback (Ch. 10)**: Production substitute for reference data.
- **Model Selection**: Pipeline produces the private leaderboard you use to choose models.

## Common Misconceptions

- **Myth**: Only the final output needs evaluation.
  **Reality**: Without per-component scores you cannot debug failures.

- **Myth**: A correct answer is a good answer.
  **Reality**: "You are a terrible fit" may be correct but unhelpful and therefore bad.

- **Myth**: One scoring metric is enough.
  **Reality**: Teams use ~2.3 criteria on average; one number cannot capture quality.

- **Myth**: Skip evaluation in production to save latency.
  **Reality**: A risky bet; sample-based human eval and lightweight classifiers exist.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Step 1 | Evaluate every component, not only end-to-end output |
| Step 2 | Write criteria + scoring rubric + business mapping |
| Step 3 | Pick methods, annotate sliced data, eval-the-eval, iterate |
| Bootstrap | If results swing, your eval set is too small |
| Slicing | Required to avoid Simpson's paradox and bias |
