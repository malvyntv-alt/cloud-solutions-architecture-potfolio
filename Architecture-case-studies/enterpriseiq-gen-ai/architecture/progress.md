# EnterpriseIQ progress

## Current checkpoint

The user confirmed that the Bedrock RAG test worked. This checkpoint records that report; it does not represent a new AWS verification or a production readiness assessment.

- Terraform definitions exist for the document bucket, Knowledge Base and S3 Vectors, with separate DEV and PROD roots.
- `backend/chat.py` provides the retrieval smoke test.
- `backend/chatbot.py` retrieves context and generates answers with Nova Lite using Converse, and prints retrieved source locations.
- The user reported successful DEV API/Cognito deployment and test-user creation. The local SRP sign-in helper is implemented; authenticated live verification, browser interface and persistent history are pending.

## Next milestone: authenticated application API

1. Implemented locally: `backend/rag_service.py` extracts the working retrieval and generation flow; the CLI uses it and receives answer text plus source references. History is limited to five completed turns by default, and failed requests do not change it. All 11 offline tests in `tests/test_rag_service.py` passed using Python 3.12.4 on November 3, 2026. The Python installation required execution outside the sandbox. A live AWS regression check is still pending.
2. Implemented locally: `backend/lambda_handler.py` validates JSON questions, returns answer/source JSON, handles errors without logging question or document content, and creates a separate conversation per request. All 20 service and adapter tests passed with Python 3.12.4 on November 3, 2026. Deployment and live verification remain pending.
3. Implemented locally: opt-in DEV `chat_api` Terraform module for Lambda without VPC configuration, scoped Bedrock access, API Gateway with Cognito JWT authorization, explicit browser origins, throttling and 14-day logs. Lambda archive builder added. Deployment and live authentication checks are pending; see `dev-api-deployment.md`.
4. Verify an authenticated request returns an answer with sources, invalid input is rejected, and unauthenticated requests cannot invoke chat.
5. Build the React chat interface with sign-in, answer and source display, loading state and useful error messages.

Use the existing Retrieve + Converse flow as the starting point. Live diagnosis confirmed that the Terraform-provisioned VECTOR Knowledge Base requires `vectorSearchConfiguration`; `managedSearchConfiguration` is rejected. The service and retrieval CLI have been corrected. The data source is restricted to `sample-knowledge-base/` so existing unrelated bucket objects are excluded.

Local infrastructure verification on November 3, 2026: Terraform initialized with an isolated cache and backend disabled; DEV validation and recursive formatting checks passed. The Lambda archive built successfully, passed ZIP integrity checks, and loaded the packaged handler and boto3 in an isolated Python process. All 20 backend tests passed. No AWS plan or apply was run.

## Following milestones

- Add user-scoped DynamoDB history and document authorization before introducing multiple users or private datasets. Sign-in alone does not provide per-document isolation.
- Add evaluation cases for supported questions, missing information and source grounding; collect measured results for the portfolio.
- Add monitoring, budget controls and the provisioned CI/CD pipeline with saved plans and production approval.
- Complete the portfolio case study with the final architecture, screenshots, measured results, trade-offs and cleanup instructions.

## Evidence still to capture

Record the AWS region, test date, synthetic question, returned answer and source reference in a sanitized test record. Capture which test was run (retrieval CLI or interactive chatbot), without publishing account identifiers, credentials or private document content. No live AWS checks were performed while recording this checkpoint.

## Live DEV repair and validation — November 3, 2026 (America/Chicago)

- API logs confirmed an unauthenticated 401 and an authenticated request reaching Lambda with an application 502.
- Safe diagnostic logging identified a Retrieve ValidationException. The deployed VECTOR Knowledge Base rejected managedSearchConfiguration; vectorSearchConfiguration succeeded.
- Updated the service and retrieval CLI; all 28 offline tests passed. Applied the Lambda code update and sample-only data-source prefix through a reviewed saved Terraform plan (zero creates, two in-place updates, zero destroys).
- User selected synthetic samples only. Uploaded the two repository policy files under sample-knowledge-base/; ingestion completed with two scanned, two newly indexed, zero failed documents. Existing unrelated PDFs were excluded by the prefix.
- Direct invocation of the deployed Lambda returned application status 200, the answer “The example disaster recovery RTO (Recovery Time Objective) is 60 minutes.” and source references under the sample prefix.
- End-to-end authenticated API retest with the user's local SRP helper remains pending. No passwords or tokens were requested or captured.
## Browser frontend — November 3, 2026

The user confirmed the complete authenticated API path returned the expected 60-minute RTO. Added a local React/Vite frontend in frontend/ using the existing Cognito SRP flow and API, with sign-in, temporary-password completion, in-memory visible conversation, independent questions, source references, retry feedback, sign-out and responsive layouts. Tokens use session storage; no client secret or AWS credentials are needed. The existing localhost:5173 API origin is used.

Eight mocked frontend tests passed, including token selection, new-password sign-in, answer/source rendering, failures, and ignoring results after sign-out. Production build passed; npm audit reported zero vulnerabilities and the development server returned HTTP 200. Browser access host was unavailable, so visual QA and live browser sign-in are pending. No frontend hosting was deployed and no AWS configuration changed in this milestone. See frontend/README.md for local use and hosting prerequisites.
## Validated application checkpoint

The user confirmed the authenticated CLI returned the expected 60-minute RTO and the local browser app successfully signed in and returned results. This closes the live API and browser acceptance checks previously marked pending. Frontend hosting remains the next delivery milestone.

## DEV hosting preparation - November 3, 2026

Added opt-in Amplify WEB hosting and dev branch, automatic API CORS origin, frontend ZIP packaging, and [deployment instructions](frontend-hosting.md). Keep both enable flags true on future plans while resources are in use. Terraform validation and formatting passed; 8 frontend and 28 backend tests passed. The frontend production build and ZIP integrity/root index.html checks passed. No AWS plan, apply or upload was run; hosted acceptance remains pending.


## Hosted DEV and cost preference - November 3, 2026

User confirmed the hosted app renders after repair. Missing hosted JS/CSS returned 404 with the PowerShell-produced archive; repacking with Python and deploying job 3 succeeded, with JS/CSS returning 200. Packaging now uses Python zipfile. Per user request to minimize costs, disassociated the app-specific WAF and deleted its CreatedByAmplify web ACL. Other account WAF resources were left unchanged. Hosted authenticated answer acceptance is still pending.


## Portfolio documentation - November 3, 2026

Created docs/portfolio with case study, architecture diagram, trade-off matrix, evidence register, synthetic evaluation plan and publication guide. Fresh sanitized JSON records capture local check results, successful Amplify deployment, hosted asset HTTP responses, WAF association absence and unauthenticated API rejection. Prepared an EnterpriseIQ entry and standalone case-study page in the sibling portfolio website; built with the existing counter endpoint and all five counter tests passed. Website source has not been published. Bitbucket destination is awaiting user input; the existing GitHub remote is unchanged. Hosted authenticated answer capture and screenshots remain pending.
