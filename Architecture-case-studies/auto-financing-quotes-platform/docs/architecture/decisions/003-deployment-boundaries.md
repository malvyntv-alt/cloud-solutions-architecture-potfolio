# ADR-003: Separate bootstrap ownership from regional workload state

- Status: Implemented design; live demo decommissioned
- Recorded: November 3, 2026 (retrospective documentation)
- Scope: Implemented design from a verified, subsequently decommissioned single-region AWS demonstration. Bootstrap was retained. HA and multi-region targets are not evidence of deployed resilience.

## Business context

State storage and CI identity can outlive a short-lived application demonstration. Shared ownership can cause accidental deletion or conflicting changes.

## Decision

Keep bootstrap ownership separate from regional workload Terraform. Demo and HA remain profiles of one regional state; retain bootstrap after regional teardown.

## Alternatives considered

One state for bootstrap and workload; separate independent stacks for each profile; immediate module extraction before a second region exists.

## Business benefit

Supports application cleanup without intentionally deleting the state/identity foundation, and makes resource ownership explicit.

## Consequences and risks

Backend keys and folder names are not account isolation. Shared account-wide OIDC ownership must be explicit. Future module extraction requires resource-address/state migration planning.

## Revisit trigger

A second region or account is implemented, or team ownership requires a stronger state and IAM boundary.

## Supporting material

[Implementation, operating guidance or evidence](../../deployment/aws.md). This record documents engineering rationale; it does not imply historical stakeholder approval, measured ROI or benchmarking of alternatives.
