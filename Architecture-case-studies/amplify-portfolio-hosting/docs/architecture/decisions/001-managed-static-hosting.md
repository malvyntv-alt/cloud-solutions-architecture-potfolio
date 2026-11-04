# ADR-001: Use Amplify for the public portfolio

- Status: Accepted for deployed portfolio
- Recorded: November 3, 2026 (retrospective documentation)
- Scope: Public malvernvito.com portfolio and approximate page-view counter. Records describe the deployed design and source configuration; individual optional controls require their own evidence.

## Business context

The portfolio needs a public HTTPS website, custom domain and repeatable releases without maintaining a web server.

## Decision

Use Amplify Hosting for the existing static website; authorize the GitHub App and import the hosting app/branch into Terraform. Keep the counter backend separately owned by Terraform modules.

## Alternatives considered

Continue the legacy S3/CloudFront site; run a container/server; add a full application backend or Amplify Gen 2 backend.

## Business benefit

Managed static delivery and domain workflow with a source-based release path. Reuses the existing site rather than creating an unnecessary application framework.

## Consequences and risks

Repository connection, monorepo build paths and embedded frontend configuration still need ownership. Hosting, builds and transfer can incur charges; no comparative cost benchmark is claimed.

## Revisit trigger

The site needs server-rendered behavior, platform capabilities unavailable here or a measured cost/operational reason to change hosting.

## Supporting material

[Implementation, operating guidance or evidence](../../evidence/2026-10-30-live-deployment/README.md). This record documents engineering rationale; it does not imply historical stakeholder approval, measured ROI or benchmarking of alternatives.
