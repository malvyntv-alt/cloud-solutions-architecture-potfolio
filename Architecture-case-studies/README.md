# Architecture Case Studies

[Portfolio home](../README.md)

Projects below contain implementation and supporting architecture documentation. Read each project's evidence and limitations before treating a capability as deployed or measured.

| Project | What to explore |
|---|---|
| [Auto-Financing Quotes Platform](auto-financing-quotes-platform/README.md) | Reliable quote persistence, asynchronous notifications, Terraform, authentication and operational tradeoffs |
| [Amplify Portfolio Hosting](amplify-portfolio-hosting/README.md) | Public hosting, anonymous page views, six Terraform modules; locally tested, not deployed |

## Add another project

Create a sibling directory with a clear lowercase-hyphenated name. Include a README covering the problem, your ownership, architecture, decisions, implementation, validation and remaining work.

Example structure:

```text
your-project/
├── README.md
├── docs/
│   ├── architecture/
│   └── evidence/
├── infra/
└── tests/
```

Include only folders that the implementation actually needs. Register the project in both indexes and add root CI checks. Do not copy nested Git metadata or invent deployment evidence.
