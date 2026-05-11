# Graph-Like Data Models Knowledge

Core concepts for graph data models, query languages, and when graphs naturally fit your data.

## Overview

Graphs model data as vertices (nodes) and edges (relationships). They excel when many-to-many relationships dominate your data, or when you need to traverse variable-length paths. Two main models exist: **property graphs** (Neo4j, Memgraph) and **triple stores** (Datomic, AllegroGraph). Multiple query languages target them: Cypher, SPARQL, Datalog, and GraphQL (which is API-layer, not a storage model).

## Key Concepts

### Graph

**Definition**: A data structure of *vertices* (nodes/entities) connected by *edges* (relationships/arcs).

**Key points**:
- Vertices and edges can both carry labels and properties
- Stored as *adjacency list* (good for traversal) or *adjacency matrix* (good for ML)
- Same graph can hold heterogeneous entity types (people, places, events) under one model

### Property Graph

**Definition**: A graph model where each vertex and edge has a unique ID, label, and a set of key-value properties.

Each vertex has: unique ID, label (type), outgoing edges, incoming edges, properties.
Each edge has: unique ID, tail vertex, head vertex, label (relationship type), properties.

**Key points**:
- No schema restricts which vertices can connect — fully flexible
- Bidirectional traversal: edges indexed on both head and tail vertex
- Can be stored in two relational tables (`vertices`, `edges`) with `jsonb` properties
- Implementations: Neo4j, Memgraph, KùzuDB, Amazon Neptune, Apache AGE

### Triple Store

**Definition**: All data stored as 3-part statements (*subject*, *predicate*, *object*), e.g. `(Jim, likes, bananas)`.

**Key points**:
- Subject = vertex; object = either a primitive value (then predicate is a property key) or another vertex (then predicate is an edge label)
- Equivalent in expressive power to property graphs, just different vocabulary
- Some stores extend to quads (Neptune) or 5-tuples (Datomic with txn ID + retraction flag)
- Implementations: Datomic, AllegroGraph, Blazegraph, OpenLink Virtuoso

### RDF (Resource Description Framework)

**Definition**: A standardized data model for triples designed for internet-wide data exchange (Semantic Web origin).

**Key points**:
- Subjects, predicates, and objects are typically **IRIs/URIs** (e.g., `<http://my-company.com/namespace#within>`) so independently-published datasets can be merged without name collisions
- URIs serve as namespaces; they need not resolve to anything
- Encodings: **Turtle** (concise), **N3**, **RDF/XML** (verbose)
- Tools like Apache Jena convert between encodings

### IRI / URI (in RDF)

**Definition**: Globally unique identifier used as a name for a subject, predicate, or object so that data from different sources can be combined unambiguously.

## Query Languages

### Cypher

Declarative pattern-matching language for property graphs. Originally Neo4j, now openCypher and the basis for the **GQL ISO standard** (2024). Uses arrow notation `(a)-[:LABEL]->(b)` for edges. Supports variable-length paths via `*0..` (Kleene-star-like syntax).

### SPARQL

Pattern-matching query language for RDF triple stores. Predates Cypher; Cypher's pattern matching was borrowed from it. Variables prefixed with `?`. Property paths use `/` and `*` (e.g., `:bornIn / :within*`).

### Datalog

Older (1980s) declarative language, subset of Prolog. Builds queries from **rules** that derive virtual tables, supporting recursion natively. Used by Datomic, LogicBlox, CozoDB, LinkedIn's LIquid. Based on relational, not graph, model — but powerful for recursive graph traversals.

### GraphQL

**Not a storage model** — an API query language for OLTP. Lets clients request a JSON document with a specific structure (only the fields they need). Designed to be safe for untrusted clients: **no recursion**, no arbitrary search conditions. Can be implemented on top of any database (relational, document, or graph).

## When Graphs Fit

- Highly connected, many-to-many data (social networks, fraud detection, knowledge graphs)
- Variable-length recursive traversals (shortest path, ancestry, "all locations in X")
- Heterogeneous entities in one model (Facebook stores people, places, events, comments together)
- Schema evolution: easily add new vertex/edge types as the application grows

## Terminology

| Term | Definition |
|------|------------|
| Vertex / Node | A graph entity |
| Edge / Arc / Relationship | A directed connection between two vertices |
| Tail vertex | Where an edge starts |
| Head vertex | Where an edge ends |
| Property graph | Graph model with labels + key-value properties on vertices and edges |
| Triple | `(subject, predicate, object)` statement |
| RDF | Standardized triple-based data model with URIs as identifiers |
| IRI / URI | Globally unique name used in RDF |
| Turtle / N3 | Concise textual encodings of RDF |
| Adjacency list | Each vertex stores neighbor IDs (good for traversal) |
| Adjacency matrix | 2D array of edge presence (good for ML / linear algebra) |
| Hypergraph | Generalization where one edge connects more than two vertices |

## Common Misconceptions

- **Myth**: GraphQL is a graph database query language.
  **Reality**: GraphQL is an API/transport layer. It can sit on top of relational, document, or graph stores. It explicitly forbids recursion.

- **Myth**: Property graphs and triple stores are fundamentally different.
  **Reality**: They're mostly equivalent in expressive power; different vocabulary and tooling. Some DBs (Neptune) support both.

- **Myth**: SQL cannot query graphs.
  **Reality**: It can, using `WITH RECURSIVE` (recursive CTEs) — but the syntax is much more verbose than Cypher.

- **Myth**: Edges always connect exactly two vertices, so graphs subsume relational.
  **Reality**: An edge in a property graph connects only **two** vertices. Three-way relationships need an extra "join vertex" or a hypergraph; relational join tables handle higher-degree relationships natively.

## Quick Reference

| Concept | One-Line Summary |
|---------|------------------|
| Property graph | Vertices + edges, each with label + properties |
| Triple store | Data as `(subject, predicate, object)` tuples |
| RDF | Standardized triple model using URIs for global identity |
| Cypher | Pattern-matching query language for property graphs |
| SPARQL | Pattern-matching query language for RDF |
| Datalog | Rule-based recursive query language (Prolog subset) |
| GraphQL | Client-driven JSON API query language; not storage |
| Recursive CTE | SQL's `WITH RECURSIVE` for variable-length traversal |
