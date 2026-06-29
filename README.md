# 📚 Skills from Books

> Turn the best technical books into **agent skills** — structured, context-efficient knowledge packages any AI agent can actually use.

This repo is a growing library of skills distilled from technical books. Each skill takes the durable knowledge from a book — the mental models, decision frameworks, and trade-offs — and packages it into progressive-disclosure reference files an agent loads only when it's relevant.

**Agent-agnostic by design.** Each skill is just a folder of Markdown: a `SKILL.md` index plus reference files. Nothing here is tied to a specific runtime. It follows the [Agent Skills](https://docs.anthropic.com/en/docs/claude-code/skills) format (which Claude Code and Claude apps read natively), but the same files work with any agent that can read Markdown and load files on demand — LangGraph, custom RAG pipelines, OpenAI/Gemini-based agents, your own orchestrator, or even a human.

Think of it as **giving your agent a bookshelf**: instead of re-explaining RAG architecture, distributed-systems trade-offs, or resume strategy every time, you drop in a skill and the agent already knows the book.

## 🚀 Why this exists

- **Books > training data for niche reasoning.** A focused book chapter beats a fuzzy memory of one. These skills ground the agent in a specific, opinionated source.
- **Progressive disclosure.** Skills load a tiny `SKILL.md` index first, then pull deeper reference files on demand — so you spend context only where it matters.
- **Battle-tested sources.** Every skill names its book and chapters. No hand-wavy "best practices" — traceable knowledge.
- **Composable.** Several skills (e.g. the JobHunter resume trio, the Context Engine stack) are designed to chain together into pipelines.
- **Portable.** Plain Markdown, no runtime lock-in. Works wherever your agent can read files.

## ⚡ Quick install

The `install.sh` script clones this repo into one managed location, then **symlinks** the skills into whichever agents you choose. Because every install points back to the same clone, you update them all at once with a single `git pull`.

```bash
git clone https://github.com/ebarti/skills.git
cd skills
./install.sh
```

You'll get an interactive picker:

```
Where should the skills be installed?
  1) Claude (Claude Code / Claude apps)
  2) Codex (OpenAI Codex CLI / IDE / app)
  3) Gemini CLI (bundled as an extension)
  4) Antigravity (Google agentic IDE)
  a) All of the above

Select (e.g. 1,3 or a):
```

Or skip the prompt:

```bash
./install.sh --all                      # every supported agent
./install.sh --targets claude,codex     # a subset
./install.sh --project                  # symlink into the current repo (project scope)
./install.sh --dry-run --all            # preview, change nothing
./install.sh --help
```

**Where skills land** (user/global scope — all use the open `SKILL.md` format):

| Agent | Install location |
|-------|------------------|
| **Claude** | `~/.claude/skills/` |
| **Codex** | `~/.agents/skills/` |
| **Gemini** | `~/.gemini/extensions/skills-from-books/skills/` (+ a generated extension manifest) |
| **Antigravity** | `~/.gemini/antigravity/skills/` |

**Update everything later:**

```bash
cd ~/.skills-from-books && git pull     # or your clone dir; all symlinked installs update instantly
```

## 📦 Manual / other agents

Each skill is a self-contained folder — a `SKILL.md` (name, description, and an index of what's inside) plus reference files — so you can wire it into any agent that reads files:

- Use each skill's `description` for routing/selection, then load `SKILL.md` and pull reference files on demand (the progressive-disclosure pattern these skills are built for).
- Index the Markdown files in your own RAG store.
- Drop the relevant `SKILL.md` straight into a system prompt for smaller tasks.
- Or just copy a folder where you want it: `cp -r ai-rag-and-agents ~/.claude/skills/`.

> 💡 Want to make your own? This repo was built with the **`skill-from-book`** approach, which converts a book's markdown into a structured skill package.

---

## 🗂️ The Skills

### 🤖 AI Engineering — *from "AI Engineering" by Chip Huyen (O'Reilly)*

Building production applications on top of foundation models, chapter by chapter.

| Skill | What it covers | Source |
|-------|----------------|--------|
| **ai-foundation-models** | Understanding and working with foundation models: the AI engineering stack, transformer architecture, training data, scaling laws, post-training (SFT, RLHF), and sampling strategies (temperature, top-k, top-p, structured outputs). | *AI Engineering*, Ch. 1–2 |
| **ai-evaluation** | Evaluating AI/LLM systems: language-modeling metrics (perplexity, cross-entropy), exact evaluation, AI-as-judge, comparative evaluation, production criteria, model selection, and end-to-end evaluation pipelines. | *AI Engineering*, Ch. 3–4 |
| **ai-prompt-engineering** | Writing, organizing, and defending prompts: in-context learning, system vs user prompts, context efficiency, best practices (CoT, decomposition), versioning, and defense against jailbreaks / prompt injection. | *AI Engineering*, Ch. 5 |
| **ai-rag-and-agents** | Building RAG systems and AI agents: retrieval algorithms (term-based, embedding, hybrid), retrieval optimization (chunking, reranking, query rewriting), multimodal RAG, agent design, failure modes, and memory systems. | *AI Engineering*, Ch. 6 |
| **ai-finetuning** | Finetuning foundation models: when to finetune (vs prompting or RAG), memory bottlenecks, parameter-efficient finetuning (PEFT, LoRA, adapters), model merging, and finetuning tactics. | *AI Engineering*, Ch. 7 |
| **ai-dataset-engineering** | Building, augmenting, and processing datasets: data curation (quality, coverage, quantity, acquisition, annotation), data synthesis, instruction data generation, model distillation, and data processing. | *AI Engineering*, Ch. 8 |
| **ai-inference-optimization** | Optimizing inference: computational bottlenecks, AI accelerators (GPUs/TPUs), model optimization (compression, speculative decoding, attention optimization), and service optimization (batching, prefill/decode split, prompt caching, parallelism). | *AI Engineering*, Ch. 9 |
| **ai-production-architecture** | Architecting and operating AI apps in production: the AI engineering architecture (context enhancement, guardrails, model router, gateway, caching, agent patterns), monitoring/observability, pipeline orchestration, and user feedback systems. | *AI Engineering*, Ch. 10 |

### 🧠 Context Engineering — *from "Context Engineering for Multi-Agent Systems"*

A full, buildable Context Engine for multi-agent systems — from theory to production.

| Skill | What it covers | Source |
|-------|----------------|--------|
| **ai-context-engineering** | Foundational context-engineering theory: the 5 levels of context (zero/linear/goal-oriented/role-based/semantic blueprint), semantic role labeling (SRL), and the layered (scope → investigation → action) analysis pattern. | *Context Engineering for Multi-Agent Systems*, Ch. 1 |
| **ai-multi-agent-mcp** | Building multi-agent systems with the Model Context Protocol (MCP): message format and transport, specialist agent design, an Orchestrator with goal decomposition, and robustness via validation loops + a Validator agent. | *Context Engineering for Multi-Agent Systems*, Ch. 2 |
| **ai-context-engine** | The full Context Engine architecture: dual RAG (procedural + factual), Pinecone-based ingestion, the Planner / Executor / Tracer triad, specialist agents, the Agent Registry, and production hardening. | *Context Engineering for Multi-Agent Systems*, Ch. 3–5 + Appendix A |
| **ai-rag-defense** | Token reduction, retrieval fidelity, and prompt-injection defense: a Summarizer agent, micro-context engineering, high-fidelity RAG with source-metadata citations, input sanitization, and grounded-reasoning validation. | *Context Engineering for Multi-Agent Systems*, Ch. 6–7 |
| **ai-context-engine-production** | Production deployment of the Context Engine: moderation gatekeepers, policy-driven meta-control, reusable control-deck templates, domain adaptation (legal + marketing), the API/worker/Docker/observability topology, and business-value framing. | *Context Engineering for Multi-Agent Systems*, Ch. 8–10 |

### 🗄️ Data-Intensive Systems — *from "Designing Data-Intensive Applications" by Martin Kleppmann (2nd ed., O'Reilly)*

The canonical distributed-systems book, distilled into decision-ready skills.

| Skill | What it covers | Source |
|-------|----------------|--------|
| **ddia-architecture** | Foundational architecture: the operational vs analytical split, cloud vs self-hosted trade-offs, distributed-systems trade-offs, and the core nonfunctional requirements (performance, reliability, scalability, maintainability). | *DDIA* (2nd ed.), Ch. 1–2 |
| **ddia-data-modeling** | Data modeling, storage engines, and encoding: relational/document/graph/event-sourced models; LSM, B-tree, in-memory, and columnar storage; specialized indexes; encoding formats; and modes of dataflow. | *DDIA* (2nd ed.), Ch. 3–5 |
| **ddia-replication-sharding** | Replication topologies, sharding strategies, conflict resolution, and request routing for distributed data systems. | *DDIA* (2nd ed.), Ch. 6–7 |
| **ddia-transactions-consistency** | Transactions, distributed-system fundamentals, and consistency/consensus: ACID semantics, weak/strong isolation, distributed failure modes, time/clocks, linearizability, and consensus protocols. | *DDIA* (2nd ed.), Ch. 8–10 |
| **ddia-batch-stream-processing** | Batch and stream processing and the future of data systems: MapReduce/dataflow engines, message brokers, change data capture, stream time semantics, dataflow architectures, and end-to-end correctness. | *DDIA* (2nd ed.), Ch. 11–13 |
| **ddia-data-ethics** | Ethical and societal frameworks: algorithmic accountability, bias, surveillance, consent, and the data-as-liability mindset. | *DDIA* (2nd ed.), Ch. 14 |

### 📄 Resume & Job Search — *from "Resumes For Dummies" (AI-era ed.)*

A composable pipeline (the **JobHunter** trio) that analyzes a job, writes a tailored resume, and scores it in a write → score → revise loop.

| Skill | What it covers | Source |
|-------|----------------|--------|
| **job-description-analyzer** | Parses a raw job description into a structured `TargetProfile` — role, seniority, must-have vs nice-to-have requirements, hard/soft skills, responsibilities, ATS keywords, and a truthful crossover map. The shared front-end for the pipeline. | *Resumes For Dummies* (AI-era ed.) |
| **resume-content-writer** | Generates tailored, schema-conformant resume content — headline, branding summary, JD-matched skills section, and quantified achievement bullets — tuned to a target role, seniority, and focus. | *Resumes For Dummies* (AI-era ed.) |
| **resume-fit-scorer** | Scores how well a resume fits a job on a 0–10 scale across 6 weighted dimensions, returns a brutally honest critique, and emits structured prioritized fixes. The verifier in a write → score → revise loop. | *Resumes For Dummies* (AI-era ed.) |

---

## 🏷️ Topics

`agent-skills` · `ai-agents` · `agentic-ai` · `llm` · `rag` · `prompt-engineering` · `ai-engineering` · `context-engineering` · `mcp` · `distributed-systems` · `ddia` · `data-engineering` · `multi-agent-systems` · `knowledge-base` · `claude` · `claude-skills`

## 🤝 Contributing

Got a book worth turning into a skill? Convert its markdown into a structured package (the `skill-from-book` approach), then open a PR. Each skill should name its source book and chapters so the knowledge stays traceable.

## 📜 License

Skills distill *concepts and frameworks* from their source books into original reference material; they do not reproduce the books. All credit for the underlying ideas goes to the respective authors and publishers. Please buy the books — they're excellent.
