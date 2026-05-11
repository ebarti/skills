# Encoding Formats Rules

Guidance for choosing wire formats and evolving them safely without breaking producers or consumers.

## Core Rules

### 1. Don't use language-specific serialization across processes

`java.io.Serializable`, Python `pickle`, Ruby `Marshal`, Kryo are for **transient** in-process use only.

- Locks data to one language; can't be read elsewhere.
- Decoder can instantiate arbitrary classes — RCE attack surface.
- Versioning and forward/backward compat are afterthoughts.
- Java's built-in is notoriously slow and bloated.

### 2. Pick the right format for the job

| Use case | Preferred format |
|----------|------------------|
| Cross-organization interchange | JSON / XML / CSV (lowest agreement cost) |
| Internal RPC, statically typed services | Protocol Buffers (or Thrift) |
| Analytics, batch dumps, Kafka topics | Avro (with schema registry) |
| Document storage where structure is loose | JSON (+ JSON Schema when validation matters) |
| Tabular without nesting | CSV (accept its limits) |

### 3. JSON: validate with JSON Schema where structure matters

- JSON cannot distinguish int vs float, has no precision spec, has no binary type.
- Numbers > 2^53 lose precision in JavaScript — return them as both number and string (X / Twitter does this for post IDs).
- Encode binary as Base64 (≈33% overhead) and document it via schema.
- Use **closed content models** (`additionalProperties: false`) when you must reject unknown fields; default is open.
- Avoid heavy use of conditional `if/else`, remote `$ref`, deep type unions — they make compatibility analysis painful.

### 4. Protocol Buffers: tags are forever

- Each field needs a unique numeric **tag** in the `.proto`. The wire format references tags, never names.
- **You can rename a field** (names aren't on the wire).
- **You cannot change a field's tag** — it invalidates all existing data.
- **Adding a field**: pick a new tag. Old code skips unknown tags using the type annotation → forward compatible. Missing fields use defaults → backward compatible.
- **Removing a field**: never reuse its tag. Reserve removed tag numbers in the schema so nobody re-allocates them.
- **Changing a field's type**: only some conversions are safe; widening (int32 → int64) can truncate when old code reads new data.
- Use `repeated` for lists; the wire format is just multiple occurrences of the same tag.

### 5. Avro: keep writer's and reader's schemas reconcilable

- Decoder needs the **exact writer's schema**; bytes carry no field IDs or types.
- Distribute the writer's schema:
  - Embed once at the start of object container files.
  - Store in a schema registry (Confluent, Apicurio) keyed by version number per record.
  - Negotiate at the start of an RPC connection.
- **Add or remove fields only if they have a default value.**
  - Adding a no-default field breaks backward compatibility (new readers fail on old data).
  - Removing a no-default field breaks forward compatibility (old readers fail on new data).
- Use **union types** (`union { null, long, string }`) for nullability; `null` is only a valid default if it is the **first branch**.
- Renaming a field requires aliases in the reader's schema → backward compatible only.
- Adding a branch to a union → backward compatible only.

### 6. Always preserve unknown fields when forwarding

If a service reads a record, mutates one field, and re-emits it, unknown (newer) fields must round-trip unchanged. Protobuf parsers and Avro reconcilers handle this for you only if you don't decode-then-re-encode through a model that drops unknowns.

### 7. Protobuf vs Avro for dynamic schemas

- **Avro wins** when you generate schemas from another source (relational tables → Avro records) and that source changes often.
  - No tags to reassign; matching is by field **name**.
  - Regenerate the schema and dump; old readers still resolve via aliases / defaults.
- **Protobuf** requires a human (or a very careful generator) to assign tags and never reuse them.

## Guidelines

- Keep the number of concurrent schema formats in your stack to a minimum — it simplifies operations.
- Treat the schema as documentation: it must exist for decoding, so it can't drift from reality (unlike hand-written docs).
- Stand up a **schema registry** even if you only have one consumer today — it gives you compat checking before deploys.
- For statically typed languages, lean on schema-driven code generation for compile-time type checking.
- Consider zero-copy formats (Cap'n Proto, FlatBuffers) only when encode/decode CPU cost dominates.

## Exceptions

- **Transient single-process use**: Language-native serialization is acceptable for short-lived caches in the same runtime.
- **Logs and exploration**: JSON / CSV are fine when humans grep them and longevity isn't a concern.
- **Database wire protocols**: Vendors ship proprietary binary protocols and ODBC/JDBC drivers — you don't pick the format.

## Quick Reference

| Rule | Summary |
|------|---------|
| Language-specific encoders | Cross-process: never. In-process transient: maybe. |
| Format choice | Cross-org → JSON/XML/CSV. Internal → Protobuf. Analytics → Avro. |
| Protobuf tags | Pick once, never change, never reuse. Reserve removals. |
| Protobuf field rename | Safe — names aren't on the wire. |
| Avro field add/remove | Only with a default value, or you break compat. |
| Avro nullability | Union with `null` first to allow `null` default. |
| Schema distribution (Avro) | File header / registry + version / RPC handshake. |
| Forwarding records | Preserve unknown fields end to end. |
