# Choosing Encoding Format Workflow

Pick a wire format and lock in a schema-evolution strategy that won't break producers or consumers as the system grows.

## When to Use

- Designing a new REST/RPC API, event topic, or analytics pipeline
- Picking a serialization format for inter-service or inter-org data exchange
- Planning how schemas will change without coordinated deploys
- Migrating from a language-specific serializer (pickle, Java Serializable) to something portable

## Prerequisites

- Know the producers and consumers (teams, runtimes, languages)
- Know whether the data crosses an organizational boundary
- Have a sense of message volume and latency budgets

**Reference**: `references/encoding-formats/rules.md`, `references/encoding-formats/knowledge.md`

---

## Workflow Steps

### Step 1: Identify the Use Case

**Goal**: Name the channel so the format constraints become obvious.

- [ ] Classify as one of: REST API, internal RPC, event log/stream, analytics file, config file
- [ ] Note who controls the producer and who controls the consumer (same team? different org?)
- [ ] Note the lifetime of the data (request/response, days in Kafka, years in S3)

**Ask**: "Who reads this, in what language, with what deploy cadence?"

---

### Step 2: Characterize Requirements

**Goal**: Surface the trade-offs that drive format choice.

- [ ] Schema rigidity: must every field be declared, or is loose structure OK?
- [ ] Dynamically generated schemas? (e.g., one record per relational table)
- [ ] Compactness: bytes-on-wire matter (mobile, high-volume Kafka) vs negligible
- [ ] Human readability needed for debugging or grepping logs?
- [ ] Ecosystem: what tooling/registry/code-gen exists for the consumers' languages?
- [ ] Cross-organization or internal-only?

**Reference**: `references/encoding-formats/knowledge.md`

---

### Step 3: Pick the Format

**Goal**: Match characteristics to the right encoder.

**Decision Tree**:

```
Is data crossing an org boundary or going to a public API?
├─ Yes → JSON (+ JSON Schema if validation matters); XML/CSV only if mandated
└─ No (internal)
   ├─ Internal RPC, statically typed services?
   │  └─ Protobuf (+ gRPC) — pick if you control schema and tags carefully
   ├─ Event log / Kafka topic / analytics dump?
   │  └─ Avro (+ Schema Registry) — best for dynamic / generated schemas
   ├─ Loose document storage?
   │  └─ JSON (+ JSON Schema for validated fields)
   └─ Tabular, no nesting?
      └─ CSV (accept its limits)

NEVER use language-specific serialization (pickle, Java Serializable, Marshal, Kryo)
across processes — it locks runtime, opens RCE, and versions poorly.
```

- [ ] Choose the format
- [ ] Document why this format (one paragraph) so future changes have context

**Reference**: `references/encoding-formats/rules.md` (Rules 1, 2, 7)

---

### Step 4: Define Schema Evolution Strategy

**Goal**: Decide which compatibility direction(s) you must guarantee.

- [ ] Pick the compatibility level:
  - **Backward**: new readers handle old data (safe to upgrade consumers first)
  - **Forward**: old readers handle new data (safe to upgrade producers first)
  - **Full**: both — required when producers and consumers deploy independently

**Format-specific rules**:

