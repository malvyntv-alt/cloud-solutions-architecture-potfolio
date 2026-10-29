# Implemented architecture

The stack deploys one region. Demo has two network AZs and one DB instance/web task/publisher/NAT. HA has three Aurora instances, three initial web tasks, two publishers and three NAT gateways.

[Current diagram source](diagrams/current-architecture.mmd) is editable Mermaid. The [target illustration](diagrams/target-architecture.png) is conceptual future state, not deployment evidence.

## Flow and boundaries

Route 53 resolves ALB; ACM supplies TLS and WAF associates with ALB. Cognito authenticates, and private web tasks verify signed ALB identity and owner scope.

Quote save commits quote/outbox atomically. A leased publisher calls SQS outside the database transaction. Lambda checks the committed event/quote relationship, leases the notification ledger, calls SES and records acceptance. Failed batch records retry individually.

Only ALB reaches web port 8080. Aurora accepts PostgreSQL from the compute security group. Runtime shares a non-admin DB credential; migration uses admin. Only an S3 gateway endpoint is provisioned; other service calls use NAT.

CloudTrail records management events in this account. CloudWatch supplies operational signals. No API Gateway, credit bureau, underwriting or pricing-management database exists.

## Failure semantics

SQS failures delay email without undoing saves. Lost acknowledgments can duplicate messages. SES acceptance and ledger commit cannot be atomic; duplicate email remains possible. Acceptance is not delivery. Local inbox dedupe is stronger than SES guarantees.

## Future-state caveats

The inherited PNG depicts unimplemented Region B, Global Database, identity federation/replication, isolated archives/backups, broader endpoints and pricing data. Email currently contains an app link. DNS resolves names rather than proxying HTTP. Correct replication arrows when replacing the illustration.

See [decisions](decisions/README.md) and [DR roadmap](../operations/recovery-roadmap.md).
