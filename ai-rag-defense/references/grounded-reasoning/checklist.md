# Is My Agent System Grounded? Checklist

Use this checklist before declaring an agent system production-ready or before merging an upgrade to a context engine.

## Before You Start

- [ ] Inventory of every function (notebook, helpers, agents, registry, engine core) is current
- [ ] Mind map of the architecture is up to date (Figures 7.2-7.5 style)
- [ ] Regression test suite contains at least the three canonical cases (high-fidelity, backward-compat, grounded)

## Citation and Sourcing

- [ ] Every factual claim in the output is accompanied by a source citation
- [ ] The Researcher agent emits `answer_with_sources` with a non-empty `Sources` list, OR explicitly states "None"
- [ ] No factual paragraph appears without traceable provenance
- [ ] Citations point to documents that actually exist in the knowledge base

## Negative Findings (Hallucination Defense)

- [ ] When retrieval returns no relevant data, the agent declines to answer from invention
- [ ] The output explicitly states what was searched and that nothing applied
- [ ] The Writer agent accepts negative results as a valid contract and narrates them gracefully
- [ ] A test case exists where the knowledge base intentionally lacks the queried topic
- [ ] In that test, the trace shows zero fabricated facts

## Backward Compatibility

- [ ] Prior-chapter/prior-version goals still execute end-to-end on the new engine
- [ ] The Writer (or any shared consumer) accepts every producer's data contract (`facts`, `summary`, `answer_with_sources`, etc.)
- [ ] Output quality on prior workflows has not regressed in tone, length, or structure
- [ ] No new dependency forces a previously optional agent to be present

## Trace and Auditability

- [ ] `ExecutionTrace.__init__()` is called for every run
- [ ] `log_plan()` records the full JSON plan
- [ ] `log_step()` records inputs, outputs, and resolved context per step (including empty retrievals)
- [ ] `finalize()` records status and duration
- [ ] Trace can be replayed and inspected by a reviewer who was not present at runtime

## Security and Sanitization

- [ ] `helper_sanitize_input()` runs on all external text before LLM use
- [ ] Prompt-injection probes in the test suite do not alter agent behavior
- [ ] Secrets used by `download_private_github_file()` (or equivalent) are not logged in the trace

## Architecture Health

- [ ] Each agent has a single, well-defined job (Librarian, Researcher, Summarizer, Writer)
- [ ] `AgentRegistry.get_capabilities_description()` returns a complete and current manual
- [ ] `resolve_dependencies()` correctly substitutes every `$$STEP_N_OUTPUT$$` placeholder
- [ ] No agent silently bypasses the engine core to call helpers directly when chaining is required

## Red Flags

Stop and address if you find:

- The agent produces fluent answers in domains where the knowledge base has nothing
- Sources cited do not exist in the corpus, or do not contain the cited claim
- A new agent works but a prior workflow now fails or produces lower-quality output
- ExecutionTrace is incomplete, missing for some runs, or scrubbed of negative-result steps
- The Writer crashes when handed a `summary` or negative `answer_with_sources` payload
- "It works in the demo" without a regression suite to back it up

## Quick Reference

| Aspect | Ideal | Acceptable | Red Flag |
|--------|-------|------------|----------|
| Empty retrieval | Structured negative result + Writer narrates absence | Negative result, terse Writer output | Fabricated answer with no sources |
| Citations | Every claim sourced and verified | Every claim sourced | Claims without sources |
| Backward compat | All prior cases pass | Prior cases pass with minor tweaks | Prior cases broken |
| Trace coverage | Every step logged with context | Most steps logged | Missing steps or runs |
| Sanitization | Always on, tested | On but untested | Off or bypassable |
