# ADR 002: Managed regional services

Status: implemented.

Aurora provides relational ownership and transactions. Fargate hosts WSGI and a polling publisher. Lambda handles SQS batches and SES; Cognito/ALB supply login.

Serverless API/Lambda/DynamoDB could reduce idle cost but requires a different runtime/data model. Consolidating workers reduces components but couples scaling/failure.

Consequences: Aurora/ALB/NAT/Fargate create idle cost. HA topology still needs load, capacity and failure testing.
