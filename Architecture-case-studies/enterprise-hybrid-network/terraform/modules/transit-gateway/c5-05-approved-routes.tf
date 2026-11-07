# Approved routes. See docs/terraform-resource-map.md for the full resource index.

resource "aws_ec2_transit_gateway_route" "allowed" {
  for_each                       = var.allowed_routes
  destination_cidr_block         = var.networks[each.value.destination].cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.value.destination].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.source].id
}
