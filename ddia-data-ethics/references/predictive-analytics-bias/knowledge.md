# Predictive Analytics, Bias, and Accountability Knowledge

Core concepts for understanding the ethical dimensions of algorithmic decision-making systems that affect people's lives.

## Overview

Predictive analytics use historical data to make decisions about individuals (loans, hiring, parole, insurance). When the underlying data carries bias, ML systems learn and amplify that bias while hiding it behind a veneer of mathematical objectivity. This creates accountability gaps and self-reinforcing feedback loops that can systematically exclude people from key aspects of society.

## Key Concepts

### Predictive Analytics

**Definition**: Using statistical/ML models to predict future outcomes about individuals based on historical patterns of "people like them."

Distinct from a credit score (which summarizes "How did *you* behave?") because it reasons about "Who is similar to you, and how did people like you behave?" — implying stereotyping by proxy traits like postal code.

### Algorithmic Decision-Making

**Definition**: Letting a learned model — not a human — decide whether to grant a loan, schedule a police patrol, hire a candidate, or grant parole.

**Key points**:
- Rules are inferred from data, not specified by engineers
- Patterns learned are opaque even to their creators
- A "no" from one algorithm can cascade into systematic exclusion ("algorithmic prison")

### Bias (three sources)

**Definition**: Systematic skew in model outputs that disadvantages a group.

- **Sampling bias** — training data doesn't represent the population the model will be applied to
- **Label bias** — historical labels reflect past human discrimination (e.g., who got hired before)
- **Feedback / deployment bias** — the model's own decisions change the world it's measuring, producing skewed future training data

### Discrimination and Disparate Impact

**Definition**: Treating people differently based on protected traits (race, gender, age, religion, disability, sexuality), or using proxies that correlate with them.

**Disparate impact**: a facially neutral rule (e.g., "use postal code") that produces unequal outcomes across protected classes. Postal code, IP address, and shopping habits are common race/class proxies.

### Feedback Loop

**Definition**: A self-reinforcing cycle where a model's decisions alter the data it later trains on, confirming its own predictions.

Examples in the chapter: predictive policing increases arrests in already-policed areas; credit scoring used for hiring causes joblessness causing further score drops; algorithmic pricing leading to tacit collusion.

### Accountability Gap

**Definition**: The absence of a clear human responsible when an automated decision causes harm, with no meaningful way for the affected person to appeal.

> "People should not be able to evade their responsibility by blaming an algorithm."

## Bias by Layer

| Layer | What goes wrong | Example |
|-------|-----------------|---------|
| Data | History encodes past discrimination | Hiring data reflects past biased hiring |
| Model | Optimizer amplifies signal in biased labels | Model learns proxies for protected traits |
| Deployment | Predictions shape the world they measure | More patrols → more arrests → "model confirmed" |

## Terminology

| Term | Definition |
|------|------------|
| Algorithmic prison | Cumulative exclusion from jobs, housing, credit, travel via algorithmic "no" decisions |
| Protected trait | Attribute legally shielded from discrimination (race, gender, age, etc.) |
| Proxy variable | A non-protected feature that correlates strongly with a protected trait |
| Money laundering for bias | Satirical phrase: ML obscures the source of biased outputs |
| Systems thinking | Reasoning about the full sociotechnical system, not just the code |
| Moral imagination | Human capacity to envision a better-than-past future; models cannot do this |

## How It Relates To

- **Privacy and Tracking**: Both concern data collected about people without meaningful consent
- **Power Asymmetry**: Algorithmic decisions concentrate power with system operators against subjects
- **Transparency / Explainability**: Required for accountability and appeal

## Common Misconceptions

- **Myth**: Data-driven decisions are objective and fair.
  **Reality**: Models learn from history; if history is biased, the model is biased — and harder to challenge because it appears mathematical.

- **Myth**: We avoided discrimination by removing the "race" column.
  **Reality**: Other features (postal code, IP, name, browsing) act as proxies for race; the model still discriminates.

- **Myth**: A statistically accurate model is fair to every individual.
  **Reality**: Outputs are probabilistic; correct on the aggregate doesn't mean correct for any one person.

- **Myth**: An algorithm can be a neutral arbiter that improves on biased humans.
  **Reality**: Algorithms extrapolate from the past — only humans can supply moral imagination for a better future.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Predictive analytics | Decisions about you based on people similar to you |
| Bias | Systematic skew that disadvantages a group |
| Disparate impact | Neutral rule, unequal outcomes by protected class |
| Feedback loop | Model decisions alter the data confirming the model |
| Accountability gap | No human is on the hook when the system harms someone |
| Algorithmic prison | Cumulative exclusion from many domains via automated "no" |
