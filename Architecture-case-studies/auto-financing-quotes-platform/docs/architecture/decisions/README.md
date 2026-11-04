# Architecture decision records

Implemented design from a verified, subsequently decommissioned single-region AWS demonstration. Bootstrap was retained. HA and multi-region targets are not evidence of deployed resilience.

These records explain business context, alternatives, benefits, consequences and revisit triggers. Recorded November 3, 2026; they are retrospective engineering documentation, not a historical approval record. Benefits are design intentions unless linked evidence demonstrates a result.

| Record | Decision |
|---|---|
| [ADR-001](001-transactional-outbox.md) | Commit quote and notification intent atomically |
| [ADR-002](002-managed-services.md) | Use managed relational data and independent compute roles |
| [ADR-003](003-deployment-boundaries.md) | Separate bootstrap ownership from regional workload state |
| [ADR-004](004-authentication-and-private-compute.md) | Authenticate at the ALB and restrict quote ownership in the application |
| [ADR-005](005-demo-ha-and-recovery-scope.md) | Keep demo cost separate from unverified HA and regional recovery targets |

[Architecture overview](../overview.md) | [Project README](../../../README.md)
