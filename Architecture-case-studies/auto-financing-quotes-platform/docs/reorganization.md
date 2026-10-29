# Independent project

Copied tracked files only. Excluded original Git metadata/history/remotes, credentials, private tfvars/backend, state/backups, plans, caches, local database and raw evidence. Original source content is unchanged. No AWS deployment or adoption occurred.

| Source | New |
|---|---|
| app/web/migrations/tests, pytest.ini, requirements | Same content/paths |
| Dockerfiles | containers/Dockerfile.web and Dockerfile.notifier |
| infra root | infra/stacks/regional/ |
| runtime.tf | registry, IAM, compute, messaging, notifications, observability |
| operations.tf | audit, observability, budget |
| bootstrap | Same root; new default project and exact OIDC subject option |
| Backend example duplicate | Consolidated backend.tf |
| tfvars/backend examples | Regional config/ with neutral placeholders |
| Scripts | scripts/local/ and scripts/deploy/ |
| Documents | docs topic directories |
| Verification | Explicit historical source record |
| Images | Architecture diagrams and demo/images/ |

No child modules were introduced. AWS default naming intentionally changes to drivequote-portfolio. Destructive retention settings are preserved and accurately documented. Dependency snapshot stays informational; no license was invented.
