# Build a Context Engine Workflow

End-to-end build of the glass-box Context Engine: dual RAG → engine triad → specialist agents → registry → first run.

## When to Use

- Starting a new context engine project from scratch
- Replacing a single-agent system with a glass-box, plan-driven engine
- Building any system that needs Planner / Executor / Tracer separation

## Prerequisites

- Pinecone account + API key
- OpenAI API key
- Familiarity with `ai-multi-agent-mcp` (the engine builds on MCP)

**Reference**: `references/engine-reference/knowledge.md`

---

## Workflow Steps

### Step 1: Decide the RAG architecture

**Goal**: Confirm dual RAG (procedural + factual) vs single.

- [ ] Read the dual-RAG knowledge file
- [ ] Decide: procedural blueprints vs factual evidence — do you need both?
- [ ] If yes → dual RAG (Context Library + Knowledge Base)
- [ ] Plan namespace strategy (one per RAG kind)

**Reference**: `references/dual-rag/knowledge.md`, `references/dual-rag/rules.md`

---

### Step 2: Set up the RAG ingestion pipeline

**Goal**: Get data into Pinecone with stable IDs.

- [ ] Run the `setup-rag-pipeline` workflow (separate, focused workflow)
- [ ] Verify both Context Library and Knowledge Base namespaces have data
- [ ] Smoke-test a probe query

**Reference**: `workflows/setup-rag-pipeline.md` (sibling workflow)

---

### Step 3: Build the engine triad

**Goal**: Implement Planner + Executor + ExecutionTracer.

- [ ] Implement `planner(goal, capabilities)` returning a structured plan
- [ ] Implement `Executor` that runs steps + resolves dependencies
- [ ] Implement `ExecutionTrace` class to record causality
- [ ] Assemble in `context_engine(goal, ...)` orchestrator

**Reference**: `references/engine-components/examples.md`, `references/engine-components/rules.md`

---

### Step 4: Build the specialist agents

**Goal**: Implement Context Librarian, Researcher, Writer.

- [ ] Context Librarian: queries Context Library for procedural blueprint
- [ ] Researcher: queries Knowledge Base for factual evidence
- [ ] Writer: synthesizes blueprint + facts into final output
- [ ] Use the data-contract pattern: wrapped dicts (`{"blueprint_json": ...}`)

**Reference**: `references/specialist-agents/examples-librarian.md`, `references/specialist-agents/examples-researcher.md`, `references/specialist-agents/examples-writer.md`

---

### Step 5: Wire the Agent Registry

**Goal**: Decouple Planner from agent implementations.

- [ ] Create the registry mapping (agent name → handler)
- [ ] Write capability descriptions the Planner LLM reads
- [ ] Use DI lambdas in `get_handler` to inject dependencies
- [ ] Test: Planner picks the right agent given a goal

**Reference**: `references/agent-registry/examples.md`, `references/agent-registry/rules.md`

---

### Step 6: Run the engine end-to-end

**Goal**: Verify Planner → Executor → agents → final output.

- [ ] Define a high-level goal
- [ ] Call `context_engine(goal)`
- [ ] Inspect the trace: did Planner produce sensible plan?
- [ ] Did each step's output feed correctly into the next?
- [ ] Did final output answer the goal?

**Reference**: `references/engine-components/examples.md` (assembly section)

---

## Quick Checklist

```
[ ] Step 1: Dual RAG decision + namespace plan
[ ] Step 2: Ingestion pipeline (delegated to setup-rag-pipeline)
[ ] Step 3: Planner + Executor + Tracer
[ ] Step 4: Specialist agents (Librarian, Researcher, Writer)
[ ] Step 5: Agent Registry with capability descriptions + DI
[ ] Step 6: End-to-end run with trace inspection
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Single RAG when content is mixed | Retrieval mixes procedural + factual | Separate namespaces |
| Planner hardcoded to specific agents | No extensibility | Read from registry capability descriptions |
| Agents share globals (Pinecone client, etc.) | Tight coupling | DI via registry lambdas |
| Skipping the Tracer | Can't audit decisions | Always record steps |
| Writer expects raw string from Researcher | Data contract drift | Wrapped dicts (`{"facts": ...}`) |

---

## Exit Criteria

- [ ] Engine produces a plan from a goal
- [ ] Plan executes step-by-step with visible trace
- [ ] Each step's output feeds correctly into next
- [ ] Final output is grounded in retrieved data
- [ ] Ready for `harden-engine` workflow next
