# ADR-001: Commit quote and notification intent atomically

- Status: Implemented design; live demo decommissioned
- Recorded: November 3, 2026 (retrospective documentation)
- Scope: Implemented design from a verified, subsequently decommissioned single-region AWS demonstration. Bootstrap was retained. HA and multi-region targets are not evidence of deployed resilience.

## Business context

A customer should retain a saved quote even if the messaging system is temporarily unavailable. Saving the quote and sending a queue message separately can leave committed quotes with no notification intent.

## Decision

Commit the quote and outbox event in one Aurora transaction. A leased publisher sends stable event IDs to SQS outside the database transaction; the notifier uses a ledger and partial batch failure reporting.

## Alternatives considered

Write the database then send SQS directly; send email synchronously; CDC; DynamoDB transactions with Streams. These are architectural alternatives, not comparative implementation benchmarks.

## Business benefit

Separates successful quote persistence from notification availability and provides a recoverable record of notification intent.

## Consequences and risks

SQS is at least once. A lost acknowledgement can duplicate messages; SES acceptance and database ledger commit are not atomic, so duplicate emails remain possible. SES acceptance is not proof of delivery. Retention, lease recovery and replay need operating procedures.

## Revisit trigger

A measured backlog or operational burden justifies CDC/managed orchestration, or the business requires delivery guarantees that email plus a database ledger cannot provide.

## Supporting material

[Implementation, operating guidance or evidence](../../evidence/dated-exercises/2026-10-29-live-verification/README.md). This record documents engineering rationale; it does not imply historical stakeholder approval, measured ROI or benchmarking of alternatives.
