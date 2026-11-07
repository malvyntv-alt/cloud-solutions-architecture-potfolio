mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/mock-role" }
  }
  mock_resource "aws_cloudwatch_log_group" {
    defaults = { arn = "arn:aws:logs:us-east-1:123456789012:log-group:mock" }
  }
  mock_resource "aws_eip" {
    defaults = { public_ip = "192.0.2.10" }
  }
  mock_resource "aws_instance" {
    defaults = { private_ip = "172.16.1.10" }
  }
  mock_data "aws_ami" {
    defaults = { id = "ami-0123456789abcdef0" }
  }
  # Policy document data sources are local JSON generators in the real provider.
  # Supply valid JSON instead of the mock provider's generated string.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  enable_hybrid      = false
  enable_test_hosts  = false
  enable_hybrid_dns  = false
  availability_zones = ["us-east-1a", "us-east-1b"]
}
run "segmentation_policy" {
  command = plan
  assert {
    condition     = length(module.vpc) == 4 && length(aws_route.workload) == 12
    error_message = "Expected four VPCs and six approved paths in each of two AZs."
  }
  assert {
    condition     = toset(keys(local.allowed_routes)) == toset(["production-shared", "production-restricted", "development-shared", "shared-production", "shared-development", "restricted-production"])
    error_message = "The routing policy must contain exactly the six approved directed paths."
  }
  assert {
    condition     = alltrue([for route in aws_route.workload : route.destination_cidr_block != "0.0.0.0/0" && route.destination_cidr_block != "10.0.0.0/8"])
    error_message = "Broad routes must not bypass segmentation."
  }
  assert {
    condition     = length(aws_flow_log.vpc) == 4 && aws_cloudwatch_log_group.flow.retention_in_days == 7
    error_message = "All four VPCs require flow logs with bounded retention."
  }
}

run "hybrid_and_test_hosts" {
  command = plan
  variables {
    enable_hybrid     = true
    enable_test_hosts = true
  }
  assert {
    condition     = length(aws_instance.test) == 8 && length(aws_vpc_endpoint.ssm) == 8
    error_message = "Each AWS network needs two hosts and two SSM endpoints."
  }
  assert {
    condition     = toset(keys(aws_ec2_transit_gateway_route_table_propagation.onprem)) == toset(["production", "shared"]) && length(aws_route.onprem_return) == 4
    error_message = "BGP propagation and return routes must only reach production/shared."
  }
  assert {
    condition     = aws_vpn_connection.onprem["lab"].static_routes_only == false && aws_network_interface.router["lab"].source_dest_check == false && length(module.vpc) == 4
    error_message = "The simulator requires BGP and forwarding, with no extra direct TGW VPC attachment."
  }
}

run "hybrid_dns_policy" {
  # Applies only to the mocked provider; no AWS API calls or resources.
  command = apply
  variables {
    enable_hybrid     = true
    enable_test_hosts = true
    enable_hybrid_dns = true
  }
  assert {
    condition     = length(aws_route53_resolver_endpoint.inbound["lab"].ip_address) == 2 && length(aws_route53_resolver_endpoint.outbound["lab"].ip_address) == 2
    error_message = "Each DNS direction needs addresses in two AZs."
  }
  assert {
    condition     = toset(keys(aws_route53_resolver_rule_association.onprem)) == toset(["production", "shared"])
    error_message = "Only production and shared may forward on-premises DNS queries."
  }
  assert {
    condition     = alltrue([for route in aws_route.dns_return : route.destination_cidr_block == "172.16.0.10/32"]) && length(aws_route.dns_return) == 2
    error_message = "Shared DNS routes must be limited to the router host in both AZs."
  }
  assert {
    condition     = aws_route53_resolver_rule.onprem["lab"].domain_name == "onprem.lab.test" && aws_route53_zone.cloud["lab"].name == "aws.lab.test"
    error_message = "Use separate namespaces to prevent a forwarding loop."
  }
}
