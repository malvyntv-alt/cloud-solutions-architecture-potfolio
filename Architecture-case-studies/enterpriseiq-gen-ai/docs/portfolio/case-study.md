# EnterpriseIQ: an authenticated AWS knowledge assistant

## Problem and scope

Enterprise knowledge often lives in policy documents that users must search and interpret manually. This portfolio project demonstrates a question-answering workflow that retrieves relevant policy text, generates a contextual answer and exposes retrieved source locations.

The workload uses two fictional ExampleCorp policies. It demonstrates cloud architecture and delivery without requiring employer or customer data. It is a personal engineering demonstration rather than a client engagement or production enterprise deployment.

## Implementation

I implemented a React/Vite interface hosted on AWS Amplify, Cognito SRP sign-in, an API Gateway HTTP API with a Cognito JWT authorizer, and a Python Lambda adapter. Lambda retrieves up to five results from a Bedrock Knowledge Base using S3 Vectors and invokes Amazon Nova Lite through Converse. Titan Embeddings v2 supports the document embedding path.

Terraform defines separate DEV and PROD roots. The demonstrated deployment is DEV in us-east-1. Both roots use standard networking with no customer-managed VPC. The API has explicit browser origins, request validation, scoped Bedrock IAM access, throttling and 14-day logs. Source documents remain private in S3; displayed S3 references do not grant download access.

## Decisions demonstrated

- Used retrieval to update knowledge through ingestion rather than model fine-tuning.
- Separated retrieval and generation behind an injectable Python service so AWS behavior can be mocked in offline tests.
- Kept the application stateless between API requests and made the UI clear that earlier questions are not sent as context.
- Used managed services and VPC-free Lambda to reduce infrastructure administration and avoid NAT/endpoints for this demonstration.
- Disabled the app-specific WAF and deleted its web ACL at the owner's request to minimize DEV cost, while retaining JWT authorization and API throttling.

## Verified outcomes

Earlier authenticated CLI and local-browser tests returned the expected fictional disaster recovery RTO of 60 minutes (user-confirmed). Recorded ingestion reported two scanned and newly indexed synthetic documents with zero failed documents. These earlier results are documented in the project progress log; raw ingestion and authenticated-response exports are not yet attached to this package.

Local verification passed 28 backend unittest cases, eight mocked frontend tests, the Vite production build, Terraform validation and formatting. Amplify deployment job 3 succeeded. The hosted HTML, JavaScript and stylesheet returned HTTP 200 after the packaging repair, and the user confirmed the app appeared. A fresh hosted authenticated answer and screenshots remain to be captured.

## Engineering problems resolved

**Retrieval configuration mismatch:** the deployed VECTOR Knowledge Base rejected managedSearchConfiguration. Using vectorSearchConfiguration restored retrieval. This showed why a live integration check is needed alongside mocked tests.

**Blank hosted page:** HTML was deployed but its JavaScript and CSS paths returned 404. Re-uploading the original archive reproduced the failure. Repacking the same build with Python zipfile and deploying it restored both asset paths to HTTP 200. The packaging workflow now uses Python. The precise archive-metadata incompatibility was not isolated, so it is not presented as a proven root cause.

## Limits and next steps

Authentication protects one shared synthetic corpus; document- or tenant-level authorization is not implemented. Retrieved locations are not verified sentence-level citations. The system prompt requests context-only answers but does not guarantee grounding or resist all prompt injection. Persistent chat history, guardrails, evaluation metrics, alarms, budgets and provisioned CI/CD remain future work.

Next, record hosted authenticated acceptance, run the evaluation matrix, measure latency and cost, and introduce user-scoped document authorization before expanding beyond the shared synthetic demonstration. The policy's 60-minute RTO is an answer in the sample corpus, not a measured recovery target for EnterpriseIQ.

See the [architecture](architecture.md), [trade-offs](trade-offs.md), and [evidence register](evidence/README.md).
