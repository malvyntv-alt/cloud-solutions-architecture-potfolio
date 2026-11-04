# DEV Amplify hosting

The DEV root can create an Amplify WEB app and a `dev` branch for manual static deployments. Hosting is opt-in. Terraform adds the exact generated HTTPS origin to API CORS while retaining `chat_allowed_origins`. No Git connection, build role, public document bucket or Cognito OAuth redirects are needed for the existing SRP sign-in flow.

## Prepare and review

Use the existing DEV backend, AWS profile and Lambda archive. From the project root:

```powershell
aws sts get-caller-identity
terraform "-chdir=terraform/environments/dev" init "-backend-config=backend.hcl"
terraform "-chdir=terraform/environments/dev" validate
terraform "-chdir=terraform/environments/dev" plan "-var=enable_chat_api=true" "-var=enable_frontend_hosting=true" "-out=hosting.tfplan"
terraform "-chdir=terraform/environments/dev" show hosting.tfplan
```

Review for two new Amplify resources and an API CORS update. Stop and investigate unexpected replacements, deletions or changes to the working Knowledge Base. Preserve any existing custom variable-file settings when planning. Do not rebuild the Lambda archive between plan and apply.

After reviewing the saved plan:

```powershell
terraform "-chdir=terraform/environments/dev" apply hosting.tfplan
terraform "-chdir=terraform/environments/dev" output -json frontend_hosting
terraform "-chdir=terraform/environments/dev" output -json chat_api
```

Keep **both enable flags true on future plans** while these resources are in use; their defaults are false. Omitting the flags would plan removal of the resources. PROD is unaffected.

## Build and upload

Set `frontend/.env.local` to the deployed `chat_api` output using the variable names in `.env.example`. These are public browser identifiers. Verify the endpoint and Cognito IDs before building; Vite embeds them in the artifact. Amplify environment variables do not change a manually uploaded bundle.

```powershell
Push-Location frontend
npm.cmd ci
npm.cmd test
Pop-Location
powershell -NoProfile -ExecutionPolicy Bypass -File frontend/package-hosting.ps1
```

In the AWS Amplify console, select the Terraform-created `enterpriseiq-dev` app and its `dev` branch, choose the manual deployment/upload action, and upload `build/frontend-hosting.zip`. Do not create a second app. The archive contains `index.html` at its root. Wait for deployment success, then open the exact `frontend_hosting.url` output.

The current UI uses a single root page with no client-side path routing, so no SPA rewrite is required. Future routes will require a hosting rewrite. Subsequent releases rebuild and upload a new archive to this same branch; Terraform manages hosting configuration separately from deployment contents.

## Acceptance and cleanup

Sign in using the existing test user. Ask “What is the example disaster recovery RTO?” and check for 60 minutes plus sample policy references. Check sign-out, narrow-screen layout, and browser preflight from the hosted origin. An unauthenticated API request must still return 401. Record sanitized results; local build/tests alone do not prove hosted sign-in or API access.

To remove only hosting, plan with `enable_chat_api=true` and `enable_frontend_hosting=false`, review, then apply the saved plan. This removes the Amplify app/branch and its CORS origin while preserving the API. Hosting may incur charges while enabled.

References: [AWS manual static deployments](https://docs.aws.amazon.com/amplify/latest/userguide/manual-deploys.html), [Terraform Amplify app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/amplify_app), [Terraform Amplify branch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/amplify_branch).

## DEV cost preference

WAF is currently disabled for this DEV app at the user's request. Its app-specific web ACL was disassociated and deleted on November 3, 2026. Skip the optional Amplify firewall onboarding step; the Terraform hosting configuration does not create WAF. Cognito API authorization and API throttling remain configured.
