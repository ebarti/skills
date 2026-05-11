# Reliability Examples

Concrete failure scenarios and fault-tolerant designs from real systems.

## Hardware Fault Scenarios

### Magnetic hard drive failures

- **Failure rate**: Approximately 2-5% of drives fail per year.
- **At scale**: A storage cluster with 10,000 disks should expect roughly one disk failure *per day* on average.
- **Implication**: At large scale, hardware faults are part of normal operation, not exceptional events.

### SSD failures

- **Failure rate**: Approximately 0.5-1% of SSDs fail per year.
- **Bit errors**: Small numbers corrected automatically; uncorrectable errors occur ~once per year per drive even on new drives.
- **Surprise**: This uncorrectable-error rate is *higher* than magnetic hard drives.

### Faulty CPU cores

- Approximately 1 in 1,000 machines has a CPU core that occasionally computes the wrong result.
- Likely caused by manufacturing defects.
- Symptom can be a crash *or* silently returning the wrong result — much harder to detect.

### RAM corruption

- Random events (cosmic rays) and permanent physical defects both corrupt RAM.
- Even with ECC memory, more than 1% of machines hit an uncorrectable error per year — typically crashes the machine, requires module replacement.
- *Rowhammer*: certain pathological memory access patterns can flip bits with high probability — a real attack vector.

### Datacenter-level events

- Power outage or network misconfiguration → entire datacenter unavailable.
- Fire, flood, earthquake → datacenter permanently destroyed.
- Solar storm → induces large currents in long-distance wires; could damage power grids and undersea network cables.
- Rare, but catastrophic if the service can't tolerate losing a DC.

## Hardware Fault-Tolerant Designs

### RAID

Spreads data across multiple disks in the same machine so a failed disk doesn't cause data loss.

- First-line response to disk unreliability.
- Tolerates a defined number of disk failures (varies by RAID level).
- Doesn't help if the whole machine, rack, or DC goes down.

### Server-level redundancy

- Dual power supplies — survives one PSU failure.
- Hot-swappable CPUs — replace without rebooting.
- ECC memory — detects and corrects most RAM bit flips.
- Combined: keeps a single machine running uninterrupted for years.

### Datacenter-level redundancy

- Backup batteries (UPS) for short power gaps.
- Diesel generators for extended outages.
- Still doesn't survive datacenter destruction.

### Multi-AZ / multi-region replication

- Tolerates loss of an entire machine, rack, or availability zone.
- Cloud providers expose *availability zones* to identify physically co-located resources.
- Resources in the same place are more likely to fail at the same time.
- Allows a machine in one DC to take over when one in another DC becomes unreachable.

### Rolling upgrade

A multi-node fault-tolerant system can be patched by restarting one node at a time without affecting users.

- Single-server systems require planned downtime for OS security patches.
- Rolling upgrade depends on the system tolerating one-node loss in the first place.

## Software Fault Scenarios

### Leap-second Linux kernel bug (June 30, 2012)

- A leap second triggered a bug in the Linux kernel.
- Caused many Java applications to hang *simultaneously*.
- Brought down several internet services at once.
- Illustrates *correlated* software failure: same code, same trigger, every node hit at once.

### SSD firmware bug — 32,768 hour failure

- A firmware bug caused certain SSD models to suddenly fail after *exactly* 32,768 hours of operation (just under 4 years).
- Data on the affected drives was unrecoverable.
- All drives of that model purchased together would fail together — defeats most redundancy schemes.

### Runaway processes

- Process consumes too much memory while handling a large request — killed by the OS.
- Bug in a client library causes a much higher request volume than anticipated.
- Exhausts shared resources: CPU, memory, disk space, network bandwidth, threads.

### Slow / unresponsive dependencies

- A service the system depends on slows down, becomes unresponsive, or returns corrupted responses.
- Without timeouts and circuit breakers, the slowness propagates.

### Cascading failures

- Problem in one component overloads another, which slows down a third.
- Each failure compounds the next until the whole system is down.
- Often amplified by retry storms.

### Emergent behavior

- Interactions between systems produce behavior that doesn't appear when each is tested in isolation.
- The bug was always there — dormant until triggered by an unusual environment.

## Human-Error Scenarios

### Configuration changes dominate outages

- Study of large internet services: operator configuration changes were the *leading* cause of outages.
- Hardware faults played a role in only 10-25% of cases.
- The vast majority of downtime is human + software, not hardware.

## Human-Error-Tolerant Designs

### Well-designed interfaces

APIs and tooling that encourage "the right thing" and discourage "the wrong thing."

- Confirmation prompts for dangerous operations.
- Dry-run modes.
- Command names that match intent (no easy footguns).

### Sandbox / staging environments

Where operators can experiment and rehearse without affecting real users.

### Quick rollback for configuration changes

- Configuration changes should be revertible in seconds, not hours.
- Treat config like code — version it, deploy it gradually, rollback fast.

### Gradual rollouts of new code

- Canary deploys.
- Percentage-based rollouts.
- Catch bad changes before they hit everyone.

### Property testing alongside handwritten tests

Test on lots of random inputs, not just hand-picked cases — catches edge cases humans miss.

### Detailed monitoring and observability

- Spot regressions during rollout.
- Diagnose production issues quickly when they happen.

### Blameless postmortem culture

- People share full details about what happened without fear of punishment.
- Others in the organization learn how to prevent similar issues.
- Surfaces the need to change priorities, incentives, or invest in neglected areas.

## Real-World Cost of Unreliability

### The Post Office Horizon scandal (UK, 1999-2019)

- Hundreds of Post Office branch managers in Britain were *convicted of theft or fraud* because the accounting software showed shortfalls in their accounts.
- Many shortfalls were actually software bugs.
- Probably the largest miscarriage of justice in British history.
- Compounded by an English-law assumption that computer evidence is reliable unless proven otherwise.
- People were imprisoned, declared bankruptcy, and committed suicide as a result.
- Software engineers may laugh at "bug-free software," but unreliable systems cause real human harm.

### Photo storage corruption

- A parent stores all pictures and videos of their children in a photo app.
- Database is suddenly corrupted.
- Would they even know how to restore from backup?
- Permanent data loss is catastrophic even when the system is "non-critical."

## Chaos Engineering Example

Randomly killing individual processes without warning — *increasing* the rate of faults deliberately.

- Many critical bugs are due to poor error handling.
- By inducing faults, the fault-tolerance machinery is continually exercised and tested.
- Increases confidence that natural faults will be handled correctly.
- Chaos engineering is the formal discipline built around this idea.
