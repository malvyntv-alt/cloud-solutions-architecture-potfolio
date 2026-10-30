# Domain module

Owns optional domain association and optional DNS records in an EXISTING public Route 53 zone. Both switches default off. Verification is asynchronous. Amplify may auto-create DNS: import existing records before enabling Terraform DNS ownership. allow_overwrite=false protects records. The apex alias zone is for standard AWS CloudFront. No registrations/zones, meldit.net records or legacy hosting are managed.
