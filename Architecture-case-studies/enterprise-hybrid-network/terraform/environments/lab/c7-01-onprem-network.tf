# Onprem network. See docs/terraform-resource-map.md for the full resource index.

resource "aws_vpc" "onprem" {
  for_each             = local.hybrid
  cidr_block           = local.on_premises_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-onprem" }
}

resource "aws_subnet" "router" {
  for_each          = local.hybrid
  vpc_id            = aws_vpc.onprem[each.key].id
  cidr_block        = "172.16.0.0/24"
  availability_zone = local.availability_zones[0]
}

resource "aws_subnet" "onprem_workload" {
  for_each          = local.hybrid
  vpc_id            = aws_vpc.onprem[each.key].id
  cidr_block        = "172.16.1.0/24"
  availability_zone = local.availability_zones[0]
}

resource "aws_internet_gateway" "onprem" {
  for_each = local.hybrid
  vpc_id   = aws_vpc.onprem[each.key].id
}
