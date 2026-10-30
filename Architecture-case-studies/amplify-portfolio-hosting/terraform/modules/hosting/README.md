# Hosting module

Owns an imported GitHub-connected app/branch, monorepo build, headers and www-to-apex redirect. First authorize the Amplify GitHub App and import both resources. No access_token input. Auto-build defaults off; previews/basic-auth are off. App has prevent_destroy. appRoot includes website/scripts; build/site is the static artifact.
