# Architecture trade-offs

Decisions apply to a low-volume synthetic DEV demonstration. No cost savings, latency advantage or quality uplift has been benchmarked.

| Decision | Why selected | Alternative and cost of the choice | Revisit when |
|---|---|---|---|
| RAG over fine-tuning | Ingest revised policies without training a model | Fine-tuning can shape behavior; retrieval introduces ingestion, chunking and relevance dependencies | Specialized behavior cannot be achieved with prompting and evaluated retrieval |
| Bedrock Knowledge Base over custom retrieval orchestration | Managed ingestion and retrieval simplify delivery | Custom pipelines offer chunking/ranking control but add operational work | Measured quality needs custom retrieval or reranking |
| S3 Vectors over OpenSearch or a database vector extension | Managed vector storage fits the existing AWS ingestion path | Alternatives support different query and tuning capabilities; no comparative benchmark exists here | Scale, filtering, latency or quality requirements demand comparison |
| Retrieve plus Converse over a single managed generation call | Application owns context handling and exposes a testable service boundary | More application code; sources are retrieved references rather than validated citations | Managed citations or orchestration meet requirements better |
| Nova Lite as the generation model | Lightweight model used in the working demo | Other models may improve reasoning at different cost and latency; not measured | Evaluation shows unacceptable accuracy or latency |
| VPC-free Lambda | No private resources require VPC connectivity; avoids NAT and endpoint infrastructure | Normal service endpoints remain reachable; does not satisfy private-only networking requirements | Private databases, hybrid access or contractual network controls are introduced |
| Cognito SRP plus HTTP API JWT | Existing managed identity, public browser client with no secret | Hosted OAuth login may improve federation and standard redirect flows; current challenge support is limited | Federation, MFA flows or richer account recovery are needed |
| Stateless API | Simple isolation between requests; no persistent chat datastore | No follow-up context or reload persistence | Conversation continuity becomes a tested requirement |
| Shared synthetic corpus | Makes the demo reviewable without private data | Sign-in alone cannot enforce document permissions | Multiple users receive different document entitlements |
| Manual Amplify artifact upload | Deploys the existing static build without Git credentials or pipeline infrastructure | More release steps and risk of stale configuration; build-time values are embedded | Release frequency requires automated build and deployment |
| WAF disabled in DEV | Owner requested lower recurring demo cost | Removes an additional request-filtering layer; JWT and throttling do not replace WAF | Public exposure, traffic or security requirements justify protection |
| DEV/PROD roots in one account | Separate state and names with lower setup burden | Weaker account boundary; production pipeline/roles are not proven by folder structure | Real production users or organizational controls require account isolation |

## Cost position

Bedrock generation/embedding, vector storage and queries, S3, API Gateway, Lambda, Amplify and CloudWatch can incur charges. WAF removal does not make the app free. Record actual spend and usage before publishing a monthly cost estimate. Budget alarms are pending. Other account resources, including a separate CloudFront WAF, were outside the EnterpriseIQ WAF removal.

## Reliability position

Managed services reduce infrastructure management but do not establish an application SLO. Lambda has a 28-second timeout and 256 MiB memory; API integration timeout is 29 seconds. Model latency can exceed that budget. API throttling is two requests/second with burst five; this is not a measured throughput result. Load, failure recovery and regional resilience exercises are pending.
