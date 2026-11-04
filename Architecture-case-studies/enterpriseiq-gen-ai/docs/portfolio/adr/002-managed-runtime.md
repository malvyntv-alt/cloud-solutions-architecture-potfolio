# ADR-002: Use a managed runtime without a customer VPC

- Status: accepted for the current DEV demonstration
- Recorded: November 3, 2026 (retrospective documentation of implemented decisions)
- Scope: personal project using fictional policies; not approval for enterprise production

## Business context

The demonstrated workload calls managed regional services and has no private database or hybrid connectivity dependency.

## Decision

Use Amplify, API Gateway and Lambda without VPC configuration.

## Alternatives considered

VPC-attached Lambda with NAT or private endpoints; container-based runtime.

## Business benefit

Fewer network components to operate and no NAT or interface-endpoint infrastructure for this DEV workload.

## Consequences and risks

Uses normal regional service endpoints and does not meet a private-only networking requirement. No comparative cost or performance benchmark is claimed.

## Revisit trigger

Private resources, hybrid connectivity or contractual network requirements become part of the workload.

## Supporting material

[Implementation, evidence or evaluation reference](../../../architecture/decisions.md). These records document engineering decisions; they do not imply stakeholder consultation, measured ROI or production governance approval.
