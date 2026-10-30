# Local validation

Date: 2026-10-29 (America/Chicago).

| Check | Outcome |
|---|---|
| Backend contracts | 9 unittest tests passed; in-memory DynamoDB double |
| Frontend counter | 5 Node tests passed; success, missing configuration, invalid origin/value, HTTP/network failure and no retry |
| Terraform formatting and validation | Passed with AWS provider 6.70.0 |
| Mocked Terraform plans | 4 passed: default domain off, association-only, explicit DNS ownership, invalid connection prerequisite |
| Lambda package | Built locally with deterministic metadata |
| Website build | Static output generated; counter intentionally disabled without API URL |
| Portfolio links and public boundaries | Passed before commit |
| Local browser | Existing portfolio rendered; Page views: Unavailable fallback verified without a configured API |

No Terraform apply, AWS app creation, GitHub App authorization, domain association, DNS cutover or live DynamoDB/API test was performed. Existing greeting.meldit.net hosting was not changed.

The fake-table concurrency test checks handler request behavior; it does not benchmark or prove real DynamoDB concurrency. The browser tests use a mocked fetch. AWS integration, TLS, actual hosting builds, throttling, alarms and deployment rollback remain to verify.

[Local browser preview](local-preview.png) shows the no-API fallback. It is not an AWS deployment screenshot.
