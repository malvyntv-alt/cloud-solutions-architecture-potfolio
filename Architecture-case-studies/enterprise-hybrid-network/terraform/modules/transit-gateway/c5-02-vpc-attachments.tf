# Vpc attachments. See docs/terraform-resource-map.md for the full resource index.

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each                                        = var.networks
  transit_gateway_id                              = aws_ec2_transit_gateway.this.id
  vpc_id                                          = each.value.vpc_id
  subnet_ids                                      = each.value.subnet_ids
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags                                            = { Name = "${var.name}-${each.key}" }
}
