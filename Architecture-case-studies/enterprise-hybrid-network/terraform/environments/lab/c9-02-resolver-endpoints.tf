# Fixed endpoint addresses make router forwarding deterministic without a dependency cycle.
resource "aws_route53_resolver_endpoint" "inbound" {
  for_each           = local.dns
  name               = "${var.project_name}-inbound"
  direction          = "INBOUND"
  security_group_ids = [aws_security_group.resolver_in[each.key].id]
  dynamic "ip_address" {
    for_each = { "0" = "10.30.1.10", "1" = "10.30.2.10" }
    content {
      subnet_id = module.vpc["shared"].workload_subnet_ids[ip_address.key]
      ip        = ip_address.value
    }
  }
  lifecycle {
    precondition {
      condition     = var.enable_hybrid && var.enable_test_hosts
      error_message = "Hybrid DNS requires enable_hybrid and enable_test_hosts."
    }
  }
}
resource "aws_route53_resolver_endpoint" "outbound" {
  for_each           = local.dns
  name               = "${var.project_name}-outbound"
  direction          = "OUTBOUND"
  security_group_ids = [aws_security_group.resolver_out[each.key].id]
  dynamic "ip_address" {
    for_each = { "0" = "10.30.1.11", "1" = "10.30.2.11" }
    content {
      subnet_id = module.vpc["shared"].workload_subnet_ids[ip_address.key]
      ip        = ip_address.value
    }
  }
}
resource "aws_route" "dns_return" {
  for_each               = var.enable_hybrid_dns ? toset(["0", "1"]) : toset([])
  route_table_id         = module.vpc["shared"].workload_route_table_ids[each.key]
  destination_cidr_block = "172.16.0.10/32"
  transit_gateway_id     = module.transit_gateway.id
}
