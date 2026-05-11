# Comparative Evaluation Knowledge

Core concepts for ranking models using pairwise comparisons rather than independent scores.

## Overview

Comparative evaluation ranks models by pitting them against each other and computing a ranking from match outcomes. It is often easier than pointwise (independent) scoring for subjective qualities, and it powers leaderboards like LMSYS Chatbot Arena. Adapted from sports rating systems (Elo, Bradley-Terry, TrueSkill), it treats model ranking as a predictive problem: a good ranking predicts who wins future matches.

## Key Concepts

### Pointwise vs Comparative Evaluation

**Pointwise evaluation**: Score each model independently (e.g., a Likert scale), then rank by score.

**Comparative evaluation**: Show outputs from two (or more) models side-by-side, ask an evaluator to pick a winner, then derive a ranking from many such matches.

**Key points**:
- Comparative is easier when quality is subjective ("which song is better?" beats "rate this song 1-10")
- Pointwise is easier to compute but harder to design good signals for
- First used in AI in 2021 by Anthropic to rank models

### Match

**Definition**: A single comparison between two (or more) models on the same prompt, with one winner picked by an evaluator (human or AI). Ties are commonly allowed.

A series of matches yields a comparison table that becomes the input to a rating algorithm.

### Win Rate

**Definition**: Probability that model A is preferred over model B, computed as the percentage of A-vs-B matches that A wins.

With many models, raw win rates do not directly produce a clean ranking — a rating algorithm is needed.

### Rating Algorithms

**Definition**: Algorithms that consume comparative signals (matches) and produce a per-model score, which is then used to rank models.

**Key algorithms**:
- **Elo** — chess-origin rating; sensitive to evaluator order and prompt order
- **Bradley-Terry** — probabilistic pairwise model; what Chatbot Arena switched to after Elo
- **TrueSkill** — Microsoft's rating system, supports multi-player ranking

### Transitivity Assumption

**Definition**: If A > B and B > C, then A > C — so direct A-vs-C comparisons are unnecessary.

Most rating algorithms assume transitivity to avoid quadratic comparison costs. Multiple papers question whether this holds for AI models, since human preference is not always transitive and different pairs are rated by different evaluators on different prompts.

### Ranking Correctness

**Definition**: A ranking is correct if, for any pair, the higher-ranked model is more likely to win against the lower-ranked one.

There is no ground-truth "correct" ranking — quality is judged by predictive power on future matches.

### Chatbot Arena

**Definition**: LMSYS public leaderboard where users prompt two anonymous models and vote for the better response. Ranks via Bradley-Terry (originally Elo).

## Terminology

| Term | Definition |
|------|------------|
| Match | Single side-by-side comparison producing a winner |
| Win rate | % of A-vs-B matches that A wins |
| Pointwise eval | Independent scoring of each model |
| Comparative eval | Ranking from pairwise matches |
| Transitivity | Assumption that A>B and B>C implies A>C |
| Bradley-Terry | Probabilistic pairwise rating algorithm |
| Elo | Sequential pairwise rating algorithm from chess |
| TrueSkill | Multi-player rating algorithm from Microsoft |
| Rating algorithm | Converts match outcomes into per-model scores |
| Preference model | AI judge trained to predict which response humans prefer |

## How It Relates To

- **A/B testing**: NOT the same — A/B tests show one output per user; comparative shows multiple side-by-side
- **AI as a judge**: AI judges can serve as the evaluator producing the win signals
- **Post-training (RLHF)**: Both rely on preference signals; preference models reuse the same data
- **Pointwise evaluation**: Complementary — comparative tells you which is better, pointwise tells you how good

## Common Misconceptions

- **Myth**: Comparative evaluation is the same as A/B testing.
  **Reality**: A/B testing presents one variant per user; comparative shows multiple variants simultaneously to one evaluator.

- **Myth**: A higher comparative ranking means a model is "good enough" for production.
  **Reality**: Win rate tells you relative ordering, not absolute capability. Both models could be bad.

- **Myth**: Every question can be settled by user preference.
  **Reality**: Factual and correctness questions ("Is X linked to Y?") should not be decided by preference voting.

- **Myth**: Chatbot Arena uses Elo.
  **Reality**: It started with Elo but switched to Bradley-Terry due to Elo's sensitivity to evaluation order.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Comparative eval | Rank models from pairwise winner picks |
| Match | One side-by-side comparison |
| Win rate | % of matches A wins vs B |
| Bradley-Terry | Pairwise probabilistic rating, Arena's choice |
| Elo | Chess rating, order-sensitive |
| Transitivity | A>B and B>C => A>C (assumed but contested) |
| Correct ranking | Higher rank predicts winning future matches |
