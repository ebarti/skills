# Cloud vs Self-Hosted Rules

Decision guidance for choosing between cloud services and self-hosting, plus rules for designing cloud-native systems.

## Core Decision Rules

### 1. Build vs. Buy by Strategic Value

Do in-house what is a core competency or competitive advantage; outsource what is routine or commonplace.

- Most companies don't fabricate their own CPUs because semiconductor vendors do it cheaper.
- Apply the same logic to data infrastructure: differentiating workloads stay in-house; commodity workloads go to vendors.

### 2. Self-Host When Load is Predictable and You Have Skills

Owning hardware tends to be cheaper when:

- You already have operational expertise for the system.
- Load doesn't fluctuate wildly (machine count is stable).
- You need to tune the system to your specific workload.

A cloud vendor is unlikely to make per-customer customizations.

### 3. Use Cloud When Load is Variable

Cloud services shine when:

- Peak load is much higher than average load (otherwise idle machines waste money).
- Workloads are bursty or unpredictable (e.g., interactive analytical queries).
- Datasets are large enough that idle compute is expensive.

For small datasets or steady load, the cost difference shrinks.

### 4. Use Cloud When You Don't Already Operate the System

Adopting a managed service is often easier and quicker than learning to deploy and operate a new system. Hiring and training specialist staff is expensive.

### 5. Self-Host for Specialist Requirements

Stay on-prem (or use dedicated hardware) when you have requirements no cloud service can meet:

- Very latency-sensitive workloads (e.g., high-frequency trading) needing full hardware control.
- Hardware-specific dependencies (specialized GPUs, RDMA NICs, custom interconnects).
- Strict regulatory, sovereignty, or trust constraints the provider can't satisfy.

### 6. Treat Vendor Lock-In as a First-Class Risk

Cloud services often lack standard APIs, which raises switching cost.

- Prefer services with compatible alternative APIs when feasible.
- Plan for vendor changes: shutdowns, price hikes, feature regressions.
- Continuing to run an old version is usually impossible — migration is forced.

### 7. Consider Geopolitical and Sovereignty Risk

If the provider is in another country, sanctions or political conflict can lock you out of the service. Factor this into provider selection for sensitive workloads.

### 8. Evaluate Data-Trust Implications

The provider must be trusted to keep data secure. This complicates compliance with privacy and security regulations and may rule out cloud for certain data classes.

## Rules for Designing Cloud-Native Systems

### 9. Separate Storage from Compute

In cloud-native designs, durable data lives in a dedicated storage service (object store or specialized service), not on instance-local disks.

- Treat local instance disks as ephemeral cache only.
- Read/write durable state through the storage service.
- Accept the network-transfer cost as a deliberate trade-off for elasticity and durability.

### 10. Avoid Virtual Block Devices for Cloud-Native Data Systems

EBS / managed disks / persistent disks emulate physical disks over the network. Each I/O is a network call. They are useful for lifting traditional software into the cloud but introduce overheads cloud-native systems should design around.

### 11. Choose Storage Granularity Per Workload

Object storage is for large files (hundreds of KB to GB).

- Don't store individual database rows or values directly in S3.
- Cloud databases manage small values in a separate service and pack many values into larger blocks stored in object storage.

### 12. Plan for Multitenancy When Building Shared Services

If you operate a multitenant service, engineer for isolation:

- Per-tenant resource quotas and rate limits.
- Performance isolation so one tenant can't degrade others.
- Security isolation so tenants can't access each other's data.

### 13. Pick the Right Abstraction Level

- Higher-level services are more use-case-specific; if your needs match, use them.
- Drop down to lower-level building blocks only when no higher-level service fits.

## Operations Rules

### 14. Operations is Still Required in the Cloud

Cloud doesn't eliminate ops; it changes the focus. Customer-side ops covers:

- Service selection and integration
- Migration between services
- Cost optimization (formerly capacity planning)
- Security of the application and its libraries
- Monitoring load and diagnosing degradation

### 15. Apply DevOps/SRE Practices to Cloud Systems

- Automate; prefer repeatable processes over one-off jobs.
- Use ephemeral VMs and services rather than long-running servers.
- Enable frequent application updates.
- Learn from incidents (post-mortems).
- Preserve institutional knowledge across staff turnover.

### 16. Plan for Quotas

Cloud services impose limits (max concurrent processes, request rates, etc.). Discover and plan for them before you hit them in production.

### 17. Capacity Planning Becomes Cost Planning

Metered billing removes the need to provision in advance, but knowing what resources you use and why is still essential to avoid waste.

## Exceptions

- **Hybrid is acceptable**: Many organizations use cloud for some aspects and self-host others.
- **Predates the cloud**: Older systems may stay on-prem indefinitely; cloud will not subsume all in-house data systems.
- **Lift-and-shift first**: Running self-hosted software on IaaS can be a transitional step before adopting a cloud-native equivalent.

## Quick Reference

| Situation | Recommendation |
|-----------|----------------|
| Predictable load, in-house expertise | Self-host |
| Variable / bursty load, large datasets | Cloud |
| New system you don't know how to operate | Managed cloud service |
| Latency-critical, custom hardware | Self-host |
| Strict data sovereignty / regulation | Self-host or sovereign cloud |
| Designing a new data system for cloud | Separate storage from compute |
| Storing rows/small values | Use a database, not raw object storage |
| Building shared multitenant service | Engineer isolation up front |
