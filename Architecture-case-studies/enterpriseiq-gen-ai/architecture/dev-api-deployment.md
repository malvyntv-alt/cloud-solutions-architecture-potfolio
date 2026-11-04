# DEV chat API preparation

The DEV root creates Lambda, an HTTP API, a Cognito user pool/client and 14-day log groups. It is opt-in (`enable_chat_api = false` by default). The user has reported successful DEV deployment and test-user creation; live authenticated chat verification is pending. PROD is unchanged.

## Build and review

From the repository root, using Python 3.12:

```powershell
python backend/build_lambda.py
python -m unittest discover -s tests -p 'test_*.py' -v
terraform fmt -check -recursive terraform
terraform "-chdir=terraform/environments/dev" init "-backend-config=backend.hcl"
terraform "-chdir=terraform/environments/dev" validate
```

The build downloads boto3 and its dependencies and writes `build/chat-lambda.zip`, including only the handler/service application files. Dependencies currently use the same boto3 version range as the application; a dependency lock is future work. Rebuild before planning after any backend changes. Preserve the archive with a saved plan, and do not rebuild between plan and apply.

When ready to review AWS changes, verify the AWS identity and use the existing DEV state/backend. Set `enable_chat_api = true` and `chat_allowed_origins` in an ignored `*.auto.tfvars.local` file only if passed explicitly using `-var-file` (Terraform does not automatically load this suffix), or supply them on the command line:

```powershell
aws sts get-caller-identity
terraform "-chdir=terraform/environments/dev" plan "-var=enable_chat_api=true" "-out=dev.tfplan"
```

The default allowed browser origin is `http://localhost:5173`. Replace it with the exact HTTPS frontend origin when hosting the UI. Origin values omit trailing slashes. Review the full plan for unexpected changes to the already working Knowledge Base. Do not import, recreate or replace deployed RAG resources simply to add the API.

Apply only after reviewing the saved plan:

```powershell
terraform "-chdir=terraform/environments/dev" apply "dev.tfplan"
terraform "-chdir=terraform/environments/dev" output chat_api
```

## Authentication and live checks

Use the local SRP sign-in helper from an interactive terminal:

```powershell
python -m pip install -r backend/requirements-smoke.txt
python backend/smoke_api.py --user-pool-id YOUR_POOL_ID --client-id YOUR_CLIENT_ID --url YOUR_CHAT_URL
```

It first checks that an unauthenticated request returns 401, then prompts for email and a hidden password. On first sign-in, enter the temporary password; if Cognito requires a change, enter and confirm a new permanent password. The helper uses the access token only in memory, refuses HTTP redirects, and prints the authenticated status, answer and sources. It does not print tokens or save credentials. Additional MFA challenges are not implemented. See the [pycognito SRP implementation](https://github.com/NabuCasa/pycognito/blob/master/pycognito/aws_srp.py) for the helper library interface.

Cognito permits administrator-created users only. The public app client uses SRP sign-in with no client secret; hosted login/OAuth redirects are not configured yet. Create the DEV test user separately, never through Terraform passwords. Use a Cognito-compatible SRP client to sign in, including completing any new-password challenge.

Send the resulting **access token** in `Authorization: Bearer TOKEN` to `POST /chat`, with body `{"question":"What is the disaster recovery RTO?"}`. Do not publish or log the token. The route requires the `aws.cognito.signin.user.admin` scope supplied by Cognito API sign-in so ID tokens are not sufficient. JWT issuer and audience are tied to this pool/client.

Verify no-token and invalid-token requests are rejected, a valid access token returns answer/source JSON, and malformed input returns 400. Check browser preflight from the configured origin. Authentication protects the shared synthetic Knowledge Base; it does not implement tenant/document isolation. The Lambda is stateless between requests.

## Operational limits

Lambda has no VPC configuration, a 28-second timeout, 256 MiB memory and shared account concurrency by default (`reserved_concurrent_executions = -1`). API throttling is two requests/second with a burst of five. Bedrock latency may exceed the timeout; measure actual DEV behavior. If reserving concurrency later, verify that the account quota leaves sufficient unreserved capacity. API throttling remains enabled but does not impose a strict Lambda concurrency cap. Runtime logs and API access logs exclude questions, documents and authorization headers in the code/configuration provided here.

The initial model policy supports the regional Nova Lite foundation model. Cross-region inference profiles require explicit model and IAM changes. Budget controls and alarms remain pending.

Reference: [AWS HTTP API JWT authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-jwt-authorizer.html).

## Recovering from a reserved concurrency failure

If apply fails at `PutFunctionConcurrency`, keep the existing Terraform state and resources. The module now defaults to shared concurrency (`-1`). Generate a fresh plan with the API enabled, review it, then apply that new plan. The previous saved plan still contains the rejected setting and is stale after a partial apply. Do not destroy the working RAG resources or rebuild the Lambda ZIP for this configuration-only fix.
