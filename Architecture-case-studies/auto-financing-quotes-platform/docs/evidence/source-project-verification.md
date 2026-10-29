# Historical source-project record

The following is the original author's record, retained as historical context. It has not been re-executed for this detached edition. Resource counts/workflow/deployment claims refer only to the source project.

## Original record

Initial authoring date: 2026-10-28.

## Completed locally

- Python syntax compilation and JavaScript syntax check.
- 18 application tests: atomic rollback, simultaneous duplicate saves, ownership isolation, SQS outage, ambiguous publish acknowledgment, expired quotes, email outage, publisher lease recovery, malformed inputs, ALB identity validation, local-only fault routes, partial Lambda batch failures.
- terraform init with actual HashiCorp provider downloads; terraform validate.
- Three mocked Terraform plan tests: demo topology/runtime off, HA topology/runtime on, and recovery workers disabled.
- Browser walkthrough: calculate/save, inspect event, enable simulated SQS outage, save another quote, observe pending event/retries while quote remains saved, restore queue and verify recovery.
- Screenshot assets capture the actual local app, not an AWS console or production deployment.

## Completed on AWS (2026-10-28, us-east-1, demo profile)

- Terraform bootstrap: encrypted, versioned S3 state bucket with KMS and native locking; GitHub OIDC role. State migrated to S3.
- Terraform apply of the demo profile: 82 resources, runtime off, then runtime on.
- GitHub Actions `checks` workflow green; `build-images` workflow built both images via OIDC and pushed tag v1 to ECR (no local Docker).
- One-off Fargate migration task completed with exit code 0 against Aurora PostgreSQL.
- Web and publisher Fargate services reached 1/1 running; HTTPS endpoint redirects unauthenticated users to Cognito.
- SES sender identity verified.
- Full destroy and rebuild of the stack, including recovery from deletion-protection blocks.

Issues found and fixed during deployment:

- GitHub OIDC trust failed: the token subject used the ID-qualified form `repo:owner@id/name@id:ref:...` rather than `repo:owner/name:ref:...`. Found by reading the failed AssumeRoleWithWebIdentity event in CloudTrail; trust policy updated.
- Lambda `reserved_concurrent_executions = 5` failed because the new account's Lambda concurrency limit is 10 (AWS requires 10 unreserved). Removed the reservation; the SQS mapping's `maximum_concurrency` still bounds concurrency.
- Destroy failed while ALB and Aurora deletion protection were enabled; disabled via targeted apply, then destroyed.

## Still to record (add dated evidence in docs/evidence/)

- Signed-in quote save and receipt of a real SES email.
- Idempotent retry producing one quote and one outbox event.
- Real AWS SQS/DLQ and CloudWatch alarm behavior.

## Not verified

- PostgreSQL-specific application test suite (tests use SQLite).
- AZ failure, regional failover, backup restoration.
- Any numerical RTO/RPO, throughput, operating-cost or availability claim.

Do not present mocked plans as deployed resources or local failure controls as AWS fault-injection results. Keep dated screenshots and notes in docs/evidence/.
