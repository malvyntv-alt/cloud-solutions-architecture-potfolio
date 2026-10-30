# Api module

Owns the public HTTP API, two routes, Lambda, scoped invocation permission and log groups. No VPC, Cognito, Lambda URL or reserved concurrency. CORS is not authentication: anonymous requests can inflate this approximate count. Throttles are best-effort controls, not a hard cost cap.
