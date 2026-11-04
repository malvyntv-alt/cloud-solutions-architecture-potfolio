# Interview walkthrough: business case to architecture trade-offs

Use this as speaker notes alongside the project README and AWS-icon diagram. Aim for 8-10 minutes; shorten to the opening paragraph for an initial introduction.

## 1. Open with the business problem (one minute)

"I built EnterpriseIQ, an AI knowledge assistant that lets an employee ask a policy question in plain language. It retrieves relevant document text, generates an answer and shows source references. The business hypothesis is reducing policy-search effort and repetitive support questions. I used fictional policies so I could demonstrate the workflow without customer or employer data."

Be explicit that this is a personal engineering project. Business benefits are hypotheses; there is no claimed customer deployment or measured ROI.

## 2. Set requirements and boundaries (one minute)

Explain the requirements: authenticated access, private source storage, policy updates through ingestion, understandable answers with retrieved references, manageable DEV cost and repeatable infrastructure. Explain the boundary: a shared synthetic corpus, independent questions, no production SLO and no document-level authorization yet.

## 3. Walk through the diagram (two minutes)

1. Amplify delivers React; Cognito signs in the user through SRP.
2. The browser sends a question and access token to API Gateway. JWT authorization protects the route; CORS controls browser origins.
3. Lambda retrieves up to five results from the Bedrock Knowledge Base backed by S3 Vectors.
4. Lambda sends retrieved context and the question to Nova Lite through Converse.
5. The response includes answer text and deduplicated source locations. Sources indicate retrieval provenance, not verified sentence-level citations.
6. Separately, private S3 policies are ingested with Titan Embeddings v2 into the Knowledge Base/vector index. IAM scopes runtime access, and CloudWatch records limited operational information.

## 4. Defend three decisions (two minutes)

- **RAG over fine-tuning:** policies can be refreshed through ingestion. Trade-off: relevance, freshness and hallucination still need evaluation. See ADR-001.
- **Managed, VPC-free runtime:** no private network dependency justified a VPC. Trade-off: this does not satisfy a private-only connectivity requirement. See ADR-002.
- **Stateless API and synthetic corpus:** kept delivery bounded and avoided premature data persistence. Trade-off: no follow-up context or per-document user isolation. See ADR-004.

Use [decision records](adr/README.md) when asked what would change your decision. Present S3 Vectors and Nova Lite as working selections, not benchmark winners.

## 5. Explain a failure and the evidence (one minute)

Choose one concrete incident. A VECTOR Knowledge Base rejected the wrong retrieval configuration; switching to vectorSearchConfiguration restored retrieval. Or explain how hosted HTML returned 200 while its JS/CSS returned 404; a Python-repacked archive restored asset delivery. The precise archive-metadata fault was not isolated.

Distinguish offline checks from live evidence: 28 backend tests, eight mocked frontend tests, local build/Terraform checks, earlier user-confirmed authenticated CLI/local-browser answers, and verified hosted rendering. A fresh hosted authenticated answer capture and a scored evaluation set remain pending.

## 6. Close with business readiness (one minute)

"Before opening this to real employee documents, I would implement document authorization, measure answer quality and latency against a manual-search baseline, add budgets and operational alerts, and define a content ownership process. I would use those results to decide whether the pilot provides enough benefit to expand."

## Questions to rehearse

| Interview question | Evidence-based answer direction |
|---|---|
| Why not ordinary search? | Search is the baseline; conversational synthesis is a hypothesis to validate against it |
| How do you prevent hallucinations? | Prompting and sources help, but do not guarantee correctness; evaluations and escalation are needed |
| Is sign-in enough for private documents? | No; user/document entitlements must be enforced in retrieval |
| How much does it save? | No measured savings yet; describe the baseline and measurement plan |
| Why no VPC or WAF? | Workload-specific DEV trade-offs; revisit for connectivity, exposure or security requirements |
| What scales first? | Measure model latency, quotas, retrieval behavior and request concurrency before claiming capacity |
| What did you personally deliver? | Service, Lambda/API adapter, Terraform, Cognito integration, frontend, hosting repair, documentation and evidence compilation |
| Is 60 minutes the app's recovery target? | No; it is a fact in the fictional policy corpus |
