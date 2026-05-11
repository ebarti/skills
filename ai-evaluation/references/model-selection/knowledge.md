# Model Selection Knowledge

Core concepts for selecting the right foundation model for your application.

## Overview

Model selection is about choosing the model that's best for *your application*, not the model with the highest leaderboard rank. The selection process is iterative across adaptation techniques (prompting, RAG, finetuning) and balances hard constraints against soft, improvable attributes.

## Key Concepts

### Hard vs Soft Attributes

**Definition**: Hard attributes are properties you cannot reasonably change (license, training data provenance, model size, your privacy policy). Soft attributes are improvable through prompting, finetuning, or system design (accuracy, toxicity, latency when self-hosted).

**Key points**:
- Latency is *soft* if you self-host (you can optimize), *hard* if you use a hosted API.
- Hard attributes typically come from the provider's decisions or your internal policies.
- Hard attributes shrink the candidate pool; soft attributes are improved during experimentation.

### Model Selection Workflow (4 steps)

**Definition**: A four-stage funnel for choosing models, from broad filter to production monitoring.

1. **Filter by hard attributes** - Drop models that violate licenses, privacy, deployment, or policy constraints.
2. **Use public information** - Benchmarks and leaderboards to narrow to promising candidates.
3. **Run private experiments** - Use your own evaluation pipeline on shortlisted models.
4. **Monitor in production** - Detect failures, collect feedback, iterate.

The steps are iterative—new information at any step can change earlier decisions.

### Open Source vs Open Weight vs Open Model

**Definition**: Three terms describing increasing levels of openness:
- **Open weight**: Model weights are downloadable; training data is NOT public.
- **Open model**: Both weights AND training data are publicly available.
- **Open source** (loose usage): Often used for any model whose weights are public, regardless of data availability.

**Key points**:
- The vast majority of "open source" models today are open weight only.
- Open data enables retraining from scratch, modification, and auditing.
- Providers often hide training data to avoid scrutiny and lawsuits.

### Model API / Inference Service

**Definition**: An inference service hosts a model, accepts queries, and returns responses. The interface is the *model API*.

**Key points**:
- Commercial models are accessible only via APIs licensed by their developers.
- Open source models can be served by any API provider (the model developer, cloud providers, or third-party services).
- The same model on different APIs may have different performance, features, and pricing.

### Public Benchmark

**Definition**: A standardized test set used to measure a model capability (e.g., MMLU for knowledge, GSM-8K for grade school math, HumanEval for code).

**Key points**:
- Thousands exist; BIG-bench alone has 214.
- Benchmarks rapidly saturate as models improve, requiring new ones.
- Evaluation harnesses (lm-evaluation-harness, OpenAI evals) run many benchmarks at once.

### Public Leaderboard

**Definition**: A ranking of models based on aggregated performance across a curated subset of benchmarks (e.g., Hugging Face Open LLM Leaderboard, Stanford HELM).

**Key points**:
- Different leaderboards pick different benchmarks, so rankings differ.
- A high public ranking does NOT guarantee good performance on your task.
- Strongly correlated benchmarks (e.g., MMLU and WinoGrande, r=0.90) bias the average.

### Data Contamination

**Definition**: When evaluation data appears in the model's training data, inflating benchmark scores. Also called data leakage, training on the test set, or cheating.

**Key points**:
- Often unintentional via web scraping that pulls public benchmarks.
- Can happen indirectly: training and eval data drawn from the same source (e.g., a math textbook).
- Can be intentional and defensible: training on benchmark data for production, but then no longer evaluable on it.
- Detection: n-gram overlap (accurate, expensive, needs training data access) or perplexity (cheap, less accurate).

### Model Distillation

**Definition**: Training a smaller "student" model to mimic the behavior of a larger "teacher" model, often using the teacher's outputs as training data.

**Key points**:
- Many model licenses (e.g., Llama as of writing) PROHIBIT using outputs to train other models.
- Always check the license clause on output usage before distilling.

## Terminology

| Term | Definition |
|------|------------|
| Hard attribute | Constraint you cannot change (license, provider's training data) |
| Soft attribute | Property you can improve (accuracy via prompting/finetuning) |
| Open weight | Weights downloadable; training data not public |
| Open model | Weights AND training data both public |
| Restricted weight | Open weight model with notable license restrictions |
| Inference service | Backend that hosts model and serves predictions |
| Model API | The query/response interface to an inference service |
| Evaluation harness | Tool that runs a model against many benchmarks (lm-eval-harness, OpenAI evals) |
| Leaderboard | Ranking aggregated from selected benchmarks |
| Data contamination | Eval data leaked into training data, inflating scores |
| Dirty sample | Eval example that overlaps with training data (e.g., 13-token n-gram match) |
| Logprobs | Log probabilities of tokens; useful for classification, eval, interpretability |
| SLA | Service-level agreement for an API provider |

## How It Relates To

- **Evaluation criteria**: Hard/soft attributes come from your defined criteria.
- **Evaluation pipeline**: Step 3 of the workflow uses your private pipeline.
- **Public benchmarks**: Step 2 uses them to shortlist; their contamination is why step 3 exists.
- **Finetuning**: Open source models give you full finetuning freedom; commercial APIs limit you.

## Common Misconceptions

- **Myth**: The top-ranked model on the leaderboard is the best for my app.
  **Reality**: Leaderboards measure broad capabilities; your app needs may not be represented.

- **Myth**: Open source means I can do anything with the model.
  **Reality**: Each license has restrictions—commercial use, MAU caps (Llama: 700M), output reuse for training.

- **Myth**: A high benchmark score means the model is genuinely capable.
  **Reality**: Contamination is widespread; the model may have memorized the answers.

- **Myth**: Self-hosting is always cheaper than APIs.
  **Reality**: Engineering cost (talent, optimization, scaling, guardrails) often exceeds API spend.

- **Myth**: Once selected, the model decision is final.
  **Reality**: The 4-step workflow is iterative; new info from any step can override earlier choices.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| 4-step workflow | Filter (hard) → Public bench → Private eval → Monitor |
| Open weight | Weights public, training data not |
| Open model | Weights AND data public |
| Build vs buy | Trade API cost for engineering cost; trade control for convenience |
| Contamination | Eval data leaked into training, inflating scores |
| Detection | n-gram overlap (precise) or perplexity (cheap) |
