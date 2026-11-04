# ADR-006: Separate website releases from infrastructure changes and degrade gracefully

- Status: Accepted for deployed portfolio
- Recorded: November 3, 2026 (retrospective documentation)
- Scope: Public malvernvito.com portfolio and approximate page-view counter. Records describe the deployed design and source configuration; individual optional controls require their own evidence.

## Business context

Content updates should not require automatic infrastructure changes, and a counter outage should not block access to project information.

## Decision

Use reviewed source releases with a separate Amplify release action while auto-build is disabled. Keep Terraform apply separate. Build with the deployed counter endpoint and let the page show a fallback if counter calls fail.

## Alternatives considered

Auto-release every main push; apply Terraform as part of content publishing; block page rendering until analytics succeeds.

## Business benefit

Allows content review before release and preserves the primary portfolio experience during a counter problem.

## Consequences and risks

Manual releases can lag source and can ship blank/stale endpoint configuration without checks. GitHub checks and Amplify build/release are separate, not a proven protected release gate.

## Revisit trigger

Release frequency justifies automated, gated delivery; ensure branch protection, build configuration and rollback are explicit first.

## Supporting material

[Implementation, operating guidance or evidence](../../deployment.md). This record documents engineering rationale; it does not imply historical stakeholder approval, measured ROI or benchmarking of alternatives.
