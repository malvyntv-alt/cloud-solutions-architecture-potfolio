# ADR-004: Keep the API stateless and defer persistent history

- Status: accepted for the current DEV demonstration
- Recorded: November 3, 2026 (retrospective documentation of implemented decisions)
- Scope: personal project using fictional policies; not approval for enterprise production

## Business context

The initial objective is policy question answering with a small bounded demonstration.

## Decision

Create a separate conversation for each API request; show conversation messages in browser memory without using earlier messages as backend context.

## Alternatives considered

User-scoped DynamoDB history and follow-up context from the first release.

## Business benefit

Reduces storage, retention and cross-user conversation handling work in the initial scope.

## Consequences and risks

No conversation continuity on reload or contextual follow-up questions. Browser tokens use session storage and are separate from visible conversation state.

## Revisit trigger

Follow-up context or history becomes a validated requirement; define retention and user-scoped access first.

## Supporting material

[Implementation, evidence or evaluation reference](../../../backend/lambda_handler.py). These records document engineering decisions; they do not imply stakeholder consultation, measured ROI or production governance approval.
