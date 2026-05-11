# Maintainability Rules

Design guidance for building data systems that stay operable, simple, and evolvable over their lifetime.

## Core Rules

### 1. Design for Operations, Not Just Functionality

Make routine operational tasks easy so the ops team can focus on high-value work.

- Expose key metrics for monitoring tools
- Support observability tools that explain runtime behavior
- Provide good documentation and an easy-to-understand operational model: "If I do X, Y will happen"
- Provide good defaults, but let administrators override them when needed

### 2. Avoid Single Points of Operational Failure

Routine maintenance must not require taking the system down.

- Avoid dependency on individual machines
- Allow machines to be taken down for maintenance while the system as a whole keeps running
- Treat any "this machine is special" as a smell

### 3. Self-Heal Where Appropriate, but Allow Manual Override

Automation is two-edged; preserve human control for the cases automation cannot handle.

- Self-heal common failure modes (restart, reroute, re-replicate)
- Always give administrators manual control over system state when needed
- Remember: more automation requires a more skilled ops team for the residual edge cases

### 4. Exhibit Predictable Behavior, Minimize Surprises

Operators must be able to reason about the system's response to actions.

- Same input + same state -> same outcome
- Document any non-obvious side effects
- Avoid "magic" behavior that hides what the system is doing

### 5. Solve the Problem in the Simplest Way Possible

Simplicity is the strongest lever on maintainability.

- Use well-understood, consistent patterns and structures
- Avoid unnecessary complexity that does not solve a real problem
- Recognize the "big ball of mud" smell early and refactor before it sets in

### 6. Use Abstraction to Hide Complexity

A good abstraction presents a clean façade that is reusable across many applications.

- Hide implementation detail behind a simple interface
- Prefer abstractions that work for a wide range of applications (more reuse, higher quality)
- Build on top of proven general-purpose abstractions (transactions, indexes, event logs) rather than reinventing
- Application-specific abstractions can be created via methodologies like design patterns and DDD

### 7. Design for Loose Coupling

Loosely coupled systems are easier to evolve than tightly coupled ones.

- Define clear interfaces between components
- Avoid cross-component assumptions about internal state
- Each component should be replaceable without rewriting its neighbors

### 8. Minimize Irreversibility

Irreversible actions raise the stakes of every change and slow down evolution.

- Prefer changes you can roll back
- For migrations (e.g., switching databases), keep the old path available until the new one is proven
- Treat irreversible actions with extra care: review, staging, dry-runs

## Guidelines

Less strict recommendations:

- Pay attention to people problems, not only technical ones — institutional knowledge is part of maintainability
- Document why a design decision was made, not just what it does
- Assume your system will outlive your tenure; the next maintainer has no context you don't write down
- Use Agile-style technical practices (TDD, refactoring) at the application level; aim for evolvability at the system level
- Reasoning about complexity as "essential vs. accidental" is useful but imperfect — the boundary moves as tools evolve

## Exceptions

When these rules may be relaxed:

- **Throwaway prototypes**: Operability and evolvability matter little if the system will be discarded; simplicity still matters for your own sanity.
- **Highly constrained environments**: Embedded or hard-real-time systems may force you to accept tight coupling for performance.
- **Very small systems**: Heavy abstraction layers can themselves become accidental complexity if the system never grows.

## Quick Reference

| Rule | Summary |
|------|---------|
| Design for operations | Monitoring, docs, defaults, overrides |
| No SPOFs in maintenance | Any machine can be taken down |
| Self-heal + manual override | Automate common cases, keep human control |
| Predictable behavior | "If I do X, Y will happen" |
| Simplest possible solution | Avoid the big ball of mud |
| Use abstraction | Clean façade hiding implementation |
| Loose coupling | Components replaceable independently |
| Minimize irreversibility | Prefer reversible changes |
