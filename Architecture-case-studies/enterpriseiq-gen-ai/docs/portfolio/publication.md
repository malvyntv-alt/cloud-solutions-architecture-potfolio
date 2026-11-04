# Publication and website handoff

## Repository

The current origin is GitHub. A Bitbucket repository URL has not been supplied. Do not replace origin or push to an assumed destination. This Markdown package can be reviewed in either service; Mermaid rendering depends on repository viewer support, so the architecture also has a written request path.

Before publishing, inspect the diff and publishable file list. Exclude generated archives, dist/node_modules, Terraform state/plans/caches, backend.hcl, local settings and raw logs. Add only sanitized evidence. Keep planned evaluation cases labeled as planned. Review older repository documentation for stale status and identifiers.

Once the Bitbucket destination is supplied, add a separate remote and push the reviewed branch according to the destination's branch policy. Repository creation and credential setup are not included in this package. Update website repository links only after the destination and accessible branch/path are known.

## malvernvito.com

The source is in the sibling amplify-portfolio-hosting/website/index.html. The new entry should describe the deployed DEV RAG architecture, link to an accessible case study and identify sign-in as invite-only. Do not publish test-user credentials or present the demo as an unrestricted public chatbot.

Preserve the existing page-view counter endpoint when building the portfolio site. The source default is blank and a build without COUNTER_API_URL disables the counter. Verify the generated counter-config.js matches the deployed endpoint before releasing. Release through the existing portfolio Amplify app, not the EnterpriseIQ app.

Website acceptance: EnterpriseIQ entry appears, links open the correct repository/case study, no claim of hosted authenticated acceptance is made until captured, and the existing counter still works. The website source update is separate from publication of the repository package.
