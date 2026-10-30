# Live AWS quote-to-email verification

Date: 2026-10-29 (America/Chicago). Region: us-east-1. Profile: demo. Image tag: release-001.

## Scope and provenance

The existing standalone deployment was operated through its initialized Terraform root in quote-resilience-lab-portfolio. The portfolio folder is the documentation/code copy; this exercise does not claim that a second independent portfolio stack was deployed.

Source commit: cd3767a178fa66d0e84ba29c829e5a4a9e67ca89. Exact deployed image digests are in the sanitized infrastructure report.

## Observed business path

1. The user signed in through Cognito to the HTTPS application.
2. A synthetic 2026 Toyota RAV4 estimate was calculated: $35,000 price, $5,000 down, 72 months, illustrative 7.49% APR, $518.56 monthly.
3. Save created one owner-visible quote, reference prefix 1359a090, and one QuoteCommitted event, prefix 721034e2.
4. The UI showed one publication attempt, Published and notification ACCEPTED, with zero pending events.
5. Retrying Save without recalculating or changing inputs retained one quote and one event. No new quote/event was visible.
6. The user received the email and supplied its screenshot. Gmail initially classified it as spam; the user marked it not spam and moved it to the inbox.

SES acceptance, provider delivery and recipient receipt are distinct observations. The ledger proves acceptance; recipient receipt is supported by the user's screenshot and confirmation. Account-level SES metrics separately showed one Send and one Delivery during the capture window, but those aggregate counters are not a per-message receipt trace.

## Application evidence

| File | Evidence |
|---|---|
| [Quote studio](01-aws-quote-studio.png) | Signed-in AWS app, initial estimate before the final 72-month calculation |
| [Saved quote](02-aws-quote-saved.png) | Persisted 72-month estimate and short quote reference |
| [Published and accepted](03-aws-event-published-accepted.png) | Completed event/notification ledger |
| [Idempotent retry](04-aws-idempotent-retry-one-event.png) | One quote/event after retry |
| [Email receipt](email-receipt.md) | Sanitized recipient-confirmed email record |

## AWS infrastructure evidence

[Sanitized AWS snapshot](aws-infrastructure.json) records:

- Fargate web and publisher services: desired/running 1/1, completed rollout.
- Aurora PostgreSQL 17.9: available, encrypted, private db.t4g.medium instance; demo is not Multi-AZ compute.
- Internet-facing HTTPS ALB in two AZs; healthy target; HTTP redirect and Cognito authentication actions.
- Active image-based Lambda and enabled SQS mapping with partial batch failures and maximum concurrency five.
- Encrypted SQS and DLQ, empty at capture; five attempts configured before redrive.
- WAF associated, CloudTrail logging and all six sampled alarms OK.
- One NAT gateway and separate subnet placements.
- App/notifier ECR image digests and release tag.

No credentials, secret values, account identifiers, endpoints, private configuration or raw logs are included. Empty structured log-sample counts do not imply absence of application activity.

## Monitoring artifacts

The following are actual CloudWatch metric-widget images for the observed low-traffic window, not load-test results:

- [Queue age](05-cloudwatch-queue-age.png)
- [Outbox age](06-cloudwatch-outbox-age.png)
- [ALB latency](07-cloudwatch-alb-latency.png)
- [Database connections](08-cloudwatch-database-connections.png)

[Monitoring summary](monitoring-and-workflows.json) records account-level SES counters. Public GitHub workflow metadata was unavailable; no new hosted CI result is claimed.

## Shutdown

The [reviewed plan summary](shutdown-plan-summary.json) lists 90 regional resource deletions. The saved executable plan stays in the private deployed Terraform root.

The plan removes Aurora without a final snapshot, Cognito users, app images, audit/log resources, compute, messaging and networking. Bootstrap state storage, KMS and the image-push role are outside that plan. [Shutdown results](shutdown-result.json) confirm successful execution of the reviewed plan and absence of the checked regional application resources.

## Limitations and follow-up

- No real SQS outage, DLQ redrive, alarm-transition, AZ failure, restore or regional-recovery drill was performed.
- No throughput, p95/p99 performance, availability, RTO/RPO or actual cost result is claimed.
- This was one signed-in user's synthetic quote and sequential retry, not a PostgreSQL concurrency test suite.
- Email reached the recipient but required spam-folder handling. Domain-authentication/reputation configuration was not audited here.
- Raw receipt screenshot is private and ignored; only the sanitized record is publishable.

## User-supplied AWS console captures

The user supplied the following unmodified console screenshots during this exercise:

| Capture | What it establishes |
|---|---|
| [ECS cluster](09-console-ecs-running.png) | Two services, two running tasks, zero pending, Container Insights |
| [Aurora database](10-console-aurora-database.png) | Available cluster and one writer instance, db.t4g.medium, demo is not Multi-AZ |
| [SQS and DLQ](11-console-sqs-and-dlq.png) | Two Standard queues, SSE-SQS encryption, zero available/in-flight messages at capture |
| [RDS overview](12-console-rds-overview.png) | Regional overview shows one cluster and one DB instance |

The RDS overview's billing widget is historical/account-level information, not this project's measured cost. Zero queue depth is a point-in-time observation, not proof of a failure/redrive exercise.

The full CloudWatch console capture contains an AWS account identifier and is retained only in ignored private raw evidence. The public account-free CloudWatch widget images above provide monitoring evidence instead.

[Provenance and image hashes](console-screenshot-provenance.json) distinguish user-supplied screenshots from API-generated charts. No screenshot was regenerated or visually altered.

## Verified shutdown outcome

The user explicitly approved deletion of the demo stack, including the database without a final snapshot. Terraform completed successfully. Post-delete AWS checks confirmed Aurora, ALB, Lambda, app/notifier ECR repositories, both SQS queues and the Cognito pool absent. The project's VPC, active NAT gateways and Elastic IPs were zero, and regional state contained no managed resources.

The separate bootstrap/state bucket, KMS key and GitHub role were deliberately retained. They can retain small storage/key costs; this exercise does not claim the entire AWS account is empty or cost-free. Unrelated workloads and the public hosted zone were outside the teardown scope.

All public evidence remains local in this repository. The original email and account-bearing dashboard screenshots remain private/ignored. No GitHub push was performed as part of evidence collection.

## Teardown cleanup observation

Aurora deletion and Lambda network cleanup made teardown take about 22 minutes. The remaining Lambda interface was still attached after the function execution role had been deleted and no function/version referenced the stack's security group. Standard detach and delete requests were rejected while it remained in use; no force detach was used. AWS subsequently released the dependency and Terraform completed normally.

The sanitized [detach observation](lambda-network-cleanup.json) and [delete observation](lambda-network-delete-attempt.json) record those attempts. AWS documents that Hyperplane ENI cleanup can take time and depends on execution-role permissions: [Lambda VPC lifecycle](https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html). Review role/ENI deletion ordering before the next deployment; the observation does not prove a production incident or measured recovery objective.
