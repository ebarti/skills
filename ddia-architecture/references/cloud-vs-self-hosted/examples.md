# Cloud vs Self-Hosted Examples

Concrete services, architectures, and trade-offs called out in the chapter.

## Self-Hosted vs Cloud-Native Database Examples

| Category | Self-hosted systems | Cloud-native systems |
|----------|--------------------|-----------------------|
| Operational / OLTP | MySQL, PostgreSQL, MongoDB | AWS Aurora, Azure SQL DB Hyperscale, Google Cloud Spanner |
| Analytical / OLAP | Teradata, ClickHouse, Spark | Snowflake, Google BigQuery, Azure Synapse Analytics |

Self-hosted systems can be lifted onto IaaS VMs; cloud-native systems are designed from scratch to use cloud services as building blocks and gain better performance, faster failure recovery, easier scaling, and larger dataset support.

## Object Storage Services

Used as the durable foundation under many cloud-native systems.

- **Amazon S3**
- **Azure Blob Storage**
- **Cloudflare R2**

**API surface**: Limited to basic file read/write — no general filesystem semantics.

**Object size sweet spot**: Hundreds of kilobytes to several gigabytes per file.

**Why use it**: Hides individual machines, replicates automatically, survives disk and machine failures, no per-instance capacity planning.

**Why not use it for everything**: Individual database rows are far smaller than the object-size sweet spot — databases pack many values into larger blocks before storing them in S3.

## Virtual Block Storage (Lift-and-Shift Path)

Block-device emulation that lets traditional disk-based software run in cloud:

- **Amazon EBS**
- **Azure managed disks**
- **Google Cloud persistent disks**

Each block is typically 4 KiB. Every I/O on the virtual block device is a network call, which adds latency and makes the application sensitive to network glitches. Useful for porting existing software; cloud-native systems avoid them.

## Snowflake — Layered Cloud-Native Architecture

Snowflake is a cloud-based analytical database that builds on object storage rather than managing its own durable disks.

```
         ┌────────────────────────────────────┐
         │  Other services built on Snowflake │
         └────────────────────────────────────┘
                          ▲
                          │
         ┌────────────────────────────────────┐
         │   Snowflake (compute + query)      │
         └────────────────────────────────────┘
                          ▲
                          │  reads/writes data files
         ┌────────────────────────────────────┐
         │   Amazon S3 (object storage)       │
         └────────────────────────────────────┘
```

Key takeaway: cloud-native services compose. Higher layers are more use-case-specific; lower layers are more general.

## Storage / Compute Disaggregation

### Traditional (co-located)

```
┌──────────────────────────────┐
│         One Server           │
│  ┌───────┐    ┌───────────┐  │
│  │ CPU + │◄──►│ Local     │  │
│  │  RAM  │    │ Disks     │  │
│  └───────┘    │ (RAID)    │  │
│               └───────────┘  │
└──────────────────────────────┘
```

Disk failures are masked by RAID; storage and compute live and die together.

### Cloud-Native (disaggregated)

```
┌──────────────┐   network    ┌──────────────────┐
│ Compute VM   │ ───────────► │ Object Storage   │
│ (CPU + RAM   │ ◄─────────── │ (S3 / Blob / R2) │
│  + ephemeral │              │  durable, scaled │
│  cache disk) │              └──────────────────┘
└──────────────┘
```

- Local instance disks are ephemeral — cache, not source of truth.
- Compute can be scaled, replaced, or resized without losing data.
- Multiple compute clusters can share the same data store (e.g., independent query engines reading the same S3 bucket).

## Variable-Load Example: Analytical Queries

Analytical workloads have extremely variable load:

- A large analytical query needs significant parallel compute for a short burst.
- Once the query completes, those resources sit idle until the next interactive query.
- Predefined daily reports can be enqueued and scheduled to smooth load.
- Interactive queries: faster completion = more variable load.

Cloud's ability to release unused resources back to the provider makes it cost-effective for large datasets with bursty queries. For small datasets, the savings are negligible.

## When Self-Hosted Wins: High-Frequency Trading

Latency-sensitive applications such as high-frequency trading require full control of the hardware. Cloud services cannot meet this requirement, so in-house systems remain necessary.

## Cloud Lock-In Failure Modes

The chapter calls out specific failure modes you have no recourse against in a cloud-only design:

- **Missing feature**: You can ask the vendor; you generally cannot implement it yourself.
- **Outage**: You can only wait for recovery.
- **Performance bug**: Without OS metrics or server logs, diagnosing is hard.
- **Vendor change / shutdown / price hike**: Migration is forced; running the old version is usually not an option.
- **Geopolitical sanctions**: A provider in another country can become unreachable.
- **Data trust**: Provider must be trusted with your data, complicating compliance.

## Operations Role Examples

| Era | Role | Focus |
|-----|------|-------|
| Traditional self-hosted | DBA / sysadmin | Per-machine work: capacity planning, disk additions, OS patches, machine moves |
| DevOps integration | Combined dev + ops team | Shared responsibility for backend services and infrastructure |
| Google's version | SRE (Site Reliability Engineer) | Reliability via automation and engineering practices |
| Cloud customer-side | Cloud operator | Service selection, integration, migration, cost control, security |
| Cloud provider-side | Infrastructure operator | Reliable service to many customers at scale |

## Metered Billing vs Capacity Planning

- **Self-hosted**: Buy disks ahead of running out of space.
- **Cloud storage**: Store data without planning capacity; pay per GB used.
- **Customer trade-off**: Capacity planning becomes financial planning; performance optimization becomes cost optimization. Quotas (e.g., max concurrent processes) still need to be planned around.
