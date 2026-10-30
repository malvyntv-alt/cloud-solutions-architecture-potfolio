# Cloud Solutions Architecture Portfolio

AWS architecture projects demonstrating infrastructure as code, application reliability, security boundaries and operational tradeoffs.

## Featured project

| Project | Focus | Evidence |
|---|---|---|
| [Auto-Financing Quotes Platform](Architecture-case-studies/auto-financing-quotes-platform/README.md) | Terraform, ECS Fargate, Aurora PostgreSQL, Cognito, transactional outbox, SQS, Lambda and SES | [Live quote-to-email verification](Architecture-case-studies/auto-financing-quotes-platform/docs/evidence/dated-exercises/2026-10-29-live-verification/README.md) |

The live exercise verified signed-in quote saving, sequential retry behavior and email receipt on the existing standalone AWS deployment, followed by verified regional teardown. Moving code into this portfolio does not create a second stack. Failure/recovery and performance remain unmeasured; the record states those limits.

## Explore

- [Architecture case studies](Architecture-case-studies/README.md): project index and contribution layout.
- [Portfolio structure and validation](docs/portfolio-structure.md): ownership, workflow paths and adding projects.
- [Contributing](CONTRIBUTING.md) and [security](SECURITY.md).

## Repository structure

```text
cloud-solutions-architecture-portfolio/
├── README.md
├── Architecture-case-studies/
│   ├── README.md
│   └── auto-financing-quotes-platform/
│       ├── README.md
│       ├── app/
│       ├── web/
│       ├── infra/
│       ├── containers/
│       ├── migrations/
│       ├── scripts/
│       ├── tests/
│       └── docs/
├── .github/workflows/
├── scripts/
└── docs/
```

Projects are ordinary folders in one Git repository. They do not contain nested .git directories or submodules. Future projects should be siblings of auto-financing-quotes-platform inside Architecture-case-studies/.

## Start the application locally

From this portfolio root, with Python 3.12+:

```powershell
Set-Location Architecture-case-studies/auto-financing-quotes-platform
python -m app.server
```

Open http://127.0.0.1:8080. Local queue, identity and email inbox are simulations. See the project README for tests, deployment and limits.

## Validation and deployment

Run `python scripts/verify-portfolio.py` from the portfolio root for link and public-artifact checks. Application and Terraform commands run from the relevant project folder.

Root workflows validate the imported project. Image publishing is manual and requires this portfolio repository's OIDC trust and GitHub variables. No workflow creates or destroys AWS infrastructure.

This portfolio was assembled locally without copying deployment credentials, state, private tfvars, provider caches or raw logs.
