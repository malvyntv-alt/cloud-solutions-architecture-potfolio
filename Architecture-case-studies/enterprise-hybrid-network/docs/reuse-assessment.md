# Current project reuse assessment

The source is the parent `terraform-manifests` application stack: one VPC, public/private/database subnets, NAT, bastion, ALB, ACM, Route 53, and Auto Scaling. Its numbered filenames organize one Terraform root; they do not impose execution order. Terraform uses resource dependencies.

| Existing source | Decision for the networking project |
| --- | --- |
| `c1-versions.tf` | Reuse separation of Terraform/provider requirements and AWS region configuration. Select a bounded provider version and commit a new lock file. Do not copy the existing S3 backend settings. |
| `c2-generic-variables.tf` | Reuse typed region, environment and owner inputs; fix `business_divsion` spelling and replace application-specific defaults. |
| `c3-local-values.tf` | Reuse predictable names and common tags; omit sample ASG tags and random naming. |
| `c4-01-vpc-variables.tf` | Reuse the CIDR/AZ/subnet input concepts, expanded to a map of four network zones. |
| `c4-02-vpc-module.tf` | Reuse DNS support, subnet tagging and multi-AZ concepts. Either wrap a reviewed, pinned VPC module or implement a small native-resource module. Remove default NAT/public/database-subnet-group assumptions. |
| `c4-03-vpc-outputs.tf` | Reuse VPC/subnet outputs; add TGW IDs, attachment IDs and route-table IDs for verification. |
| `c5-*` security groups | Reuse narrow, purpose-specific group organization. Replace the bastion's `0.0.0.0/0` SSH rule with a deliberately chosen lab access method. |
| `c6-*`, `c7-*`, `c8-*` | Defer AMIs, hosts and EIPs until testing or router simulation requires them. Do not copy Route 53 hosted-zone lookups. |
| `c9-nullresource-provisioners.tf` | Do not copy: this transfers a private SSH key onto the bastion. Prefer instance roles and Systems Manager for test hosts, with a planned connectivity path. |
| `c10-*` through `c13-*` | Leave ALB, ACM, public DNS and Auto Scaling in the application project. They do not implement TGW segmentation. |
| `dev.conf`, `stag.conf`, variable files | Reuse the idea of per-root configuration, not the account identifiers, backend keys or application values. |
| `private-key/`, `.terraform/`, state | Never copy into the new project. |

Keep a single lab root initially because the four VPCs are simultaneous network zones, not four separate deployment environments. Use modules for repeated components. Multiple accounts and AWS RAM sharing are a later production-design extension, not a claim about this single-account lab.
