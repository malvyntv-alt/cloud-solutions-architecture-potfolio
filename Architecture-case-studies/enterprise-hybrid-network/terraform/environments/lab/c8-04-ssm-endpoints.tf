# Ssm endpoints. See docs/terraform-resource-map.md for the full resource index.

resource "aws_vpc_endpoint" "ssm" {
  for_each            = local.management_endpoints
  vpc_id              = module.vpc[each.value.network].vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value.service}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = values(module.vpc[each.value.network].workload_subnet_ids)
  security_group_ids  = [aws_security_group.ssm[each.value.network].id]
}

resource "aws_vpc_endpoint" "onprem_ssm" {
  for_each            = var.enable_hybrid && var.enable_test_hosts ? toset(["ssm", "ssmmessages"]) : toset([])
  vpc_id              = aws_vpc.onprem["lab"].id
  service_name        = "com.amazonaws.${var.aws_region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.onprem_workload["lab"].id]
  security_group_ids  = [aws_security_group.onprem_ssm["lab"].id]
}
