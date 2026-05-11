# Encoding Formats Examples

Concrete schemas, encodings, and real systems for the encoding formats covered in DDIA Chapter 5.

## Sample Record

The book encodes the same record across all formats:

```javascript
{
  "userName": "Martin",
  "favoriteNumber": 1337,
  "interests": ["daydreaming", "hacking"]
}
```

JSON text length (whitespace removed): **81 bytes**.

## JSON Schema (with integer-keyed map workaround)

JSON has no integer-keyed map type, so a schema constrains string keys to digits and values to strings:

```json
{
  "type": "object",
  "patternProperties": {
    "^[0-9]+$": { "type": "string" }
  },
  "additionalProperties": false
}
```

**Why it's odd**: JSON object keys must be strings. `patternProperties` enforces "digits only," and `additionalProperties: false` (closed content model) rejects anything else. The default open model would silently accept any other key.

## MessagePack Binary Encoding (66 bytes)

First few bytes of the sample record:

| Byte | Meaning |
|------|---------|
| `0x83` | Object header: `0x80` mask + `0x03` field count (3 fields) |
| `0xa8` | String header: `0xa0` mask + `0x08` length (8 chars) |
| `userName` (8 bytes ASCII) | First field name |
| `0xa6` `Martin` | String of length 6, then value |
| ... | Continues for `favoriteNumber` and `interests` |

**Size**: 66 bytes vs 81 bytes JSON. Field names (`userName`, `favoriteNumber`, `interests`) are all carried inline because there is no schema.

## Protocol Buffers Schema (.proto)

```protobuf
syntax = "proto3";

message Person {
  required string user_name       = 1;
  optional int64  favorite_number = 2;
  repeated string interests       = 3;
}
```

**Encoded size**: **33 bytes** for the sample record.

Notes:
- Tags `1`, `2`, `3` are the only field identifiers on the wire.
- `repeated` replaces an explicit list type — list elements are emitted as multiple occurrences of the same tag.
- Field type and tag are packed into one byte for tags 1–15.
- Variable-length integers: `1337` → 2 bytes; numbers in –64..63 → 1 byte.

### Evolving the schema

Add a field — must pick an unused tag:

```protobuf
message Person {
  required string user_name       = 1;
  optional int64  favorite_number = 2;
  repeated string interests       = 3;
  optional string email           = 4;   // new, tag 4 — old readers ignore
}
```

Remove a field — reserve its tag:

```protobuf
message Person {
  reserved 2;
  reserved "favorite_number";
  required string user_name = 1;
  repeated string interests = 3;
}
```

## Avro IDL

```
record Person {
  string               userName;
  union { null, long } favoriteNumber = null;
  array<string>        interests;
}
```

## Avro JSON Schema

```json
{
  "type": "record",
  "name": "Person",
  "fields": [
    { "name": "userName",       "type": "string" },
    { "name": "favoriteNumber", "type": ["null", "long"], "default": null },
    { "name": "interests",      "type": { "type": "array", "items": "string" } }
  ]
}
```

**Encoded size**: **32 bytes** — the most compact of all formats in the chapter.

The wire format has no field IDs and no type tags. Decoding is just walking the schema and reading concatenated values.

### Avro schema evolution

Add a field — must have a default to stay compatible both ways:

```json
{ "name": "email", "type": ["null", "string"], "default": null }
```

Rename a field — use an alias in the reader's schema (backward compat only, not forward):

```json
{ "name": "user_name", "type": "string", "aliases": ["userName"] }
```

## Encoding Size Comparison

| Format | Size (bytes) | Notes |
|--------|--------------|-------|
| JSON (text, no whitespace) | 81 | Field names + delimiters inline |
| MessagePack (binary JSON) | 66 | Type bytes save delimiters; names still inline |
| Protocol Buffers | 33 | Numeric tags replace names; varint integers |
| Avro | 32 | No tags, no type bytes; schema does all the work |

## Real Systems Using Each Format

| System | Format | Why |
|--------|--------|-----|
| Confluent Kafka + Schema Registry | **Avro** | Per-record version numbers point to writer's schema; forward/backward checks before deploy. |
| LinkedIn Espresso | **Avro** | Same registry pattern as Confluent. |
| gRPC | **Protocol Buffers** | Schema-driven RPC across many languages. |
| REST APIs / OpenAPI | **JSON** + **JSON Schema** | Human-readable, broad tooling, contract validation. |
| MongoDB (`$jsonSchema`) | **JSON Schema** | Document validation in the database. |
| PostgreSQL (`pg_jsonschema`) | **JSON Schema** | Column-level validation extension. |
| Hadoop / HDFS bulk dumps | **Avro** (object container files) | Schema embedded at file start; ideal for batch. |
| SSL / X.509 certificates | **ASN.1 / DER** | Tag-numbered like Protobuf, standardized 1984. |
| Apache Thrift services (Facebook origin) | **Thrift** | Sibling of Protobuf with similar tag rules. |
| Database drivers (ODBC / JDBC) | Vendor-proprietary binary | Network protocol per database; driver decodes. |

## Cross-Format Refactoring: Relational Dump

### Before: hand-maintained Protobuf

When the source DB adds/drops a column, an admin must update the `.proto` and assign a new tag — and never reuse old ones.

```protobuf
message Customer {
  required int64  id    = 1;
  required string name  = 2;
  optional string email = 3;
}
// New column "phone" → must assign tag 4 by hand.
```

### After: dynamically generated Avro

Generate the Avro record per table, with each column as a field by name. No tags. On schema change, just regenerate and dump:

```json
{
  "type": "record",
  "name": "Customer",
  "fields": [
    { "name": "id",    "type": "long" },
    { "name": "name",  "type": "string" },
    { "name": "email", "type": ["null", "string"], "default": null },
    { "name": "phone", "type": ["null", "string"], "default": null }
  ]
}
```

**Why it works**: Avro matches by field name; old readers with the previous schema still resolve via defaults / aliases. Protobuf would require human tag management.
