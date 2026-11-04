# Publication and website handoff

## Repository

The confirmed destination is the existing GitHub repository: https://github.com/malvyntv-alt/cloud-solutions-architecture-potfolio, under Architecture-case-studies/enterpriseiq-gen-ai. Keep the existing origin remote. The architecture includes both Mermaid and a written request path.

Before publishing, inspect the diff and publishable file list. Exclude generated archives, dist/node_modules, Terraform state/plans/caches, backend.hcl, local settings and raw logs. Add only sanitized evidence. Keep planned evaluation cases labeled as planned. Review older repository documentation for stale status and identifiers.

Commit reviewed changes and push to the existing GitHub origin. A read-only Amplify branch check confirmed enableAutoBuild=false for the portfolio main branch; pushing alone does not publish the website. Release the website separately through the existing portfolio hosting workflow.

## malvernvito.com

The source is in the sibling amplify-portfolio-hosting/website/index.html. The new entry should describe the deployed DEV RAG architecture, link to an accessible case study and identify sign-in as invite-only. Do not publish test-user credentials or present the demo as an unrestricted public chatbot.

Preserve the existing page-view counter endpoint when building the portfolio site. The source default is blank and a build without COUNTER_API_URL disables the counter. Verify the generated counter-config.js matches the deployed endpoint before releasing. Release through the existing portfolio Amplify app, not the EnterpriseIQ app.

Website acceptance: EnterpriseIQ entry appears, links open the correct repository/case study, no claim of hosted authenticated acceptance is made until captured, and the existing counter still works. The website source update is separate from publication of the repository package.
