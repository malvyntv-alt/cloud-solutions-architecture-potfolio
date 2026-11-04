# EnterpriseIQ — AWS GenAI Knowledge Assistant

**Status:** DEV API and Amplify-hosted React UI are deployed. Authenticated CLI/local-browser answers and hosted UI rendering are user-confirmed; hosted authenticated answer evidence is pending. See the [portfolio case study and trade-offs](docs/portfolio/README.md), [hosting instructions](architecture/frontend-hosting.md) and [progress](architecture/progress.md).

## Approved networking mode: standard (VPC-free)

Both environments use `network_mode = "standard"` in `terraform.tfvars`. Terraform rejects unsupported network modes; the project creates **no customer VPC, subnets, NAT Gateway, Internet Gateway, security groups, or VPC endpoints**. This is an explicit architecture decision, not an omission.

Application request path: browser → Amplify-hosted React app → API Gateway HTTPS + Cognito/JWT authorization → Lambda (no `vpc_config`) → Bedrock Knowledge Base / S3 Vectors; persistent chat history is not yet implemented. Managed AWS APIs are accessed through their normal regional endpoints. Keep S3 private, IAM least-privileged, log access, limit cross-user document retrieval, and protect public APIs with authorization and throttling.

DEV and PROD remain in the **same existing AWS account**, with separate Terraform state keys, distinct resource names and IAM deployment roles. Production deployments require manual approval and an exact saved plan; the `ENV` variable is only a selector, not permission to deploy to production.

See `architecture/decisions.md` for VPC-free trade-offs and criteria to revisit networking.

## Architecture
S3 documents → Amazon Bedrock Knowledge Base (Titan Embeddings v2) → Amazon S3 Vectors. The Python CLI supports retrieval and generation with Nova Lite. The Lambda adapter and DEV API Gateway/Cognito infrastructure are deployed. The React UI is hosted on Amplify. DynamoDB history, monitoring alarms and CodePipeline remain pending.

## Prerequisites
- AWS account and permission to create Bedrock Knowledge Bases, S3 Vectors, S3, IAM.
- AWS CLI v2, Terraform >=1.10, Python >=3.11 (Python 3.12 for Lambda packaging).
- Choose a region where the selected embedding model and S3 Vectors integration are supported (default `us-east-1`).
- Verify your AWS CLI identity points to your **existing AWS account** before provisioning.
- Set up a **dedicated S3 remote state bucket** with versioning, restricted access and encryption. `backend.hcl` is not checked in with a real bucket name. `use_lockfile = true` provides native S3 state locking.
- Ensure the Bedrock embedding model is usable in your account/region.
- Configure an AWS CLI profile using SSO or temporary credentials; do not commit credentials.

## First local DEV deployment

```bash
aws sts get-caller-identity
cp terraform/environments/dev/backend.hcl.example terraform/environments/dev/backend.hcl
# Edit backend.hcl to specify YOUR existing remote state S3 bucket.
cd terraform/environments/dev
terraform init -backend-config=backend.hcl
terraform fmt -recursive ../../
terraform validate
terraform plan -out=dev.tfplan
terraform apply dev.tfplan
terraform output
```

Save the output values, then from repository root:

```bash
aws s3 cp documents/sample-knowledge-base/ s3://YOUR_DOCUMENT_BUCKET/sample-knowledge-base/ --recursive
aws bedrock-agent start-ingestion-job --knowledge-base-id YOUR_KB_ID --data-source-id YOUR_DATA_SOURCE_ID
# Wait for ingestion job completion with aws bedrock-agent get-ingestion-job.
python -m pip install -r backend/requirements.txt
python backend/chat.py --knowledge-base-id YOUR_KB_ID --question 'What is the example disaster recovery RTO?'
```

**Expected:** returned source snippets referencing the fictional ExampleCorp DR policy. This test is retrieval only, not generated chat.

To start the interactive chatbot with Amazon Nova Lite:

```powershell
$env:AWS_REGION = "us-east-1"
$env:BEDROCK_KB_ID = "YOUR_KB_ID"
$env:BEDROCK_MODEL_ARN = "amazon.nova-lite-v1:0"
python backend\chatbot.py
```

`BEDROCK_MODEL_ARN` defaults to `amazon.nova-lite-v1:0` if it is not set. Type `exit` to quit.

## Reusable chat service

