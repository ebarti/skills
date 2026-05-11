# Graph-Like Data Models Examples

Query examples in Cypher, SPARQL, Datalog, and SQL — all answering the same question: *find people who emigrated from the US to Europe* (from DDIA's running graph example with Lucy and Alain).

## The Running Example

A graph with two people (Lucy from Idaho, Alain from Saint-Lô, France) and locations forming a hierarchy: city → state/region → country → continent. Both now live in London. Edges: `BORN_IN`, `LIVES_IN`, `WITHIN`.

## Property Graph Schema (in PostgreSQL)

A property graph can be stored as two relational tables:

```sql
CREATE TABLE vertices (
  vertex_id   integer PRIMARY KEY,
  properties  jsonb
);

CREATE TABLE edges (
  edge_id     integer PRIMARY KEY,
  tail_vertex integer REFERENCES vertices (vertex_id),
  head_vertex integer REFERENCES vertices (vertex_id),
  label       text,
  properties  jsonb
);

CREATE INDEX edges_tails ON edges (tail_vertex);
CREATE INDEX edges_heads ON edges (head_vertex);
```

**Why both indexes**: enables efficient traversal in both directions (incoming and outgoing edges of any vertex).

## Cypher

### Inserting graph data

```cypher
CREATE
  (namerica:Location {name:'North America', type:'continent'}),
  (usa:Location      {name:'United States', type:'country'  }),
  (idaho:Location    {name:'Idaho',         type:'state'    }),
  (lucy:Person       {name:'Lucy' }),
  (idaho)  -[:WITHIN]->  (usa),
  (usa)    -[:WITHIN]->  (namerica),
  (lucy)   -[:BORN_IN]-> (idaho)
```

Symbolic names (`usa`, `idaho`) are scoped to the query, not stored.

### Query: people who emigrated from US to Europe

```cypher
MATCH
  (person) -[:BORN_IN]->  () -[:WITHIN*0..]-> (us:Location {name:'United States'}),
  (person) -[:LIVES_IN]-> () -[:WITHIN*0..]-> (eu:Location {name:'Europe'})
RETURN person.name
```

**Why it works**:
- `() -[:BORN_IN]-> ()` matches any pair of vertices joined by a `BORN_IN` edge
- `:WITHIN*0..` means "follow `WITHIN` zero or more times" (Kleene-star on edges)
- Single `MATCH` with two patterns naturally expresses an AND

## SQL with Recursive CTE

The same query, against the property-graph schema above (sketch):

```sql
WITH RECURSIVE
  -- 1. Build set of all vertex IDs within "United States" (transitively)
  in_usa(vertex_id) AS (
      SELECT vertex_id FROM vertices WHERE properties->>'name' = 'United States'
    UNION
      SELECT edges.tail_vertex FROM edges
        JOIN in_usa ON edges.head_vertex = in_usa.vertex_id
      WHERE edges.label = 'within'
  ),
  -- 2. Same for "Europe" (in_europe CTE, identical shape) ...
  -- 3. born_in_usa: tails of 'born_in' edges into in_usa vertices
  -- 4. lives_in_europe: tails of 'lives_in' edges into in_europe vertices
  ...
SELECT vertices.properties->>'name'
FROM vertices
  JOIN born_in_usa     USING (vertex_id)
  JOIN lives_in_europe USING (vertex_id);
```

**Takeaway**: the full version is ~31 lines of SQL vs 4 lines of Cypher. Same answer; the data model and query language matter.

## Triple Store / RDF (Turtle)

Same graph, expressed as triples in Turtle:

```turtle
@prefix : <urn:example:>.
_:lucy     a :Person;   :name "Lucy";          :bornIn _:idaho.
_:idaho    a :Location; :name "Idaho";         :type "state";   :within _:usa.
_:usa      a :Location; :name "United States"; :type "country"; :within _:namerica.
_:namerica a :Location; :name "North America"; :type "continent".
```

Notes: `_:name` denotes a local vertex identifier. Semicolons let you make multiple statements about the same subject.

## SPARQL

```sparql
PREFIX : <urn:example:>

SELECT ?personName WHERE {
  ?person :name ?personName.
  ?person :bornIn  / :within* / :name "United States".
  ?person :livesIn / :within* / :name "Europe".
}
```

**Cypher vs SPARQL equivalence**:

```
(person) -[:BORN_IN]-> () -[:WITHIN*0..]-> (location)   # Cypher
?person :bornIn / :within* ?location.                   # SPARQL
```

## Datalog

Facts (the data):

```prolog
location(1, "North America", "continent").
location(2, "United States", "country").
location(3, "Idaho",         "state").
within(2, 1).      % USA within North America
within(3, 2).      % Idaho within USA
person(100, "Lucy").
born_in(100, 3).   % Lucy born in Idaho
```

Query (with rules):

```prolog
within_recursive(LocID, Name) :- location(LocID, Name, _).        /* Rule 1 */
within_recursive(LocID, Name) :- within(LocID, ViaID),            /* Rule 2 */
                                 within_recursive(ViaID, Name).

migrated(PName, BornIn, LivingIn) :-                              /* Rule 3 */
  person(PersonID, PName),
  born_in(PersonID, BornID), within_recursive(BornID, BornIn),
  lives_in(PersonID, LivingID), within_recursive(LivingID, LivingIn).

us_to_europe(Name) :-                                              /* Rule 4 */
  migrated(Name, "United States", "Europe").
```

**How it works**: Each rule (after `:-`) defines a **virtual table** derived from facts. Rule 2 invokes itself — that's how recursive traversal works in Datalog. Build complex queries rule-by-rule, like composing functions.

## GraphQL

GraphQL is API-layer, not storage. Client sends a query describing the JSON shape it wants:

```graphql
query ChatApp {
  channels {
    name
    recentMessages(latest: 50) {
      timestamp
      content
      sender { name, imageUrl }
      replyTo {
        content
        sender { name }
      }
    }
  }
}
```

Server returns a JSON document mirroring the query exactly — no over- or under-fetching. The server's database can be relational, document, or graph; only joins declared in the GraphQL schema can be requested.

**Trade-off shown**: `replyTo` duplicates message content rather than returning an ID. This avoids a follow-up round trip and simplifies UI rendering, at the cost of larger responses.

## Real Implementations

| Database | Model | Primary Query Language |
|----------|-------|------------------------|
| Neo4j | Property graph | Cypher |
| Memgraph | Property graph | Cypher |
| KùzuDB | Property graph | Cypher |
| Apache AGE | Property graph (on Postgres) | Cypher |
| Amazon Neptune | Both | Cypher + SPARQL + Gremlin |
| Datomic | Triple store (5-tuples) | Datalog |
| AllegroGraph | Triple store | SPARQL |
| Blazegraph | Triple store | SPARQL |
| OpenLink Virtuoso | Triple store | SPARQL |
| LogicBlox | Relational | Datalog |
| CozoDB | Relational | Datalog |

**Standards**: openCypher; **GQL ISO standard** (2024, based on Cypher) for graph queries; SPARQL/RDF/Turtle (W3C) for triple stores.
