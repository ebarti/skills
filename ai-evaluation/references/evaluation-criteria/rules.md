# Evaluation Criteria Rules

Guidelines for choosing and applying evaluation criteria.

## Core Rules

### 1. Define Criteria Before Building (Evaluation-Driven Development)

List evaluation criteria at the start of the project, not after deployment.

- Start every AI application spec with measurable success criteria
- Pick criteria from all four buckets: domain, generation, instruction-following, cost/latency
- Without criteria, you can neither prove ROI nor decide whether to ship

### 2. Match Evaluation Method to Criterion Type

Don't use MCQ benchmarks to evaluate generation; don't use AI judges where exact evaluation works.

- Domain knowledge / reasoning -> MCQ benchmarks, accuracy
- Code -> functional correctness (test cases), plus efficiency and readability
- Open-ended generation -> AI judge or specialized scorer
- Format / length / keyword instructions -> deterministic verifier (regex, parser)
- Subjective instructions ("appropriate tone") -> AI judge with yes/no criteria

### 3. Evaluating Factual Consistency

Pick the verification approach based on whether you have a context.

**Local consistency (context provided)**:
- Use AI as a judge with a prompt that compares output to source text
- Or use a textual entailment classifier (premise=context, hypothesis=output)
- Or train a specialized scorer (e.g., DeBERTa-based)

**Global consistency (no context)**:
- Use knowledge-augmented verification (SAFE-style): decompose -> self-contain -> search -> verify
- Or use self-verification (SelfCheckGPT): generate N samples, check agreement (expensive)

**Always**:
- Analyze where the model hallucinates (niche topics, non-existent things) and weight benchmark toward those
- Be skeptical of "facts" — verify which sources you trust before scoring

### 4. Evaluating Safety

Layer general-purpose and specialized detectors.

- Use general AI judges (GPT-4, Claude, Gemini) for broad harm detection
- Add specialized classifiers for toxicity, hate speech (faster, cheaper)
- Use moderation APIs (OpenAI moderation, Perspective API) as a baseline gate
- Stress-test with adversarial prompts (RealToxicityPrompts, BOLD)
- Check all six harm categories: language, harmful tutorials, hate, violence, stereotypes, ideological bias

### 5. Evaluating Instruction-Following

Curate your own benchmark — public benchmarks won't cover your instructions.

- For verifiable instructions (format, length, keywords): write deterministic checks
- For non-verifiable instructions: decompose each instruction into yes/no criteria, then have AI or human evaluate each
- Score = fraction of criteria satisfied
- Distinguish instruction-following failure from domain-capability failure: try simpler instructions first
- Include the exact instructions you actually use in production (YAML output? "Don't say 'As a language model'"? Add them.)

### 6. Evaluating Roleplaying

Evaluate both style AND knowledge of the character.

- Style: speech patterns, tone, vocabulary match the persona
- Knowledge: outputs reflect what the character would know
- Use heuristics where possible (e.g., output length for a taciturn character)
- Use AI as a judge with role-specific prompts otherwise

### 7. Balancing Cost/Latency vs Quality

Treat as Pareto optimization with hard constraints.

- Identify which dimensions are non-negotiable (e.g., "TTFT must be < 200ms")
- Filter out all candidates that fail hard constraints first
- Optimize remaining dimensions on the surviving set
- Track latency at the percentile users feel (P90, P95) — not the average
- For APIs: cost scales linearly with tokens; control with prompt brevity and stop conditions
- For self-hosted: cost is fixed compute; cost-per-token drops with scale

## Guidelines

- Track whether your application can even be evaluated before deciding to build it
- Weight evaluation set toward queries the model is most likely to fail on (niche topics, edge cases)
- For RAG: factual consistency is the primary quality metric
- Re-evaluate API vs self-hosting at each scale milestone (cost economics flip)
- A high benchmark score on IFEval/INFOBench does not guarantee performance on YOUR instructions

## Exceptions

- **Creative writing applications**: Hallucinations may be desirable; relax factual consistency
- **Weak or low-resource models**: Fluency and coherence remain useful metrics
- **Internal tools with technical users**: Subjective generation quality may matter less than throughput
- **Deterministic / classification tasks**: Skip generation metrics entirely; use accuracy/F1

## Quick Reference

| Rule | Summary |
|------|---------|
| Criteria first | Define before building, not after |
| Match method to type | MCQ for knowledge, judge for generation, parser for format |
| Local vs global facts | Use AI judge with context; use SAFE without |
| Layer safety checks | General judge + specialized classifier + moderation API |
| Custom IF benchmark | Public benchmarks won't cover your prompts |
| Roleplay = style + knowledge | Evaluate both dimensions |
| Pareto cost/quality | Hard constraints first, optimize the rest |
