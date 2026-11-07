# Associations. See docs/terraform-resource-map.md for the full resource index.

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each                       = var.networks
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.key].id
}