- **Protobuf**: tags are forever — never change or reuse a tag; reserve removed tags. Renaming a field is safe (names aren't on the wire).
- **Avro**: add/remove fields ONLY with a default value. For nullability use `union { null, T }` with `null` first. Renaming requires aliases.
- **JSON Schema**: prefer open content model unless you must reject unknown fields; avoid heavy `if/else` and `$ref` indirection.

- [ ] Document allowed and forbidden changes for the chosen format
- [ ] Always preserve unknown fields when forwarding records (don't decode-then-re-encode through a model that drops unknowns)

**Reference**: `references/encoding-formats/rules.md` (Rules 3, 4, 5, 6)

---

### Step 5: Pick a Schema Registry (Avro / Protobuf)

**Goal**: Distribute schemas safely and check compatibility before deploys.

**If Avro**:
- [ ] Pick a registry: Confluent Schema Registry, AWS Glue Schema Registry, Apicurio
- [ ] Configure compatibility mode (BACKWARD / FORWARD / FULL) per subject
- [ ] Decide schema distribution: file header (object container), registry + version per record, or RPC handshake

**If Protobuf**:
- [ ] Check in `.proto` files to a single repo of record (Buf Schema Registry is one option)
- [ ] Add CI check that rejects breaking changes (Buf lint/breaking)

**If JSON**:
- [ ] Stand up JSON Schema validation in CI and at the API boundary

---

### Step 6: Plan Version-Tagging Strategy

**Goal**: Make every encoded record self-identifying enough to route to the right schema.

- [ ] Avro file: schema embedded once at the start
- [ ] Avro per-record (Kafka): schema-registry version ID prefixed to each message
- [ ] Avro RPC: schemas exchanged at connection setup
- [ ] Protobuf: tags carry forever; major version bumps go in the message namespace (`v1.UserCreated` → `v2.UserCreated`)
- [ ] JSON: include `schemaVersion` field; URL-version your APIs (`/v2/users`)

---

### Step 7: Document Choice, Rules, and Ownership

**Goal**: Lock the decision into something reviewable.

- [ ] Write a short ADR or schema README capturing: chosen format, why, registry, compatibility mode, version-tagging convention
- [ ] Name an owner (team) for the schema repo and registry
- [ ] Add CI compatibility check before any merge that touches the schema
- [ ] Cross-link to dataflow-modes notes (REST/RPC, message brokers, datastore writes)

**Reference**: `references/dataflow-modes/`

---

## Quick Checklist

```
[ ] Step 1: Use case identified (REST / RPC / event / file / config)
[ ] Step 2: Requirements characterized (rigidity, dynamic, compact, ecosystem)
[ ] Step 3: Format chosen with documented rationale
[ ] Step 4: Compatibility direction (backward / forward / full) defined
[ ] Step 5: Schema registry / validation tooling set up
[ ] Step 6: Version-tagging convention agreed
[ ] Step 7: ADR/README written, owner named, CI check active
```

---

## Common Mistakes

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Using `pickle` / Java `Serializable` across services | Runtime lock-in; RCE risk; brittle versioning | Pick a portable, schema-driven format (Protobuf/Avro/JSON) |
| Removing or renaming a Protobuf field's tag | Wire format references tags — old data becomes unreadable | Reserve removed tags; only rename field names (safe) |
| Adding an Avro field without a default | Breaks backward compatibility — new readers fail on old data | Require defaults on every additive change |
| Schemaless event streams ("we'll figure it out later") | Consumers diverge on interpretation; replay becomes guesswork | Register a schema (even loose JSON Schema) before first publish |
| One Avro union without `null` first | `null` is only a valid default if it's the first branch | `union { null, T }` always for nullable fields |
| Decoding then re-encoding through a stale model | Drops unknown fields added by newer producers | Preserve unknown fields end to end when forwarding |
| Skipping a schema registry "until we need it" | First breaking change ships to prod with no warning | Stand up the registry day one; it's cheap insurance |
| Picking JSON for high-volume internal RPC | 2-3x larger than Protobuf, no compile-time types | Protobuf or Avro for internal hot paths |

---

## Cross-References

- `references/encoding-formats/rules.md` — format-specific evolution rules
- `references/encoding-formats/knowledge.md` — concepts, terminology, size comparisons
- `references/dataflow-modes/` — how the format flows through REST, RPC, message brokers, and databases

---

## Exit Criteria

Task is complete when:
- [ ] Format chosen and rationale recorded in an ADR or schema README
- [ ] Compatibility level (backward / forward / full) is explicit and enforced in CI
- [ ] Schema lives in a registry or a versioned repo with one named owner
- [ ] Producers and consumers can deploy independently without coordination
- [ ] No language-specific serializer crosses a process boundary
