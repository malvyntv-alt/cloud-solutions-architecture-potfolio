# ADR-002: Use an atomic DynamoDB aggregate for approximate views

- Status: Accepted for deployed portfolio
- Recorded: November 3, 2026 (retrospective documentation)
- Scope: Public malvernvito.com portfolio and approximate page-view counter. Records describe the deployed design and source configuration; individual optional controls require their own evidence.

## Business context

The portfolio benefits from a lightweight usage indicator rather than audited analytics or unique visitor measurement.

## Decision

Use a public HTTP API and Lambda to read/increment a single DynamoDB aggregate with on-demand capacity. POST increments; GET reads. Disable automatic increment retries in browser and SDK.

## Alternatives considered

Relational storage; client-only count; third-party analytics; unique-visitor tracking with per-event storage.

## Business benefit

Durable atomic updates fit the simple one-key access pattern with no running application server.

## Consequences and risks

Bots, refreshes and repeated requests inflate counts. A write can succeed even when its response is lost. Disabling retries does not create exactly-once counting. The metric is not suitable for billing or audited analytics.

## Revisit trigger

Unique visitors, attribution, auditability or event analysis becomes a real requirement; define consent and retention before collecting richer data.

## Supporting material

[Implementation, operating guidance or evidence](../overview.md). This record documents engineering rationale; it does not imply historical stakeholder approval, measured ROI or benchmarking of alternatives.
