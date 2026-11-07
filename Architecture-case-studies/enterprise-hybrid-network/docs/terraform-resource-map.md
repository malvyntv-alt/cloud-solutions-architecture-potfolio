# Terraform resource map

> Live-session update: the full lab was deployed and tested on November 6, 2026. See [observed results and cleanup status](live-validation-2026-11-06.md); failover recovery remains unfinished. Earlier pending-status text below describes the predeployment baseline.


Status: resources are defined in code; no AWS deployment is claimed.

File prefixes group related topics, following the sample project. Terraform loads all `.tf` files in a directory together; numbers do not control creation order. References and dependencies do. Keep resources in their existing root/module directories so resource addresses and state ownership stay unchanged.

## Lab root

Run Terraform from `terraform/environments/lab`. `module.vpc` repeats the VPC module for Production, Development, Shared and Restricted. `module.transit_gateway` creates the centralized routing hub.

| File | Defines |
| --- | --- |
| [c3-01-availability-zones.tf](../terraform/environments/lab/c3-01-availability-zones.tf) | `data.aws_availability_zones.available.available` |
| [c4-01-vpc-module.tf](../terraform/environments/lab/c4-01-vpc-module.tf) | `module.vpc` |
| [c5-01-transit-gateway-module.tf](../terraform/environments/lab/c5-01-transit-gateway-module.tf) | `module.transit_gateway` |
| [c5-02-workload-routes.tf](../terraform/environments/lab/c5-02-workload-routes.tf) | `aws_route.workload` |
| [c6-01-flow-logs.tf](../terraform/environments/lab/c6-01-flow-logs.tf) | `aws_cloudwatch_log_group.flow`, `aws_flow_log.vpc` |
| [c6-02-flow-log-iam.tf](../terraform/environments/lab/c6-02-flow-log-iam.tf) | `data.aws_iam_policy_document.flow_assume`, `aws_iam_role.flow`, `data.aws_iam_policy_document.flow`, `aws_iam_role_policy.flow` |
| [c7-01-onprem-network.tf](../terraform/environments/lab/c7-01-onprem-network.tf) | `aws_vpc.onprem`, `aws_subnet.router`, `aws_subnet.onprem_workload`, `aws_internet_gateway.onprem` |
| [c7-02-onprem-routing.tf](../terraform/environments/lab/c7-02-onprem-routing.tf) | `aws_route_table.router`, `aws_route_table_association.router`, `aws_route_table.onprem_workload`, `aws_route_table_association.onprem_workload`, `aws_route.onprem_workload` |
| [c7-03-router-security.tf](../terraform/environments/lab/c7-03-router-security.tf) | `aws_security_group.router` |
| [c7-04-router-interface.tf](../terraform/environments/lab/c7-04-router-interface.tf) | `aws_network_interface.router`, `aws_eip.router` |
| [c7-05-router-iam.tf](../terraform/environments/lab/c7-05-router-iam.tf) | `aws_iam_role.router`, `aws_iam_role_policy_attachment.router_ssm`, `aws_iam_role_policy.router_vpn`, `aws_iam_instance_profile.router` |
| [c7-06-router-instance.tf](../terraform/environments/lab/c7-06-router-instance.tf) | `aws_instance.router` |
| [c7-07-customer-gateway.tf](../terraform/environments/lab/c7-07-customer-gateway.tf) | `aws_customer_gateway.onprem` |
| [c7-08-site-to-site-vpn.tf](../terraform/environments/lab/c7-08-site-to-site-vpn.tf) | `aws_vpn_connection.onprem` |
| [c7-09-hybrid-tgw-routing.tf](../terraform/environments/lab/c7-09-hybrid-tgw-routing.tf) | `aws_ec2_transit_gateway_route_table.hybrid`, `aws_ec2_transit_gateway_route_table_association.hybrid`, `aws_ec2_transit_gateway_route.hybrid`, `aws_ec2_transit_gateway_route_table_propagation.onprem`, `aws_route.onprem_return` |
| [c8-01-ami.tf](../terraform/environments/lab/c8-01-ami.tf) | `data.aws_ami.ubuntu` |
| [c8-02-test-host-iam.tf](../terraform/environments/lab/c8-02-test-host-iam.tf) | `aws_iam_role.test`, `aws_iam_role_policy_attachment.test`, `aws_iam_instance_profile.test` |
| [c8-03-test-security.tf](../terraform/environments/lab/c8-03-test-security.tf) | `aws_security_group.test`, `aws_security_group.ssm`, `aws_security_group.onprem_test`, `aws_security_group.onprem_ssm` |
| [c8-04-ssm-endpoints.tf](../terraform/environments/lab/c8-04-ssm-endpoints.tf) | `aws_vpc_endpoint.ssm`, `aws_vpc_endpoint.onprem_ssm` |
| [c8-05-test-instances.tf](../terraform/environments/lab/c8-05-test-instances.tf) | `aws_instance.test`, `aws_instance.onprem_test` |
| [locals.tf](../terraform/environments/lab/locals.tf) | locals, locals, locals, locals, locals |
| [outputs.tf](../terraform/environments/lab/outputs.tf) | `output.hybrid`, `output.address_space`, `output.networks`, `output.transit_gateway`, `output.flow_log_group`, `output.allowed_routes`, `output.test_hosts`, `output.onprem_test_host` |
| [providers.tf](../terraform/environments/lab/providers.tf) | `provider.aws` |
| [variables.tf](../terraform/environments/lab/variables.tf) | `variable.aws_region`, `variable.project_name`, `variable.owner`, `variable.availability_zones`, `variable.enable_hybrid`, `variable.enable_test_hosts` |
| [versions.tf](../terraform/environments/lab/versions.tf) | terraform |

