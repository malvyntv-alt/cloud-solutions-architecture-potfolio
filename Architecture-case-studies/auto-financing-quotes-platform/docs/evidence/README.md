# Evidence

This edition was deployed once as a demo and torn down: [2026-10-29 exercise](dated-exercises/2026-10-29-demo-deployment.md). [Historical source record](source-project-verification.md) is original-author context. [Local validation](local-validation.md) records checks executed here.

## Dated exercise format

Use dated-exercises/YYYY-MM-DD-topic.md with commit/tag, region/profile/capacity, objective/prerequisites, failure trigger, timestamps, observed quote/outbox/queue/ledger behavior, sanitized screenshots/workflow links, measured result versus proposed target and limitations.

## AWS exercises remaining

Cognito save/read and SES email; real queue failure/recovery; DLQ/redrive/alarms; backup restore; AZ/regional recovery; load/latency/cost.

Never publish tokens, credentials, state, plans, raw CLI dumps or customer data. Redact personal identifiers. raw/ is ignored; inspect all staged artifacts.

## Portfolio import

The exercise above predates this portfolio import. The new monorepository layout has not been deployed. See [portfolio validation](../../../../docs/portfolio-validation.md) for local checks of the imported layout.
