# ADR 003: Deployment ownership

Status: implemented.

Bootstrap owns state storage/CI identity; regional Terraform owns workload resources. Demo/HA are profiles of one state.

This edition has new Git history, AWS project default and backend key. Source state/credentials are excluded. Account-wide OIDC needs explicit ownership.

File grouping preserves resource addresses; no modules were introduced. Extract a regional module when implementing a second region, with explicit providers and state migration. Folder names alone do not isolate AWS.
