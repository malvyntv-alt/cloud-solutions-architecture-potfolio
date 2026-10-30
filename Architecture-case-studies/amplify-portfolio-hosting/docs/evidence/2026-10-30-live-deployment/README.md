# Live deployment — 2026-10-30

The portfolio is deployed at https://malvernvito.com/ using Amplify Hosting. The browser calls an API Gateway HTTP API, which invokes Lambda to read or increment an aggregate DynamoDB counter.

## Evidence

[Sanitized verification results](verification.json) record the capture time, Amplify domain status, HTTPS response, www redirect, public counter configuration, read-only API response and security headers. The JSON intentionally omits account IDs, resource ARNs, credentials and Terraform state.

- Apex HTTPS returned 200; www returned 301 to the apex.
- The published website contains the API endpoint. The user confirmed the page-view counter works on the new domain.
- Amplify build 4 succeeded after correcting the monorepo custom-header structure.
- The first backend read timed out at the original five-second Lambda limit; a subsequent read succeeded. Lambda was increased from 128 to 256 MB and its timeout from five to ten seconds. This is a mitigation, not a measured cold-start performance guarantee.
- Amplify created the Route 53 apex alias, www CNAME and TLS validation CNAME. Terraform owns the domain association; manage_dns_records remains false.
- The existing state bucket and KMS key are reused with a separate Amplify project state key. Private tfvars/backend configuration and build artifacts remain ignored.

The page-view total includes repeat visits and may include bots. It is not unique-user analytics. No load, failover, alarm-delivery or rollback exercise was performed. Automatic builds remain disabled; releases are manual. Alarm email is not configured, and the budget is not a spending cap. Legacy greeting.meldit.net hosting remains running.

Custom-domain provisioning can lag public reachability; the machine-readable evidence records the actual observed Amplify status rather than inferring completion from HTTPS alone.
