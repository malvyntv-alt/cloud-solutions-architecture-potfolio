# Transit gateway. See docs/terraform-resource-map.md for the full resource index.

resource "aws_ec2_transit_gateway" "this" {
  description                     = var.name
  amazon_side_asn                 = 64512
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  auto_accept_shared_attachments  = "disable"
  tags                            = { Name = var.name }
}
