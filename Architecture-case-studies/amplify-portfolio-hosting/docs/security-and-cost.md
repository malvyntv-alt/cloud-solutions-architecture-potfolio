# Security, privacy and cost

The portfolio and API are public. Cognito is intentionally absent. IAM permits Lambda only GetItem/UpdateItem on the counter table and writes to its log group. No AWS or GitHub credentials are shipped to the browser.

CORS is not authorization; clients outside browsers can call a public API. API throttling is best effort. Low traffic is expected, but bots can increase both count and costs. No per-IP tracking or fingerprint is implemented. Cloud/provider infrastructure can still retain metadata under its own logging behavior.

Public frontend configuration contains the API URL only. Terraform state remains private. GitHub connection is established through the Amplify GitHub App and then imported, avoiding Terraform access_token values.

The API stores only pk=PAGE#home and a numeric views aggregate. Browser and SDK do not automatically retry the increment. An accepted write followed by a lost response can still affect the count. The counter is not an audited visitor/billing metric.

Amplify builds/hosting/transfer, Lambda, HTTP API requests, DynamoDB, logs/alarms/dashboard, Route 53 and retained KMS/state storage can incur charges. The default budget threshold is not an estimate, cap or guaranteed alert. Blank alarm_email creates no external notifications; confirmed subscriptions, cost-tag activation and alarm tests are separate steps.

CSP permits local scripts, existing inline styles/Google Fonts, and the API endpoint. The website remains public and useful when the counter fails. Email/contact information already present on the reused public page is not collected by the counter.
