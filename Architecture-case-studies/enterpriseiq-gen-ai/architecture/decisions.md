# Architectural decisions

- **RAG instead of fine-tuning**: update knowledge by synchronizing documents.
- **S3 Vectors**: managed vector store for retrieval-centric workload; benchmark before production.
- **Separate Terraform roots**: dev/prod isolated state and validation against mis-targeting.
- **Saved Terraform plans**: an approved prod plan must be the exact plan applied.
- **Synthetic documents**: avoids uploading employer or customer confidential data.
- **Validated DEV application**: Cognito-authenticated API and local React chat return grounded answers and source references. Persistent chat history, document-level authorization and hosted frontend remain future work.

## Network decision — standard / no customer-managed VPC

- Both DEV and PROD use `network_mode = "standard"`; Terraform validates the only supported mode.
- No `aws_vpc`, subnets, routing tables, IGW, NAT gateways, security groups or VPC endpoints are created.
- The Phase 1 Bedrock Knowledge Base uses managed AWS services, S3 source documents, and S3 Vectors.
- Future Lambda chat functions will **omit `vpc_config`** and call AWS regional service endpoints using tightly scoped IAM permissions.
- The frontend uses Amplify Hosting; the planned regional API Gateway endpoint is public HTTPS, secured through Cognito/JWT authorizers, application authorization and rate limiting. Publicly reachable does not mean anonymous access.
- S3 must keep Block Public Access, server-side encryption and constrained bucket policies. KMS/IAM/Guardrails, audit logging and per-document authorization remain important and are not replaced by a VPC.
- This avoids NAT and interface endpoint hourly charges, but Bedrock, vector storage, API, compute and CI/CD usage may still incur charges.
- If future requirements include private databases, on-prem connectivity, or strict private-only API network access, revisit the design with a separate enterprise VPC option rather than enabling a VPC flag without implementing all dependencies.
