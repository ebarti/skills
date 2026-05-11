# Cloud vs Self-Hosted Knowledge

Core concepts for the build-vs-buy decision in data systems and the architectural shift introduced by cloud-native design.

## Overview

Choosing between cloud services and self-hosted software is fundamentally a business decision (core competency vs. routine work) with deep technical consequences. Cloud-native architectures differ from traditional on-premises designs because they layer services, separate storage from compute, and assume multitenant, ephemeral infrastructure.

## Key Concepts

### Deployment Spectrum

A continuum from in-house bespoke software to fully outsourced SaaS. Key points along the spectrum:

- **Bespoke in-house**: You write and run it.
- **Self-hosted off-the-shelf**: Open source or commercial software you deploy yourself, on premises or on IaaS VMs.
- **Managed service**: Vendor operates the software for you.
- **SaaS**: Vendor builds and operates; you access via web/API.

"On premises" includes rented datacenter racks, not literally your own building.

### IaaS / PaaS / SaaS Layering

**Definition**: Cloud services come in layers, with each higher layer hiding more underlying machinery.

- **IaaS (Infrastructure as a Service)**: VMs / instances with allocated CPU, RAM, disk, network. You install and manage your own software. Provisions faster than physical machines, more size variety.
- **Higher-level services**: Built on top of lower-level cloud services (e.g., Snowflake builds on S3; other services build on Snowflake).
- **SaaS**: Fully managed application accessed via API/UI.

Higher-level abstractions are more use-case-specific. They reduce hassle when your needs match; building from lower-level components is necessary only when no high-level service fits.

### Cloud-Native Architecture

**Definition**: An architecture designed from the ground up to take advantage of cloud services rather than just lifted-and-shifted onto VMs.

Advantages over self-hosted equivalents running on IaaS:
- Better performance on the same hardware
- Faster recovery from failures
- Quick scaling of compute to match load
- Support for larger datasets

Examples:
- **OLTP cloud-native**: AWS Aurora, Azure SQL DB Hyperscale, Google Cloud Spanner
- **OLAP cloud-native**: Snowflake, Google BigQuery, Azure Synapse Analytics

### Separation of Storage and Compute

**Definition**: Disaggregating durable storage from the machines doing computation, instead of co-locating them on the same server.

Traditional model: same machine owns disk + CPU + RAM; RAID provides disk redundancy.

Cloud-native model:
- Local instance disks are treated as ephemeral cache, not durable storage (lost when instance fails or is resized).
- Durable data lives in a dedicated storage service (object store, virtual disk, or specialized cloud storage).
- Compute reads from / writes to storage over the network.

Block-device emulation (Amazon EBS, Azure managed disks, GCP persistent disks) lets traditional disk-based software run in the cloud, but adds network-call overhead per I/O. Cloud-native systems typically avoid virtual disks and build directly on object storage or workload-optimized storage services.

### Object Storage

**Definition**: A cloud storage service for large files (hundreds of KB to multiple GB) that hides the underlying machines and replicates data automatically.

Examples: Amazon S3, Azure Blob Storage, Cloudflare R2.

Trade-off: Limited APIs (basic file reads/writes) compared to a filesystem, but unlimited capacity from the user's view and durability across machine/disk failures.

### Multitenancy

**Definition**: Multiple customers' data and computation share the same hardware behind one service, instead of each customer getting dedicated machines.

- Enables better hardware utilization, easier scaling, easier provider-side management.
- Requires careful engineering so one tenant cannot affect another's performance or security.

### Operations in the Cloud Era

The DBA/sysadmin role has evolved. DevOps and SRE (Google's implementation) integrate development and operations.

DevOps/SRE emphasis:
- Automation over manual one-off jobs
- Ephemeral VMs and services rather than long-running servers (often called "cattle not pets" — though the book uses the concept without the slogan)
- Frequent application updates
- Learning from incidents
- Preserving institutional knowledge as people come and go

Customer-side cloud operations focus on: choosing services, integrating them, migrating between them, controlling cost. Capacity planning becomes financial planning; performance optimization becomes cost optimization.

## Terminology

| Term | Definition |
|------|------------|
| On premises | Software running on hardware you control (incl. rented racks) |
| IaaS | VMs with raw CPU/RAM/disk/network you administer yourself |
| Self-host | Deploying off-the-shelf software you operate |
| Cloud-native | Designed from scratch to use cloud services as building blocks |
| Disaggregation | Separating storage from compute across different services |
| Object storage | Service for large-file durable storage (S3, Blob, R2) |
| Block device | Emulated disk service exposing 4 KiB blocks over network |
| Multitenant | Many customers share the same physical hardware behind a service |
| Metered billing | Pay for resources used; no upfront capacity planning |
| Quota | Cloud-imposed resource limit (e.g., max concurrent processes) |

## How It Relates To

- **Reliability**: Cloud providers offer high availability across machine failures via managed services and replication.
- **Scalability**: Cloud's ability to scale compute up/down on demand directly addresses variable workloads.
- **OLAP / OLTP split**: Cloud-native systems exist for both categories with different storage strategies.

## Common Misconceptions

- **Myth**: Cloud is always cheaper than self-hosting.
  **Reality**: With predictable load and existing operational expertise, owning hardware is often cheaper.

- **Myth**: Cloud removes the need for an operations team.
  **Reality**: Operations is still required; the focus shifts to service selection, integration, cost control, and security.

- **Myth**: Lifting-and-shifting onto IaaS gives you cloud-native benefits.
  **Reality**: Cloud-native advantages come from architecture redesign (e.g., disaggregated storage), not just running on VMs.

- **Myth**: Local instance disks are durable.
  **Reality**: They are ephemeral cache; they vanish when the instance fails or is resized.

## Quick Reference

| Concept | One-Line Summary |
|---------|-----------------|
| Deployment spectrum | In-house bespoke → self-hosted → managed → SaaS |
| Cloud-native | Designed for cloud, not just running in cloud |
| Storage/compute split | Durable data lives in a separate service from compute |
| Multitenancy | Shared hardware across customers, isolated by software |
| DevOps/SRE | Combined dev+ops with automation and ephemeral infra |
