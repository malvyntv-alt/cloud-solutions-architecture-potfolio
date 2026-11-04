# ADR-004: Authenticate at the ALB and restrict quote ownership in the application

- Status: Implemented design; live demo decommissioned
- Recorded: November 3, 2026 (retrospective documentation)
- Scope: Implemented design from a verified, subsequently decommissioned single-region AWS demonstration. Bootstrap was retained. HA and multi-region targets are not evidence of deployed resilience.

## Business context

Saved quotes must be available only to their owner, while the web runtime and database should not be directly public.

## Decision

Use Cognito login through the HTTPS ALB, verify the signed ALB identity in the web application, enforce owner-scoped access and idempotency, and place compute/database behind security-group boundaries in private subnets.

## Alternatives considered

Application-managed passwords; public compute/database endpoints; trusting identity headers without validating their provenance.

## Business benefit

Uses managed authentication and explicit resource ownership checks while limiting direct network access to backend services.

## Consequences and risks

Authentication does not replace per-record authorization. Runtime shares a non-admin database credential rather than individual per-user database identities. Only the S3 gateway endpoint is provisioned; other service access uses NAT.

## Revisit trigger

Federation, finer-grained privileges, compliance controls or additional service connectivity become requirements.

## Supporting material

[Implementation, operating guidance or evidence](../../security/security.md). This record documents engineering rationale; it does not imply historical stakeholder approval, measured ROI or benchmarking of alternatives.