## vpc module

| File | Defines |
| --- | --- |
| [c4-01-vpc.tf](../terraform/modules/vpc/c4-01-vpc.tf) | `aws_vpc.this` |
| [c4-02-subnets.tf](../terraform/modules/vpc/c4-02-subnets.tf) | `aws_subnet.workload`, `aws_subnet.attachment` |
| [c4-03-route-tables.tf](../terraform/modules/vpc/c4-03-route-tables.tf) | `aws_route_table.workload`, `aws_route_table_association.workload`, `aws_route_table.attachment`, `aws_route_table_association.attachment` |
| [locals.tf](../terraform/modules/vpc/locals.tf) | locals |
| [outputs.tf](../terraform/modules/vpc/outputs.tf) | `output.vpc_id`, `output.workload_subnet_ids`, `output.attachment_subnet_ids`, `output.workload_route_table_ids` |
| [variables.tf](../terraform/modules/vpc/variables.tf) | `variable.name`, `variable.cidr`, `variable.availability_zones` |
| [versions.tf](../terraform/modules/vpc/versions.tf) | terraform |

## transit-gateway module

| File | Defines |
| --- | --- |
| [c5-01-transit-gateway.tf](../terraform/modules/transit-gateway/c5-01-transit-gateway.tf) | `aws_ec2_transit_gateway.this` |
| [c5-02-vpc-attachments.tf](../terraform/modules/transit-gateway/c5-02-vpc-attachments.tf) | `aws_ec2_transit_gateway_vpc_attachment.this` |
| [c5-03-route-tables.tf](../terraform/modules/transit-gateway/c5-03-route-tables.tf) | `aws_ec2_transit_gateway_route_table.this` |
| [c5-04-associations.tf](../terraform/modules/transit-gateway/c5-04-associations.tf) | `aws_ec2_transit_gateway_route_table_association.this` |
| [c5-05-approved-routes.tf](../terraform/modules/transit-gateway/c5-05-approved-routes.tf) | `aws_ec2_transit_gateway_route.allowed` |
| [outputs.tf](../terraform/modules/transit-gateway/outputs.tf) | `output.id`, `output.attachment_ids`, `output.route_table_ids` |
| [variables.tf](../terraform/modules/transit-gateway/variables.tf) | `variable.name`, `variable.networks`, `variable.allowed_routes` |
| [versions.tf](../terraform/modules/transit-gateway/versions.tf) | terraform |

## Resource counts and switches

- Core: four VPCs, sixteen subnets, twelve explicit VPC route tables, sixteen subnet associations, one TGW, four VPC attachments, four TGW tables/associations, six TGW routes and twelve workload routes. Each VPC also receives AWS default networking objects.
- Logging: four VPC flow logs, one log group, one IAM role and one inline policy.
- `enable_hybrid = true`: simulated data-center VPC/subnets/IGW/routing, router ENI/EIP/EC2/IAM, customer gateway, VPN and selective hybrid TGW routing.
- `enable_test_hosts = true`: eight AWS test instances, security groups, instance role/profile and eight interface endpoints across two AZs.
- Both switches enabled: one additional on-premises test host, two endpoint services in its subnet and their security groups.

Use `terraform state list` to see what is actually managed after deployment. Source files show definitions; `for_each` and `count` determine instance counts. The `.terraform` directory is generated provider/module metadata, not project source. `.terraform.lock.hcl` pins provider selection and should be committed.

## Hybrid DNS additions

| File | Defines |
| --- | --- |
| `c9-01-dns-security.tf` | DNS locals and endpoint/router/client security groups |
| `c9-02-resolver-endpoints.tf` | Two Resolver endpoints, each in two AZs; Shared /32 return routes |
| `c9-03-dns-zones-and-rules.tf` | Private zone, record, Production association, forwarding rule/associations and DNS outputs |

Optional DNS requires both existing switches. See [DNS guide](hybrid-dns.md) for the additional router BGP prefix and query paths.
