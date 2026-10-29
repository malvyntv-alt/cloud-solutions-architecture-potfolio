# 2026-10-29 demo deployment and teardown

Region/profile: us-east-1, demo, runtime enabled after migration. Single operator, sandbox account. Account IDs, domains and addresses are omitted.

## Objective

Verify the documented path on AWS: bootstrap, regional foundation, image build through GitHub Actions OIDC, migration, runtime activation and teardown.

## Verified

| Step | Outcome |
|---|---|
| Bootstrap | 8 resources created; reused the account's existing GitHub OIDC provider; role trusts one repository on main |
| Regional foundation | Plan and apply of 82 resources with runtime off |
| Images | build-images workflow pushed app and notifier tag release-001 to ECR via OIDC |
| Migration | One-off Fargate task exited 0 against Aurora PostgreSQL |
| Runtime | Web and publisher services 1/1 running; ALB target healthy |
| HTTPS | Unauthenticated request redirected (302) to Cognito sign-in |
| SES | Sender identity verified |
| Teardown | Regional destroy removed 90 resources; no Aurora, NAT gateway, load balancer or ECR repository remained |

## Issues found

- First image push failed: the OIDC role trusted a different repository than the one running the workflow. Trust updated to the exact repository and branch.
- Second image push failed: ECR repositories are created by the regional stack, so the foundation must be applied before images are pushed.
- GitHub's OIDC provider is account-wide, so creating it in bootstrap conflicts when it already exists. Bootstrap now looks the provider up instead of creating it.

## Not verified

Signed-in quote save and read, real SES delivery, idempotent retry, SQS/DLQ behavior under failure, CloudWatch alarm behavior, backup restore, AZ or regional recovery, load, latency and measured cost. Do not cite this exercise for any of these.
