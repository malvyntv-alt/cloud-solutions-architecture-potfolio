# ADR-005: Stage the custom domain and assign one owner per resource

- Status: Accepted for deployed portfolio
- Recorded: November 3, 2026 (retrospective documentation)
- Scope: Public malvernvito.com portfolio and approximate page-view counter. Records describe the deployed design and source configuration; individual optional controls require their own evidence.

## Business context

Domain migration should preserve a working website and avoid conflicting DNS changes or accidental loss of hosting/state.

## Decision

Verify hosting before domain cutover, preserve the legacy site during transition, separate hosting/domain/API/table/IAM/monitoring ownership, and import existing DNS records before Terraform ownership where applicable.

## Alternatives considered

Combine all domain/deployment changes in one step; allow multiple modules to manage the same records; recreate an existing hosting app.

## Business benefit

Makes rollout and rollback easier to reason about and limits conflicting ownership. Hosting prevent_destroy and table deletion protection reduce accidental deletion.

## Consequences and risks

Certificate validation, DNS delegation and existing mail/verification records need independent review. Protection settings require a deliberate procedure for intentional teardown; state structure alone is not isolation.

## Revisit trigger

Domain ownership changes, legacy hosting retirement or multi-site/team ownership requires a revised migration plan.

## Supporting material

[Implementation, operating guidance or evidence](../../deployment.md). This record documents engineering rationale; it does not imply historical stakeholder approval, measured ROI or benchmarking of alternatives.
