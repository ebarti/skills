# Graph-Like Data Models Rules

Decision guidance for choosing graph models, triple stores, and graph query languages versus relational alternatives.

## Core Rules

### 1. Use a graph database when many-to-many relationships dominate

If the connections in your data are as important as the entities themselves — and they're complex, varied, or recursive — a graph model is more natural than a relational schema.

- Social graphs, knowledge graphs, fraud rings, recommendation networks
- Heterogeneous entity types you want to query under one model
- Schemas that need to evolve frequently (graphs are schema-flexible)

### 2. Do NOT use a graph DB for mostly tabular data

If your data is predominantly rows-and-columns with a fixed set of joins known in advance, use a relational database. Graph DBs add operational complexity without payback for tabular workloads.

- One-to-many / tree-shaped data → document model
- Fixed join structure known at query design time → SQL
- Reporting/analytics over wide tables → relational + OLAP

### 3. Reach for recursive CTEs before adopting a graph DB if traversals are rare

If you're already on PostgreSQL/Oracle/SQL Server and only occasionally need a transitive-closure query, `WITH RECURSIVE` works. Don't introduce a new datastore for one or two queries.

- Caveat: Cypher's 4 lines became ~31 lines of SQL in the book's example
- Caveat: SQL recursion handles cycles, traversal order awkwardly
- Switch to a graph DB when recursive queries become central, not occasional

### 4. Choose property graph vs triple store by tooling, not expressive power

The two models can express the same things. Pick based on the ecosystem you need.

- **Property graph (Neo4j, Memgraph, KùzuDB)**: better tooling for app developers, Cypher is widely known, GQL standard is based on Cypher
- **Triple store (Datomic, AllegroGraph, Blazegraph)**: better fit if you need RDF interop, Semantic Web data (Wikidata, Schema.org, JSON-LD, biomedical ontologies), or Datomic's time-travel queries
- **Both (Amazon Neptune)**: if you want to defer the choice

### 5. Choose Cypher when you need imperative-feeling pattern matching

Cypher's `MATCH (a)-[:REL]->(b)` is the most accessible graph query syntax for engineers coming from SQL. It's also the basis of the new GQL ISO standard (2024).

- Use Cypher for property graphs, app-facing queries, and OLTP traversals
- `:WITHIN*0..` syntax expresses variable-length paths concisely

### 6. Choose SPARQL when consuming or publishing RDF/Linked Data

SPARQL is the right choice when integrating with Semantic Web data, biomedical ontologies, government open data, or anything publishing as RDF.

- Equivalent power to Cypher; pattern matching is nearly identical
- Property paths: `?person :bornIn / :within* ?location`
- Variables prefixed with `?`

### 7. Choose Datalog for complex, composable, recursive queries

Datalog lets you build queries rule by rule, like decomposing code into functions. Rules can call themselves (recursion). Best when query complexity exceeds what fits in a single Cypher/SPARQL statement.

- Niche but powerful: Datomic, LogicBlox, CozoDB
- Steep learning curve; small ecosystem
- Strong fit for derived/computed views and rule-based reasoning

### 8. Treat GraphQL as an API contract, NOT a database

GraphQL is for client-server communication. It can sit on top of any database. Do not pick a database "because we use GraphQL."

- GraphQL forbids recursion and arbitrary search by design (untrusted clients)
- Server resolves the GraphQL schema's joins against the underlying store
- Expect duplication in responses (e.g., embedded sender info per message) — that's intentional for client simplicity

## Guidelines

- For 3+ way relationships, add a "join vertex" (an edge can only connect two vertices) or use a hypergraph
- Index both `head_vertex` and `tail_vertex` so traversal works in both directions
- For graph storage in PostgreSQL, use `jsonb` for flexible properties and Apache AGE for Cypher
- For ML on graphs, prefer adjacency-matrix representations
- Use IRIs in RDF defensively — even if you don't publish data, they prevent naming collisions if you ever merge datasets

## Exceptions

- **Document model wins**: One-to-many, self-contained aggregates with few cross-references
- **Relational wins**: Stable schema, well-known joins, strong analytics needs
- **Graph wins anyway**: Even moderately connected data benefits from graphs if connectivity is *the* feature (e.g., knowledge graphs for search)

## Quick Reference

| Situation | Recommended Choice |
|-----------|-------------------|
| Tree-structured / one-to-many | Document model |
| Mostly tabular, known joins | Relational (SQL) |
| Many-to-many, complex traversals | Property graph + Cypher |
| Need RDF / Linked Data interop | Triple store + SPARQL |
| Deeply recursive, rule-based logic | Datalog (Datomic, CozoDB) |
| Occasional transitive query in SQL shop | Recursive CTE (`WITH RECURSIVE`) |
| Client-driven JSON API | GraphQL (over any DB) |
| 3+ way relationship | Join vertex or hypergraph |
| Heterogeneous entities in one model | Property graph or triple store |
