# Terraform

Two roots: bootstrap/ owns protected state storage and CI identity; stacks/regional/ owns the workload. No child modules exist yet.

Regional files group declarations by responsibility. References establish dependencies. Demo/HA are profiles of the same state; pass the HA override after the base configuration.

Both provider lock files are committed. State, caches, plans and private tfvars are ignored. Protect bootstrap local state separately. Use a new backend identity; see [deployment](../docs/deployment/aws.md).
