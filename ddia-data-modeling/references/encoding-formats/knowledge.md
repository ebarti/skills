# Encoding Formats Knowledge

Core concepts for encoding in-memory data structures into byte sequences for storage or network transmission, and evolving those formats over time.

## Overview

Programs hold data in two representations: in-memory objects (optimized for CPU access via pointers) and byte sequences (for files or network). Translation between them is *encoding* (writing) and *decoding* (reading). Format choice affects portability, size, performance, and the ability to evolve schemas without breaking existing code or data.

## Key Concepts

### Encoding / Decoding

**Definition**: Encoding (a.k.a. serialization, marshaling) translates in-memory representation into a self-contained byte sequence. Decoding (parsing, deserialization, unmarshaling) is the reverse.

The book uses *encoding* to avoid clashing with *serializable* in the transactions sense.

### Schema vs Schemaless

- **Schema**: Explicit definition of fields, types, and structure (Protobuf, Avro, JSON Schema, XML Schema).
- **Schemaless / schema-on-read**: Structure is implied by readers at access time (raw JSON, CSV).

### Language-Specific Formats

**Definition**: Built-in serializers tied to one runtime: Java `java.io.Serializable`, Python `pickle`, Ruby `Marshal`, Kryo (Java).

Convenient but locks data to one language, opens RCE security holes (decoders instantiate arbitrary classes), versions poorly, and is often slow/bloated.

### Text Formats

| Format | Notes |
|--------|-------|
| JSON | Distinguishes strings vs numbers, but not int vs float; no precision; no binary type (Base64 hack adds ~33% size). |
| XML | Verbose, complex; cannot distinguish numbers from digit-strings without schema. |
| CSV | Tabular only, no nesting, no schema, ambiguous escaping. |

### Binary Variants of JSON/XML

MessagePack, BSON, CBOR, BJSON, UBJSON, BISON, Hessian, Smile (JSON); WBXML, Fast Infoset (XML). They keep the JSON/XML data model and must include field names inline (no schema). MessagePack of the example record = 66 bytes vs 81 bytes JSON — modest savings.

### JSON Schema

**Definition**: Validation language for JSON documents. Used in OpenAPI, Confluent / Apicurio Schema Registry, PostgreSQL `pg_jsonschema`, MongoDB `$jsonSchema`.

- Primitive types: `string`, `number`, `integer`, `object`, `array`, `boolean`, `null`.
- Validators: numeric ranges, regex, etc.
- **Open content model** (default, `additionalProperties: true`) allows undeclared fields; **closed** restricts to declared fields.
- Powerful (conditional `if/else`, `$ref`, named types) but unwieldy: hard to evolve forward/backward compatibly.

### Protocol Buffers (Google) / Thrift (Facebook)

**Definition**: Schema-required binary encoders. Schema written in an IDL; code generators emit classes in many languages. Protobuf example = 33 bytes for the same record.

- Field identified by **numeric tag**, not name.
- Type annotation packed into a single byte alongside the tag.
- Variable-length integers (zigzag) — small numbers use fewer bytes.
- `repeated` modifier replaces explicit list/array types.

### Avro (Apache, Hadoop subproject, 2009)

**Definition**: Schema-required binary encoder with two schema dialects: Avro IDL (human) and a JSON-based schema (machine). Avro example = 32 bytes — most compact.

- **No tag numbers, no inline type info.** Fields are concatenated values.
- Decoding requires the writer's schema (the same one used to encode).
- Supports unions (e.g., `union { null, long, string }`) for nullability.
- Designed for **dynamically generated schemas** (e.g., one Avro record per relational table).

### Writer's Schema vs Reader's Schema (Avro)

- **Writer's schema**: The schema used when the data was encoded.
- **Reader's schema**: The schema the consuming application expects.
- Avro reconciles them at decode time: matches by **field name**, ignores writer-only fields, fills reader-only fields from defaults.

### Schema Evolution

**Definition**: The ongoing process of changing the schema while keeping old and new code interoperable.

- **Backward compatibility**: New code can read data written by old code.
- **Forward compatibility**: Old code can read data written by new code.
- **Full compatibility**: Both backward and forward.

### How Avro Knows the Writer's Schema

| Context | Mechanism |
|---------|-----------|
| Large file, many records | Schema embedded once at file start (Avro object container files). |
| Database / per-record writes | Version number prefix; lookup in schema registry (Confluent for Kafka, LinkedIn Espresso). |
| Bidirectional network connection | Negotiated at connection setup; reused for connection lifetime (Avro RPC). |

## Terminology

| Term | Definition |
|------|------------|
| Encoding / Serialization / Marshaling | In-memory → bytes |
| Decoding / Parsing / Deserialization / Unmarshaling | Bytes → in-memory |
| Field tag | Stable numeric ID for a Protobuf/Thrift field |
| Schema evolution | Changing schemas while preserving compatibility |
| Backward compat | New reader handles old data |
| Forward compat | Old reader handles new data |
| Writer's schema | Schema used at encode time (Avro) |
| Reader's schema | Schema the consumer expects (Avro) |
| Open content model | Schema permits undeclared fields (JSON Schema default) |
| Zero-copy format | Same layout in memory and on wire (Cap'n Proto, FlatBuffers) |

## Quick Reference

| Format | Schema | Tags | Size (sample record) | Best for |
|--------|--------|------|----------------------|----------|
| JSON | Optional (JSON Schema) | None | 81 bytes | Cross-org interchange, human eyes |
| MessagePack | None | None | 66 bytes | Compact JSON drop-in |
| Protobuf | Required (.proto) | Numeric | 33 bytes | RPC, statically typed services |
| Avro | Required (IDL/JSON) | None | 32 bytes | Analytics, dynamic schemas, Kafka |
