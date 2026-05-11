# Context Engine Reference Examples

Reference snippets for each commons file, the ingestion pipeline, and a sample control deck. Full implementations live in the cross-referenced categories.

## helpers.py — Centralized LLM Call

```python
@retry(stop=stop_after_attempt(6), wait=wait_exponential(min=1, max=30),
       retry=retry_if_exception_type((openai.APIError,)))
def call_llm_robust(system_prompt, user_prompt, client,
                    generation_model, json_mode=False):
    response_format = {"type": "json_object"} if json_mode else None
    resp = client.chat.completions.create(
        model=generation_model,
        messages=[{"role": "system", "content": system_prompt},
                  {"role": "user",   "content": user_prompt}],
        response_format=response_format,
    )
    return resp.choices[0].message.content.strip()
```

## helpers.py — MCP Envelope

```python
def create_mcp_message(sender, content, metadata=None):
    return {
        "protocol_version": "1.0",
        "sender": sender,
        "content": content,
        "metadata": metadata or {},
    }
```

## helpers.py — Sanitize + Moderate (signatures)

```python
def helper_sanitize_input(text: str) -> str: ...
# raises ValueError on injection pattern hit

def helper_moderate_content(text_to_moderate: str, client) -> dict: ...
# returns {"flagged": bool, "categories": dict, "scores": dict}
# fail-safe: any exception => flagged=True
```

See `references/hardening/` for full bodies.

## agents.py — Researcher Skeleton

```python
def agent_researcher(mcp_message, client, index, generation_model,
                     embedding_model, namespace_knowledge):
    topic = mcp_message["content"]["topic_query"]
    matches = query_pinecone(topic, namespace_knowledge, top_k=3,
                             index=index, client=client,
                             embedding_model=embedding_model)
    sanitized, sources = [], set()
    for m in matches:
        try:
            sanitized.append(helper_sanitize_input(m["metadata"]["text"]))
            sources.add(m["metadata"]["source"])
        except ValueError:
            continue  # skip tainted chunk
    answer = call_llm_robust(
        "Answer ONLY from the provided sources.",
        f"Topic: {topic}\nSources:\n" + "\n".join(sanitized),
        client=client, generation_model=generation_model)
    return create_mcp_message("Researcher", {
        "answer_with_sources": {"answer": answer, "sources": sorted(sources)}})
```

See `references/specialist-agents/` for Librarian, Writer, Summarizer.

## registry.py — AgentRegistry Core

```python
class AgentRegistry:
    def __init__(self):
        self.registry = {
            "Librarian":  agents.agent_context_librarian,
            "Researcher": agents.agent_researcher,
            "Writer":     agents.agent_writer,
            "Summarizer": agents.agent_summarizer,
        }

    def get_handler(self, agent_name, client, index, generation_model,
                    embedding_model, namespace_context, namespace_knowledge):
        if agent_name not in self.registry:
            raise ValueError(f"Unknown agent: {agent_name}")
        fn = self.registry[agent_name]
        if agent_name == "Researcher":
            return lambda msg: fn(msg, client, index, generation_model,
                                  embedding_model, namespace_knowledge)
        if agent_name == "Librarian":
            return lambda msg: fn(msg, client, index, embedding_model,
                                  namespace_context)
        return lambda msg: fn(msg, client, generation_model)  # Writer/Summarizer

    def get_capabilities_description(self) -> str: ...
    # multi-line string embedded into Planner system prompt

AGENT_TOOLKIT = AgentRegistry()
```

See `references/agent-registry/` for full handler matrix.

## engine.py — Dependency Resolution

```python
def resolve_dependencies(input_params, state):
    if isinstance(input_params, dict):
        return {k: resolve_dependencies(v, state) for k, v in input_params.items()}
    if isinstance(input_params, list):
        return [resolve_dependencies(v, state) for v in input_params]
    if isinstance(input_params, str) and input_params.startswith("$$STEP_"):
        key = input_params.strip("$")  # e.g. "STEP_1_OUTPUT"
        if key not in state:
            raise ValueError(f"Missing dependency: {key}")
        return state[key]
    return input_params
```

## engine.py — Executor Loop

```python
def context_engine(goal, client, pc, index_name, generation_model,
                   embedding_model, namespace_context, namespace_knowledge):
    trace = ExecutionTrace(goal)
    registry, index = AGENT_TOOLKIT, pc.Index(index_name)
    try:
        plan = planner(goal, registry.get_capabilities_description(),
                       client, generation_model)
        trace.log_plan(plan)
        state = {}
        for i, step in enumerate(plan, start=1):
            resolved = resolve_dependencies(step["input"], state)
            handler = registry.get_handler(step["agent"], client, index,
                generation_model, embedding_model,
                namespace_context, namespace_knowledge)
            output = handler(create_mcp_message("Executor", resolved))
            state[f"STEP_{i}_OUTPUT"] = output["content"]
            trace.log_step(i, step["agent"], step["input"], output, resolved)
        final = state[f"STEP_{len(plan)}_OUTPUT"]
        trace.finalize("Success", final)
        return final, trace
    except Exception:
        trace.finalize("Failed", None)
        return None, trace
```

See `references/engine-components/` for `ExecutionTrace` and `planner()`.

## utils.py — Setup

```python
def install_dependencies():
    subprocess.check_call([sys.executable, "-m", "pip", "install",
                           "openai==X.Y", "pinecone==X.Y", "tenacity==X.Y"])

def initialize_clients():
    api_key = userdata.get("API_KEY")            # Colab secret
    pc_key  = userdata.get("PINECONE_API_KEY")
    os.environ["OPENAI_API_KEY"] = api_key
    return OpenAI(), Pinecone(api_key=pc_key)
```

## Data Ingestion Pipeline

```python
def ingest_documents(folder, client, index, namespace="KnowledgeStore"):
    for path in load_documents(folder):
        text = read_file(path)
        chunks = chunk_text(text, size=400, overlap=50, model="text-embedding-3-small")
        vectors = get_embeddings_batch(chunks, client)
        items = [{
            "id": f"{path.stem}-{i}",
            "values": vec,
            "metadata": {"text": chunk, "source": path.name},
        } for i, (chunk, vec) in enumerate(zip(chunks, vectors))]
        index.upsert(vectors=items, namespace=namespace)
```

Context Library variant: embed the **description** (intent), store `blueprint_json` as metadata, upsert to `ContextLibrary` namespace.

See `references/rag-ingestion/` for chunking + batch helpers, and `references/dual-rag/` for the two-namespace contract.

## Sample Control Deck

```python
goal = "Draft a memo summarizing precedent for case X with citations."
config = {
    "index_name": "context-engine",
    "generation_model": "gpt-5",
    "embedding_model": "text-embedding-3-small",
    "namespace_context":   "ContextLibrary",
    "namespace_knowledge": "KnowledgeStore",
}
client, pc = initialize_clients()
execute_and_display(goal, config, client, pc, moderation_active=True)
```
