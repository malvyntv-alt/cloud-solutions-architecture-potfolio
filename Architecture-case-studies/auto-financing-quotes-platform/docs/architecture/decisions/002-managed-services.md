# ADR-002: Use managed relational data and independent compute roles

- Status: Implemented design; live demo decommissioned
- Recorded: November 3, 2026 (retrospective documentation)
- Scope: Implemented design from a verified, subsequently decommissioned single-region AWS demonstration. Bootstrap was retained. HA and multi-region targets are not evidence of deployed resilience.

## Business context

The application needs relational quote ownership, transactional writes, a web runtime and asynchronous notification processing.

## Decision

Use Aurora PostgreSQL, ECS Fargate for the web application and polling publisher, SQS Standard, and Lambda with SES for notifications.

## Alternatives considered

Lambda/API Gateway/DynamoDB; self-managed database or compute; a single process handling both web requests and publishing.

## Business benefit

Retains the existing Python/WSGI and relational transaction model while separating web requests from asynchronous work. Managed services reduce infrastructure administration.

## Consequences and risks

Aurora, ALB, Fargate and NAT can incur idle costs. More independently deployed components increase configuration and monitoring work. No alternative has been benchmarked as slower, less reliable or more expensive here.

## Revisit trigger

Usage, cost or scaling measurements favor a different runtime/data model; publisher polling becomes a material operational constraint.

## Supporting material

[Implementation, operating guidance or evidence](../overview.md). This record documents engineering rationale; it does not imply historical stakeholder approval, measured ROI or benchmarking of alternatives.
