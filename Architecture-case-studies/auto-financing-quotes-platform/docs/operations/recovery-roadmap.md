# Stage 3 — regional disaster recovery

This is a design/runbook, not a deployed second-region Terraform module. The current demo and ha profiles both deploy only one region. Completing this stage requires additional Terraform, AWS integration tests and measured drills.

The [target illustration](../architecture/diagrams/target-architecture.png) is conceptual. Some icons are illustrative; Route 53 provides DNS resolution rather than proxying HTTP, WAF attaches to ALB, and Aurora replication flows from primary to secondary. The initial deployment only implements the Region A path.

## Proposed business objectives

- 99.95% monthly availability.
- Replace failed app capacity within one minute; healthy capacity should continue serving.
- AZ recovery within two minutes; no acknowledged database commits lost for the covered failure.
- Regional RTO fifteen minutes; saved-quote RPO five minutes.
- Email delivery is asynchronous and needs a separately agreed recovery objective.

These are unmeasured targets. RTO starts at business disruption, including detection and decision time. An async replica is not a hard five-minute data-loss guarantee. Define what to do when lag exceeds the target (restrict saves, suspend notification sends, or explicitly accept exposure).

## Implement independent Region B

1. Refactor the regional resources into a module and use explicit primary/secondary AWS provider aliases. Use unique regional names and separate networking.
2. Deploy the same versioned images and HA compute in Region B with production traffic blocked.
3. Attach an Aurora secondary cluster to an Aurora Global Database; check current engine-version and Secrets Manager constraints before converting an existing cluster. Do not apply a global-cluster change casually to a populated database.
4. Prepare secondary-region app credentials without granting admin access to runtime. DATABASE_HOST must point to the promoted regional writer when activated.
5. Configure Cognito multi-region user-pool replication using supported region/tier/issuer configuration. Verify ALB integration, login redirect URLs, signed token issuer/client expectations, subject identity continuity, and reauthentication. Merely creating a second unrelated pool does not replicate accounts or preserve quote ownership.
6. Prepare regional secrets, KMS access, ECR images, ACM certificate, DNS, alarms, IAM, SES identities/configuration, quotas and production access.
7. Create Region B SQS/DLQ and Lambda, but keep publisher count zero and event-source mapping disabled.
8. Use Route 53/ARC routing controls with one authorized primary write region. Initial Terraform creates a simple single-region alias; failover records and ARC are not yet provisioned.
9. Add isolated cross-account/region backup and audit storage. PITR in Region A is not independent regional backup recovery.

Cognito MRR reference: https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-multi-region.html
Aurora recovery reference: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database-disaster-recovery.html

## Controlled regional failover

1. Confirm business disruption with independent synthetic transactions and infrastructure signals.
2. Fence Region A writes, publishers and consumers using a tested ownership mechanism. Do not assume inability to reach a region means its workers have stopped.
3. Assess replication lag and business approval for possible loss. Promote Region B database and coordinate identity recovery.
4. Validate runtime credentials, authenticated identity/ownership, pricing version, quote reads and a synthetic transactional save. No public traffic yet.
5. Run app.replay in dry-run mode against the promoted DB. After fencing, run with --execute to reset retained unfinished notification events.
6. Enable Region B publisher and SQS consumer. Bound backlog drain rate to SES and DB capacity.
7. Route production users and verify actual quote/save/read success.
8. Reconcile quote counts and notifications. Record achieved RTO/RPO, missing IDs, duplicate risk and monitoring gaps.

SQS does not automatically copy queues cross-region. Replay must include events marked PUBLISHED whose notification ledger is not terminal, because the original queue might be inaccessible.

The ledger and outbox share asynchronous database replication. If SES accepted an email but the ledger update never replicated, replay can send it again. If a quote was emailed before its data replicated, the secondary may temporarily lack that quote. Regional replay cannot eliminate either ambiguity. Stronger cross-region durability before email release is a separate design change.

ACCEPTED means SES accepted a send request. Track delivery/bounce separately; do not equate acceptance, delivery and customer receipt.

## Failback

Keep Region B authoritative while rebuilding Region A. Restore replication, reconcile data and side effects, validate, then execute a planned switch. Never automatically send users back because an old health check turns green.

## Evidence required

Test regional isolation, not just toggling a DNS record. Record disruption time, detection, promotion, first successful business transaction, last committed/recovered quote IDs, pending outbox age, replay volume, identity readiness and actual data loss. Use that evidence to claim experience.
