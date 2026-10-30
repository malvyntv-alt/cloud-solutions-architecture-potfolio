# Staged deployment and domain cutover

No AWS deployment is performed by the build/check workflow. Do not run these steps before reviewing account, region, current DNS, costs and the actual plan.

## 1. Local preparation and state

Run the README checks and package the Lambda. Copy terraform.tfvars.example to ignored terraform.tfvars inside terraform/environments/production. Copy backend.hcl.example to ignored backend.hcl and fill the existing state bucket/KMS configuration with a NEW project key.

```powershell
terraform -chdir=terraform/environments/production init -backend-config=backend.hcl
```

The retained bootstrap from the first project may supply state storage. This project does not recreate it or manage domain registration. Protect local state if you choose a temporary local backend.

## 2. Authorize GitHub and import hosting

Through the Amplify console, authorize the Amplify GitHub App for the portfolio repository and connect main. Select monorepo root Architecture-case-studies/amplify-portfolio-hosting. Use build command node scripts/build-website.mjs and artifact directory build/site. The initial build can show a disabled counter because no API URL is configured yet.

Set amplify_app_id to the returned app ID in private tfvars. Disable automatic builds until Terraform configuration and CI are reviewed. The imported app and branch must be this project's resources, not another application's.

```powershell
terraform -chdir=terraform/environments/production import module.hosting.aws_amplify_app.this YOUR_APP_ID
terraform -chdir=terraform/environments/production import module.hosting.aws_amplify_branch.this YOUR_APP_ID/main
terraform -chdir=terraform/environments/production plan -out=deploy.tfplan
```

Do not put access tokens in tfvars, Terraform environment maps, state or the browser. GitHub authorization may require an owner-operated permission step.

Review changes to the imported app carefully; this configuration deliberately replaces its build specification/headers. The app is protected with prevent_destroy.

## 3. Deploy without domain cutover

Keep enable_custom_domain=false, manage_dns_records=false and enable_auto_build=false. Review the saved plan, then apply it explicitly. It creates the counter backend and updates imported hosting settings with the API URL.

For the temporary Amplify hostname to call the API, copy its exact HTTPS origin into additional_allowed_origins and review a follow-up plan. No wildcard origin is necessary.

Start one manual Amplify deployment of the chosen branch after configuration is applied. Verify static pages, a GET read, a POST increment, invalid-input rejection and browser fallback when the API is unavailable. Record evidence; do not use the counter as unique-user analytics.

## 4. Review malvernvito.com DNS

Confirm the registration and PUBLIC hosted-zone delegation. Inventory existing apex, www, email and verification records. Keep greeting.meldit.net and its S3/CloudFront hosting available during transition.

Set enable_custom_domain=true only after approving the association step. Amplify-managed TLS verification is asynchronous; inspect certificate_dns_record/subdomain_dns_records and the Amplify domain status.

Amplify's Route 53 integration may create records automatically. Choose ONE owner:
- Leave manage_dns_records=false if Amplify owns the records.
- For Terraform ownership, import already-created records before setting manage_dns_records=true. Set hosted_zone_id to the existing public zone. allow_overwrite=false deliberately prevents silently replacing existing records.

The optional Terraform records are certificate CNAME, apex A alias and www CNAME. This module does not create IPv6 AAAA records or a hosted zone. Validate returned DNS targets before taking ownership.

Verify TLS and both hostnames; www redirects to the apex. Public Route 53 delegation and service verification must be checked, not inferred from a successful plan.

## 5. Activate releases and rollback

After tests and first deployment succeed, enable_auto_build=true through a reviewed plan. Amplify then builds on connected branch pushes; root GitHub checks and Amplify deployment are separate systems, so a successful push is not proof tests gated the Amplify build. Use protected branches/reviewed merges before treating CI as a release gate.

Repo-root amplify.yml, if added later, can override app build settings. Document all applications there before introducing it.

Rollback website changes by redeploying a known good source revision; keep compatible counter configuration. Revert custom DNS only to recorded pre-cutover targets. Do not remove the old hosting until the new domain has been independently verified.

## Teardown

A permanent portfolio is intended to remain available. Terraform prevent_destroy protects the Amplify app; deletion protection protects the table. Intentional full teardown requires a reviewed change to those controls and a data/DNS retention decision. Domain teardown is not domain deregistration. State storage and legacy hosting remain outside this root.
