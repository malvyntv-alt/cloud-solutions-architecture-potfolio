# ADR-003: Keep the portfolio public and minimize application-collected visitor data

- Status: Accepted for deployed portfolio
- Recorded: November 3, 2026 (retrospective documentation)
- Scope: Public malvernvito.com portfolio and approximate page-view counter. Records describe the deployed design and source configuration; individual optional controls require their own evidence.

## Business context

A public professional portfolio should remain accessible without registration, and its counter does not need visitor identities.

## Decision

Do not use Cognito for the portfolio. Store only the home-page key and numeric aggregate in the counter application. Ship the public API endpoint, not AWS credentials, to the browser.

## Alternatives considered

Visitor sign-in; IP-based deduplication; persistent cookies/fingerprints; event-level analytics.

## Business benefit

Avoids sign-in friction and unnecessary identity/history storage for the page-view feature.

## Consequences and risks

The API is intentionally callable outside the website. CORS is not authorization and throttling is best effort. Cloud/provider infrastructure may retain operational metadata; this is not a claim of zero data processing.

## Revisit trigger

Abuse or a legitimate analytics requirement changes the risk/value balance; evaluate privacy and retention before expanding collection.

## Supporting material

[Implementation, operating guidance or evidence](../../security-and-cost.md). This record documents engineering rationale; it does not imply historical stakeholder approval, measured ROI or benchmarking of alternatives.
