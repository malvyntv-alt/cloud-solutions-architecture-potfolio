# Architecture and decisions

The public site uses Amplify Hosting with a separately Terraform-managed API Gateway/Lambda/DynamoDB counter. It does not need visitor accounts or an Amplify Gen 2 backend.

| Decision | Why | Tradeoff |
|---|---|---|
| Amplify Hosting | Git-based static hosting and custom-domain support | Repository connection and build behavior need explicit ownership |
| HTTP API + Lambda | Small public counter endpoints | Public clients can fabricate counts; protect costs, not fictitious analytics accuracy |
| DynamoDB on-demand | One durable atomic aggregate | Repeated/ambiguous writes are not exactly once |
| No VPC | No private-network dependency | Uses managed AWS service endpoints; avoids the earlier Lambda ENI cleanup dependency |
| IAM table-scoped permissions | Backend access without browser credentials | Deployment principal remains separately privileged |
| Separate domain phase | Verify new hosting before cutover | Extra operational step and DNS ownership review |

Module dependencies: database -> IAM -> API -> hosting -> domain. Monitoring consumes API/function/table identifiers. API CORS uses configured domain inputs; it does not depend on computed hosting outputs, avoiding a cycle.

Every resource has one owner. API owns Lambda/API log groups; monitoring owns alarms/dashboard. Optional Route 53 records must be imported if Amplify created them automatically.

Public API request bodies allow only page=home and are limited to 512 bytes in Lambda. API ingress still has the service's request limits; this validation is not a pre-ingress firewall. Errors omit payload and credential details. SDK write retries and browser retries are disabled, but that does not make counts exact.

Official references: [Amplify monorepos](https://docs.aws.amazon.com/amplify/latest/userguide/monorepo-configuration.html), [DynamoDB counters](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithItems.html), [HTTP API throttling](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-throttling.html).
