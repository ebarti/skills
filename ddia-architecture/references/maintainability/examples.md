# Maintainability Examples

Concrete patterns and anti-patterns for maintainability, drawn from the DDIA Maintainability section.

## Bad Examples (Anti-Patterns)

### Big Ball of Mud

A long-lived project where complexity has accumulated without management — modules entangled, hidden assumptions, unclear ownership.

**Problems**:
- Slows down everyone who needs to work on the system
- Increases the risk of introducing bugs when making any change
- Hidden assumptions, unintended consequences, and unexpected interactions are easily overlooked
- Drives schedule and budget overruns

### Legacy System with Lost Institutional Knowledge

A system running for many years on outdated technologies (e.g., mainframes and COBOL), where the engineers who designed it have left the organization.

**Problems**:
- Few engineers today understand the technology
- The reasons behind original design decisions are lost
- Maintenance becomes a people problem, not just a technical one
- Fixing other people's mistakes is necessary but risky

### Over-Automated System Without Manual Override

An ops platform that automates everything but provides no escape hatch for the edge cases automation cannot handle.

**Problems**:
- The cases that resist automation tend to be the most complex
- An automated system that goes wrong is harder to troubleshoot than one with manual steps
- Skilled operators have no way to intervene when automation misbehaves
- More automation paradoxically requires a *more* skilled ops team

### Machine-as-a-Pet Dependency

A system where individual machines cannot be taken down without disrupting the whole service.

**Problems**:
- Routine maintenance forces downtime
- One machine failure cascades to the entire system
- Operators cannot perform OS upgrades, hardware swaps, or rolling restarts safely

### Unpredictable / "Magic" Behavior

A system where the same action can produce different outcomes depending on hidden state, with no clear operational model.

**Problems**:
- Operators cannot reason about the consequences of their actions
- Surprises during incidents make recovery harder
- Documentation cannot match runtime behavior

### Irreversible Migration with No Rollback

Migrating from one database to another with no ability to switch back if the new system has problems.

**Problems**:
- Stakes of the change are dramatically higher
- Any defect in the new system becomes an emergency
- Forces over-cautious, slow rollouts that themselves invite mistakes

## Good Examples (Patterns)

### Data System That Aids Operability

A system that exposes the affordances operations teams need to do their job well.

**Why it works**:
- Allows monitoring tools to check the system's key metrics
- Supports observability tools that give insight into runtime behavior
- Avoids dependency on individual machines (any host can be drained)
- Provides good documentation and an easy-to-understand operational model
- Provides good defaults but lets administrators override them
- Self-heals common failures while preserving manual control
- Exhibits predictable behavior, minimizing surprises

### High-Level Programming Language as Abstraction

A high-level language hides machine code, CPU registers, and system calls behind a clean interface.

**Why it works**:
- The programmer is still using machine code, just not directly
- Hides a great deal of detail behind a simple-to-understand façade
- Reusable across an enormous range of applications
- Quality improvements to the language/runtime benefit every program

### SQL as Abstraction

SQL hides complex on-disk and in-memory data structures, concurrent client requests, and crash-recovery inconsistencies.

**Why it works**:
- One declarative interface serves countless applications
- Implementations can evolve (new storage engines, query optimizers) without breaking consumers
- Improvements to the engine benefit every application using it

### General-Purpose Foundations + Application-Specific Abstractions

Build applications on top of general-purpose abstractions (database transactions, indexes, event logs); layer application-specific abstractions (design patterns, DDD) on top.

**Why it works**:
- Foundations are widely understood, well-tested, reusable
- Application-specific layers express domain concepts cleanly
- The two layers evolve independently

### Reversible Migration Strategy

Run old and new systems in parallel, route traffic gradually, keep the ability to switch back until the new system is proven.

**Why it works**:
- Reduces the stakes of each step
- Defects can be caught and rolled back without crisis
- Encourages bolder, faster evolution overall
- Directly improves flexibility by minimizing irreversibility

## Pattern Comparisons

### Where the Complexity Lives

| Approach | Trade-off |
|----------|-----------|
| Simple interface hiding complex implementation | Easy for callers; complexity is concentrated and managed |
| Simple implementation exposing internal detail | Easy to understand internally; pushes complexity to every caller |

Neither is objectively "simpler" — the right choice depends on how many callers exist and how stable the interface needs to be.

### Operations Maturity Spectrum

| Level | Behavior | Maintainability |
|-------|----------|-----------------|
| Manual everything | Operators required for every routine task | Poor — does not scale |
| Automation + manual override | Common cases automated, edge cases handled by skilled operators | Good — the sweet spot for most systems |
| Full automation, no override | Everything automated, no escape hatch | Risky — automation failures become unrecoverable |
