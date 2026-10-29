# Portfolio walkthrough

## 60-second opening

“I built an estimated auto-financing quote application to demonstrate fault isolation. Saving a quote commits its state and notification event in one database transaction. A separate publisher sends the event to SQS; Lambda calls SES. If messaging fails, quote saving still succeeds. The publisher retries, and consumers track event IDs. My Terraform default is a smaller single-region deployment; the HA expansion adds redundancy. Regional recovery is a documented implementation stage, not a measured result yet.”

## Demo 1 — normal operation

Calculate a quote, save, open Saved quotes, Event pipeline, and Notification inbox. Explain inputs, integer cents, pricing version, expiry and commit-before-email. “ACCEPTED” means the email provider accepted the request, not that the customer read or received it.

## Demo 2 — SQS outage

Enable SQS unavailable in the LOCAL failure lab. Create another quote. Show saved quote exists and outbox pending. Publication attempts increase and carry a simulated error category. Disable the fault and show recovery.

Discuss: exponential backoff, database capacity for backlog, oldest-event alarm, and why a DLQ cannot help a message that never reached SQS.

## Demo 3 — lost acknowledgment

Enable Publish acknowledgment lost. Save another quote. The simulator enqueues the message but reports failure to the publisher. The publisher retries the SAME event ID. Local inbox dedupes. State clearly that real SES can still send twice if it accepts a send just before a worker crashes.

## Demo 4 — email failure

Enable Email unavailable. Save a quote. Publication can succeed while notification processing remains pending. Restore email and observe recovery. The local adapter does not emulate real queue visibility or DLQ movement; demonstrate those in AWS after deployment.

## Questions to prepare

- Why the outbox? Atomicity between quote state and intent to notify; not atomicity between database and SQS.
- Why leases? Multiple publishers need exclusive, time-limited claims without holding locks during network I/O.
- Why SQS Standard? Email notifications do not require strict global ordering; idempotency is needed anyway.
- Why Aurora? Relational ownership/quote records and transactions. A DynamoDB design is possible with different modeling and streams.
- Why Cognito? Managed identity for a public portfolio; existing dealer OIDC federation can be added.
- What does CloudTrail capture? AWS API activity; CloudWatch tracks app operation; neither automatically supplies a complete business audit.
- What is the RPO? A proposed saved-quote regional target of five minutes, not a result from these local tests.
- What is your scale? Report actual load-test records/bytes/RPS. Do not claim an invented production scale.

## Evidence to collect after deploying

Date/time, Git commit/image tag, Terraform profile, region, database class, task counts, quote count and data size, average/peak RPS, p95/p99, error rate, outbox age, queue age, recovery start/end, last committed quote and recovered quote.

Publish screenshots and measured results in your own README. Never publish credentials, tokens, real customer data or raw Terraform state.

## Interview scope statement

“I built and tested X” refers only to measured work. “The target architecture would add Y” describes the planned multi-region stage. Keep that distinction explicit.

