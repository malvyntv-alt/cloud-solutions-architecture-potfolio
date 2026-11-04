# ADR-004: Keep the counter runtime outside a customer VPC

- Status: Accepted for deployed portfolio
- Recorded: November 3, 2026 (retrospective documentation)
- Scope: Public malvernvito.com portfolio and approximate page-view counter. Records describe the deployed design and source configuration; individual optional controls require their own evidence.

## Business context

The counter accesses DynamoDB and CloudWatch without a private network dependency.

## Decision

Use Lambda without VPC attachment and restrict its IAM permissions to the counter table and relevant logs.

## Alternatives considered

VPC-attached Lambda with NAT/endpoints; a container service; broad managed IAM policies.

## Business benefit

Avoids NAT/interface endpoint infrastructure and Lambda ENI lifecycle work for a small serverless counter.

## Consequences and risks

Uses managed regional endpoints and does not satisfy private-only networking requirements. The deployment principal has separate privileges; runtime IAM is not a complete deployment security boundary.

## Revisit trigger

Private data stores, hybrid connectivity or mandated network controls are introduced.

## Supporting material

[Implementation, operating guidance or evidence](../overview.md). This record documents engineering rationale; it does not imply historical stakeholder approval, measured ROI or benchmarking of alternatives.
