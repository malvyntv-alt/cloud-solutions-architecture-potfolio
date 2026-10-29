# Portfolio ownership and layout

The exact owner-selected names are cloud-solutions-architecture-portfolio and Architecture-case-studies. The current project is auto-financing-quotes-platform.

This is one Git repository, not a submodule collection. Both existing local repositories remain untouched. The latest tracked standalone project files were copied, excluding raw deployment logs and private/generated artifacts. Existing deployment records were preserved as historical evidence.

## Working directories

| Operation | Working directory |
|---|---|
| Portfolio index / link checks | Portfolio root |
| Python application/tests | Architecture-case-studies/auto-financing-quotes-platform |
| Local deployment helpers | Project folder; helpers locate it via their own paths |
| Terraform | Project folder, using -chdir=infra/... |
| GitHub workflow definitions | Portfolio-root .github/workflows |
| GitHub Docker build context | Architecture-case-studies/auto-financing-quotes-platform |

Root CI is named auto-financing-checks. The manual auto-financing-build-images workflow depends on those checks and uses project-scoped Dockerfiles/context. Future projects need their own CI jobs/workflows.

The new repository has no inherited remote or Git history. Existing AWS names/defaults are preserved; no infrastructure or backend migration occurred. Configure OIDC trust for the portfolio repository before attempting image publishing.

## Adding projects

Add a sibling folder under Architecture-case-studies, document status/ownership/decisions/evidence, update both indexes and CI, then run link/artifact checks. Keep project files local to the project and shared portfolio policy at the root.

A future repository-wide license is an owner decision and has not been invented.
