# Evidence register

Evidence date: November 3, 2026 (America/Chicago). This register distinguishes session records, user confirmation and saved machine-readable evidence. Historical session facts have not all been recaptured as durable artifacts.

| ID | Claim | Provenance | Artifact / remaining action |
|---|---|---|---|
| E01 | Two synthetic policies define RTO 60 minutes, RPO 15 minutes and quarterly reviews/rehearsals | Repository source | [Sample corpus](../../../documents/sample-knowledge-base/disaster-recovery-policy.md) and [access policy](../../../documents/sample-knowledge-base/access-control-policy.md) |
| E02 | Ingestion scanned/indexed two new documents, zero failures | Historical session progress | [Progress record](../../../architecture/progress.md); sanitized ingestion export pending |
| E03 | Authenticated CLI and local-browser RTO answer succeeded | User confirmation in prior session | [Progress record](../../../architecture/progress.md); answer screenshot/export pending |
| E04 | 28 backend and 8 frontend tests passed; build and Terraform checks passed | Tool output recorded in session | Fresh durable validation report below |
| E05 | Amplify job 3 succeeded; hosted assets returned 200 | AWS CLI and HTTP checks in session | Fresh sanitized deployment/HTTP report below |
| E06 | Hosted app appears after packaging repair | User confirmation | Screenshot pending |
| E07 | Hosted authenticated answer has expected answer and sources | Not yet captured | Run Q01 and attach sanitized screenshot |
| E08 | App-specific WAF removed at owner's request | AWS API deletion succeeded in session | Sanitized association check below; no claim about other account WAFs |
| E09 | Quality, latency, load and monthly spend | Not measured | Run [evaluation plan](../evaluation-plan.md); collect billing/usage separately |

## Screenshots to capture

1. Hosted sign-in screen without email/password filled in.
2. Hosted answer to Q01, showing 60 minutes and source references; obscure bucket/account identifiers.
3. Expanded synthetic source reference, with identifiers redacted.
4. Amplify successful deployment, with account details redacted.
5. Knowledge Base ingestion completion and document counts, with account/resource IDs redacted.

Name screenshots with the actual capture date and a short subject. Store only sanitized copies here. Do not recreate console screenshots or fabricate missing evidence. Never publish Terraform state/plans, backend.hcl, local variable files, tokens, passwords, raw logs or signed deployment upload URLs.

Generated artifacts: [validation record](validation.json) and [live checks](live-checks.json). These record their own capture time and scope. A successful HTTP response alone does not establish authenticated chat success.
