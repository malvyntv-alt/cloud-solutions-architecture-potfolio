# Deploy this independent project

These are operator-invoked steps. Repository creation and local checks do not deploy AWS.

## Isolation and prerequisites

Use a sandbox account, Python 3.12+, Terraform >=1.10, AWS CLI, and Docker or GitHub Actions. Choose new DNS in a public Route 53 zone and an SES sender you control.

Run from this project folder: `Architecture-case-studies/auto-financing-quotes-platform/`. Verify `aws sts get-caller-identity`; configure matching CLI/Terraform/helper regions. Default project: drivequote-portfolio. Use new state storage/key and unique resource/DNS names.

GitHub's OIDC provider is account-wide. Bootstrap looks up the existing provider and creates only this repository's IAM role; it does not create or manage the provider. Confirm the provider exists and includes the `sts.amazonaws.com` audience before applying. For a new AWS account without it, create the provider separately first.

## 1. Bootstrap

```powershell
Copy-Item infra/bootstrap/bootstrap.tfvars.example infra/bootstrap/bootstrap.tfvars
# Edit project, region and github_repo for the NEW repository.
terraform -chdir=infra/bootstrap init
terraform -chdir=infra/bootstrap plan -var-file=bootstrap.tfvars -out=bootstrap.tfplan
terraform -chdir=infra/bootstrap apply bootstrap.tfplan
```

Bootstrap creates versioned KMS-encrypted S3 and an ECR-push OIDC role. Its own state starts locally; protect/back it up privately. Destroy the regional stack before destroying bootstrap, because the regional Terraform state is stored in the bootstrap S3 bucket.

Trust defaults to the new repository's main branch. For customized claims, set github_oidc_subject to the exact subject. Never publish tokens.

## 2. Regional foundation

```powershell
Copy-Item infra/stacks/regional/config/backend.hcl.example infra/stacks/regional/backend.hcl
Copy-Item infra/stacks/regional/config/demo.tfvars.example infra/stacks/regional/config/demo.tfvars
```

Fill new bootstrap outputs and private project, region, DNS, zone and email settings. Match bootstrap project/region. Keep enable_runtime=false and choose a fresh image tag. backend.tf is already committed.

```powershell
terraform -chdir=infra/stacks/regional init -backend-config=backend.hcl
terraform -chdir=infra/stacks/regional plan -var-file=config/demo.tfvars -out=deploy.tfplan
terraform -chdir=infra/stacks/regional apply deploy.tfplan
```

Check regional engine/class availability, quotas and costs. ACM needs working DNS. Web/publisher desired counts remain zero until activation.

## 3. Images

For GitHub Actions, publish the portfolio repository and set variables on that repository:

| Variable | Value |
|---|---|
| AWS_ROLE_ARN | New bootstrap github_role_arn output |
| AWS_REGION | Deployment region |
| PROJECT_NAME | Exact Terraform project |

Push to main and manually dispatch auto-financing-build-images with the tag in tfvars. Checks precede image push. The role cannot apply Terraform. Review ECR scan findings; they are not an automated release gate.

Alternatively, with Docker:

```powershell
./scripts/deploy/build-images.ps1 -Tag release-001 -Region us-east-1
```

Local Docker context remains this project folder; the root GitHub workflow uses the same project folder as its context. Tags are immutable. After a partial push failure choose a fresh tag for BOTH images.

## 4. Migration

Install runtime dependencies, then:

```powershell
python scripts/deploy/run-migration.py --region us-east-1
```

This launches a real Fargate task using this project's outputs. Require exit zero before runtime. Migration uses the admin secret; runtime uses quote_app. SQL is idempotent initial setup, not a versioned migration framework.

## 5. Activate and verify

Set enable_runtime=true in the same private base tfvars; review a fresh plan/apply. Confirm healthy targets, running tasks, Cognito login and authenticated save/read.

Verify SES sender identity. Sandbox recipients need SES verification separately from Cognito. Confirm SNS subscriptions and activate cost-allocation tags.

Record actual quote/outbox/SQS/Lambda/SES behavior, retry idempotency, DLQ and delivery metrics using the [evidence template](../evidence/README.md). Liveness alone is insufficient.

## 6. HA and teardown

```powershell
Copy-Item infra/stacks/regional/config/ha.override.tfvars.example infra/stacks/regional/config/ha.override.tfvars
terraform -chdir=infra/stacks/regional plan -var-file=config/demo.tfvars -var-file=config/ha.override.tfvars
```

HA expands the same state. Review increased costs and retain both arguments on subsequent operations. Both profiles are single-region. Read [teardown](../operations/teardown.md) before deleting anything.

## Portfolio repository identity

Set private bootstrap github_repo to YOUR_GITHUB_OWNER/cloud-solutions-achitecture-potfolio before configuring this portfolio's image-push role. OIDC subjects identify the repository and branch, not a folder. Existing trust for the standalone project does not automatically authorize the portfolio.

Do not reuse the standalone project's state or assume this folder move migrated infrastructure. Review state/resource ownership separately before any deployment. No state or credentials were imported.
