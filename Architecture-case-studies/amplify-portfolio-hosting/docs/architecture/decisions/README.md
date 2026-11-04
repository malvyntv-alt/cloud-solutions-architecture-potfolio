# Architecture decision records

Public malvernvito.com portfolio and approximate page-view counter. Records describe the deployed design and source configuration; individual optional controls require their own evidence.

These records explain business context, alternatives, benefits, consequences and revisit triggers. Recorded November 3, 2026; they are retrospective engineering documentation, not a historical approval record. Benefits are design intentions unless linked evidence demonstrates a result.

| Record | Decision |
|---|---|
| [ADR-001](001-managed-static-hosting.md) | Use Amplify for the public portfolio |
| [ADR-002](002-approximate-page-views.md) | Use an atomic DynamoDB aggregate for approximate views |
| [ADR-003](003-anonymous-access-and-data-minimization.md) | Keep the portfolio public and minimize application-collected visitor data |
| [ADR-004](004-vpc-free-counter-and-scoped-iam.md) | Keep the counter runtime outside a customer VPC |
| [ADR-005](005-domain-and-resource-ownership.md) | Stage the custom domain and assign one owner per resource |
| [ADR-006](006-controlled-releases-and-counter-fallback.md) | Separate website releases from infrastructure changes and degrade gracefully |

[Architecture overview](../overview.md) | [Project README](../../../README.md)
