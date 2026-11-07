# DNS access is limited to the on-premises client subnet and shared Resolver addresses.
locals {
  dns      = var.enable_hybrid_dns ? { lab = true } : {}
  dns_vpcs = var.enable_hybrid_dns ? { production = local.networks.production, shared = local.networks.shared } : {}
}
resource "aws_security_group" "resolver_in" {
  for_each = local.dns
  vpc_id   = module.vpc["shared"].vpc_id
  dynamic "ingress" {
    for_each = ["tcp", "udp"]
    content {
      protocol    = ingress.value
      from_port   = 53
      to_port     = 53
      cidr_blocks = ["172.16.0.10/32"]
    }
  }
}
resource "aws_security_group" "resolver_out" {
  for_each = local.dns
  vpc_id   = module.vpc["shared"].vpc_id
  dynamic "egress" {
    for_each = ["tcp", "udp"]
    content {
      protocol    = egress.value
      from_port   = 53
      to_port     = 53
      cidr_blocks = ["172.16.0.10/32"]
    }
  }
}
resource "aws_security_group" "router_dns" {
  for_each = local.dns
  vpc_id   = aws_vpc.onprem["lab"].id
  dynamic "ingress" {
    for_each = ["tcp", "udp"]
    content {
      protocol    = ingress.value
      from_port   = 53
      to_port     = 53
      cidr_blocks = ["172.16.1.0/24", "10.30.1.11/32", "10.30.2.11/32"]
    }
  }
}
resource "aws_security_group" "onprem_dns_client" {
  for_each = local.dns
  vpc_id   = aws_vpc.onprem["lab"].id
  dynamic "egress" {
    for_each = ["tcp", "udp"]
    content {
      protocol    = egress.value
      from_port   = 53
      to_port     = 53
      cidr_blocks = ["172.16.0.10/32"]
    }
  }
}
