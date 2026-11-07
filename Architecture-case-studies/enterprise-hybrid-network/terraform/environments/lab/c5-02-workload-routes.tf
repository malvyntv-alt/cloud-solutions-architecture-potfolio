# Workload routes. See docs/terraform-resource-map.md for the full resource index.

resource "aws_route" "workload" {
  for_each               = local.workload_routes
  route_table_id         = module.vpc[each.value.source].workload_route_table_ids[each.value.zone]
  destination_cidr_block = local.networks[each.value.destination]
  transit_gateway_id     = module.transit_gateway.id
  depends_on             = [module.transit_gateway]
}
