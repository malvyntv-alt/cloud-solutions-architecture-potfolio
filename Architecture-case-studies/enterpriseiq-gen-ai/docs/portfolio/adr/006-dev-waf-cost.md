# ADR-006: Disable app-specific WAF for the low-volume DEV demonstration

- Status: accepted for the current DEV demonstration
- Recorded: November 3, 2026 (retrospective documentation of implemented decisions)
- Scope: personal project using fictional policies; not approval for enterprise production

## Business context

The owner requested lower ongoing demo costs after the app was hosted.

## Decision

Disassociate and delete only the EnterpriseIQ app-specific web ACL; retain Cognito JWT authorization and API throttling.

## Alternatives considered

Keep WAF enabled and fund the additional protection; limit access with other controls as requirements evolve.

## Business benefit

Removes that app-specific WAF resource and its potential ongoing charges.

## Consequences and risks

Removes a request-filtering layer. JWT and throttling are not WAF substitutes. Other account WAF resources are outside this decision.

## Revisit trigger

Traffic, public exposure or security requirements justify WAF; review budgets and monitoring before a real pilot.

## Supporting material

[Implementation, evidence or evaluation reference](../evidence/README.md). These records document engineering decisions; they do not imply stakeholder consultation, measured ROI or production governance approval.
