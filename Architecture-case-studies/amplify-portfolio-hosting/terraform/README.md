# Terraform layout

Six reusable child modules are wired by environments/production. Each has resources, input variables, outputs, requirements and a README. No provider credentials are embedded.

Use a distinct remote-state key for this project. Existing state bucket/KMS may be reused with appropriate access; do not reuse the auto-financing state key. Backend and private tfvars are ignored.

Package build/counter.zip before validation/planning. For offline checks initialize with backend=false and run mocked tests. A real apply requires an imported GitHub-connected Amplify app/branch. Read the [deployment runbook](../docs/deployment.md).

This design uses standard AWS (not China partitions). No VPC, NAT gateway, EC2, Aurora, Cognito, Amplify Gen 2 backend or second Terraform provider manages these resources.
