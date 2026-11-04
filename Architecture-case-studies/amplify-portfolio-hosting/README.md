# Amplify Portfolio Hosting and Serverless Page Views

Public portfolio for malvernvito.com, with an approximate page-view counter. The existing page is reused; visitors do not sign in.

**Status: deployed on 2026-10-30. Live at [malvernvito.com](https://malvernvito.com/), with HTTPS, a www redirect and a working page-view counter.**

[Live deployment evidence](docs/evidence/2026-10-30-live-deployment/README.md). The legacy greeting.meldit.net hosting remains available.

[Portfolio home](../../README.md) · [Architecture](docs/architecture/overview.md) · [Deployment](docs/deployment.md) · [Security and cost](docs/security-and-cost.md) · [Validation](docs/evidence/validation.md)


## Business case and architecture decisions

The use case is a public professional portfolio with managed HTTPS hosting and an approximate page-view indicator. Visitors do not need an account; the site remains usable when the counter is unavailable. Page views are not unique visitors or an audited business metric.

[Architecture decision records](docs/architecture/decisions/README.md) explain why the design was selected, the alternatives, intended business benefit, risks and conditions for reconsidering it.

| Decision | Rationale and trade-off |
|---|---|
| [ADR-001: Use Amplify for the public portfolio](docs/architecture/decisions/001-managed-static-hosting.md) | Managed static delivery and domain workflow with a source-based release path. Reuses the existing site rather than creating an unnecessary application framework. Repository connection, monorepo build paths and embedded frontend configuration still need ownership. |
| [ADR-002: Use an atomic DynamoDB aggregate for approximate views](docs/architecture/decisions/002-approximate-page-views.md) | Durable atomic updates fit the simple one-key access pattern with no running application server. Bots, refreshes and repeated requests inflate counts. |
| [ADR-003: Keep the portfolio public and minimize application-collected visitor data](docs/architecture/decisions/003-anonymous-access-and-data-minimization.md) | Avoids sign-in friction and unnecessary identity/history storage for the page-view feature. The API is intentionally callable outside the website. |
| [ADR-004: Keep the counter runtime outside a customer VPC](docs/architecture/decisions/004-vpc-free-counter-and-scoped-iam.md) | Avoids NAT/interface endpoint infrastructure and Lambda ENI lifecycle work for a small serverless counter. Uses managed regional endpoints and does not satisfy private-only networking requirements. |
| [ADR-005: Stage the custom domain and assign one owner per resource](docs/architecture/decisions/005-domain-and-resource-ownership.md) | Makes rollout and rollback easier to reason about and limits conflicting ownership. Hosting prevent_destroy and table deletion protection reduce accidental deletion. Certificate validation, DNS delegation and existing mail/verification records need independent review. |
| [ADR-006: Separate website releases from infrastructure changes and degrade gracefully](docs/architecture/decisions/006-controlled-releases-and-counter-fallback.md) | Allows content review before release and preserves the primary portfolio experience during a counter problem. Manual releases can lag source and can ship blank/stale endpoint configuration without checks. |

## Architecture

```mermaid
flowchart LR
  GitHub --> Amplify[Amplify Hosting]
  Visitor --> Amplify
  Amplify --> API[API Gateway HTTP API]
  API --> Lambda[Counter Lambda]
  Lambda --> DB[(DynamoDB)]
  Role[IAM execution role] -. permissions .-> Lambda
```

The browser records a view using POST /views and receives the aggregate count. GET /views reads it without incrementing. No identity, IP address, cookie, fingerprint or event history is persisted by the application. Infrastructure services may keep operational metadata.

The number is approximate: refreshes, bots and repeated requests can increase it. CORS and throttling are not authentication or bot-proof analytics. The portfolio remains usable if the counter is unavailable.

## Layout

| Path | Responsibility |
|---|---|
| website/ | Existing HTML and independent counter script |
| backend/counter/ | Python Lambda handler |
| terraform/modules/hosting/ | Imported Amplify app/branch and builds |
| terraform/modules/domain/ | Optional custom-domain association and explicit DNS ownership |
| terraform/modules/database/ | On-demand counter table |
| terraform/modules/iam/ | Scoped Lambda permissions |
| terraform/modules/api/ | Public HTTP API, Lambda and log groups |
| terraform/modules/monitoring/ | Alarms, dashboard and optional notifications |
| terraform/environments/production/ | Module wiring and separate state |
| tests/ | Backend contract tests and frontend fallback tests |

## Local checks

From this project folder, with Python 3.12+, Node.js and Terraform:

```powershell
python -m unittest discover -s tests -p "test_*.py"
node --test tests/counter.test.mjs
node scripts/build-website.mjs
python scripts/package-lambda.py
terraform fmt -check -recursive terraform
terraform -chdir=terraform/environments/production init -backend=false
terraform -chdir=terraform/environments/production validate
terraform -chdir=terraform/environments/production test
```

The tests use an in-memory table double, not DynamoDB. Terraform tests mock AWS. These checks are not deployment evidence.

To build with a real deployed API, set COUNTER_API_URL to its HTTPS origin, then rerun the website build. The public API URL is configuration, not a secret. Without it, the counter displays Unavailable and the rest of the page works.

## AWS Services — Chosen and Why

| Service | Why Chosen | Alternative Considered | Tradeoff |
|---|---|---|---|
| Amplify Hosting | Static portfolio delivery and Git-based releases | Existing S3/CloudFront site | Managed build/domain workflow; GitHub connection and build settings still require care |
| API Gateway HTTP API | Small public read/increment endpoints | Lambda function URL | Explicit routes, CORS and throttling; added service configuration and request charges |
| Lambda | Short counter logic without a running server | Container service | Minimal runtime management; cold starts and execution limits; no VPC dependency |
| DynamoDB | Durable atomic aggregate with on-demand capacity | Relational database | Fits one-key access; deliberately approximate, not exactly-once analytics |
| IAM | Table-scoped backend permissions | Broad managed permissions | More explicit policy work; no credentials or visitor sign-in in the browser |

## Deployment boundaries

No workflow automatically applies Terraform. Auto-build and custom-domain switches default off. The hosting module protects the Amplify app against accidental destruction; table deletion protection defaults on.

GitHub connection is a prerequisite: authorize the Amplify GitHub App, then import its app/branch into Terraform. No GitHub token is accepted in this Terraform configuration. Follow the staged [deployment runbook](docs/deployment.md) before any apply.

The old site, domain registration and hosted zones are not owned by this project. Custom-domain cutover is a separate reviewed step.
