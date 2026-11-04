# Architecture decision records

These retrospective records explain the implemented DEV decisions in business terms: context, alternatives, benefit, risks and reconsideration triggers. Recorded November 3, 2026; they do not imply a historical approval process.

| Record | Decision | Status |
|---|---|---|
| [ADR-001](001-rag.md) | Use retrieval-augmented generation for policy questions | Accepted for DEV |
| [ADR-002](002-managed-runtime.md) | Use a managed runtime without a customer VPC | Accepted for DEV |
| [ADR-003](003-authentication-boundary.md) | Use Cognito access tokens to protect a shared synthetic corpus | Accepted for DEV |
| [ADR-004](004-stateless-api.md) | Keep the API stateless and defer persistent history | Accepted for DEV |
| [ADR-005](005-retrieval-model-baseline.md) | Use S3 Vectors and Nova Lite as the DEV baseline | Accepted for DEV |
| [ADR-006](006-dev-waf-cost.md) | Disable app-specific WAF for the low-volume DEV demonstration | Accepted for DEV |

The [architecture diagram](../diagrams/README.md) shows the design. The [executive brief](../executive-brief.md) describes business value and pilot gates. Each decision record explains its context, alternatives and consequences.
