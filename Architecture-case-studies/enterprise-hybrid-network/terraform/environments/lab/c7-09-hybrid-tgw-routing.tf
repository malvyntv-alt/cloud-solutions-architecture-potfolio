# Hybrid tgw routing. See docs/terraform-resource-map.md for the full resource index.

resource "aws_ec2_transit_gateway_route_table" "hybrid" {
  for_each           = local.hybrid
  transit_gateway_id = module.transit_gateway.id
  tags               = { Name = "${var.project_name}-hybrid" }
}

resource "aws_ec2_transit_gateway_route_table_association" "hybrid" {
  for_each                       = local.hybrid
  transit_gateway_attachment_id  = aws_vpn_connection.onprem[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hybrid[each.key].id
}

resource "aws_ec2_transit_gateway_route" "hybrid" {
  for_each                       = local.hybrid_networks
  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = module.transit_gateway.attachment_ids[each.key]
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hybrid["lab"].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "onprem" {
  for_each                       = local.hybrid_networks
  transit_gateway_attachment_id  = aws_vpn_connection.onprem["lab"].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.transit_gateway.route_table_ids[each.key]
}

resource "aws_route" "onprem_return" {
  for_each               = { for pair in setproduct(keys(local.hybrid_networks), ["0", "1"]) : "${pair[0]}-${pair[1]}" => pair }
  route_table_id         = module.vpc[each.value[0]].workload_route_table_ids[each.value[1]]
  destination_cidr_block = "172.16.1.0/24"
  transit_gateway_id     = module.transit_gateway.id
  depends_on             = [aws_ec2_transit_gateway_route_table_association.hybrid]
}
