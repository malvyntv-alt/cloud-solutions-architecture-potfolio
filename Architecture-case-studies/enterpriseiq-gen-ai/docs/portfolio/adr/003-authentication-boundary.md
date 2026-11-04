# ADR-003: Use Cognito access tokens to protect a shared synthetic corpus

- Status: accepted for the current DEV demonstration
- Recorded: November 3, 2026 (retrospective documentation of implemented decisions)
- Scope: personal project using fictional policies; not approval for enterprise production

## Business context

The browser needs authenticated access without embedding a client secret or AWS credentials.

## Decision

Use Cognito SRP with a public client and API Gateway JWT authorization; retain scoped runtime IAM and explicit CORS origins.

## Alternatives considered

Anonymous demo; hosted OAuth login; a custom identity service.

## Business benefit

Managed sign-in and API authorization with no browser client secret.

## Consequences and risks

Authentication is not document authorization. All admitted users access the same synthetic corpus; complex sign-in challenges and account recovery remain limited.

## Revisit trigger

Federation, MFA workflows or differentiated document access are required; introduce document entitlements before private multi-user data.

## Supporting material

[Implementation, evidence or evaluation reference](../../../terraform/modules/chat_api/main.tf). These records document engineering decisions; they do not imply stakeholder consultation, measured ROI or production governance approval.
