# Domain Applications Patterns

Reusable architectural patterns for re-tasking the Context Engine across business verticals.

## Pattern: Domain Adaptation (Same Engine, Different KB + Decks)

### Intent

Repurpose a production Context Engine to a new business vertical without modifying engine code, agents, or registry. Deliver a different product by changing only the knowledge base and the goals fed to the existing Control Decks.

### When to Use

- Standing up a new vertical (legal, marketing, finance, support, etc.) on top of an existing engine
- Validating the modularity of a glass-box architecture before scaling
- Reducing time-to-market for new AI products inside an organization
- Demonstrating ROI of the engine investment to stakeholders

### Structure

```text
[ Engine + Agents + Registry + Moderation ]   <-- unchanged
              |
              +--- Domain A KB (legal_documents/)        + Goals using Decks 1/2/3
              +--- Domain B KB (marketing_documents/)    + Goals using Decks 1/2/3
              +--- Domain N KB (...)                     + Goals using Decks 1/2/3
```

Three reusable assets:

1. `Data_Ingestion.ipynb` -> duplicate per domain, swap source directory
2. Three Control Deck templates -> reuse verbatim, change only the `goal` string
3. Specialist agents (`agent_researcher`, `agent_librarian`, `agent_summarizer`, `agent_writer`) -> shared across domains

### Example

```python
# Legal vertical
goal = "What are the key confidentiality obligations in the Service Agreement v1, and what is the termination notice period? Please cite your sources."
execute_and_display(goal, config, client, pc, moderation_active=False)

# Marketing vertical (same engine, same function, same deck shape)
goal = "Analyze the ChronoTech press release and summarize their core product messaging and value proposition. Please cite your sources."
execute_and_display(goal, config, client, pc, moderation_active=True)
```

### Benefits

- New domain stands up in minutes, not weeks
- Single engine to maintain, debug, and harden
- Investment in moderation, tracing, and safeguards amortizes across all verticals
- Context Engineer's role becomes strategic (curate KB, articulate goals) rather than implementation-bound

### Considerations

- KB curation quality dominates output quality; budget time for source selection
- Each domain needs its own limit tests to surface organizational requirements
- Adversarial content per domain may demand namespace-level policies, not global ones
- Latency (~70s for complex chains) is shared across domains; optimize once

---

## Pattern: Organizational Fix Over Code Patch

### Intent

When a domain limit test surfaces a failure (sanitizer false positive, vague goal, ambiguous request), resolve it by changing data segmentation or context library content, not by adding code exceptions.

### When to Use

- A sanitizer pattern flags legitimate domain language (e.g., legal testimony)
- Users issue vague or out-of-scope requests that confuse the planner
- An ambiguous request has no matching blueprint in the context library

### Structure

```text
1. Limit test surfaces failure mode in production-like trace
2. Convene workshop with domain experts (legal team, marketing team)
3. Choose organizational lever:
   - Namespace segmentation (e.g., KnowledgeStore-Testimony)
   - Standardized summary objectives stored as reusable blueprints
   - Pre-approved semantic blueprints for every critical document type
4. Update KB / context library; engine code unchanged
```

### Example

```text
Failure: Researcher skips testimony chunk because text contains
         'ignore any legal advice' (matches injection pattern)

Wrong fix: Add an exception to helper_sanitize_input

Right fix: Move adversarial corpora into KnowledgeStore-Testimony
          namespace; Researcher applies a relaxed policy when querying
          that namespace
```

```text
Failure: 'Analyze the attached NDA and draft a pleading based on its terms'
         fails because no pleading blueprint exists

Wrong fix: Hardcode pleading structure into agent_writer prompt

Right fix: Workshop with legal team to enumerate critical document types;
          curate blueprint_for_pleading, blueprint_for_motion_to_dismiss,
          blueprint_for_cease_and_desist as reusable context-library entries
```

### Benefits

- Engine remains generic and reusable across domains
- Failures become catalysts for valuable knowledge curation
- Domain experts gain a clear mechanism to encode their expertise
- Sanitizer pattern list stays short and trustworthy

### Considerations

- Requires organizational buy-in and domain-expert availability
- Slower than a code patch in the short term; faster and safer over time
- Demands disciplined Context Engineers who push back on "just add an exception"

---

## Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|-------------------|
| Launching a new business vertical on existing engine | Domain Adaptation |
| Limit test surfaces sanitizer false positive | Organizational Fix Over Code Patch |
| Vague or ambiguous user goals | Organizational Fix Over Code Patch (standardized blueprints) |
| Need to demonstrate engine ROI to leadership | Domain Adaptation (run two verticals on same engine) |
| Adversarial content class identified in domain corpus | Organizational Fix Over Code Patch (namespace segmentation) |