`backend/rag_service.py` provides `RagConversation` with injected retrieval and generation clients. `ask(question)` returns a `ChatResult` with `answer` and deduplicated S3 `sources`. The CLI uses this service and uses Retrieve with `vectorSearchConfiguration` for the Terraform-provisioned VECTOR Knowledge Base, followed by Converse.

Create a separate conversation per session and call it sequentially. By default, it retains five completed question/answer pairs; failed requests leave history unchanged. This limits retained turns, not token usage. Source references identify retrieved documents, not verified sentence-level citations.

Run the offline service tests from the project root (no AWS login or boto3 installation required):

```powershell
python -m unittest discover -s tests -p test_rag_service.py -v
```

## Lambda adapter (local implementation)

`backend/lambda_handler.py` accepts API Gateway HTTP API payload v2 events for POST requests. Configure the Lambda handler as `backend.lambda_handler.lambda_handler`, with the `backend` directory at the deployment archive root and boto3 available. Set `BEDROCK_KB_ID`; optional settings are `BEDROCK_MODEL_ARN` and `AWS_REGION`, as in the CLI.

Request body:

```json
{"question": "What is the disaster recovery RTO?"}
```

Successful response body:

```json
{"answer": "60 minutes.", "sources": ["s3://example/dr.md"]}
```

The answer above illustrates the response format, not a new live result. Only `question` is accepted; it must be nonblank and at most 4,000 characters after trimming. Body size is limited to 32 KiB after base64 decoding. Responses use JSON and `Cache-Control: no-store`. Invalid input returns 400, unsupported methods 405, service setup errors 500, and retrieval/generation failures 502. Internal exception messages are not returned or logged. Failures log only the stage, exception type, SDK error code/operation and Lambda request ID.

Each request starts a fresh conversation. Persistent sessions, authentication enforcement and browser CORS are not implemented in this handler; Cognito authorization and explicit allowed origins belong in the next infrastructure milestone. The DEV endpoint is deployed and the authenticated CLI smoke test succeeded. See `frontend/README.md` for the browser client.

Run both offline suites without AWS access:

```powershell
python -m unittest discover -s tests -p 'test_*.py' -v
```

This command runs the unittest-based service and handler suites; the existing project-structure tests use pytest separately.

## Environment selection / CI-CD

`ENV=dev` or `ENV=prod` is explicitly passed from CodePipeline V2 to CodeBuild build actions. The CI/CD specs in `cicd/` provide the starting build commands. **CodePipeline and CodeBuild infrastructure are not yet provisioned in this phase.** They must be configured to:

1. Pass CodePipeline V2 `ENV` to each CodeBuild action using `#{variables.ENV}`.
2. Use a pinned build image that includes the appropriate Terraform version.
3. Supply environment-specific `backend.hcl` (via a protected deployment setup) and separate AWS execution roles.
4. Preserve the entire source tree **plus saved `tfplan`** between plan and apply; otherwise Terraform cannot apply the planned change. Use a pipeline artifact containing the full workspace or a durable and access-controlled plan artifact.
5. For production, require manual approval after plan, before apply; restrict the production role to the authorized path. A variable alone is *not* a security boundary.
6. Serialize deployments to the same environment, and do not re-plan after approval. Terraform plans can contain sensitive values: restrict artifact and log access.

The sample plan/apply YAML is a **starting point** and assumes the preceding setup and artifact propagation are implemented. Do not execute the production flow without them.

## Cost & cleanup

Set an AWS Budget, use synthetic documents, and monitor Bedrock and S3 Vectors charges. The resources in Phase 1 can cost money. Destroy DEV when finished, and empty the versioned S3 document bucket manually if needed. State backend bucket is separate and should not be destroyed along with the application.

## Terraform environment selection

`terraform/environments/dev/terraform.tfvars` and `terraform/environments/prod/terraform.tfvars` both specify `network_mode = "standard"`. The pipeline passes `ENV=dev` or `ENV=prod` and selects the matching root. No VPC configuration is required, including for CodeBuild.

## Future implementation
- Phase 2: reuse the working Retrieve + Converse flow in Lambda, add authenticated API Gateway, then a React interface.
- Phase 3: Cognito, per-user authorization, tenant-safe retrieval, DynamoDB and guardrails.
- Phase 4: fully provisioned CodePipeline/CodeBuild Terraform CI/CD with exact plan artifacts and production approvals.
- Phase 5: evaluation tests, monitoring, polished architecture diagrams and portfolio case study.
