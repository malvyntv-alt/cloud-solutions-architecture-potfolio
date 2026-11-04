# EnterpriseIQ browser workspace

React + Vite client for the existing Terraform-managed Cognito pool and chat HTTP API. No new AWS resources are created by this frontend.

## Run locally

From the project root in PowerShell:

```powershell
cd frontend
npm.cmd ci
Copy-Item .env.example .env.local
npm.cmd run dev
```

Open **http://localhost:5173**. This exact origin is already allowed by the DEV API. Use the Cognito email and permanent password from the successful CLI test. The app also supports Cognito's initial new-password challenge. New accounts must be created by an administrator; self-registration and password reset are not implemented here.

Use `npm.cmd` in Windows PowerShell if the execution policy blocks `npm.ps1`. Node.js 22.12+ or a supported newer release is required by the toolchain; this workspace was built with Node.js 26.

`.env.example` contains public DEV resource identifiers only. Configuration values prefixed with `VITE_` are embedded in the browser bundle; never put passwords, AWS credentials, or client secrets in them. Keep `.env.local` ignored. Restart Vite after configuration changes.

## Behavior

- Cognito SRP sign-in uses the existing public client. Amplify stores tokens in browser session storage rather than persistent local storage; sign-out clears the signed-in workspace.
- The API receives the Cognito **access token** and only `{ "question": "..." }`. Tokens are never rendered or logged by this app.
- The visible conversation is held in component memory and clears on sign-out, reload, or New conversation. The current backend answers each question independently; earlier messages are not sent as context.
- Retrieved S3 references expand to their full location. S3 documents remain private. Download links require a separate authorized download API; these references are not sentence-level citations.
- Failed questions stay in the composer for retry. Requests time out after 40 seconds; sign-out aborts outstanding requests and ignores late results.

## Verify and build

```powershell
npm.cmd test
npm.cmd run build
npm.cmd audit
```

`dist/` is the static hosting artifact. Before hosting on Amplify, provide the three public build-time variables and add the exact HTTPS hosting origin to Terraform's `chat_allowed_origins`, preserving localhost if still needed. Review and apply that saved DEV plan. Hosting has not been configured or deployed in this milestone.

Manual live acceptance: sign in, ask the DR RTO question, verify **60 minutes** and policy references, start a new conversation, and sign out. Then check a narrow browser window. Automated frontend tests mock Cognito and HTTP; they do not establish a live browser login result.

Library reference: [Amplify existing Cognito configuration](https://docs.amplify.aws/gen1/react/build-a-backend/auth/set-up-auth/).
