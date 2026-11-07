# Route tables. See docs/terraform-resource-map.md for the full resource index.

resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each           = var.networks
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags               = { Name = "${var.name}-${each.key}" }
}
